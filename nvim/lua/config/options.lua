vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- Add any additional options here

-- A black, opaque canvas with one compact status row and one tab row.
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.number = true
vim.opt.relativenumber = true
-- Keep one sign slot; add a second when multiple signs share a line.
vim.opt.signcolumn = "auto:1-2"
vim.opt.statuscolumn = "" -- Native rendering honors the dynamic sign width.
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.showmode = false
vim.opt.showcmd = false
vim.opt.ruler = false
vim.opt.shortmess:append({ I = true, W = true, c = true })
vim.opt.timeoutlen = 350
vim.opt.updatetime = 250
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.fillchars:append({ eob = " ", fold = " ", foldopen = "", foldclose = "", foldsep = " ", vert = "│", diff = " " })

-- Stable visual anchors; a short completion menu keeps code visible.
vim.opt.pumheight = 8
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,line"
vim.opt.numberwidth = 2
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }

vim.opt.winborder = require("config.ui").border


vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.wrap = false
vim.opt.synmaxcol = 300

-- Keep the current split visually anchored without making other splits compete
-- for attention. Preserve window-local highlighting used by floating panels.
require('config.focus_ui').setup()

-- Session options
vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }

-- Fold settings
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Mouse and clipboard
vim.opt.mouse = 'a'
vim.opt.mousemodel = 'extend'
vim.opt.clipboard = 'unnamedplus'

-- Search improvements
vim.opt.inccommand = 'split'  -- Live preview of :s substitutions in a split
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Backup/swap improvements
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Split animation smoothness
vim.opt.splitkeep = 'screen'  -- Reduce visual noise when splitting

-- Enable soft wrap for text-heavy filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('SoftWrapFiletypes', { clear = true }),
  pattern = { 'markdown', 'text', 'help', 'gitcommit' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
  end,
})
