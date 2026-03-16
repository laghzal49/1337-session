-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Stable visual anchors; a short completion menu keeps code visible.
vim.opt.pumheight = 8
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,line"

vim.opt.winborder = require("config.ui").border

vim.opt.pumblend = require("config.ui").blend
