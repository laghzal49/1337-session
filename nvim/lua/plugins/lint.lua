-- ============================================================================
-- lua/plugins/lint.lua — flake8 + mypy automatically on save (Python)
-- ============================================================================
-- Uses nvim-lint: runs the external binaries and shows results as normal
-- Neovim diagnostics (same UI as LSP diagnostics — lualine counts, bufferline
-- badges, and noice rendering from ui.lua all pick them up automatically).
--
-- Requires `flake8` and `mypy` on $PATH (found at ~/.local/bin).
-- ============================================================================

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = {
      linters_by_ft = {
        python = { "flake8", "mypy" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      -- mypy is much more useful when it follows imports from the project
      -- root; nvim-lint's default args are fine, but make output terse:
      lint.linters.mypy.args = vim.list_extend({
        "--no-error-summary",
        "--show-column-numbers",
        "--hide-error-context",
      }, lint.linters.mypy.args or {})

      local group = vim.api.nvim_create_augroup("AutoLintOnSave", { clear = true })

      -- lint automatically: on open (so existing issues show right away) and
      -- on EVERY save — this is the "run flake8 + mypy when I save" part
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = group,
        callback = function()
          -- try_lint is a no-op for filetypes with no linters configured
          lint.try_lint(nil, { ignore_errors = true })
        end,
      })

      -- the plugin lazy-loads on the first file's BufReadPost, which has
      -- already fired by the time the autocmd above exists — lint it now
      vim.schedule(function()
        lint.try_lint(nil, { ignore_errors = true })
      end)
    end,
  },
}

-- ============================================================================
-- WHAT THIS FILE ADDS (for diffing):
--   mfussenegger/nvim-lint  — flake8 + mypy on Python buffers, triggered on
--                             file open and on every :w
-- No keymaps added. Results appear as standard diagnostics:
--   inline virtual text / signs, counts in lualine + bufferline (ui.lua)
-- ============================================================================
