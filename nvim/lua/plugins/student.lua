return {
  { "folke/tokyonight.nvim", opts = {
    style = "night", transparent = false,
    styles = { comments = { italic = true }, keywords = { italic = true }, floats = "dark", sidebars = "dark" },
    on_colors = function(c)
      c.bg = "#000000"; c.bg_dark = "#000000"; c.bg_float = "#080808"; c.bg_popup = "#080808"
      c.bg_sidebar = "#000000"; c.bg_statusline = "#080808"; c.bg_highlight = "#181818"; c.border = "#353535"
    end,
  } },
  { "neovim/nvim-lspconfig", opts = { servers = {
    clangd = { mason = false, cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" } },
  } } },
}
