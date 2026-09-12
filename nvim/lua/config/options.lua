-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_python_lsp = "ty"
vim.g.lazyvim_python_ruff = "ruff"
vim.opt.guifont = "JetBrainsMono Nerd Font:h12:i"
vim.opt.clipboard = "unnamedplus"

vim.opt.laststatus = 3
vim.opt.splitkeep = "screen"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.winminwidth = 5
vim.opt.pumheight = 10
vim.opt.winborder = "rounded"
