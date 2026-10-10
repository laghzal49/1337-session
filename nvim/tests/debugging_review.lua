-- Requires debugpy in stdpath('data')/debugpy; all fixtures are disposable.
local plugins = require('lazy.core.config').plugins
assert(not plugins['nvim-dap']._.loaded, 'debugger adds startup work')
require('lazy').load({ plugins = { 'nvim-dap' } })
local dap = require('dap')
local debug = require('config.debugging')
assert(vim.deep_equal(debug.parse_args([[--name "hello world" 'two words' plain\ value ""]]),
  { '--name', 'hello world', 'two words', 'plain value', '' }), 'quoted arguments broken')
assert(vim.deep_equal(debug.parse_args([["a\path" "a\"b"]]), { [[a\path]], [[a"b]] }), 'double-quoted backslashes lost')
assert(debug.parse_args([["unfinished]]) == nil, 'invalid quotes accepted')
assert(#dap.configurations.python == 4, 'Python launch/module/attach configurations missing')
assert(#dap.configurations.c == 2 and #dap.configurations.cpp == 2, 'native launch/attach missing')
local input = vim.fn.input
vim.fn.input = function() error('cancelled') end
assert(debug.prompt('cancel') == dap.ABORT and debug.arguments() == dap.ABORT, 'cancel does not abort')
vim.fn.input = input

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local file = dir .. '/main.py'
vim.fn.writefile({ 'import sys', 'assert sys.argv[1:] == ["hello world", "42"]', 'value = 40', 'value += 2', 'print(value)' }, file)
vim.cmd.edit(file)
vim.api.nvim_win_set_cursor(0, { 4, 0 })
dap.toggle_breakpoint()
dap.run({ name = 'Debug review', type = 'python', request = 'launch', program = file,
  args = { 'hello world', '42' }, pythonPath = vim.fn.exepath('python3'), cwd = dir, console = 'internalConsole' })
assert(vim.wait(15000, function() local s = dap.session(); return s and s.stopped_thread_id ~= nil end), 'debugpy did not stop at breakpoint')
local session = dap.session()
assert(vim.wait(3000, function() return session.current_frame and session.current_frame.line == 4 end), 'wrong stopped line')
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
assert(vim.wait(5000, function() local s = dap.session(); return s and s.current_frame and s.current_frame.line == 5 end), 'step over failed')
dap.continue()
assert(vim.wait(5000, function() return dap.session() == nil end), 'debuggee did not finish')
vim.wait(100)
for _, win in ipairs(vim.api.nvim_list_wins()) do
  assert(vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'dapui_scopes', 'debug panels not closed')
end
-- Module launch exercises a separate configuration shape used by pytest and packages.
dap.run({ name = 'Module review', type = 'python', request = 'launch', module = 'main',
  args = { 'hello world', '42' }, pythonPath = vim.fn.exepath('python3'), cwd = dir,
  console = 'internalConsole' })
assert(vim.wait(15000, function() local active = dap.session(); return active and active.stopped_thread_id ~= nil end),
  'module launch did not stop at breakpoint')
dap.continue()
assert(vim.wait(5000, function() return dap.session() == nil end), 'module debuggee did not finish')
vim.wait(100)
-- Project JSON is loaded by source-buffer root, never leaked into global defaults.
local projects = require('config.debug_projects')
local second = dir .. '/other'
vim.fn.mkdir(dir .. '/.git', 'p')
vim.fn.mkdir(dir .. '/.vscode', 'p')
vim.fn.mkdir(second .. '/.git', 'p')
vim.fn.mkdir(second .. '/.vscode', 'p')
local launch_path = dir .. '/.vscode/launch.json'
local function write_project(path, name)
  vim.fn.writefile({ vim.json.encode({ version = '0.2.0', configurations = {
    { name = name, type = 'debugpy', request = 'launch', program = '${workspaceFolder}/main.py',
      args = { 'hello world', '42' }, console = 'internalConsole' },
  } }) }, path)
end
write_project(launch_path, 'Project one')
write_project(second .. '/.vscode/launch.json', 'Project two')
vim.cmd.edit(file)
local first = dap.providers.configs['dap.launch.json']()
assert(#first == 1 and first[1].name == 'Project one' and first[1].cwd == dir and first[1].type == 'python',
  'source-root launch resolution failed')
vim.cmd.edit(second .. '/other.py')
local next_project = dap.providers.configs['dap.launch.json']()
assert(#next_project == 1 and next_project[1].name == 'Project two', 'previous project launch leaked')
assert(#dap.configurations.python == 4, 'project launches mutated built-ins')
vim.fn.writefile({ '{ broken json' }, second .. '/.vscode/launch.json')
local rejected, validation_error = projects.read()
assert(#rejected == 0 and validation_error, 'malformed launch.json accepted')
vim.fn.writefile({ '{"configurations":[{"name":"bad","type":"python","request":"launch","program":"main.py","args":"unsafe"}]}' }, second .. '/.vscode/launch.json')
assert(select(2, projects.read()), 'invalid argument schema accepted')
vim.fn.writefile({ '{"configurations":{"not":"an array"}}' }, second .. '/.vscode/launch.json')
assert(select(2, projects.read()), 'non-array configurations accepted')
local generated = dir .. '/generated'
vim.fn.mkdir(generated .. '/.git', 'p')
vim.fn.writefile({ 'print("generated")' }, generated .. '/main.py')
vim.cmd.edit(generated .. '/main.py')
vim.cmd.DebugProjectGenerate()
local generated_path = generated .. '/.vscode/launch.json'
assert(vim.fn.filereadable(generated_path) == 1, 'Python profile command did not generate launch.json')
local generated_configs, generated_err = projects.read()
assert(not generated_err and #generated_configs == 1 and generated_configs[1].program == '${file}',
  'generated Python profile is invalid')
local original = table.concat(vim.fn.readfile(generated_path), '\n')
assert(not select(2, projects.ensure()) and table.concat(vim.fn.readfile(generated_path), '\n') == original,
  'existing launch.json was overwritten')
local c_project = dir .. '/c-project'
vim.fn.mkdir(c_project .. '/.git', 'p')
vim.fn.writefile({ 'int main(void) { return 0; }' }, c_project .. '/main.c')
vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, c_project .. '/a.out')
vim.fn.setfperm(c_project .. '/a.out', 'rwxr-xr-x')
vim.cmd.edit(c_project .. '/main.c')
vim.cmd.DebugProjectCheck()
assert(vim.fn.filereadable(c_project .. '/.vscode/launch.json') == 1, 'check did not generate C profile')
local c_configs, c_err = projects.read()
assert(not c_err and #c_configs == 1 and c_configs[1].program == c_project .. '/a.out',
  'generated C profile did not select existing executable')
vim.cmd.edit(file)
dap.run(projects.read()[1])
assert(vim.wait(15000, function() local active = dap.session(); return active and active.stopped_thread_id ~= nil end),
  'real project JSON launch did not stop')
dap.continue()
assert(vim.wait(5000, function() return dap.session() == nil end), 'project debuggee did not finish')
vim.wait(100)
-- A live attach server chooses a disposable loopback port; no fixed-port conflicts.
local port, output, server_done = nil, '', false
local adapter_python = vim.fn.stdpath('data') .. '/debugpy/bin/python'
local server = vim.system({ adapter_python, '-u', '-c',
  'import debugpy,runpy,sys; endpoint=debugpy.listen(("127.0.0.1",0)); print(endpoint[1],flush=True); debugpy.wait_for_client(); sys.argv=[sys.argv[1],"hello world","42"]; runpy.run_path(sys.argv[0],run_name="__main__")', file }, {
  text = true,
  stdout = function(_, data)
    if data then output = output .. data; port = tonumber(output:match('^(%d+)')) end
  end,
}, function() server_done = true end)
assert(vim.wait(10000, function() return port ~= nil or server_done end) and port, 'attach server did not start')
dap.run({ name = 'Attach review', type = 'python', request = 'attach',
  connect = { host = '127.0.0.1', port = port }, justMyCode = true })
local attached = vim.wait(15000, function() local active = dap.session(); return active and active.stopped_thread_id ~= nil end)
if not attached then server:kill(15) end
assert(attached, 'live attach did not stop at breakpoint')
dap.continue()
assert(vim.wait(5000, function() return dap.session() == nil end), 'attached debuggee did not finish')
assert(vim.wait(5000, function() return server_done end), 'attach server leaked after exit')
vim.wait(100)
-- Adapter/session failures can close without any terminated/exited DAP event.
dap.run({ name = 'Abrupt close review', type = 'python', request = 'launch', program = file,
  args = { 'hello world', '42' }, pythonPath = vim.fn.exepath('python3'), cwd = dir, console = 'internalConsole' })
assert(vim.wait(15000, function() local active = dap.session(); return active and active.stopped_thread_id ~= nil end),
  'abrupt-close fixture did not stop')
dap.session():close()
assert(vim.wait(3000, function() return dap.session() == nil end), 'closed adapter retained session')
vim.wait(100)
for _, win in ipairs(vim.api.nvim_list_wins()) do
  assert(vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'dapui_scopes', 'abrupt adapter closure leaked debug panels')
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
print('DEBUGGING: quoted arguments/cancellation/configurations, project JSON validation/isolation, real debugpy file/module/project/attach arguments/breakpoint/evaluation/step/exit, abrupt-close panel cleanup, timed yank PASS')
