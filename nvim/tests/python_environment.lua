-- Run from repository root: nvim --headless -u NONE -l nvim/tests/python_environment.lua
package.path = vim.fn.getcwd() .. "/nvim/lua/?.lua;" .. package.path
local saved = { system = vim.system, venv = vim.env.VIRTUAL_ENV, conda = vim.env.CONDA_PREFIX, userbase = vim.env.PYTHONUSERBASE }
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local requests, complete = 0, nil
vim.system = function(_, opts, callback)
  requests = requests + 1
  assert(opts.timeout == 1500, "lookup must have a deadline")
  complete = callback
  return { wait = function() error("blocking wait is forbidden") end }
end
local m = require("config.python_environment")
local paths = {}
m.user_site(function(path) paths[#paths + 1] = path end)
m.user_site(function(path) paths[#paths + 1] = path end)
assert(requests == 1 and #paths == 0, "concurrent requests should share an async lookup")
complete({ code = 0, stdout = dir .. "\n" })
assert(vim.wait(500, function() return #paths == 2 end))
assert(paths[1] == dir and paths[2] == dir)
m.user_site(function(path) assert(path == dir) end)
assert(requests == 1, "reuse the discovered path")

vim.cmd.cd(vim.fn.fnameescape(dir))
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buf, dir .. "/example.py")
local root
m.root_dir(buf, function(value) root = value end)
assert(root == dir)
local config = { root_dir = root, settings = { ty = { diagnosticMode = "openFilesOnly" } } }
m.before_init({}, config)
assert(config.settings.ty.configuration.environment["extra-paths"][1] == dir)
assert(config.settings.ty.diagnosticMode == "openFilesOnly")
local shared = { ty = { diagnosticMode = 'openFilesOnly' } }
config = { root_dir = root, settings = shared }
m.before_init({}, config)
assert(shared.ty.configuration == nil, 'environment initialization mutated shared settings')
local selected = vim.fn.exepath('python3')
assert(m.set_interpreter(root, selected))
config = { root_dir = root, settings = shared }
m.before_init({}, config)
assert(config.settings.ty.configuration.environment.python == selected, 'explicit interpreter not sent to ty')
assert(config._python_base_settings.ty.configuration == nil, 'native settings baseline captured an override')
assert(m.set_interpreter(root, nil))

vim.env.VIRTUAL_ENV = dir .. "/venv"
m.root_dir(buf, function(value) root = value end)
config = { root_dir = root, settings = { ty = {} } }
m.before_init({}, config)
assert(config.settings.ty.configuration == nil, "active environments must stay isolated")
vim.env.VIRTUAL_ENV = nil
vim.fn.writefile({ "[project]", 'name = "example"' }, dir .. "/pyproject.toml")
m.root_dir(buf, function(value) root = value end)
config = { root_dir = root, settings = { ty = {} } }
m.before_init({}, config)
assert(config.settings.ty.configuration == nil, "projects must retain native discovery")
assert(requests == 1)
for _, marker in ipairs({ 'pytest.ini', 'Pipfile', 'poetry.lock', 'uv.lock' }) do
  local project = vim.fn.tempname()
  vim.fn.mkdir(project, 'p')
  vim.fn.writefile({}, project .. '/' .. marker)
  local testbuf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(testbuf, project .. '/test.py')
  assert(m.project_root(testbuf) == vim.uv.fs_realpath(project), marker .. ' root missing')
  vim.api.nvim_buf_delete(testbuf, { force = true })
  vim.fn.delete(project, 'rf')
end
local alias = dir .. "-desk"
assert(vim.uv.fs_symlink(dir, alias))
vim.api.nvim_buf_set_name(buf, alias .. "/example.py")
m.root_dir(buf, function(value) root = value end)
assert(root == vim.uv.fs_realpath(dir), "symlink roots must share the physical project")
vim.fn.delete(alias)
vim.env.CONDA_PREFIX = dir .. "/conda"
m.root_dir(buf, function(value) root = value end)
config = { root_dir = root, settings = { ty = {} } }
m.before_init({}, config)
assert(config.settings.ty.configuration == nil, "Conda environment must retain native discovery")
vim.env.CONDA_PREFIX = nil

package.loaded["config.python_environment"] = nil
local failure = require("config.python_environment")
local finished = false
failure.user_site(function(path) assert(path == nil); finished = true end)
complete({ code = 124, stdout = "" })
assert(vim.wait(500, function() return finished end), "failure must release pending startup")
failure.user_site(function(path) assert(path == nil) end)
assert(requests == 2, "cache failure to avoid repeated slow probes")
local standalone = vim.fn.tempname()
vim.fn.mkdir(standalone, 'p')
vim.cmd.cd(vim.fn.fnameescape(standalone))
vim.env.PYTHONUSERBASE = standalone
vim.api.nvim_buf_set_name(buf, standalone .. '/before.py')
local stale_called = false
failure.root_dir(buf, function() stale_called = true end)
vim.api.nvim_buf_set_name(buf, standalone .. '/after.py')
complete({ code = 0, stdout = dir .. '\n' })
vim.wait(50)
assert(not stale_called, 'renamed buffer received a stale asynchronous root')
vim.fn.delete(standalone, 'rf')
vim.system = saved.system
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = saved.venv, saved.conda
vim.env.PYTHONUSERBASE = saved.userbase
vim.fn.delete(dir, "rf")
print("PYTHON ENVIRONMENT: async, coalescing, cache, isolation and failure PASS")
