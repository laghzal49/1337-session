-- Quick navigation leaves the editor visible. Project searches keep a preview.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        prompt = "  ",
        layout = {
          preset = function(source)
            local quick = { files = true, buffers = true, recent = true, oldfiles = true, commands = true, keymaps = true }
            if quick[source] then
              return vim.o.columns >= 90 and "quick" or "quick_small"
            end
            return vim.o.columns >= 110 and "inspect" or "inspect_small"
          end,
        },
        layouts = {
          quick = {
            layout = {
              box = "vertical", width = 0.54, height = 0.46, min_width = 48,
              border = require("config.ui").border, title = "   {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
            },
          },
          quick_small = {
            layout = {
              box = "vertical", width = 0.92, height = 0.55,
              border = require("config.ui").border, title = "   {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
            },
          },
          inspect = {
            layout = {
              box = "vertical", width = 0.78, height = 0.70,
              border = require("config.ui").border, title = "   {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { box = "horizontal",
                { win = "list", border = "none", width = 0.42 },
                { win = "preview", border = "left", title = " {preview} " },
              },
            },
          },
          inspect_small = {
            layout = {
              box = "vertical", width = 0.92, height = 0.78,
              border = require("config.ui").border, title = "   {title} ", title_pos = "left", backdrop = false,
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
              { win = "preview", border = "top", height = 0.38, title = " {preview} " },
            },
          },
        },
        sources = {
          files = { hidden = true, ignored = false, title = "Files" },
          grep = { hidden = true, ignored = false, title = "Search project" },
          grep_word = { hidden = true, ignored = false, title = "References" },
        },
        win = {
          input = { keys = { ["<Esc>"] = { "cancel", mode = { "n", "i" } } } },
          preview = { wo = { number = true, relativenumber = false, wrap = false, cursorline = false } },
        },
      },
    },
  },
}
