-- Run from repository root: nvim --headless -u NONE -l nvim/tests/python_environment.lua
package.path = vim.fn.getcwd() .. "/nvim/lua/?.lua;" .. package.path
local saved = { system = vim.system, venv = vim.env.VIRTUAL_ENV, conda = vim.env.CONDA_PREFIX }
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

package.loaded["config.python_environment"] = nil
local failure = require("config.python_environment")
local finished = false
failure.user_site(function(path) assert(path == nil); finished = true end)
complete({ code = 124, stdout = "" })
assert(vim.wait(500, function() return finished end), "failure must release pending startup")
failure.user_site(function(path) assert(path == nil) end)
assert(requests == 2, "cache failure to avoid repeated slow probes")
vim.system = saved.system
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = saved.venv, saved.conda
vim.fn.delete(dir, "rf")
print("PYTHON ENVIRONMENT: async, coalescing, cache, isolation and failure PASS")
