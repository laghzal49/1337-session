if vim.fn.has("nvim-0.11") == 0 then error("Perfect Black requires Neovim 0.11 or newer") end

-- Make Mason executables available to Neovim
local path_separator = vim.fn.has('win32') == 1 and ';' or ':'
local inherited_path = vim.env.PATH or ''
vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin'
  .. (inherited_path ~= '' and (path_separator .. inherited_path) or '')

-- Bootstrap lazy.nvim and the explicitly configured plugins
require("config.lazy")
