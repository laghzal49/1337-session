-- ============================================================================
-- lua/plugins/python.lua — complete Python IDE stack (ruff generation)
-- ============================================================================
-- LSP (basedpyright for intelligence + ruff's native server for style),
-- type checking (mypy on save, wired in plugins/lint.lua), formatting
-- (ruff), and virtualenv switching. Everything installs itself via mason.
--
-- WHY RUFF (v5.2 upgrade): flake8 + isort + autopep8 were three separate
-- Python-based tools; ruff is ONE Rust binary that reimplements all of
-- them (flake8's E/W/F rules, isort's import sorting, the pycodestyle
-- autofixes) roughly 100x faster — and its LSP server surfaces the same
-- diagnostics LIVE as you type instead of only on :w. Same rules, same
-- diagnostics UI (chips/lualine/bufferline pick them up unchanged), no
-- new keymaps.
-- ============================================================================

return {
  -- LSPs. basedpyright — pyright fork, faster + more inference features —
  -- owns intelligence (hover, completion, go-to-def). typeCheckingMode is
  -- off on purpose: mypy (nvim-lint) owns type checking, so we don't get
  -- duplicate/conflicting diagnostics. ruff's native server owns style
  -- diagnostics + code actions (fix-all, organize imports).
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
        ruff = {
          init_options = {
            settings = {
              logLevel = "error",
              lineLength = 79,
            },
          },
        },
      },
      setup = {
        ruff = function()
          -- basedpyright owns hover; ruff would shadow it with rule docs
          Snacks.util.lsp.on({ name = "ruff" }, function(_, client)
            client.server_capabilities.hoverProvider = false
          end)
        end,
      },
    },
  },

  -- Formatter: ruff — import sorting + black-style formatting in one pass
  -- (replaces isort + autopep8). Runs on save via LazyVim's format-on-save
  -- (vim.g.autoformat), same as every other ft.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
      formatters = {
        ruff_format = {
          args = { "format", "--line-length", "70", "--force-exclude", "--stdin-filename", "$FILENAME", "-" },
        },
      },
    },
  },

  -- Virtualenv / interpreter switcher.
  -- No branch pin: the old "regexp" rewrite branch WAS the recommended
  -- install, but it was merged into main on 2025-08-27 — pinning it now
  -- breaks fresh installs.
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    opts = {},
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },

  -- Make sure everything above (and mypy from lint.lua) is on $PATH.
  -- (mason-org/mason.nvim is the canonical repo since the 2025 org move)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "basedpyright",
        "ruff",
        "mypy",
      },
    },
  },
}

-- ============================================================================
-- WHAT THIS FILE ADDS (for diffing):
--   basedpyright               Python LSP (hover, completion, go-to-def, refs)
--   ruff (native LSP server)   live style diagnostics + code actions —
--                              replaces flake8 (same E/W/F rule families,
--                              ~100x faster, live instead of on-save-only)
--   ruff via conform.nvim      format-on-save: import sorting + formatting
--                              in one pass — replaces isort + autopep8
--   linux-cultist/venv-selector.nvim   <leader>cv to pick a venv/interpreter
--   mason ensure_installed     basedpyright, ruff, mypy (+ lua/sh)
-- ============================================================================
