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
  -- lsp_signature.nvim owns automatic/insert-mode signature help and <C-k>.
  -- Keep gK as an explicit native fallback when a manual popup is wanted.
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

-- Window resize keymaps
map('<C-Up>', '<cmd>resize +2<cr>', 'Increase window height')
map('<C-Down>', '<cmd>resize -2<cr>', 'Decrease window height')
map('<C-Left>', '<cmd>vertical resize -2<cr>', 'Decrease window width')
map('<C-Right>', '<cmd>vertical resize +2<cr>', 'Increase window width')

-- Quick buffer navigation
map('<leader>1', '<cmd>BufferLineGoToBuffer 1<cr>', 'Go to buffer 1')
map('<leader>2', '<cmd>BufferLineGoToBuffer 2<cr>', 'Go to buffer 2')
map('<leader>3', '<cmd>BufferLineGoToBuffer 3<cr>', 'Go to buffer 3')
map('<leader>4', '<cmd>BufferLineGoToBuffer 4<cr>', 'Go to buffer 4')
map('<leader>5', '<cmd>BufferLineGoToBuffer 5<cr>', 'Go to buffer 5')

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
    vim.lsp.buf.hover()
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
map('[d', function() vim.diagnostic.goto_prev() end, 'Previous diagnostic')
map(']d', function() vim.diagnostic.goto_next() end, 'Next diagnostic')
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
