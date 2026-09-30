local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = true, version = false },
  install = { colorscheme = { "perfect-black", "habamax" } },
  ui = { border = require("config.ui").border },
  checker = {
    enabled = false, -- check manually with :Lazy check
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

vim.cmd.colorscheme('perfect-black')

require("config.keymaps")
require("config.autocmds")
require('config.cursor_ui').setup()
-- Context lookup starts after startup; statusline draws only the cached string.
vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('BlackSpatialInit', { clear = true }),
  pattern = 'VeryLazy', once = true,
  callback = function()
    require('config.symbol_context').setup()
    require('config.symbol_illumination').setup()
  end,
})

-- 1337 Station Mode: non-blocking deferred startup scan
vim.defer_fn(function()
  pcall(function() require('config.station').init() end)
end, 300)
