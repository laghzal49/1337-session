-- Make Mason executables available to Neovim
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
