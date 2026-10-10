local plugins = require('lazy.core.config').plugins
local guide = require('config.debug_help')
vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'unsaved work' })
local editor, source = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
vim.cmd.DebugHelp()
assert(not plugins['nvim-dap']._.loaded, 'reading help loads the debugger')
assert(not vim.bo[guide.buf].modifiable, 'guide is editable')
local text = table.concat(vim.api.nvim_buf_get_lines(guide.buf, 0, -1, false), '\n')
for _, key in ipairs({ 'F5', 'F10', 'F11', 'F12', 'Space Db', 'Space Dw', 'Space D?', 'BEFORE' }) do
  assert(text:find(key, 1, true), 'guide omits ' .. key)
end
for _, size in ipairs({ {140,42}, {80,24}, {40,20} }) do
  vim.o.columns, vim.o.lines = size[1], size[2]
  vim.api.nvim_exec_autocmds('VimResized', {})
  assert(vim.wait(500, function()
    local config = vim.api.nvim_win_get_config(guide.win)
    return config.width <= size[1]-6 and config.height <= size[2]-6
  end), 'guide does not fit after resizing')
end
local win = guide.win
assert(guide.show() == win, 'guide is duplicated')
guide.close()
assert(vim.api.nvim_get_current_win() == editor and vim.api.nvim_get_current_buf() == source, 'guide lost editor')
assert(vim.api.nvim_buf_get_lines(source, 0, -1, false)[1] == 'unsaved work', 'guide changed source')

-- First-use example creates a separate temporary project and runs as advertised.
vim.o.columns, vim.o.lines = 140, 42
local tab = vim.api.nvim_get_current_tabpage()
vim.cmd.DebugExample()
local directory, dap = guide.directory, require('dap')
assert(vim.api.nvim_get_current_tabpage() ~= tab, 'example replaced editing tab')
assert(require('config.project').root() == directory, 'example escaped its project')
assert(not dap.session(), 'example started without F5')
require('config.debug_launch').start()
assert(vim.wait(15000, function() return dap.session() and dap.session().stopped_thread_id end), 'practice did not pause')
local session = dap.session()
assert(vim.wait(3000, function() return session.current_frame ~= nil end))
local value
session:request('evaluate', { expression = 'total', frameId = session.current_frame.id, context = 'watch' }, function(err, result)
  assert(not err, vim.inspect(err)); value = result.result
end)
assert(vim.wait(3000, function() return value ~= nil end) and value == '0', 'practice initial value differs from guide')
dap.step_over()
assert(vim.wait(3000, function() return session.current_frame and session.current_frame.line == 3 end), 'practice step failed')
value = nil
session:request('evaluate', { expression = 'total', frameId = session.current_frame.id, context = 'watch' }, function(err, result)
  assert(not err, vim.inspect(err)); value = result.result
end)
assert(vim.wait(3000, function() return value ~= nil end) and value == '4', 'practice stepped value differs from guide')
guide.show()
local count = #vim.api.nvim_list_tabpages()
guide.example()
assert(#vim.api.nvim_list_tabpages() == count and dap.session() == session, 'example disrupted an active session')
guide.close()
dap.terminate()
assert(vim.wait(5000, function() return not dap.session() end), 'practice did not terminate')
vim.wait(100)
vim.cmd.tabclose()
assert(vim.api.nvim_buf_get_lines(source, 0, -1, false)[1] == 'unsaved work', 'practice changed editing buffer')
vim.fn.delete(directory, 'rf')
print('DEBUG HELP PASS: no startup adapter loading, guide resize/reuse/close, unsaved buffers, isolated example and real breakpoint/evaluation/step/stop')
