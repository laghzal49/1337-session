return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
    opts = {
      close_if_last_window = true,
      popup_border_style = require("config.ui").border,
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = " Files" },
          { source = "buffers", display_name = " Buffers" },
          { source = "git_status", display_name = " Git" },
        },
      },
      window = { position = "left", width = 32 },
      filesystem = {
        filtered_items = { hide_dotfiles = true, hide_gitignored = true },
        follow_current_file = { enabled = true },
        group_empty_dirs = true,
      },
      default_component_configs = {
        indent = {
          indent_size = 2,
          with_markers = true,
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        icon = { folder_closed = "", folder_open = "", folder_empty = "", default = "" },
        modified = { symbol = "●" },
        git_status = {
          symbols = {
            added = "✚", modified = "●", deleted = "✖", renamed = "➜",
            untracked = "?", ignored = "◌", unstaged = "○", staged = "✓", conflict = "!",
          },
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = { options = { offsets = {
      { filetype = "neo-tree", text = "  Explorer", text_align = "left", highlight = "Directory" },
    } } },
  },
}
