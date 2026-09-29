-- Explicit foundations: no distribution defaults or automatic tool installers.
return {
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = {}, keys = {
    { '<leader>qs', function() require('persistence').load() end, desc = 'Restore session' },
    { '<leader>qS', function() require('persistence').select() end, desc = 'Select session' },
    { '<leader>qd', function() require('persistence').stop() end, desc = "Don't save session" },
    { '<leader>ql', function() require('persistence').load({ last = true }) end, desc = 'Restore last session' },
  } },
  { 'nvim-treesitter/nvim-treesitter', lazy = false, build = ':TSUpdate', opts = {}, config = function(_, opts)
    require('nvim-treesitter').setup(opts)
    vim.api.nvim_create_autocmd('FileType', { callback = function(ev)
      if vim.bo[ev.buf].buftype == '' then pcall(vim.treesitter.start, ev.buf) end
    end })
  end },
  { 'nvim-treesitter/nvim-treesitter-context', event = { 'BufReadPost', 'BufNewFile' }, opts = { max_lines = 2, trim_scope = 'outer' } },
  { 'neovim/nvim-lspconfig', event = { 'BufReadPre', 'BufNewFile' }, dependencies = { 'saghen/blink.cmp' },
    config = function(_, opts)
      vim.diagnostic.config(opts.diagnostics or {})
      for name, config in pairs(opts.servers or {}) do
        config = vim.deepcopy(config)
        config.enabled, config.mason = nil, nil
        local base_caps = require('blink.cmp').get_lsp_capabilities()
        config.capabilities = vim.tbl_deep_extend('force', base_caps, config.capabilities or {})
        vim.lsp.config(name, config)
        local resolved = vim.lsp.config[name]
        if resolved and type(resolved.cmd) == 'table' and vim.fn.executable(resolved.cmd[1]) == 1 then
          vim.lsp.enable(name)
        end
      end
    end },
  { 'stevearc/conform.nvim', event = 'BufWritePre', cmd = 'ConformInfo', opts = {
    format_on_save = function(buf)
      if vim.b[buf].autoformat == false or vim.g.autoformat == false then return end
      return { timeout_ms = 1500, lsp_format = 'fallback' }
    end,
  }, keys = { { '<leader>cf', function() require('conform').format({ async = true, lsp_format = 'fallback' }) end, desc = 'Format buffer' } } },
  { 'mason-org/mason.nvim', cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' }, opts = {
    ui = { border = require('config.ui').border, width = 0.8, height = 0.8 },
  } },
}
