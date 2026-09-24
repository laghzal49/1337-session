return {
  {
    "snacks.nvim",
    opts = {
      terminal = { win = { position = "bottom", height = 0.30, border = "rounded" } },
      styles = {
        notification = { border = "rounded", wo = { winblend = 0 } },
      },
    },
    keys = {
      {
        "<leader>ft",
        function()
          Snacks.terminal(nil, { cwd = require("config.project").root() })
        end,
        desc = "Project terminal",
      },
      {
        "<leader>gL",
        function()
          require("config.pick").open("git_commits")
        end,
        desc = "Git commit history",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Git diff view" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
    },
    opts = {},
  },
}
