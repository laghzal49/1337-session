-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- terminal / OS window title follows the current file
vim.opt.title = true
vim.opt.titlestring = "%t %m — nvim"

-- gentle cursor blink in every mode (pure design touch; delete to disable)
vim.opt.guicursor:append("a:blinkwait700-blinkoff400-blinkon600")
