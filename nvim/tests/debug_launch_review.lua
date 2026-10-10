require('lazy').load({ plugins = { 'nvim-dap' } })
local launch, dap = require('config.debug_launch'), require('dap')
local dir = vim.fn.tempname()
for _, name in ipairs({ 'one', 'two' }) do
  vim.fn.mkdir(dir .. '/' .. name .. '/.git', 'p')
  vim.fn.writefile({ 'value = 40', 'value += 2', 'print(value)' }, dir .. '/' .. name .. '/main.py')
end
local first, second = dir .. '/one', dir .. '/two'
vim.cmd.edit(first .. '/main.py')
local run, select_ui, input, notify = dap.run, vim.ui.select, vim.ui.input, vim.notify
local runs, notices, selections = {}, {}, 0
dap.run = function(config) runs[#runs + 1] = vim.deepcopy(config) end
vim.notify = function(message) notices[#notices + 1] = message end
vim.ui.select = function() selections = selections + 1; error('unexpected picker') end
launch.start()
assert(#runs == 1 and runs[1].program == first .. '/main.py' and runs[1].cwd == first,
  'one profile should launch without a picker')
assert(vim.fn.filereadable(first .. '/.vscode/launch.json') == 1, 'first F5 did not create profile')

-- A delayed choice still launches the source that opened it, even after switching projects.
local callback, items
vim.ui.select = function(choices, _, done) items, callback = choices, done end
launch.pick()
vim.cmd.edit(second .. '/main.py')
callback(items[1])
assert(runs[#runs].program == first .. '/main.py' and runs[#runs].cwd == first, 'picker lost source context')
launch.rerun()
assert(runs[#runs].program == second .. '/main.py', 'rerun leaked another project')

-- Cancelling a save leaves both the file and launch untouched.
vim.api.nvim_buf_set_lines(0, 0, 1, false, { 'value = 41' })
local before = #runs
launch.start()
callback(nil)
assert(#runs == before and vim.fn.readfile(second .. '/main.py')[1] == 'value = 40', 'cancel wrote or ran')
launch.start()
callback('Save and debug')
assert(#runs == before + 1 and vim.fn.readfile(second .. '/main.py')[1] == 'value = 41', 'save/start failed')

-- Selection is remembered within a project; editing the JSON is read on the next F5.
vim.fn.writefile({ vim.json.encode({ configurations = {
  { name = 'A', type = 'python', request = 'launch', program = '${file}' },
  { name = 'B', type = 'python', request = 'launch', program = '${file}', args = { 'old' } },
} }) }, second .. '/.vscode/launch.json')
launch.start(); callback(items[2])
assert(runs[#runs].name == 'B')
vim.ui.select = function() error('remembered selection should not prompt') end
launch.start()
assert(runs[#runs].name == 'B')
local data = vim.json.decode(table.concat(vim.fn.readfile(second .. '/.vscode/launch.json'), '\n'))
data.configurations[2].args = { 'new' }
vim.fn.writefile({ vim.json.encode(data) }, second .. '/.vscode/launch.json')
launch.start()
assert(runs[#runs].args[1] == 'new', 'changed profile was not reloaded')

-- Invalid setup and missing modules produce actionable messages, never a launch.
vim.fn.writefile({ '{ broken' }, second .. '/.vscode/launch.json')
before = #runs
launch.start()
assert(#runs == before and notices[#notices]:find('DebugProjectEdit', 1, true), 'invalid profile was launched')
launch.run({ name = 'missing', type = 'python', request = 'launch', module = 'no_such_debug_module_1337' })
assert(vim.wait(3000, function() return notices[#notices]:find('unavailable', 1, true) end))
assert(#runs == before, 'missing module launched')

-- Real binary discovery ignores shell scripts and dependency build trees.
vim.fn.mkdir(first .. '/build/CMakeFiles', 'p')
vim.fn.writefile({ 'int main(void) { return 0; }' }, first .. '/main.c')
assert(vim.system({ 'cc', '-g', first .. '/main.c', '-o', first .. '/build/app' }):wait().code == 0)
vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, first .. '/build/script')
vim.fn.setfperm(first .. '/build/script', 'rwxr-xr-x')
assert(vim.deep_equal(launch.executables(first), { first .. '/build/app' }), 'executable discovery returned wrong targets')

-- Actual watch UI API; no session is required to prepare a watch.
vim.ui.input = function(_, done) done('value + 2') end
launch.watch()
assert(require('dapui').elements.watches.get()[1].expression == 'value + 2', 'watch was not added')
assert(vim.wait(1000, function() return vim.bo.filetype == 'dapui_watches' end), 'watch inspector did not focus')
vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
launch.step('step_over')
assert(notices[#notices]:find('breakpoint', 1, true), 'step without a session tried to start')

-- Check the installed older GDB instead of allowing a cryptic adapter exit.
if vim.fn.executable('/usr/bin/gdb') == 1 then
  local previous = vim.g.debug_gdb
  vim.g.debug_gdb = '/usr/bin/gdb'
  local completed = false
  local old_count = #notices
  require('config.debugging').gdb(function() completed = true end)
  assert(vim.wait(6000, function() return completed or #notices > old_count end), 'GDB probe stalled')
  if not completed then assert(notices[#notices]:find('GDB 14+', 1, true), 'GDB probe gave no useful guidance') end
  vim.g.debug_gdb = previous
end
dap.run, vim.ui.select, vim.ui.input, vim.notify = run, select_ui, input, notify

-- Exercise the new start path with real debugpy, including save/target/preflight flow.
vim.cmd.edit(first .. '/main.py')
vim.api.nvim_win_set_cursor(0, { 2, 0 })
dap.toggle_breakpoint()
local profile = vim.json.decode(table.concat(vim.fn.readfile(first .. '/.vscode/launch.json'), '\n'))
profile.configurations[1].console = 'internalConsole'
vim.fn.writefile({ vim.json.encode(profile) }, first .. '/.vscode/launch.json')
launch.start()
assert(vim.wait(15000, function() return dap.session() and dap.session().stopped_thread_id end), 'smart F5 did not stop')
launch.step('step_over')
assert(vim.wait(5000, function() return dap.session().current_frame and dap.session().current_frame.line == 3 end), 'smart step failed')
dap.continue()
assert(vim.wait(5000, function() return not dap.session() end), 'smart session did not finish')
vim.wait(100)
vim.cmd.enew()
vim.fn.delete(dir, 'rf')
print('SMART DEBUG PASS: first F5, generation, context isolation, save/cancel, remembered selection, profile reload, missing module, binary discovery, watches, GDB preflight and real debugpy start/step/exit')
