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

map('<leader>?', function() require('config.cheatsheet').toggle() end, 'Keymap Guide')
map('<leader>hk', function() require('config.cheatsheet').toggle() end, 'Keymap Guide')
map('<leader>hg', '<cmd>ConfigGuide<cr>', 'Config Guide')

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
map('<leader>bb', function() require('config.pick').open('buffers') end, 'Buffers')
-- Preserve splits and prompt before discarding unsaved changes.
map('<leader>bd', function() Snacks.bufdelete() end, 'Close buffer')
map('<leader>ww', '<C-w>w', 'Switch window')
map('<leader>wv', '<cmd>vsplit<cr>', 'Vertical split')
map('<leader>ws', '<cmd>split<cr>', 'Horizontal split')
map('<leader>qq', '<cmd>qa<cr>', 'Quit')
map('<leader>l', '<cmd>Lazy<cr>', 'Plugins')
map('<leader>uh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({bufnr=0}), {bufnr=0})
end, 'Inlay Hints')
map('<leader>uf', function() vim.g.autoformat = vim.g.autoformat == false end, 'Format on Save')
local workspace = require('config.workspace')
map('<leader>uw', workspace.toggle, 'Workspace')
map('<leader>uW', workspace.exit, 'Exit Workspace')
map('<leader>ch', function() require('config.python_help').show() end, 'Python Builtins')
vim.keymap.set({'n','i'}, '<C-s>', '<cmd>write<cr>', {desc='Save'})
vim.api.nvim_create_autocmd('LspAttach', { callback = function(ev)
  local function lmap(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, {buffer=ev.buf, silent=true, desc=desc})
  end
  lmap('gd', function() require('config.lsp_actions').locations('definition') end, 'Definition')
  lmap('gD', function() require('config.lsp_actions').locations('declaration') end, 'Declaration')
  lmap('gr', function() require('config.pick').open('references') end, 'References')
  lmap('gI', function() require('config.lsp_actions').locations('implementation') end, 'Implementation')
  lmap('gy', function() require('config.lsp_actions').locations('type_definition') end, 'Type definition')
  lmap('K', function() require('config.smart_docs').show() end, 'Smart Docs')
  lmap('<leader>ca', function() require('config.lsp_actions').code_action() end, 'Code Actions')
  vim.keymap.set('n', '<leader>cr', function() return ':IncRename ' .. vim.fn.expand('<cword>') end,
    {buffer=ev.buf, expr=true, desc='Rename'})
  -- Ctrl-K retains contextual signatures; gK lazily opens external references.
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

-- ── 1337 Station Mode Commands & Keymaps ──────────────────────────────────────
vim.api.nvim_create_user_command('StationHealth', function()
  require('config.station').health()
end, { desc = 'Open 1337 Station Health & Repair modal' })

vim.api.nvim_create_user_command('StationFix', function()
  require('config.station').fix_safe()
end, { desc = 'Execute safe 1337 Station repairs (create /goinfre/$USER, link, UV_CACHE_DIR)' })

vim.api.nvim_create_user_command('StationVenv', function()
  require('config.station').rebuild_venv()
end, { desc = 'Rebuild project .venv on local /goinfre using uv' })

vim.api.nvim_create_user_command('StationTools', function()
  require('config.station').install_tools()
end, { desc = 'Run 1337 tool installer (install.sh)' })

vim.api.nvim_create_user_command('StationMode', function(opts)
  local arg = vim.trim(opts.args:lower())
  if arg == 'on' or arg == '1' or arg == 'enable' then
    vim.g.station_1337 = true
    vim.notify('1337 Station Mode enabled', vim.log.levels.INFO)
    require('config.station').init()
  elseif arg == 'off' or arg == '0' or arg == 'disable' then
    vim.g.station_1337 = false
    vim.notify('1337 Station Mode disabled', vim.log.levels.INFO)
  elseif arg == 'toggle' then
    vim.g.station_1337 = not require('config.station').is_1337()
    vim.notify('1337 Station Mode: ' .. (vim.g.station_1337 and 'ON' or 'OFF'), vim.log.levels.INFO)
    if vim.g.station_1337 then require('config.station').init() end
  else
    require('config.station').health()
  end
end, { nargs = '?', desc = 'Manage or inspect 1337 Station Mode' })

map('<leader>13', function() require('config.station').health() end, '1337 Station Health')
map('<leader>u1', function() require('config.station').health() end, '1337 Station Health')

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
map('<leader>cm', function() require('config.makefile').pick() end, 'Make Targets')
map('<leader>cM', function() require('config.makefile').run() end, 'Default Target')

-- Window resize keymaps
map('<C-Up>', '<cmd>resize +2<cr>', 'Increase window height')
map('<C-Down>', '<cmd>resize -2<cr>', 'Decrease window height')
map('<C-Left>', '<cmd>vertical resize -2<cr>', 'Decrease window width')
map('<C-Right>', '<cmd>vertical resize +2<cr>', 'Increase window width')


-- Zen mode toggle
map('<leader>uz', function() Snacks.zen() end, 'Zen Mode')
map('<leader>uZ', function() Snacks.zen.zoom() end, 'Zoom')

-- Visual mode indenting
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left (keep selection)' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right (keep selection)' })

-- Commands register cheaply; reference modules and indices stay lazy.
require('config.docs_lifecycle').setup()
map('K', function() require('config.smart_docs').show() end, 'Smart Docs')
map('gK', function() require('config.deep_docs').lookup() end, 'Deep Docs')
map('<leader>dk', function() require('config.smart_docs').show() end, 'Smart Docs')
map('<leader>dK', function() require('config.deep_docs').lookup() end, 'Deep Docs')
map('<leader>db', '<cmd>DocsBrowse<cr>', 'Browse Docs')
map('<leader>du', '<cmd>DocsUpdate<cr>', 'Update Docs')
map('<leader>dh', '<cmd>DocsHealth<cr>', 'Docs Health')

-- Diagnostic navigation keymaps
local function diagnostic_jump(count)
  local before = require('config.cursor_ui').snapshot()
  vim.diagnostic.jump({ count = count * vim.v.count1, on_jump = function(diagnostic, buf)
    if diagnostic and buf == vim.api.nvim_get_current_buf() then
      require('config.cursor_ui').after(before)
      vim.diagnostic.open_float({ bufnr = buf, scope = 'cursor', focus = false })
    end
  end })
end
map('[d', function() diagnostic_jump(-1) end, 'Previous diagnostic')
map(']d', function() diagnostic_jump(1) end, 'Next diagnostic')
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
