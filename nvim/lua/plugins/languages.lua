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
        -- lua_ls: only register if lua-language-server is installed system-wide
        lua_ls = vim.fn.executable('lua-language-server') == 1 and {
          mason = false,
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file('', true) },
              diagnostics = { globals = { 'vim', 'Snacks' } },
              telemetry = { enable = false },
            },
          },
        } or nil,
        -- jsonls: only register if vscode-json-language-server is installed
        jsonls = vim.fn.executable('vscode-json-language-server') == 1 and {
          mason = false,
        } or nil,
      },
    },
  },
  -- NOTE: lsp_signature.nvim removed — blink.cmp has built-in signature help
  -- (signature = { enabled = true } in completion.lua). Keeping both causes
  -- duplicate floating windows on every function call.
}
