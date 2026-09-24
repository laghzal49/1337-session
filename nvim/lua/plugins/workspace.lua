return {
  {
    "snacks.nvim",
    opts = {
      terminal = { shell = "/usr/bin/zsh", win = { position = "bottom", height = 0.35, border = "rounded" } },
      picker = { layout = { preset = "default" }, win = { input = { border = "rounded" } } },
      scroll = { enabled = true },
      styles = {
        notification = { border = "rounded", wo = { winblend = 0 } },
      },
    },
    keys = {
      {
        "<leader>ft",
        function()
          Snacks.terminal(nil, { cwd = LazyVim.root() })
        end,
        desc = "Project terminal",
      },
      {
        "<leader>gL",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git commit history",
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      window = { width = 28, position = "left" },
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = "󰉋 Files" },
          { source = "buffers", display_name = "󰈙 Bufs" },
          { source = "git_status", display_name = " Git" },
        },
      },
      filesystem = {
        filtered_items = { hide_dotfiles = false, hide_gitignored = true, hide_by_name = { ".git", "__pycache__" } },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          indent_size = 2,
          padding = 1,
          expander_collapsed = "",
          expander_expanded = "",
          indent_marker = "│",
          last_indent_marker = "└",
        },
        icon = { folder_closed = "", folder_open = "", folder_empty = "󰜌", default = "󰈙" },
        modified = { symbol = "●" },
        git_status = {
          symbols = {
            added = "+",
            modified = "~",
            deleted = "-",
            renamed = "➜",
            untracked = "?",
            ignored = "·",
            unstaged = "!",
            staged = "✓",
            conflict = "",
          },
        },
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
