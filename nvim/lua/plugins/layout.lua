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
      opts.left = {
        { title = " 󰉋  PROJECT", ft = "neo-tree", size = { width = 28 } },
      }
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
    opts = {
      layout = { default_direction = "right", min_width = 22, max_width = 28 },
      show_guides = true,
      guides = { mid_item = "├─", last_item = "└─", nested_top = "│ ", whitespace = "  " },
    },
  },
  { "nvim-treesitter/nvim-treesitter-context", opts = { max_lines = 2, trim_scope = "outer" } },
  {
    "nvim-mini/mini.icons",
    opts = {
      extension = {
        c = { glyph = "", hl = "MiniIconsBlue" },
        h = { glyph = "", hl = "MiniIconsCyan" },
        cpp = { glyph = "", hl = "MiniIconsBlue" },
        py = { glyph = "", hl = "MiniIconsYellow" },
        lua = { glyph = "", hl = "MiniIconsAzure" },
        md = { glyph = "", hl = "MiniIconsGrey" },
        sh = { glyph = "", hl = "MiniIconsGreen" },
      },
      file = {
        Makefile = { glyph = "", hl = "MiniIconsOrange" },
        [".gitignore"] = { glyph = "", hl = "MiniIconsOrange" },
        ["pyproject.toml"] = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = { preset = "helix", delay = 250, win = { border = "rounded" } },
  },
  {
    "folke/noice.nvim",
    opts = { presets = { bottom_search = true, command_palette = true, long_message_to_split = true } },
  },
}
