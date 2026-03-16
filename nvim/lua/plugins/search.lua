return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        prompt = "  ",
        layout = { preset = function() return vim.o.columns >= 110 and "workspace" or "workspace_small" end },
        layouts = {
          workspace = {
            layout = {
              box = "vertical", width = 0.84, height = 0.65,
              border = require("config.ui").border, title = " {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { box = "horizontal",
                { win = "list", border = "none", width = 0.44 },
                { win = "preview", border = "left", title = " {preview} " },
              },
            },
          },
          workspace_small = {
            layout = {
              box = "vertical", width = 0.92, height = 0.76,
              border = require("config.ui").border, title = " {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
              { win = "preview", border = "top", height = 0.36, title = " {preview} " },
            },
          },
        },
        sources = {
          files = { hidden = true, ignored = false, title = "Find files" },
          grep = { hidden = true, ignored = false, title = "Search project" },
          grep_word = { hidden = true, ignored = false, title = "References" },
        },
        win = {
          input = { keys = { ["<Esc>"] = { "cancel", mode = { "n", "i" } } } },
          preview = { wo = { number = true, relativenumber = false, wrap = false, cursorline = false, winhighlight = "Normal:SnacksPickerPreview,NormalNC:SnacksPickerPreview,EndOfBuffer:SnacksPickerPreview" } },
        },
      },
    },
  },
}
