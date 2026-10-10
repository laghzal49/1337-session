-- A read-only guide that can be opened before loading any debug adapters.
local M = {}
local api = vim.api

local function intact()
  return M.win and api.nvim_win_is_valid(M.win) and api.nvim_win_get_buf(M.win) == M.buf
end

function M.close()
  if intact() then api.nvim_win_close(M.win, true) end
  M.win, M.buf = nil, nil
end

function M.show()
  if intact() then api.nvim_set_current_win(M.win); return M.win end
  local path = vim.fn.stdpath('config') .. '/DEBUGGING.md'
  local lines, highlights = {}, {}
  for _, source in ipairs(vim.fn.readfile(path)) do
    local heading = source:match('^#+%s')
    source = source:gsub('^#+%s*', '')
    local text, cursor = '', 1
    while true do
      local first, last = source:find('`[^`]+`', cursor)
      if not first then text = text .. source:sub(cursor); break end
      text = text .. source:sub(cursor, first - 1)
      local start = #text
      text = text .. source:sub(first + 1, last - 1)
      highlights[#highlights + 1] = { #lines, start, #text, 'BlackPopupCommand' }
      cursor = last + 1
    end
    if heading then highlights[#highlights + 1] = { #lines, 0, -1, 'Title' } end
    lines[#lines + 1] = text
  end
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden, vim.bo[buf].filetype, vim.bo[buf].swapfile = 'wipe', 'debugguide', false
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = api.nvim_create_namespace('BlackDebugHelp')
  for _, h in ipairs(highlights) do api.nvim_buf_add_highlight(buf, ns, h[4], h[1], h[2], h[3]) end
  local width, height = math.max(1, math.min(78, vim.o.columns - 6)), math.max(1, math.min(26, vim.o.lines - 6))
  local win = api.nvim_open_win(buf, true, { relative = 'editor', style = 'minimal',
    width = width, height = height, row = 1, col = 1, border = require('config.ui').border })
  M.win, M.buf = win, buf
  for name, value in pairs({ wrap = true, linebreak = true, breakindent = true, spell = false,
    conceallevel = 0, winblend = 0, winhighlight = 'Normal:BlackDocs,NormalNC:BlackDocs,FloatBorder:BlackDocsBorder' }) do
    vim.wo[win][name] = value
  end
  require('config.popups').frame(win, { title = 'Debugger · how to use it',
    center = { width = 78, height = 26 }, pad = true, scroll = true,
    hints = { 't try example · j/k scroll · q close', 't example · q close', 'q close' } })
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, M.close, { buffer = buf, nowait = true, desc = 'Close debugger guide' })
  end
  vim.keymap.set('n', 'j', 'gj', { buffer = buf })
  vim.keymap.set('n', 'k', 'gk', { buffer = buf })
  vim.keymap.set('n', 't', M.example, { buffer = buf, nowait = true, desc = 'Open debugger practice project' })
  return win
end

function M.example()
  local dap = package.loaded['dap']
  if dap and dap.session() then
    vim.notify('Stop the current session with Shift-F5 before opening the practice project.', vim.log.levels.INFO)
    return
  end
  if not M.directory or vim.fn.filereadable(M.directory .. '/main.py') == 0 then
    M.directory = vim.fn.tempname()
    vim.fn.mkdir(M.directory .. '/.vscode', 'p')
    vim.fn.writefile({ '[project]', 'name = "debug-practice"', 'version = "0.1.0"' }, M.directory .. '/pyproject.toml')
    vim.fn.writefile({
      'def total_values(values: list[int]) -> int:',
      '    total = 0', '    for value in values:', '        total += value', '    return total', '', '',
      'numbers = [4, 8, 12]', 'result = total_values(numbers)', 'print(result)',
    }, M.directory .. '/main.py')
    vim.fn.writefile({ vim.json.encode({ version = '0.2.0', configurations = {
      { name = 'Python: debugger practice', type = 'python', request = 'launch',
        program = '${workspaceFolder}/main.py', cwd = '${workspaceFolder}', console = 'internalConsole', justMyCode = true },
    } }) }, M.directory .. '/.vscode/launch.json')
  end
  M.close()
  vim.cmd.tabnew(vim.fn.fnameescape(M.directory .. '/main.py'))
  dap = require('dap')
  -- Set, rather than toggle, so reopening the example keeps its breakpoint.
  for row, line in ipairs(api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:find('total += value', 1, true) then
      api.nvim_win_set_cursor(0, { row, 8 }); dap.set_breakpoint(); break
    end
  end
  vim.notify('Practice ready. F5 starts; F10 steps; Space D? reopens the guide.', vim.log.levels.INFO, { title = 'Debugger' })
  return M.directory
end
return M
