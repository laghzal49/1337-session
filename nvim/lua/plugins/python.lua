return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = { mason = false },
        ruff = { mason = false },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
    },
  },
}
