local station, project = require('config.station'), require('config.project')
local dir = vim.fn.tempname()
for _, path in ipairs({ '/a/shared', '/b/shared', '/goinfre', '/old', '/bin' }) do vim.fn.mkdir(dir .. path, 'p') end
vim.fn.writefile({ 'working' }, dir .. '/old/marker')
local first, second = dir .. '/a/shared', dir .. '/b/shared'
assert(vim.uv.fs_symlink(dir .. '/old', first .. '/.venv'))
local root, paths, terminal, executable = project.root, station.get_goinfre_paths, Snacks.terminal, vim.fn.executable
local notify, messages = vim.notify, {}
vim.notify = function(message) messages[#messages + 1] = message end
local current, commands = first, {}
project.root = function() return current end
station.get_goinfre_paths = function() return dir, dir .. '/goinfre' end
Snacks.terminal = function(cmd) commands[#commands + 1] = cmd end
vim.fn.executable = function(name) return name == 'uv' and 0 or executable(name) end
station.rebuild_venv()
assert(#commands == 0 and vim.uv.fs_readlink(first .. '/.venv') == dir .. '/old', 'missing uv destroyed existing environment')
assert(messages[#messages]:find('Install uv', 1, true), 'missing-tool guidance absent')
vim.fn.executable = function(name) return name == 'uv' and 1 or executable(name) end
station.rebuild_venv()
assert(vim.uv.fs_readlink(first .. '/.venv') == dir .. '/old', 'link changed before build ran')
current = second
station.rebuild_venv()
assert(commands[1] ~= commands[2], 'same-basename projects shared environment target')
local stub = dir .. '/bin/uv'
vim.fn.writefile({ '#!/bin/sh', 'exit 1' }, stub)
vim.fn.setfperm(stub, 'rwx------')
local env = { PATH = dir .. '/bin:' .. vim.env.PATH }
assert(vim.system({ 'sh', '-c', commands[1] }, { cwd = first, env = env }):wait().code ~= 0)
assert(vim.uv.fs_readlink(first .. '/.venv') == dir .. '/old', 'failed build replaced working environment')
vim.fn.writefile({ '#!/bin/sh', 'mkdir -p "$2"', 'printf created > "$2/marker"' }, stub)
assert(vim.system({ 'sh', '-c', commands[1] }, { cwd = first, env = env }):wait().code == 0)
local target = vim.uv.fs_readlink(first .. '/.venv')
assert(target ~= dir .. '/old' and vim.fn.filereadable(target .. '/marker') == 1, 'successful build did not publish new environment')
assert(vim.fn.filereadable(dir .. '/old/marker') == 1, 'old environment was deleted')
vim.fn.mkdir(second .. '/.venv', 'p')
local count = #commands
station.rebuild_venv()
assert(#commands == count and vim.fn.isdirectory(second .. '/.venv') == 1, 'real environment directory silently repurposed')
project.root, station.get_goinfre_paths, Snacks.terminal, vim.fn.executable = root, paths, terminal, executable
vim.notify = notify
vim.fn.delete(dir, 'rf')
print('STATION VENV PASS: tool check, distinct targets, failed/successful publication, old environment and directory preservation')
