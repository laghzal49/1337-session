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
        float = { border = 'rounded', source = 'if_many', header = '', max_width = 80, focusable = true, title = ' 󰅚 Diagnostics ' },
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
  {
    'ray-x/lsp_signature.nvim',
    event = 'LspAttach',
    opts = {
      bind = true,
      doc_lines = 10,
      max_height = 12,
      max_width = 80,
      wrap = true,
      floating_window = true,
      floating_window_above_cur_line = true,
      floating_window_off_x = 1,
      floating_window_off_y = 0,
      fix_pos = false,
      hint_enable = true,
      hint_prefix = '󰅩 ',
      hint_scheme = 'String',
      hi_parameter = 'LspSignatureActiveParameter',
      handler_opts = {
        border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
      },
      always_trigger = true,
      auto_close_after = nil,
      extra_trigger_chars = { '(', ',' },
      zindex = 200,
      padding = '',
      timer_interval = 100,
      toggle_key = '<C-k>',
    },
    config = function(_, opts)
      require('lsp_signature').setup(opts)
    end,
  },
}
