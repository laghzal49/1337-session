return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    priority = 1000,
    opts = {
      default = true, color_icons = false, strict = true,
      override = {
        default_icon = { icon = "", color = "#A0AFC1", cterm_color = "248", name = "Default" },
      },
      override_by_extension = {
        py = { icon = "", name = "Python", color = "#A0AFC1" },
        lua = { icon = "", name = "Lua", color = "#A0AFC1" },
        c = { icon = "", name = "C", color = "#A0AFC1" },
        cpp = { icon = "", name = "Cpp", color = "#A0AFC1" },
        json = { icon = "", name = "Json", color = "#A0AFC1" },
        md = { icon = "", name = "Markdown", color = "#A0AFC1" },
        sh = { icon = "", name = "Shell", color = "#A0AFC1" },
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
