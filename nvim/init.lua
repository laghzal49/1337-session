if vim.fn.has("nvim-0.11") == 0 then error("Perfect Black requires Neovim 0.11 or newer") end

-- Make Mason executables available to Neovim
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Bootstrap lazy.nvim and the explicitly configured plugins
require("config.lazy")
require("config.pdf").setup()
