-- ============================================================================
-- lua/plugins/lint.lua — mypy on demand (Python)
-- ============================================================================
-- Uses nvim-lint: runs the external binary and shows results as normal
-- Neovim diagnostics (same UI as LSP diagnostics — the tiny-inline chips,
-- lualine counts, and bufferline badges from ui.lua all pick them up).
--
-- mypy is the only external linter left here on purpose: style linting
-- moved to ruff's native LSP server (plugins/python.lua), which reports
-- the same flake8-family rules LIVE as you type instead of on save.
--
-- Manual trigger only (<leader>cm) — whole-program type checking spikes all
-- CPU cores for a second+, which isn't worth paying on every single save on
-- weak hardware. Run it when you actually want the answer.
--
-- Requires `mypy` on $PATH (mason installs it — see plugins/python.lua).
-- ============================================================================

return {
  {
    "mfussenegger/nvim-lint",
    ft = "python",
    keys = {
      {
        "<leader>cm",
        function() require("lint").try_lint(nil, { ignore_errors = true }) end,
        desc = "Run mypy (nvim-lint)",
        ft = "python",
      },
    },
    opts = {
      linters_by_ft = {
        python = { "mypy" },
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
    end,
  },
}

-- ============================================================================
-- WHAT THIS FILE ADDS (for diffing):
--   mfussenegger/nvim-lint  — mypy on Python buffers, triggered manually via
--                             <leader>cm (style rules live in ruff's LSP
--                             server, plugins/python.lua)
-- Results appear as standard diagnostics: tiny-inline chips, counts in
-- lualine + bufferline (ui.lua)
-- ============================================================================
