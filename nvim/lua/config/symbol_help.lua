local M = {}
local request = 0
local pending = {}
M.timeout_ms = 1500
local docs = require('config.documentation')
local signature_ns = vim.api.nvim_create_namespace('symbol_help_parameter')

function M.cancel()
  request = request + 1
  for record in pairs(pending) do
    record.finished = true
    if record.timer then record.timer:stop(); record.timer:close() end
    if record.id and record.client.cancel_request then pcall(record.client.cancel_request,record.client,record.id) end
    pending[record] = nil
  end
end

-- Track the innermost unfinished call, ignoring quoted strings and comments.
-- This fallback also works before a parser has been installed.
function M.call_name(prefix)
  local stack, quote, escaped = {}, nil, false
  local i = 1
  while i <= #prefix do
    local c = prefix:sub(i, i)
    if quote then
      if escaped then escaped = false
      elseif c == '\\' then escaped = true
      elseif c == quote then quote = nil end
    elseif c == '"' or c == "'" or c == '`' then
      quote = c
    elseif c == '#' or prefix:sub(i, i + 1) == '//' or prefix:sub(i, i + 1) == '--' then
      i = prefix:find('\n', i, true) or #prefix
    elseif c == '(' or c == '[' or c == '{' then
      local name = c == '(' and prefix:sub(1, i - 1):match('([%a_][%w_%.:]*)%s*$') or nil
      if name == 'if' or name == 'while' or name == 'for' or name == 'switch' then name = nil end
      stack[#stack + 1] = { char = c, name = name }
    elseif c == ')' or c == ']' or c == '}' then
      local expected = ({ [')'] = '(', [']'] = '[', ['}'] = '{' })[c]
      if stack[#stack] and stack[#stack].char == expected then table.remove(stack) end
    end
    i = i + 1
  end
  if quote then return nil end
  for j = #stack, 1, -1 do
    if stack[j].name then return stack[j].name end
  end
end

function M.show(word, prefer_signature, signature_only)
  if not signature_only and not word and docs.focus() then return end
  local resolver = package.loaded['config.docs_resolver']
  if resolver then resolver.cancel() end
  M.cancel()
  local id, buf = request, vim.api.nvim_get_current_buf()
  local origin = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local function current()
    return id == request and vim.api.nvim_get_current_win() == origin and vim.api.nvim_get_current_buf() == buf
      and vim.api.nvim_buf_get_changedtick(buf) == tick
      and vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor)
  end
  local call
  if not word then
    local lines = vim.api.nvim_buf_get_lines(buf, math.max(0, cursor[1] - 40), cursor[1], false)
    local insert = vim.api.nvim_get_mode().mode:sub(1, 1) == 'i'
    lines[#lines] = lines[#lines]:sub(1, cursor[2] + (insert and 0 or 1))
    call = M.call_name(table.concat(lines, '\n'))
  end
  local function missing()
    if current() then vim.notify('No documentation available for this symbol', vim.log.levels.INFO) end
  end
  local function builtin()
    if not current() then return end
    if signature_only then return missing() end
    if vim.bo[buf].filetype == 'python' then
      require('config.python_help').show(word or call or vim.fn.expand('<cword>'), missing, current)
    else missing() end
  end
  -- Buffer suggestions have no resolver. Use the full label, not the typed prefix.
  if word then return builtin() end
  local function params(client)
    return vim.lsp.util.make_position_params(0, client.offset_encoding)
  end
  local function send(client,method,response)
    local record = {client=client}
    pending[record] = true
    local function finish(err,result)
      if record.finished then return end
      record.finished = true
      pending[record] = nil
      if record.timer then record.timer:stop(); record.timer:close(); record.timer=nil end
      response(err,result)
    end
    local position = params(client)
    if method == 'textDocument/signatureHelp' then position.context = {triggerKind=1,isRetrigger=false} end
    local ok,accepted,id = pcall(client.request,client,method,position,finish,buf)
    record.id = id
    if not ok or not accepted then finish(true)
    elseif not record.finished then
      record.timer = vim.defer_fn(function()
        record.timer = nil
        if record.id and client.cancel_request then pcall(client.cancel_request,client,record.id) end
        finish('timeout')
      end,M.timeout_ms)
    end
  end
  local function hover()
    if not current() then return end
    if signature_only then return missing() end
    local clients = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/hover' })
    if #clients == 0 then return builtin() end
    local remaining, lines = #clients, {}
    for _, client in ipairs(clients) do
      local function response(err, result)
        remaining = remaining - 1
        if not err and type(result) == 'table' and result.contents then
          local ok, content = pcall(vim.lsp.util.convert_input_to_markdown_lines, result.contents)
          if ok and #content > 0 and table.concat(content):match('%S') then
            if #lines > 0 then lines[#lines + 1] = '---' end
            vim.list_extend(lines, content)
          end
        end
        if remaining == 0 then
          if not current() then return end
          if #lines == 0 then return builtin() end
          docs.open(lines, 'Documentation · ' .. vim.fn.expand('<cword>'))
        end
      end
      send(client,'textDocument/hover',response)
    end
  end
  if (call or prefer_signature) and #vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/signatureHelp' }) > 0 then
    local sig_clients = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/signatureHelp' })
    local sig_remaining, sig_found = #sig_clients, false
    for _, client in ipairs(sig_clients) do
      local function response(err, result)
        sig_remaining = sig_remaining - 1
        if sig_found then return end
        if not current() then return end
        if not err and type(result) == 'table' and type(result.signatures) == 'table' and #result.signatures > 0 then
          local formatter = require('config.signature_help')
          local lines = formatter.format(result,vim.bo[buf].filetype)
          if lines and #lines > 0 then
            sig_found = true
            local function render(selected,focus)
              local content,hl,meta = formatter.format(result,vim.bo[buf].filetype,selected)
              local float,win = docs.open(content,'Signature '..(meta.total > 1 and (meta.selected+1)..'/'..meta.total..' · ' or '· ')..(call or vim.fn.expand('<cword>')),
                signature_only and {max_height=math.min(8,docs.options().max_height)} or nil)
              vim.api.nvim_buf_clear_namespace(float,signature_ns,0,-1)
              if hl then vim.hl.range(float,signature_ns,'LspSignatureActiveParameter',{hl[1],hl[2]},{hl[3],hl[4]}) end
              if meta.total > 1 then
                for key,delta in pairs({[']s']=1,['[s']=-1}) do
                  vim.keymap.set('n',key,function()
                    if not vim.api.nvim_win_is_valid(origin) or not vim.api.nvim_buf_is_valid(buf)
                      or vim.api.nvim_buf_get_changedtick(buf) ~= tick
                      or not vim.deep_equal(vim.api.nvim_win_get_cursor(origin),cursor) then return docs.close() end
                    -- Anchor replacements at the original call, then restore docs focus.
                    vim.api.nvim_set_current_win(origin)
                    docs.close()
                    render((meta.selected+delta)%meta.total,true)
                  end,{buffer=float,silent=true,desc='Switch signature overload'})
                end
              end
              if focus then vim.api.nvim_set_current_win(win) end
            end
            render()
            return
          end
        end
        if sig_remaining == 0 and not sig_found then hover() end
      end
      send(client,'textDocument/signatureHelp',response)
    end
  else
    hover()
  end
end

function M.signature()
  -- Expression mappings run under textlock; opening/closing windows must wait.
  vim.schedule(function()
    local cmp = package.loaded['blink.cmp']
    if cmp then cmp.hide(); cmp.hide_documentation(); cmp.hide_signature() end
    docs.close()
    M.show(nil, true, true)
  end)
  return true
end

return M
