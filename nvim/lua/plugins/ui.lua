return {
  { "nvim-mini/mini.icons", enabled = false },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    priority = 1000,
    opts = { default = true, color_icons = true, strict = true },
  },
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = false },
      terminal = {
        win = { position = "bottom", height = 0.30, border = "top", wo = { winbar = "  Terminal" } },
      },
    },
  },
}
