-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- A black, opaque canvas with one compact status row and one tab row.
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.number = true
-- Keep one sign slot; add a second when multiple signs share a line.
vim.opt.signcolumn = "auto:1-2"
vim.opt.statuscolumn = "" -- Native rendering honors the dynamic sign width.
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.timeoutlen = 350
vim.opt.updatetime = 250
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.fillchars:append({ eob = " ", fold = " ", vert = "│", diff = " " })

-- Stable visual anchors; a short completion menu keeps code visible.
vim.opt.pumheight = 8
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,line"

vim.opt.winborder = require("config.ui").border
