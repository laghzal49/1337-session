-- Language-specific LSP servers and formatters.
return {
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'ruff_format' },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      diagnostics = {
        update_in_insert = false,
        severity_sort = true,
        virtual_text = false,
        virtual_lines = false,
        float = { border = require('config.ui').border, source = 'if_many', header = '', max_width = 80, focusable = true },
      },
      servers = {
        clangd = {
          mason = false,
          cmd = { 'clangd', '--background-index', '--clang-tidy', '--header-insertion=never' },
        },
        ty = {
          enabled = true,
          mason = false,
          cmd = { 'ty', 'server' },
          settings = { ty = vim.empty_dict() },
          root_dir = require('config.python_environment').root_dir,
          before_init = require('config.python_environment').before_init,
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
        },
        ruff = {
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },
}
