return {
  { "nvim-mini/mini.icons", enabled = false },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    priority = 1000,
    opts = {
      default = true, color_icons = false, strict = true,
      override = {
        default_icon = { icon = "", color = "#A0A0A0", cterm_color = "248", name = "Default" },
      },
      override_by_extension = {
        py = { icon = "", name = "Python", color = "#A0A0A0" },
        lua = { icon = "", name = "Lua", color = "#A0A0A0" },
        c = { icon = "", name = "C", color = "#A0A0A0" },
        cpp = { icon = "", name = "Cpp", color = "#A0A0A0" },
        json = { icon = "", name = "Json", color = "#A0A0A0" },
        md = { icon = "", name = "Markdown", color = "#A0A0A0" },
        sh = { icon = "", name = "Shell", color = "#A0A0A0" },
      },
    },
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
