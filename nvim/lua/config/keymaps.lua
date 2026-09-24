vim.api.nvim_create_user_command("ConfigGuide", function()
  vim.cmd.edit(vim.fn.expand("~/NEOVIM-GUIDE.md"))
end, { desc = "Open your Neovim usage guide" })

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc }) end
map('<C-h>', '<C-w>h', 'Window left')
map('<C-j>', '<C-w>j', 'Window down')
map('<C-k>', '<C-w>k', 'Window up')
map('<C-l>', '<C-w>l', 'Window right')
map('<S-h>', '<cmd>bprevious<cr>', 'Previous buffer')
map('<S-l>', '<cmd>bnext<cr>', 'Next buffer')
map('<leader>bd', '<cmd>bdelete<cr>', 'Close buffer')
map('<leader>ww', '<C-w>w', 'Switch window')
map('<leader>wv', '<cmd>vsplit<cr>', 'Vertical split')
map('<leader>ws', '<cmd>split<cr>', 'Horizontal split')
map('<leader>qq', '<cmd>qa<cr>', 'Quit')
map('<leader>l', '<cmd>Lazy<cr>', 'Plugin manager')
map('<leader>uh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({bufnr=0}), {bufnr=0})
end, 'Toggle native inlay hints')
map('<leader>uf', function() vim.g.autoformat = vim.g.autoformat == false end, 'Toggle format on save')
vim.keymap.set({'n','i'}, '<C-s>', '<cmd>write<cr>', {desc='Save'})
vim.api.nvim_create_autocmd('LspAttach', { callback = function(ev)
  local function lmap(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, {buffer=ev.buf, silent=true, desc=desc})
  end
  lmap('gd', vim.lsp.buf.definition, 'Definition')
  lmap('gD', vim.lsp.buf.declaration, 'Declaration')
  lmap('gr', function() require('config.pick').open('references') end, 'References')
  lmap('gI', vim.lsp.buf.implementation, 'Implementation')
  lmap('gy', vim.lsp.buf.type_definition, 'Type definition')
  lmap('K', vim.lsp.buf.hover, 'Documentation')
  lmap('<leader>ca', vim.lsp.buf.code_action, 'Code action')
  vim.keymap.set('n', '<leader>cr', function() return ':IncRename ' .. vim.fn.expand('<cword>') end,
    {buffer=ev.buf, expr=true, desc='Rename symbol'})
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, {buffer=ev.buf, desc='Signature help'})
  lmap('gK', vim.lsp.buf.signature_help, 'Signature help')
end })

vim.ui.select = function(...) return require("mini.pick").ui_select(...) end

map('<leader>gg', function()
  if vim.fn.executable('lazygit') == 0 then vim.notify('Install lazygit to open Git UI', vim.log.levels.WARN); return end
  Snacks.lazygit({ cwd = require('config.project').root() })
end, 'Git UI')
map('<leader>ch', function() require('config.python_help').show() end, 'Python builtin help')
vim.api.nvim_create_user_command('ConfigTools', function()
  local lines = { 'Tools found on PATH:' }
  for _, name in ipairs({'ty','ruff','clangd','rg','git','tree-sitter','cc','lazygit'}) do
    local path = vim.fn.exepath(name)
    lines[#lines + 1] = name .. ': ' .. (path ~= '' and path or 'MISSING')
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, {title='Config tools'})
end, {})
