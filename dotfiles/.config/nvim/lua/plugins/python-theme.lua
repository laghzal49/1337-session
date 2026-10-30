return {
  { "Shatur/neovim-ayu", main = "ayu", lazy = false, priority = 1000, opts = { mirage = false } },
  { "LazyVim/LazyVim", opts = { colorscheme = "ayu-dark" } },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = { mason = false, cmd = { vim.fn.expand("~/.local/bin/ty"), "server" } },
        ruff = { mason = false, cmd = { vim.fn.expand("~/.local/bin/ruff"), "server" } },
        pyright = { enabled = false },
        basedpyright = { enabled = false },
      },
    },
  },
}
