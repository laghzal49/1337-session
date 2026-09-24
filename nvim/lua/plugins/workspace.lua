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
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      window = { width = 28, position = "left" },
      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            if vim.o.columns < 110 then require("neo-tree.command").execute({ action = "close" }) end
          end,
        },
      },
      source_selector = {
        winbar = false,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = " Files" },
          { source = "buffers", display_name = " Bufs" },
          { source = "git_status", display_name = " Git" },
        },
      },
      filesystem = {
        filtered_items = { show_hidden_count = false, hide_dotfiles = false, hide_gitignored = true, hide_by_name = { ".git", "__pycache__" }, hide_by_pattern = { "*.bak-*" } },
        follow_current_file = { enabled = true },
        group_empty_dirs = true,
        components = {
          name = function(config, node, state)
            if node:get_depth() == 1 and node.type == "directory" then
              return { text = "  " .. vim.fn.fnamemodify(node.path, ":t"), highlight = "NeoTreeRootName" }
            end
            return require("neo-tree.sources.common.components").name(config, node, state)
          end,
        },
      },
      default_component_configs = {
        name = { use_git_status_colors = false },
        indent = {
          with_expanders = true,
          indent_size = 2,
          padding = 1,
          expander_collapsed = "",
          expander_expanded = "",
          indent_marker = "│",
          last_indent_marker = "└",
        },
        icon = { folder_closed = "", folder_open = "", folder_empty = "", default = "" },
        modified = { symbol = "●" },
        git_status = {
          symbols = {
            added = "+",
            modified = "~",
            deleted = "-",
            renamed = "➜",
            untracked = "?",
            ignored = "·",
            unstaged = "", -- Change type already carries this information.
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
