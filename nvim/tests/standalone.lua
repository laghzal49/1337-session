-- Run with the full config: nvim --headless '+lua dofile("nvim/tests/standalone.lua")' +qa!
local plugins = require('lazy.core.config').plugins
assert(not plugins.LazyVim and not _G.LazyVim)
for _, name in ipairs({'mini.pick','mini.extra','nvim-cmp','aerial.nvim','noice.nvim','nvim-lspconfig'}) do
  require('lazy').load({plugins={name}})
end
assert(vim.fn.maparg('<leader>e','n') ~= '')
assert(vim.fn.maparg('<leader><space>','n') ~= '')
assert(vim.fn.maparg('<leader>gg','n') ~= '')
assert(vim.fn.executable('ty') == 1, 'put ty on PATH for this test')
local dir=vim.fn.tempname()
vim.fn.mkdir(dir,'p')
vim.fn.writefile({'[project]','name="standalone-review"','version="0.1.0"'},dir..'/pyproject.toml')
vim.fn.writefile({'result: int = "incorrect"'},dir..'/main.py')
vim.cmd.edit(dir..'/main.py')
local buf=vim.api.nvim_get_current_buf()
assert(vim.wait(10000,function()
  local c=vim.lsp.get_clients({bufnr=buf,name='ty'})[1]
  return c and c.initialized
end), 'configured ty did not attach')
assert(vim.fn.maparg('<leader>cr','n') ~= '', 'rename mapping missing')
assert(vim.wait(10000,function() return #vim.diagnostic.get(buf)>0 end), 'configured ty diagnostics missing')
for _, client in ipairs(vim.lsp.get_clients({bufnr=buf})) do client:stop(true) end
vim.api.nvim_buf_delete(buf,{force=true})
vim.fn.delete(dir,'rf')
print('STANDALONE: no LazyVim, mappings, actual configured ty attachment and diagnostics PASS')
