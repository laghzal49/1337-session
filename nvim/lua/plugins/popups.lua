local ui = require("config.ui")

return {
  {
    "folke/noice.nvim",
    opts = {
      -- Completion owns automatic documentation; signatures remain on Ctrl-K.
      lsp = { signature = { enabled = true, auto_open = { enabled = false } } },
      presets = { command_palette = false },
      views = {
        cmdline_popup = {
          win_options = { winblend = ui.blend },
          position = { row = "20%", col = "50%" },
          size = { min_width = 32, width = "auto", max_width = ui.max_width, height = "auto" },
          border = { style = ui.border, padding = { 0, 1 } },
        },
        popupmenu = {
          win_options = { winblend = ui.blend },
          border = { style = ui.border, padding = { 0, 1 } },
          size = { max_height = 8 },
        },
        hover = {
          border = { style = ui.border, padding = { 0, 1 } },
          size = { max_width = ui.max_width, max_height = ui.max_height },
          win_options = { wrap = true, linebreak = true, winblend = ui.blend },
        },
        popup = {
          win_options = { winblend = ui.blend },
          border = { style = ui.border },
          size = { width = ui.max_width, height = ui.max_height },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>n", function() require("config.notifications").history() end, desc = "Notification history drawer" },
      { "<leader>un", function() require("config.notifications").dismiss() end, desc = "Dismiss notifications" },
    },
    opts = {
      input = {
        enabled = true,
        win = { border = ui.border, width = 50, row = 3, title_pos = "left", wo = { winblend = ui.blend } },
      },
      notifier = {
        enabled = true, style = "compact", timeout = 3000,
        level = vim.log.levels.INFO,
        filter = require("config.notifications").filter,
        width = { min = 24, max = 0.35 }, height = { min = 1, max = 0.25 },
        margin = { top = 1, right = 1, bottom = 0 }, padding = true,
      },
      styles = {
        notification = { border = ui.border, wo = { winblend = ui.blend, wrap = true } },
        notification_history = {
          position = "bottom", height = 0.35, width = 0, border = "none",
          wo = { wrap = true, winblend = 0, winbar = "  Notification history · q to close" },
        },
      },
      picker = {
        layouts = {
          select = {
            layout = {
              box = "vertical", width = 0.65, min_width = 20, max_width = ui.max_width,
              height = 0.4, min_height = 3, border = ui.border,
              title = " {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
              { win = "preview", height = 0.4, border = "top" },
            },
          },
        },
      },
    },
  },
  { "folke/which-key.nvim", opts = { win = { border = ui.border, padding = { 0, 1 }, wo = { winblend = ui.blend } } } },
  { "mason-org/mason.nvim", opts = { ui = { border = ui.border, width = 0.8, height = 0.8 } } },
  { "lewis6991/gitsigns.nvim", opts = {
    signs_staged_enable = false, -- One Git marker leaves room for the diagnostic.
    preview_config = { border = ui.border, style = "minimal", relative = "cursor", row = 0, col = 1 },
  } },
}
