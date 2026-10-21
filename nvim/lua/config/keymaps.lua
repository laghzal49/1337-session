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
vim.api.nvim_create_user_command('DebugHelp', function() require('config.debug_help').show() end,
  { desc = 'Debugger tutorial and keyboard guide' })
vim.api.nvim_create_user_command('DebugExample', function() require('config.debug_help').example() end,
  { desc = 'Open a temporary Python debugger practice project' })
map('<leader>D?', '<cmd>DebugHelp<cr>', 'How to use the debugger')

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
  if vim.bo[ev.buf].filetype == 'python' then
    lmap('<leader>cI', function() require('config.python_lsp').source_action('source.organizeImports') end, 'Organize Python imports')
    lmap('<leader>cF', function() require('config.python_lsp').source_action('source.fixAll') end, 'Apply Ruff fixes')
    lmap('<leader>cp', function() require('config.python_lsp').info() end, 'Python LSP environment')
  end
  -- Ctrl-K retains contextual signatures; gK lazily opens external references.
end })

map('<leader>gg', function()
  if not require('config.tool_health').require_tool('lazygit') then return end
  Snacks.lazygit({ cwd = require('config.project').root() })
end, 'Git UI')

-- Focus the project terminal, or hide it when it already has focus.
local toggle_terminal = function() require('config.terminal').toggle() end
vim.keymap.set({ 'n', 't', 'i' }, '<C-t>', toggle_terminal, { desc = 'Focus or hide project terminal' })
vim.keymap.set({ 'n', 't', 'i' }, '<C-/>', toggle_terminal, { desc = 'Focus or hide project terminal' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.api.nvim_create_user_command('ConfigTools', function()
  require('config.tool_health').show()
end, {})

vim.api.nvim_create_user_command('SessionProfile', function(args)
  require('config.session_profile').command(args.args)
end, { nargs = '?', complete = function() return { 'start', 'stop', 'report' } end,
  desc = 'Measure live LSP requests and event-loop stalls on this machine' })

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

vim.api.nvim_create_user_command('StationVenvMigrate', function()
  require('config.station').migrate_venv()
end, { desc = 'Preview and migrate an existing .venv to goinfre with a retained backup' })

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
      require('config.popups').diagnostic({ bufnr = buf, scope = 'cursor', focus = false })
    end
  end })
end
map('[d', function() diagnostic_jump(-1) end, 'Previous diagnostic')
map(']d', function() diagnostic_jump(1) end, 'Next diagnostic')
map('<leader>cd', function()
  require('config.popups').diagnostic()
end, 'Line diagnostics')

-- Yank to system clipboard helpers
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to clipboard' })
map('<leader>Y', '"+Y', 'Yank line to clipboard')

-- Display-line movement makes wrapped prose usable; counts retain logical lines.
vim.keymap.set({ 'n', 'x' }, 'j', function() return vim.v.count == 0 and 'gj' or 'j' end,
  { expr = true, silent = true, desc = 'Down (display line)' })
vim.keymap.set({ 'n', 'x' }, 'k', function() return vim.v.count == 0 and 'gk' or 'k' end,
  { expr = true, silent = true, desc = 'Up (display line)' })
map('<leader>ud', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, 'Toggle buffer diagnostics')
map('<leader>ul', function() vim.wo.number = not vim.wo.number end, 'Toggle line numbers')
map('<leader>ur', function() vim.wo.relativenumber = not vim.wo.relativenumber end, 'Toggle relative numbers')
map('<leader>uv', function() vim.wo.wrap = not vim.wo.wrap end, 'Toggle line wrap')
map('<leader>bo', function() Snacks.bufdelete.other() end, 'Close other buffers')

-- Project tasks run in the background; errors feed editable quickfix.
vim.api.nvim_create_user_command('Task', function(args) require('config.tasks').pick(args.args) end,
  { nargs = '*', desc = 'Pick and run a project build/test/lint task', complete = function()
    return vim.tbl_map(function(task) return task.name end, require('config.tasks').discover())
  end })
vim.api.nvim_create_user_command('TaskLast', function() require('config.tasks').rerun() end, { desc = 'Repeat last project task' })
vim.api.nvim_create_user_command('TaskStop', function() require('config.tasks').stop() end, { desc = 'Stop active project task' })
vim.api.nvim_create_user_command('TaskOutput', function() require('config.tasks').show_output() end, { desc = 'Open live or last task output' })
map('<leader>rt', '<cmd>Task<cr>', 'Project tasks')
map('<leader>rr', '<cmd>TaskLast<cr>', 'Repeat last task')
map('<leader>rs', '<cmd>TaskStop<cr>', 'Stop task')
map('<leader>ro', '<cmd>TaskOutput<cr>', 'Task output')
map('<leader>xn', '<cmd>cnext<cr>', 'Next quickfix item')
map('<leader>xp', '<cmd>cprevious<cr>', 'Previous quickfix item')
map('<leader>xc', '<cmd>cclose<cr>', 'Close quickfix')
map('<leader>uy', function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then return end
  local root = require('config.project').root()
  if path:sub(1, #root + 1) == root .. '/' then path = path:sub(#root + 2) end
  vim.fn.setreg('+', path)
  vim.notify('Copied ' .. path, vim.log.levels.INFO)
end, 'Copy project-relative file path')
vim.keymap.set('x', '<A-j>', ":move '>+1<CR>gv=gv", { silent = true, desc = 'Move selected lines down' })
vim.keymap.set('x', '<A-k>', ":move '<-2<CR>gv=gv", { silent = true, desc = 'Move selected lines up' })

map('<leader>uB', '<cmd>BufferPerformanceRestore<cr>', 'Restore full features for a small buffer')
