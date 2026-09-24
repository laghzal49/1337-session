return {
  {
    "folke/edgy.nvim",
    opts = function(_, opts)
      opts.animate = { enabled = false }
      opts.options = {
        left = { size = 28 },
        right = { size = 26 },
        bottom = { size = 12 },
        top = { size = 8 },
      }
      opts.left = {}
      opts.right = {
        { title = " 󰅩  SYMBOLS", ft = "aerial", size = { width = 26 } },
        { title = " 󰙨  TESTS", ft = "neotest-summary" },
      }
      opts.bottom = {
        {
          title = "   TERMINAL",
          ft = "snacks_terminal",
          size = { height = 0.30 },
          filter = function(_, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        { title = " 󰒡  RESULTS", ft = "qf", size = { height = 0.25 } },
        { title = " 󰅚  DIAGNOSTICS", ft = "trouble", size = { height = 0.25 } },
        { title = " 󰙨  TEST OUTPUT", ft = "neotest-output-panel", size = { height = 0.30 } },
        { title = " 󰋖  HELP", ft = "help", size = { height = 0.35 } },
      }
      opts.top = {}
    end,
  },
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    keys = { { "<leader>cs", "<cmd>AerialToggle float<cr>", desc = "Code outline (Aerial)" } },
    opts = {
      layout = { default_direction = "right", min_width = 22, max_width = 28 },
      show_guides = true,
      guides = { mid_item = "├─", last_item = "└─", nested_top = "│ ", whitespace = "  " },
    },
  },
  { "nvim-treesitter/nvim-treesitter-context", opts = { max_lines = 2, trim_scope = "outer" } },
  {
    "folke/which-key.nvim",
    opts = { preset = "helix", delay = 250, win = { border = "rounded" } },
  },
}
