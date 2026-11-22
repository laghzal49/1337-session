local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    -- CI and unattended setup must fail rather than wait for keyboard input.
    vim.cmd('cquit 1')
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = true, version = false },
  install = { colorscheme = { "tokyonight-moon", "perfect-black", "habamax" } },
  ui = { border = require("config.ui").border },
  checker = {
    enabled = false, -- check manually with :Lazy check
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  rocks = { enabled = false }, -- no configured plugin needs LuaRocks
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

require('config.typography').setup()
vim.cmd.colorscheme(vim.g.black_color_style == 'nvimz' and 'nvimz' or (vim.g.black_color_style == 'electrovoid' and 'electrovoid' or 'perfect-black'))
-- Restore semantic Rose variable color after theme/plugin initialization.
if vim.g.black_color_style == 'rose' then
  vim.api.nvim_set_hl(0, '@variable', { fg = require('config.palette').variable })
end
require('config.accessibility').setup()
require('config.popups').setup()

require("config.keymaps")
require("config.autocmds")
require('config.cursor_ui').setup()
-- Context lookup starts after startup; statusline draws only the cached string.
vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('BlackSpatialInit', { clear = true }),
  pattern = 'VeryLazy', once = true,
  callback = function()
    require('config.workspace_info').setup()
    if vim.g.black_color_style ~= 'nvimz' then require('config.editor_ui').setup() end
    require('config.symbol_context').setup()
    require('config.symbol_illumination').setup()
  end,
})

-- Native nvimz-style statusline and startup dashboard, without the heavyweight UI plugins.
if vim.g.black_color_style == 'nvimz' then
  require('config.nvimz_statusline').setup()
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function() vim.schedule(function() require('config.nvimz_dashboard').open_if_empty() end) end,
  })
end

-- 1337 Station Mode: non-blocking deferred startup scan
vim.defer_fn(function()
  pcall(function() require('config.station').init() end)
end, 300)
