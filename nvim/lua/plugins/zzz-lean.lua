-- Keep navigation immediate on shared 1337 workstations.
return {
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = true },
      animate = { enabled = false },
      indent = { enabled = true },
      scroll = { enabled = false },
    },
  },
}
