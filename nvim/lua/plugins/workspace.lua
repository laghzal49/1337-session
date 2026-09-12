return {
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
          ██╗██████╗ ██████╗ ███████╗
         ███║╚════██╗╚════██╗╚════██║
         ╚██║ █████╔╝ █████╔╝    ██╔╝
          ██║ ╚═══██╗ ╚═══██╗   ██╔╝
          ██║██████╔╝██████╔╝   ██║
          ╚═╝╚═════╝ ╚═════╝    ╚═╝

             T A R I K  /  N V I M
]],
        },
        sections = {
          { section = "header", padding = 1 },
          { section = "keys", gap = 1, padding = 1 },
          { icon = " ", title = "Recent files", section = "recent_files", limit = 4, indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
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
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = "slant",
        show_close_icon = false,
        always_show_bufferline = false,
        indicator = { style = "icon", icon = "▎" },
        modified_icon = "●",
        buffer_close_icon = "󰅖",
        offsets = {
          { filetype = "neo-tree", text = "󰉋  PROJECT", text_align = "left", separator = true },
          { filetype = "aerial", text = "󰅩  SYMBOLS", separator = true },
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
