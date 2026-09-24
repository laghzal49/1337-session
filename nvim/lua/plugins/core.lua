-- Explicit foundations: no distribution defaults or automatic tool installers.
return {
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = {}, keys = {
    { '<leader>qs', function() require('persistence').load() end, desc = 'Restore session' },
  } },
  { 'folke/snacks.nvim', lazy = false, priority = 900, opts = { bigfile = { enabled = true }, quickfile = { enabled = true } } },
  { 'folke/noice.nvim', event = 'VeryLazy', dependencies = { 'MunifTanjim/nui.nvim' },
    opts = { presets = { inc_rename = true }, lsp = { override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
    } } } },
  { 'folke/which-key.nvim', event = 'VeryLazy', opts = {} },
  { 'nvim-lualine/lualine.nvim', event = 'VeryLazy', opts = {} },
  { 'akinsho/bufferline.nvim', event = 'VeryLazy', dependencies = { 'nvim-tree/nvim-web-devicons' }, opts = {} },
  { 'lewis6991/gitsigns.nvim', event = { 'BufReadPre', 'BufNewFile' }, opts = {} },
  { 'folke/trouble.nvim', cmd = 'Trouble', opts = {}, keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Project diagnostics' },
    { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix diagnostics' },
  } },
  { 'folke/edgy.nvim', event = 'VeryLazy', opts = {} },
  { 'mason-org/mason.nvim', cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' }, opts = {} },
  { 'jay-babu/mason-nvim-dap.nvim', enabled = false },
  { 'mfussenegger/nvim-dap', cmd = { 'DapContinue', 'DapToggleBreakpoint' }, keys = {
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Breakpoint' },
    { '<leader>dc', function() require('dap').continue() end, desc = 'Continue debugger' },
  } },
  { 'nvim-treesitter/nvim-treesitter', lazy = false, build = ':TSUpdate', opts = {}, config = function(_, opts)
    require('nvim-treesitter').setup(opts)
    vim.api.nvim_create_autocmd('FileType', { callback = function(ev)
      if vim.bo[ev.buf].buftype == '' then pcall(vim.treesitter.start, ev.buf) end
    end })
  end },
  { 'nvim-treesitter/nvim-treesitter-context', event = { 'BufReadPost', 'BufNewFile' }, opts = {} },
  { 'neovim/nvim-lspconfig', event = { 'BufReadPre', 'BufNewFile' }, dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function(_, opts)
      vim.diagnostic.config(opts.diagnostics or {})
      for name, config in pairs(opts.servers or {}) do
        config = vim.deepcopy(config)
        config.enabled, config.mason = nil, nil
        config.capabilities = vim.tbl_deep_extend('force', require('cmp_nvim_lsp').default_capabilities(), config.capabilities or {})
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
  { 'iguanacucumber/magazine.nvim', name = 'nvim-cmp', event = 'InsertEnter', dependencies = {
    'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path',
  }, opts = {
    snippet = { expand = function(args) vim.snippet.expand(args.body) end },
    sources = { { name = 'nvim_lsp' }, { name = 'path' }, { name = 'buffer' } },
  }, config = function(_, opts) require('cmp').setup(opts) end },
}
