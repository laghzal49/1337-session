-- Requires debugpy in stdpath('data')/debugpy; all fixtures are disposable.
local plugins = require('lazy.core.config').plugins
assert(not plugins['nvim-dap']._.loaded, 'debugger adds startup work')
require('lazy').load({ plugins = { 'nvim-dap' } })
local dap = require('dap')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local file = dir .. '/main.py'
vim.fn.writefile({ 'value = 40', 'value += 2', 'print(value)' }, file)
vim.cmd.edit(file)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
dap.toggle_breakpoint()
dap.run({ name = 'Debug review', type = 'python', request = 'launch', program = file,
  pythonPath = vim.fn.exepath('python3'), cwd = dir, console = 'internalConsole' })
assert(vim.wait(15000, function() local s = dap.session(); return s and s.stopped_thread_id ~= nil end), 'debugpy did not stop at breakpoint')
local session = dap.session()
assert(vim.wait(3000, function() return session.current_frame and session.current_frame.line == 2 end), 'wrong stopped line')
local value
session:request('evaluate', { expression = 'value', frameId = session.current_frame.id, context = 'watch' }, function(err, result)
  assert(not err, vim.inspect(err)); value = result.result
end)
assert(vim.wait(3000, function() return value ~= nil end) and value == '40', 'variable evaluation failed')
local ui_open = false
for _, win in ipairs(vim.api.nvim_list_wins()) do
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_scopes' then ui_open = true end
end
assert(ui_open, 'debug panels did not open')
dap.step_over()
assert(vim.wait(5000, function() local s = dap.session(); return s and s.current_frame and s.current_frame.line == 3 end), 'step over failed')
dap.continue()
assert(vim.wait(5000, function() return dap.session() == nil end), 'debuggee did not finish')
vim.wait(100)
for _, win in ipairs(vim.api.nvim_list_wins()) do
  assert(vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'dapui_scopes', 'debug panels not closed')
end
-- Yank must mark the copied range briefly, then clear it.
vim.cmd.edit(file)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd.normal({ 'yy', bang = true })
local ns = vim.api.nvim_get_namespaces()['nvim.hlyank']
assert(ns and #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0, 'yank region not highlighted')
vim.wait(250)
assert(#vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) == 0, 'yank highlight did not clear')
vim.cmd.enew()
vim.fn.delete(dir, 'rf')
print('DEBUGGING: real debugpy breakpoint/evaluation/step/exit, panels, timed yank PASS')
