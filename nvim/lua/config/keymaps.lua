vim.api.nvim_create_user_command("ConfigGuide", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/README.md")
end, { desc = "Open your Neovim usage guide" })

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc }) end

map('<leader>?', function()
  local ok, which_key = pcall(require, 'which-key')
  if ok then
    which_key.show('<leader>', { mode = 'n', auto = false })
  else
    vim.cmd('ConfigGuide')
  end
end, 'Show all shortcuts')
map('<leader>h', '<cmd>ConfigGuide<cr>', 'Open keyboard guide')

-- Clear search highlights and transient notifications immediately on <Esc>
map('<Esc>', function()
  vim.cmd('nohlsearch')
  pcall(function() require('config.notifications').dismiss() end)
end, 'Clear search highlights & popups')
map('<C-h>', '<C-w>h', 'Window left')
map('<C-j>', '<C-w>j', 'Window down')
map('<C-k>', '<C-w>k', 'Window up')
map('<C-l>', '<C-w>l', 'Window right')
map('<S-h>', '<cmd>bprevious<cr>', 'Previous buffer')
map('<S-l>', '<cmd>bnext<cr>', 'Next buffer')
map('<leader>bb', function() require('config.pick').open('buffers') end, 'Browse buffers')
-- Smart buffer close: handles the last-buffer edge case gracefully.
map('<leader>bd', function()
  local name = vim.api.nvim_buf_get_name(0)
  local bufs = vim.tbl_filter(function(b)
    return vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b)
  end, vim.api.nvim_list_bufs())
  if #bufs <= 1 then
    vim.cmd('enew | bdelete #')
  else
    vim.cmd('bprevious | bdelete #')
  end
  local label = name ~= '' and vim.fn.fnamemodify(name, ':t') or '[No Name]'
  vim.notify('Closed buffer: ' .. label, vim.log.levels.INFO)
end, 'Close buffer')
map('<leader>ww', '<C-w>w', 'Switch window')
map('<leader>wv', '<cmd>vsplit<cr>', 'Vertical split')
map('<leader>ws', '<cmd>split<cr>', 'Horizontal split')
map('<leader>qq', '<cmd>qa<cr>', 'Quit')
map('<leader>l', '<cmd>Lazy<cr>', 'Plugin manager')
map('<leader>uh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({bufnr=0}), {bufnr=0})
end, 'Toggle native inlay hints')
map('<leader>uf', function() vim.g.autoformat = vim.g.autoformat == false end, 'Toggle format on save')
local workspace = require('config.workspace')
map('<leader>uw', workspace.toggle, 'Toggle workspace mode')
map('<leader>uW', workspace.exit, 'Exit workspace mode')
map('<leader>ch', function() require('config.python_help').show() end, 'Python builtin help')
map('<leader>fp', '<cmd>PdfOpen<cr>', 'Open PDF externally')
map('<leader>fR', '<cmd>PdfRead<cr>', 'Read PDF text')
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

map('<leader>gg', function()
  if vim.fn.executable('lazygit') == 0 then vim.notify('Install lazygit to open Git UI', vim.log.levels.WARN); return end
  Snacks.lazygit({ cwd = require('config.project').root() })
end, 'Git UI')

-- Toggle terminal quickly with Ctrl-t or Ctrl-/ (works in normal & terminal mode)
local function toggle_terminal()
  Snacks.terminal(nil, { cwd = require('config.project').root() })
end
vim.keymap.set({ 'n', 't' }, '<C-t>', toggle_terminal, { desc = 'Toggle Terminal' })
vim.keymap.set({ 'n', 't' }, '<C-/>', toggle_terminal, { desc = 'Toggle Terminal' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('<leader>ai', function()
  if vim.fn.executable('copilot') == 0 then
    vim.notify('Install GitHub Copilot CLI to use AI terminal', vim.log.levels.WARN)
    return
  end
  Snacks.terminal('copilot', {
    cwd = require('config.project').root(),
    win = {
      position = 'float',
      width = 0.82,
      height = 0.82,
      border = require('config.ui').border,
      wo = { winbar = '  󰚩 GitHub Copilot CLI · q to close' },
    },
  })
end, 'Copilot CLI Terminal')

vim.api.nvim_create_user_command('ConfigTools', function()
  local lines = { 'Tools found on PATH:' }
  for _, name in ipairs({'ty','ruff','clangd','copilot','rg','git','tree-sitter','cc','lazygit'}) do
    local path = vim.fn.exepath(name)
    lines[#lines + 1] = name .. ': ' .. (path ~= '' and path or 'MISSING')
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, {title='Config tools'})
end, {})
