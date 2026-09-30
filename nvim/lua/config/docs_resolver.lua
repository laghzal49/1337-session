-- Resolve only on an explicit documentation action; no idle work or text matches.
local M = { timeout_ms = 500, max_context_lines = 500 }
local generation, pending = 0, nil
local contexts = {}

local function stop()
  if not pending then return end
  local work = pending
  pending = nil
  if work.timer then work.timer:stop(); work.timer:close() end
  if work.group then vim.api.nvim_del_augroup_by_id(work.group) end
  for _, request in ipairs(work.requests) do
    if not request.done and request.id then pcall(request.client.cancel_request, request.client, request.id) end
  end
end

function M.cancel()
  generation = generation + 1
  stop()
end
M.cleanup = M.cancel

function M.current(saved, picker)
  if saved.epoch ~= generation or not vim.api.nvim_buf_is_valid(saved.buf) or not vim.api.nvim_win_is_valid(saved.win)
    or vim.api.nvim_win_get_buf(saved.win) ~= saved.buf or vim.api.nvim_buf_get_changedtick(saved.buf) ~= saved.tick then return false end
  local pos = vim.api.nvim_win_get_cursor(saved.win)
  return pos[1] == saved.pos[1] and pos[2] == saved.pos[2]
    and (picker or (vim.api.nvim_get_current_win() == saved.win and vim.api.nvim_get_current_buf() == saved.buf))
end

function M.capture()
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local width = vim.fn.col('$') - 1
  local first, last = math.max(0, pos[2] - 256), math.min(width, pos[2] + 257)
  local text = vim.api.nvim_buf_get_text(buf, pos[1] - 1, first, pos[1] - 1, last, {})[1] or ''
  local at = pos[2] - first + 1
  local word = (text:sub(1, at):match('([%w_%.:]+)$') or '') .. (text:sub(at + 1):match('^([%w_%.:]+)') or '')
  local metadata = vim.b[buf].black_docs
  return { epoch = generation, buf = buf, win = win, pos = pos, tick = vim.api.nvim_buf_get_changedtick(buf),
    word = word, docset = metadata and metadata.docset or require('config.docs_store').docset_for(vim.bo[buf].filetype),
    candidates = {}, hover_lines = {}, currentfunction = vim.b[buf].current_symbol }
end

local function qualify(name, aliases)
  local head, tail = name:match('^([%w_]+)(.*)$')
  return head and aliases[head] and aliases[head] .. tail or nil
end

local function python_context(saved)
  local cached = contexts[saved.buf]
  local count = vim.api.nvim_buf_line_count(saved.buf)
  local first = count <= M.max_context_lines and 0 or math.max(128, saved.pos[1] - 372)
  local key = saved.tick .. ':' .. first .. ':' .. saved.pos[1]
  if cached and cached.key == key then return cached end
  local rows = {}
  local function read(start, finish)
    for offset, line in ipairs(vim.api.nvim_buf_get_lines(saved.buf, start, finish, false)) do
      rows[#rows + 1] = { row = start + offset, line = line }
    end
  end
  if first == 0 then read(0, math.min(count, M.max_context_lines))
  else read(0, math.min(128, count)); read(first, math.min(count, first + 372)) end
  local scopes, scope_stack, records, row_scope = {}, {}, {}, {}
  for _, item in ipairs(rows) do
    local line, row = item.line, item.row
    local indent = #(line:match('^%s*') or '')
    if line:match('%S') and not line:match('^%s*#') then
      while #scope_stack > 0 and indent <= scope_stack[#scope_stack].indent do table.remove(scope_stack) end
    end
    local scope = #scope_stack > 0 and scope_stack[#scope_stack].row or 0
    row_scope[row] = scope
    local function add(name, imported, receiver)
      if name then records[#records + 1] = { row = row, scope = scope, name = name, imported = imported, receiver = receiver } end
    end
    local module, imported = line:match('^%s*from%s+([%w_%.]+)%s+import%s+(.+)')
    if module then
      for part in imported:gmatch('[^,]+') do
        local name, alias = part:match('^%s*([%w_]+)%s+as%s+([%w_]+)')
        name = name or part:match('^%s*([%w_]+)')
        if name then add(alias or name, module .. '.' .. name) end
      end
    else
      local imports = line:match('^%s*import%s+(.+)')
      if imports then
        for part in imports:gmatch('[^,]+') do
          local name, alias = part:match('^%s*([%w_%.]+)%s+as%s+([%w_]+)')
          name = name or part:match('^%s*([%w_%.]+)')
          if name then add(alias or name:match('^[^.]+'), alias and name or name:match('^[^.]+')) end
        end
      end
    end
    local name, parameters = line:match('^%s*def%s+([%w_]+)%s*%((.-)%)')
    name = name or line:match('^%s*class%s+([%w_]+)')
    if name then
      add(name)
      local parent = scope
      scope_stack[#scope_stack + 1] = { row = row, indent = indent }
      scopes[row] = parent
      if parameters then
        for part in parameters:gmatch('[^,]+') do
          local parameter = part:match('^%s*[%*]*([%w_]+)')
          local annotation = part:match('^%s*[%*]*[%w_]+%s*:%s*([%w_%.]+)')
          if parameter then records[#records + 1] = { row = row, scope = row, name = parameter, receiver = annotation } end
        end
      end
    end
    local lhs, annotation, rhs = line:match('^%s*([%w_]+)%s*:%s*([%w_%.]+)%s*=%s*(.*)')
    if not lhs then lhs, rhs = line:match('^%s*([%w_]+)%s*=%s*(.*)') end
    if not lhs then lhs, annotation = line:match('^%s*([%w_]+)%s*:%s*([%w_%.]+)%s*$') end
    if lhs then add(lhs, nil, annotation or rhs:match('^([%w_%.]+)%s*%(')) end
  end
  local target = row_scope[saved.pos[1]] or 0
  local active = { [0] = true }
  for _ = 1, 32 do if target == 0 or not target then break end; active[target] = true; target = scopes[target] end
  local aliases, receivers, locals = {}, {}, {}
  for _, record in ipairs(records) do
    if record.row <= saved.pos[1] and active[record.scope] then
      if record.imported then aliases[record.name], locals[record.name], receivers[record.name] = record.imported, nil, nil
      elseif record.receiver then
        receivers[record.name] = qualify(record.receiver, aliases)
        aliases[record.name], locals[record.name] = nil, not receivers[record.name]
      else aliases[record.name], receivers[record.name], locals[record.name] = nil, nil, true end
    end
  end
  cached = { key = key, aliases = aliases, receivers = receivers, locals = locals }
  contexts = { [saved.buf] = cached }
  return cached
end

local function normalize_type(name)
  if type(name) ~= 'string' then return '' end
  return name:gsub('%b<>', ''):gsub('__cxx11::', ''):gsub('__1::', ''):gsub('const ', ''):gsub('volatile ', '')
    :gsub('^%s+', ''):gsub('[%s&%*]+$', ''):gsub('::$', '')
end

local function markdown(result)
  if type(result) ~= 'table' or not result.contents then return {} end
  local ok, lines = pcall(vim.lsp.util.convert_input_to_markdown_lines, result.contents)
  return ok and lines or {}
end

local function candidates(saved, work)
  local seen = {}
  local function add(name)
    if type(name) ~= 'string' or name == '' or #name > 256 or seen[name] then return end
    seen[name] = true; saved.candidates[#saved.candidates + 1] = name
  end
  local py = saved.docset == 'python' and python_context(saved) or nil
  if py then
    local head, tail = saved.word:match('^([%w_]+)(.*)$')
    if head then
      saved.project_local = py.locals[head] == true
      local qualified = qualify(saved.word, py.aliases) or (py.receivers[head] and py.receivers[head] .. tail)
      if qualified then add(qualified) end
    end
  end
  if not py and (saved.docset == 'c' or saved.docset == 'cpp' or saved.docset == 'lua') then
    -- A bounded declaration check prevents a project implementation named like
    -- a standard API from being mistaken for that API. Never scan a whole file.
    local escaped = vim.pesc(saved.word)
    local lines = vim.api.nvim_buf_get_lines(saved.buf, 0, math.min(vim.api.nvim_buf_line_count(saved.buf), 500), false)
    for row, line in ipairs(lines) do
      if saved.docset == 'lua' then
        if line:match('^%s*local%s+function%s+' .. escaped .. '%s*%(')
          or line:match('^%s*function%s+' .. escaped .. '%s*%(') then saved.project_local = true; break end
      elseif saved.word:match('^[%w_]+$') and not line:match('^%s*[/%%*]') then
        local declaration = line:match('^%s*[%w_%s%*]+' .. escaped .. '%s*%b()%s*{')
          or (line:match('^%s*[%w_%s%*]*' .. escaped .. '%s*%b()%s*$') and (lines[row + 1] or ''):match('^%s*{'))
        if declaration then saved.project_local = true; break end
      end
    end
  end
  for _, result in ipairs(work.symbols) do
    local item = type(result) == 'table' and result[1]
    if type(item) == 'table' and type(item.name) == 'string' then
      local container = normalize_type(item.containerName)
      if container:find('::', 1, true) then add(container .. '::' .. item.name) end
    end
  end
  for _, result in ipairs(work.hovers) do
    local lines = markdown(result)
    if #saved.hover_lines == 0 then saved.hover_lines = lines end
    local text = table.concat(lines, '\n'):sub(1, 16384)
    if py then
      for fence in text:gmatch('```[^\n]*\n(.-)\n```') do
        for line in fence:gmatch('[^\n]+') do
          local name = line:match('^%s*bound method%s+([%w_%.]+)%s*%(') or line:match('^%s*def%s+([%w_%.]+)%s*%(')
            or line:match('^%s*class%s+([%w_%.]+)') or line:match("^%s*<class '([%w_%.]+)'>%s*$")
            or line:match('^%s*([%a_][%w_%.]*)%s*$')
          if name then
            local head = name:match('^[^.]+')
            if not py.locals[head] then add(qualify(name, py.aliases) or name) end
          end
        end
      end
    elseif saved.docset == 'c' or saved.docset == 'cpp' then
      local ty = text:match('Type: `([^`\n]+)`')
      if ty then
        add(normalize_type(ty:match('^(.-)%s*%(aka%s') or ty))
        local alias = ty:match('%(aka%s+(.*)%)%s*$')
        if alias then add(normalize_type(alias)) end
      end
    end
  end
  if saved.project_local then saved.candidates = {} end
  saved.allow_literal = not saved.project_local
  saved.identity = saved.candidates[1] or saved.word
end

function M.resolve(callback, opts)
  M.cancel()
  local saved = M.capture()
  if opts and opts.word then saved.word = opts.word end
  if opts and opts.docset then saved.docset = opts.docset end
  local work = { requests = {}, symbols = {}, hovers = {}, left = 0 }
  local function finish()
    if pending ~= work then return end
    stop()
    if not M.current(saved) then return end
    candidates(saved, work)
    callback(saved)
  end
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = saved.buf })) do
    for _, method in ipairs({ 'textDocument/symbolInfo', 'textDocument/hover' }) do
      if (method == 'textDocument/symbolInfo' and client.name == 'clangd' and (saved.docset == 'c' or saved.docset == 'cpp'))
        or (method == 'textDocument/hover' and client:supports_method(method, saved.buf)) then
        work.requests[#work.requests + 1] = { client = client, method = method }; work.left = work.left + 1
      end
    end
  end
  pending = work
  if work.left == 0 then finish(); return saved end
  work.group = vim.api.nvim_create_augroup('BlackDocsResolveRequest', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'BufLeave', 'WinLeave', 'TextChanged', 'VimLeavePre' }, {
    group = work.group, callback = M.cancel,
  })
  work.timer = vim.uv.new_timer()
  work.timer:start(opts and opts.timeout_ms or M.timeout_ms, 0, vim.schedule_wrap(finish))
  for _, request in ipairs(work.requests) do
    local params = vim.lsp.util.make_position_params(saved.win, request.client.offset_encoding)
    local function response(err, result)
      if pending ~= work or request.done then return end
      request.done = true; work.left = work.left - 1
      if not err and type(result) == 'table' then table.insert(request.method == 'textDocument/hover' and work.hovers or work.symbols, result) end
      if work.left == 0 then finish() end
    end
    local ok, id = request.client:request(request.method, params, response, saved.buf)
    request.id = id
    if not ok then response({ message = 'Request unavailable' }) end
  end
  return saved
end

return M
