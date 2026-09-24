-- NVIM_TY=/path/to/ty nvim --headless -u NONE -l nvim/tests/real_ty.lua
package.path = vim.fn.getcwd() .. "/nvim/lua/?.lua;" .. package.path
local exe = vim.env.NVIM_TY or vim.fn.exepath("ty")
assert(exe ~= "", "Install ty or set NVIM_TY")
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ '[project]', 'name = "ty-review"', 'version = "0.1.0"' }, dir .. '/pyproject.toml')
local venv = vim.system({ 'python3', '-m', 'venv', dir .. '/.venv' }, {text=true}):wait()
assert(venv.code == 0, venv.stderr)
local site = vim.trim(vim.system({dir .. '/.venv/bin/python', '-c', 'import site; print(site.getsitepackages()[0])'}, {text=true}):wait().stdout)
vim.fn.mkdir(site .. '/review_dependency', 'p')
vim.fn.writefile({'def external(value: str) -> str:', '    return value'}, site .. '/review_dependency/__init__.py')
local alias = dir .. '-desk-link'
assert(vim.uv.fs_symlink(dir, alias))
vim.fn.writefile({ 'def greet(name: str) -> str:', '    return name.upper()', '', 'result = greet("Tarik")', 'result.up', 'broken: int = "wrong"', 'from review_dependency import external', 'external("ok")' }, dir .. '/main.py')
vim.cmd.edit(alias .. '/main.py')
vim.bo.filetype = 'python'
local buf = vim.api.nvim_get_current_buf()
local config = { name = 'real-ty-review', cmd = { exe, 'server' }, root_dir = vim.uv.fs_realpath(alias), settings = { ty = vim.empty_dict() } }
require('config.python_environment').before_init({}, config)
local id = assert(vim.lsp.start(config))
local client = vim.lsp.get_client_by_id(id)
assert(vim.wait(10000, function() return client.initialized end), 'ty initialization timed out')
local function request(method, position, extra)
  local params = vim.tbl_extend('force', { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = position }, extra or {})
  local response, err = client:request_sync(method, params, 10000, buf)
  assert(response and not response.err, vim.inspect(err or response))
  return response.result
end
local result = request('textDocument/completion', {line=4, character=9})
local entries = result.items or result
assert(vim.iter(entries):any(function(item) return item.label:match('upper') end), 'missing string completion')
local hover = request('textDocument/hover', {line=3, character=10})
assert(hover and hover.contents, 'hover missing')
local rename = request('textDocument/rename', {line=0, character=5}, {newName='welcome'})
assert(rename and (rename.changes or rename.documentChanges), 'rename missing')
local imported = request('textDocument/definition', {line=7, character=3})
assert(imported and #imported > 0 and vim.inspect(imported):find('review_dependency',1,true), 'venv import definition missing')
local hints = request('textDocument/inlayHint', nil, {range={start={line=0,character=0}, ['end']={line=8,character=0}}})
assert(hints and #hints > 0, 'real ty inlay hints missing')
if client:supports_method('textDocument/diagnostic') then
  local diag = request('textDocument/diagnostic')
  assert(diag and diag.items and #diag.items > 0, 'diagnostics missing: ' .. vim.inspect(diag))
else
  assert(vim.wait(10000, function() return #vim.diagnostic.get(buf) > 0 end), 'diagnostics missing')
end
print('REAL TY: completion, hover, rename, inlay hints, diagnostics, .venv import through project symlink PASS')
client:stop(true)
vim.wait(1000, function() return client:is_stopped() end)
vim.fn.delete(alias)
vim.fn.delete(dir, 'rf')
