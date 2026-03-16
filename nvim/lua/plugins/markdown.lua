return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle Markdown rendering" },
      { "<leader>cp", "<cmd>RenderMarkdown preview<cr>", ft = "markdown", desc = "Markdown reading preview" },
    },
    opts = {
      file_types = { "markdown" },
      heading = { sign = false, icons = {}, width = "block", right_pad = 2 },
      code = { sign = false, width = "block", right_pad = 2, left_pad = 1 },
      checkbox = { enabled = true },
    },
  },
}
