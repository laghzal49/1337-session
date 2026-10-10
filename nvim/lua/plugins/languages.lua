-- Language-specific LSP servers and formatters.
return {
  -- Neovim Lua development: injects runtime paths, vim API types, and plugin
  -- type annotations into lua_ls automatically (replaces deprecated neodev).
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = 'lazy.nvim', words = { 'LazyVim' } },
      },
    },
  },
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
          settings = { ty = {
            diagnosticMode = 'openFilesOnly',
            completions = { autoImport = true, completeFunctionParentheses = true },
            -- Ruff reports syntax errors when installed; ty still owns types.
            showSyntaxErrors = vim.fn.executable('ruff') == 0,
          } },
          root_dir = require('config.python_environment').root_dir,
          before_init = require('config.python_environment').before_init,
          on_init = function(client)
            -- Client.settings is captured before before_init runs. Publish its
            -- isolated result for workspace/configuration requests from ty.
            client.settings = client.config.settings
          end,
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
        },
        ruff = {
          cmd = { 'ruff', 'server' },
          root_dir = require('config.python_environment').ruff_root_dir,
          init_options = { settings = { organizeImports = true, fixAll = true } },
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
            -- Conform provides one deterministic formatter; Ruff LSP owns lint
            -- and explicit source actions, ty owns semantic language services.
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        },
        -- lua_ls: only register if lua-language-server is installed system-wide
        lua_ls = vim.fn.executable('lua-language-server') == 1 and {
          mason = false,
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              workspace = { checkThirdParty = false },
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
  {
    'neovim/nvim-lspconfig',
    init = function() require('config.python_lsp').setup() end,
  },
  -- NOTE: lsp_signature.nvim removed — blink.cmp has built-in signature help
  -- (signature = { enabled = true } in completion.lua). Keeping both causes
  -- duplicate floating windows on every function call.
}
