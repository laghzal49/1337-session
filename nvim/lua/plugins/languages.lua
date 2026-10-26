-- Language-specific LSP servers and formatters.
local ruff_config = vim.fn.stdpath('config') .. '/ruff.toml'
local function ruff_args(safe)
  return function(_, ctx)
    local args = safe and { '--no-unsafe-fixes' } or {}
    -- Mirror Ruff discovery: pyproject files without tool.ruff do not count.
    for directory in vim.fs.parents(ctx.filename) do
      for _, name in ipairs({ '.ruff.toml', 'ruff.toml', 'pyproject.toml' }) do
        local path = directory .. '/' .. name
        if vim.fn.filereadable(path) == 1 then
          if name ~= 'pyproject.toml' then return args end
          for _, line in ipairs(vim.fn.readfile(path)) do
            if line:match('^%s*%[tool%.ruff[%].]') then return args end
          end
        end
      end
    end
    vim.list_extend(args, { '--config', ruff_config })
    return args
  end
end
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
        python = { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' },
      },
      -- Share editor-owned Flake8 defaults between Ruff LSP and Conform.
      formatters = {
        ruff_fix = { append_args = ruff_args(true) },
        ruff_organize_imports = { append_args = ruff_args(true) },
        ruff_format = { append_args = ruff_args(false) },
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
        float = {
          border = 'rounded', source = 'if_many', header = '', max_width = 80,
          focusable = true, title = ' Diagnostics ',
          format = function(diagnostic) return diagnostic.message end,
          suffix = function(diagnostic)
            local code = diagnostic.code
            return code ~= nil and (' [' .. tostring(code) .. ']') or '', 'BlackPopupHint'
          end,
          prefix = function(diagnostic, index, total)
            local name = ({'error','warn','info','hint'})[diagnostic.severity] or 'info'
            local group = ({'Error','Warn','Info','Hint'})[diagnostic.severity] or 'Info'
            return require('config.ui').icon(name)..' '..(total>1 and index..'. ' or ''), 'Diagnostic'..group
          end,
        },
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
          init_options = { settings = {
            organizeImports = true,
            fixAll = true,
            configuration = ruff_config,
            configurationPreference = 'filesystemFirst',
          } },
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
