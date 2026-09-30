vim.api.nvim_create_user_command("ConfigGuide", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/README.md")
end, { desc = "Open your Neovim usage guide" })

vim.api.nvim_create_user_command("Features", function()
  require("config.cheatsheet").toggle()
end, { desc = "Neovim feature & keymap guide" })

vim.api.nvim_create_user_command("Cheatsheet", function()
  require("config.cheatsheet").toggle()
end, { desc = "Neovim feature & keymap guide" })

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { silent = true, desc = desc }) end

map('<leader>?', function() require('config.cheatsheet').toggle() end, 'Feature & Keymap Guide')
map('<leader>hk', function() require('config.cheatsheet').toggle() end, 'Help: Keys & Features')
map('<leader>hg', '<cmd>ConfigGuide<cr>', 'Open keyboard guide')

-- Clear search highlights and transient notifications immediately on <Esc>
map('<Esc>', function()
  vim.cmd('nohlsearch')
  pcall(function() require('config.notifications').dismiss() end)
end, 'Clear search highlights & popups')
map('<C-h>', '<C-w>h', 'Window left')
map('<C-j>', '<C-w>j', 'Window down')
map('<C-k>', function() require('config.symbol_help').show() end, 'Symbol documentation and usage')
map('<C-l>', '<C-w>l', 'Window right')
map('<S-h>', '<cmd>bprevious<cr>', 'Previous buffer')
map('<S-l>', '<cmd>bnext<cr>', 'Next buffer')
map('<leader>bb', function() require('config.pick').open('buffers') end, 'Browse buffers')
-- Preserve splits and prompt before discarding unsaved changes.
map('<leader>bd', function() Snacks.bufdelete() end, 'Close buffer')
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
  lmap('K', function() vim.lsp.buf.hover({ border = require('config.ui').border, max_width = 80, max_height = 24 }) end, 'Documentation')
  lmap('<leader>ca', vim.lsp.buf.code_action, 'Code action')
  vim.keymap.set('n', '<leader>cr', function() return ':IncRename ' .. vim.fn.expand('<cword>') end,
    {buffer=ev.buf, expr=true, desc='Rename symbol'})
  -- Blink owns automatic signature help and insert-mode documentation on <C-k>.
  -- Keep gK as an explicit native fallback when a manual popup is wanted.
  lmap('gK', function() vim.lsp.buf.signature_help({ border = require('config.ui').border, max_width = 80, max_height = 16 }) end, 'Signature help')
end })

map('<leader>gg', function()
  if vim.fn.executable('lazygit') == 0 then vim.notify('Install lazygit to open Git UI', vim.log.levels.WARN); return end
  Snacks.lazygit({ cwd = require('config.project').root() })
end, 'Git UI')

-- Focus the project terminal, or hide it when it already has focus.
local toggle_terminal = function() require('config.terminal').toggle() end
vim.keymap.set({ 'n', 't', 'i' }, '<C-t>', toggle_terminal, { desc = 'Focus or hide project terminal' })
vim.keymap.set({ 'n', 't', 'i' }, '<C-/>', toggle_terminal, { desc = 'Focus or hide project terminal' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.api.nvim_create_user_command('ConfigTools', function()
  local lines = { 'Tools found on PATH:' }
  for _, name in ipairs({'ty','ruff','clangd','rg','git','tree-sitter','cc','lazygit'}) do
    local path = vim.fn.exepath(name)
    lines[#lines + 1] = name .. ': ' .. (path ~= '' and path or 'MISSING')
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, {title='Config tools'})
end, {})

vim.api.nvim_create_user_command('IconInfo', function()
  local font = vim.g.have_nerd_font == false and 'ASCII fallback' or 'Nerd Font glyphs'
  vim.notify(table.concat({
    'Icon mode: ' .. font,
    'Expected terminal font: JetBrainsMono Nerd Font Mono',
    'To use ASCII on the next launch: NVIM_ASCII_ICONS=1 nvim',
  }, '\n'), vim.log.levels.INFO, { title = 'Neovim icons' })
end, { desc = 'Show icon font status' })

-- Register Make commands before their first use.
require("config.makefile")

-- Makefile target runner
map('<leader>cm', function() require('config.makefile').pick() end, 'Pick Makefile target')
map('<leader>cM', function() require('config.makefile').run() end, 'Run default Makefile target')

-- Window resize keymaps
map('<C-Up>', '<cmd>resize +2<cr>', 'Increase window height')
map('<C-Down>', '<cmd>resize -2<cr>', 'Decrease window height')
map('<C-Left>', '<cmd>vertical resize -2<cr>', 'Decrease window width')
map('<C-Right>', '<cmd>vertical resize +2<cr>', 'Increase window width')


-- Zen mode toggle
map('<leader>uz', function() Snacks.zen() end, 'Toggle zen mode')
map('<leader>uZ', function() Snacks.zen.zoom() end, 'Toggle zoom mode')

-- Visual mode indenting
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left (keep selection)' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right (keep selection)' })

-- Smart documentation popup (Shift-K): Uses LSP hover when available, or vim help gracefully
map('K', function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 0 then
    vim.lsp.buf.hover({ border = require('config.ui').border, max_width = 80, max_height = 24 })
  else
    local cword = vim.fn.expand('<cword>')
    if cword ~= '' then
      local ok = pcall(vim.cmd, 'help ' .. cword)
      if not ok then
        vim.notify('No documentation found for: ' .. cword, vim.log.levels.INFO, { title = 'Documentation' })
      end
    end
  end
end, 'Documentation (Hover)')

-- Diagnostic navigation keymaps
map('[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Previous diagnostic')
map(']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'Next diagnostic')
map('<leader>cd', function()
  vim.diagnostic.open_float({
    border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
    title = ' 󰅚 Diagnostics ',
    title_pos = 'center',
    header = '',
    prefix = ' ',
    source = 'if_many',
  })
end, 'Line diagnostics')

-- Yank to system clipboard helpers
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to clipboard' })
map('<leader>Y', '"+Y', 'Yank line to clipboard')
