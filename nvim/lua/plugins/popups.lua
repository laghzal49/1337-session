local ui = require("config.ui")
local active_notifications = {}
local notification_priority = { trace = 0, debug = 1, info = 2, warn = 3, error = 4 }

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
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification history drawer" },
    },
    opts = {
      input = {
        enabled = true,
        win = { border = ui.border, width = 50, row = 3, title_pos = "left", wo = { winblend = ui.blend } },
      },
      notifier = {
        enabled = true, style = "compact", timeout = 3000,
        level = vim.log.levels.INFO,
        filter = function(notif)
          if notif.timeout == 3000 then
            if notif.level == "warn" then notif.timeout = 6000 end
            if notif.level == "error" then notif.timeout = 0 end
          end
          -- History keeps every toast. Cap only the live stack, and keep
          -- errors visible ahead of informational notifications.
          active_notifications = vim.tbl_filter(function(item)
            return not item.hidden and item.id ~= notif.id
          end, active_notifications)
          active_notifications[#active_notifications + 1] = notif
          if #active_notifications > 3 then
            local oldest = 1
            for i, item in ipairs(active_notifications) do
              if notification_priority[item.level] < notification_priority[active_notifications[oldest].level] then
                oldest = i
              end
            end
            local removed = table.remove(active_notifications, oldest)
            if removed == notif then
              return false -- Retained in history; live slots have higher severity.
            end
            Snacks.notifier.hide(removed.id)
          end
          return true
        end,
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
  { "lewis6991/gitsigns.nvim", opts = { preview_config = { border = ui.border, style = "minimal", relative = "cursor", row = 0, col = 1 } } },
}
