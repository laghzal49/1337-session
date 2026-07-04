-- ============================================================================
-- lua/plugins/python.lua — complete Python IDE stack
-- ============================================================================
-- LSP (basedpyright), linting (flake8 + mypy, wired in plugins/lint.lua),
-- formatting (isort + autopep8 — the flake8/pycodestyle-driven formatter),
-- virtualenv switching, and debugging (debugpy). Everything installs itself
-- via mason — this is also the only ACTIVE mason.nvim spec in this config
-- (the one in the old example.lua never ran: it sat behind `if true then
-- return {} end`, so flake8/mypy were never actually auto-installed).
-- ============================================================================

return {
  -- LSP: basedpyright — pyright fork, faster + more inference features.
  -- typeCheckingMode is off here on purpose: mypy (nvim-lint) owns type
  -- checking, so we don't get duplicate/conflicting diagnostics.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                autoImportCompletions = true,
                typeCheckingMode = "off",
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
      },
    },
  },

  -- Formatter: isort (import sorting) + autopep8 (the flake8/pycodestyle
  -- autofixer — the "flake8 formatter" you asked for). Runs on save via
  -- LazyVim's format-on-save (vim.g.autoformat), same as every other ft.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "isort", "autopep8" },
      },
      formatters = {
        autopep8 = {
          prepend_args = { "--max-line-length", "100" },
        },
      },
    },
  },

  -- Virtualenv / interpreter switcher.
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    cmd = "VenvSelect",
    opts = {},
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },

  -- Debugging: debugpy via nvim-dap, using LazyVim's dap UI/core.
  { import = "lazyvim.plugins.extras.dap.core" },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    keys = {
      { "<leader>dPt", function() require("dap-python").test_method() end, desc = "Debug Method", ft = "python" },
      { "<leader>dPc", function() require("dap-python").test_class() end, desc = "Debug Class", ft = "python" },
    },
    config = function()
      -- LazyVim.get_pkg_path resolves the mason install dir on both mason
      -- 1.x and 2.0 (get_install_path() was removed in mason 2.0)
      require("dap-python").setup(LazyVim.get_pkg_path("debugpy", "/venv/bin/python"))
    end,
  },

  -- Make sure everything above (and flake8/mypy from lint.lua) is on $PATH.
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "basedpyright",
        "flake8",
        "mypy",
        "autopep8",
        "isort",
        "debugpy",
      },
    },
  },
}

-- ============================================================================
-- WHAT THIS FILE ADDS (for diffing):
--   basedpyright               Python LSP (hover, completion, go-to-def, refs)
--   isort + autopep8           format-on-save via conform.nvim
--   linux-cultist/venv-selector.nvim   <leader>cv to pick a venv/interpreter
--   nvim-dap-python + dap.core extra   <leader>d* debugging, <leader>dPt/dPc
--   mason ensure_installed      the ACTIVE list (flake8/mypy now really
--                                get installed — the old one in example.lua
--                                was dead code and never ran)
-- ============================================================================
