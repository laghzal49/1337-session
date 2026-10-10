-- Project-aware background jobs. No shell interpolation or startup dependencies.
local M = { running = nil, last = nil, output = nil }
local posix = vim.fn.has('win32') == 0
local function signal_task(token, signal)
  if not token or not token.job then return end
  if token.group then
    -- detach gives this task a new POSIX session/process group; never signal the editor's group.
    pcall(vim.uv.kill, -token.job.pid, signal)
  else
    pcall(token.job.kill, token.job, signal)
  end
end
local output_limit = 1024 * 1024 -- Bound retained stdout/stderr even for noisy builds.
local function capture(stream, data)
  if not data or stream.truncated then return end
  local remaining = output_limit - stream.bytes
  local chunk = data:sub(1, math.max(0, remaining))
  local cursor = 1
  while true do
    local newline = chunk:find('\n', cursor, true)
    if not newline then break end
    stream.lines = (stream.lines or 0) + 1
    if stream.lines >= 5000 then
      chunk = chunk:sub(1, newline)
      stream.truncated = true
      break
    end
    cursor = newline + 1
  end
  if #chunk > 0 then
    stream.chunks[#stream.chunks + 1] = chunk
    stream.bytes = stream.bytes + #chunk
  end
  if #data > remaining then stream.truncated = true end
end

local function clean_output(output)
  return output:gsub('\27%[[%d;]*[%a]', '')
end

-- Parse familiar runner output without changing compiler options or editor cwd.
function M.parse_errors(task, output, efm)
  local root = task.cwd or require('config.project').root()
  local runner = task.runner or (task.name or ''):match('^([^:]+):')
  local lines, items, seen, handled = vim.split(clean_output(output), '\n'), {}, {}, {}
  local function severity(message)
    message = (message or ''):lower()
    if message:match('^warning[%s:]') then return 'W' end
    if message:match('^note[%s:]') or message:match('^hint[%s:]') then return 'I' end
    return 'E'
  end
  local function add(path, line, col, message, kind)
    if not path or not line then return end
    if not path:match('^[/\\]') and not path:match('^%a:[/\\]') then path = root .. '/' .. path end
    path = vim.fs.normalize(path)
    local key = path .. ':' .. line .. ':' .. (col or 0)
    if seen[key] then return seen[key] end
    local item = { filename = path, lnum = tonumber(line), col = tonumber(col) or 0,
      text = message or '', type = kind or severity(message), valid = 1 }
    seen[key], items[#items + 1] = item, item
    return item
  end
  local pending, eslint_file, traceback
  for row, line in ipairs(lines) do
    local common_path, common_line, common_col, common_message = line:match('^%s*(.-):(%d+):(%d+):%s*(.+)$')
    if not common_path then common_path, common_line, common_message = line:match('^%s*(.-):(%d+):%s*(.+)$') end
    if common_path and not line:match('^%s*%-%->') and not line:match(':%d+%s+%-%s') then add(common_path, common_line, common_col, common_message); handled[row] = true end
    if runner == 'cargo' then
      local kind, message = line:match('^(error[^:]*):%s*(.+)')
      if not kind then kind, message = line:match('^(warning):%s*(.+)') end
      if kind then pending = { message = message, kind = kind == 'warning' and 'W' or 'E' } end
      local path, lnum, col = line:match('^%s*%-%->%s*(.-):(%d+):(%d+)%s*$')
      if path then add(path, lnum, col, pending and pending.message or 'Rust diagnostic', pending and pending.kind); handled[row] = true end
    elseif runner == 'npm' or runner == 'pnpm' or runner == 'yarn' then
      local path, lnum, col, message = line:match('^(.-)%((%d+),(%d+)%)%s*:%s*(.+)$')
      if not path then path, lnum, col, message = line:match('^(.-):(%d+):(%d+)%s+%-%s+(.+)$') end
      if path then add(path, lnum, col, message); handled[row] = true end
      if line:match('^[^%s].-%.[jt]sx?$') then eslint_file = line end
      local eline, ecol, severity, msg = line:match('^%s+(%d+):(%d+)%s+(%a+)%s+(.+)$')
      if eslint_file and eline then add(eslint_file, eline, ecol, msg, severity == 'warning' and 'W' or 'E'); handled[row] = true end
    elseif runner == 'python' then
      local path, lnum = line:match('^%s*File "(.-)", line (%d+)')
      if not path then path, lnum = line:match('^E%s+File "(.-)", line (%d+)') end
      if path then traceback = add(path, lnum, 0, 'Python traceback'); handled[row] = true end
      local message = line:match('^E%s+(.+)') or line:match('^([%w_.]*Error:.*)')
      if traceback and message and not message:match('^File ') then traceback.text = message end
    end
  end
  -- Common compiler / Go / pytest locations retain the buffer's own errorformat.
  local fallback = { '__TASK_CWD__:' .. root }
  for row, line in ipairs(lines) do if not handled[row] then fallback[#fallback + 1] = line end end
  local parsed = vim.fn.getqflist({ lines = fallback,
    efm = '%D__TASK_CWD__:%f,' .. (task.efm or efm or vim.bo.errorformat) .. ',%f:%l:%c: %m,%f:%l: %m' }).items
  for _, item in ipairs(parsed) do
    if item.valid == 1 and item.bufnr > 0 and item.lnum > 0 then
      add(vim.api.nvim_buf_get_name(item.bufnr), item.lnum, item.col, item.text, item.type ~= '' and item.type:upper() or nil)
    end
  end
  return items
end

function M.discover(root)
  root = root or require('config.project').root()
  local tasks = {}
  local function add(name, argv)
    tasks[#tasks + 1] = { name = name, argv = argv, cwd = root, runner = name:match('^([^:]+):') }
  end
  local function exists(path) return vim.fn.filereadable(root .. '/' .. path) == 1 end
  if exists('Makefile') or exists('makefile') or exists('GNUmakefile') then
    add('make: default', { 'make' })
    for _, target in ipairs(require('config.makefile').parse(require('config.makefile').find_makefile(root))) do
      add('make: ' .. target.name, { 'make', '--', target.name })
    end
  end
  if exists('package.json') then
    local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(root .. '/package.json'), '\n'))
    if ok and type(package) == 'table' and type(package.scripts) == 'table' then
      local manager = exists('pnpm-lock.yaml') and 'pnpm' or (exists('yarn.lock') and 'yarn' or 'npm')
      for _, name in ipairs(vim.tbl_keys(package.scripts)) do add(manager .. ': ' .. name, { manager, 'run', name }) end
    end
  end
  if exists('Cargo.toml') then
    add('cargo: check', { 'cargo', 'check' }); add('cargo: test', { 'cargo', 'test' }); add('cargo: build', { 'cargo', 'build' })
  end
  if exists('go.mod') then
    add('go: test', { 'go', 'test', './...' }); add('go: build', { 'go', 'build', './...' })
  end
  if exists('pyproject.toml') or exists('pytest.ini') or exists('requirements.txt') then
    local python = vim.fn.executable(root .. '/.venv/bin/python') == 1 and root .. '/.venv/bin/python' or 'python3'
    add('python: tests', { python, '-m', 'pytest' })
    if vim.fn.executable('ruff') == 1 then add('python: lint', { 'ruff', 'check', '.' }) end
  end
  table.sort(tasks, function(a, b) return a.name < b.name end)
  return tasks
end

function M.show_output()
  if M.running and M.running.refresh then M.running.refresh() end
  if not M.output then vim.notify('No task output yet', vim.log.levels.INFO); return end
  local buf = M.output_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    M.output_buf = buf
    vim.api.nvim_create_autocmd('BufWipeout', { buffer = buf, once = true, group = 'ProjectTaskLifecycle',
      callback = function() if M.output_buf == buf then M.output_buf = nil end end })
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'log'
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.output)
  vim.bo[buf].modifiable = false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then vim.api.nvim_set_current_win(win); return end
  end
  vim.cmd('botright 12split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_cursor(0, { #M.output, 0 })
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, desc = 'Close task output' })
end

function M.run(task)
  if M.running then vim.notify('A task is running. Use :TaskStop first.', vim.log.levels.WARN); return false end
  if not task or not task.argv or #task.argv == 0 then return false end
  if vim.fn.executable(task.argv[1]) ~= 1 then
    vim.notify('Task tool missing: ' .. task.argv[1], vim.log.levels.ERROR); return false
  end
  task = vim.deepcopy(task)
  task.cwd = task.cwd or require('config.project').root()
  M.last = vim.deepcopy(task)
  local started = vim.uv.hrtime()
  local token = { task = task, stopped = false, group = posix, efm = vim.bo.errorformat, tab = vim.api.nvim_get_current_tabpage() }
  local stdout, stderr = { chunks = {}, bytes = 0 }, { chunks = {}, bytes = 0 }
  M.running = token
  local function output_text()
    local output = table.concat(stdout.chunks) .. '\n' .. table.concat(stderr.chunks)
    if stdout.truncated or stderr.truncated then output = output .. '\n[Task output truncated at 1 MiB / 5000 lines per stream]' end
    return clean_output(output)
  end
  local function refresh_output()
    M.output = { '$ ' .. table.concat(task.argv, ' '), 'cwd: ' .. task.cwd, '' }
    vim.list_extend(M.output, vim.split(output_text(), '\n', { trimempty = false }))
    local buf = M.output_buf
    if buf and vim.api.nvim_buf_is_valid(buf) then
      local end_windows = {}
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_get_cursor(win)[1] >= math.max(1, vim.api.nvim_buf_line_count(buf) - 1) then end_windows[#end_windows + 1] = win end
      end
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.output)
      vim.bo[buf].modifiable = false
      for _, win in ipairs(end_windows) do
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_set_cursor(win, { #M.output, 0 }) end
      end
    end
  end
  token.refresh = refresh_output
  local function stream_capture(stream, data)
    local previous_bytes, previous_truncated = stream.bytes, stream.truncated
    capture(stream, data)
    if stream.bytes == previous_bytes and stream.truncated == previous_truncated then return end
    -- BufWipeout clears output_buf; the uv callback cannot call Neovim APIs.
    if not data or not M.output_buf or token.refresh_pending then return end
    token.refresh_pending = true
    vim.defer_fn(function()
      token.refresh_pending = false
      if M.running == token and M.output_buf and vim.api.nvim_buf_is_valid(M.output_buf) then refresh_output() end
    end, 120)
  end
  refresh_output()
  vim.notify('Running ' .. task.name, vim.log.levels.INFO, { title = 'Project tasks' })
  local ok, job = pcall(vim.system, task.argv, { cwd = task.cwd, text = true, detach = posix,
    stdout = function(_, data) stream_capture(stdout, data) end,
    stderr = function(_, data) stream_capture(stderr, data) end,
  }, function(result)
    vim.schedule(function()
      if M.running ~= token then return end
      M.running = nil
      refresh_output()
      local items = M.parse_errors(task, output_text(), token.efm)
      vim.fn.setqflist({}, ' ', { title = task.name, items = items })
      local valid = #items
      local status = token.stopped and 'stopped' or (result.code == 0 and 'passed' or ('failed (' .. result.code .. ')'))
      vim.notify(('%s %s · %.2fs'):format(task.name, status, (vim.uv.hrtime() - started) / 1e9),
        result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN, { title = 'Project tasks' })
      if result.code ~= 0 and not token.stopped and token.tab == vim.api.nvim_get_current_tabpage() then
        if valid > 0 then vim.cmd('botright copen') else M.show_output() end
      end
    end)
  end)
  if not ok then M.running = nil; vim.notify(tostring(job), vim.log.levels.ERROR); return false end
  token.job = job
  return true
end

function M.stop()
  local token = M.running
  if not token or not token.job or token.stopped then return end
  token.stopped = true
  signal_task(token, 15)
  vim.defer_fn(function()
    if token.group or M.running == token then signal_task(token, 9) end
  end, 1000)
end
function M.rerun()
  if M.last then M.run(M.last) else M.pick() end
end
function M.pick(name)
  local tasks = M.discover()
  if name and name ~= '' then
    for _, task in ipairs(tasks) do if task.name == name then return M.run(task) end end
    vim.notify('Unknown task: ' .. name, vim.log.levels.WARN); return
  end
  if #tasks == 0 then
    vim.notify('No Make, package.json, Cargo, Go or Python tasks found in project root', vim.log.levels.INFO); return
  end
  vim.ui.select(tasks, { prompt = 'Run project task', format_item = function(task) return task.name end }, function(task)
    if task then M.run(task) end
  end)
end
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('ProjectTaskLifecycle', { clear = true }),
  callback = function()
    local token = M.running
    M.running = nil
    signal_task(token, 9)
  end,
})
return M
