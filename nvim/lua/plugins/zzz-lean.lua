-- Preserve the UI while keeping scrolling responsive.
return {
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = true },
      animate = { enabled = true },
      indent = { enabled = true },
      scroll = {
        enabled = true,
        animate = { duration = { step = 8, total = 120 } },
        animate_repeat = { duration = { step = 4, total = 40 } },
      },
    },
  },
}
