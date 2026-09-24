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
            hidden = { "preview" },
            layout = {
              box = "vertical", width = 0.54, height = 0.46, min_width = 48, max_width = 110, max_height = 36,
              border = "none", backdrop = false,
              { win = "input", height = 1, border = "none" },
              { win = "list", border = "none" },
              { win = "preview", border = "none", height = 0.4 },
            },
          },
          quick_small = {
            hidden = { "preview" },
            layout = {
              box = "vertical", width = 0.92, height = 0.55, max_width = 110, max_height = 36,
              border = "none", backdrop = false,
              { win = "input", height = 1, border = "none" },
              { win = "list", border = "none" },
              { win = "preview", border = "none", height = 0.4 },
            },
          },
          inspect = {
            layout = {
              box = "vertical", width = 0.90, height = 0.70, max_width = 130, max_height = 36,
              border = "none", backdrop = false,
              { win = "input", height = 1, border = "none" },
              { box = "horizontal",
                { win = "list", border = "none", width = 0.58 },
                { win = "preview", border = "none" },
              },
            },
          },
          inspect_small = {
            hidden = { "preview" },
            layout = {
              box = "vertical", width = 0.92, height = 0.78, max_width = 110, max_height = 36,
              border = "none", backdrop = false,
              { win = "input", height = 1, border = "none" },
              { win = "list", border = "none" },
              { win = "preview", border = "none", height = 0.38 },
            },
          },
        },
        sources = {
          files = { hidden = true, ignored = false, exclude = { "*.bak-*" }, title = "Files", prompt = "Files    " },
          buffers = { prompt = "Buffers    " },
          recent = { prompt = "Recent    " },
          commands = { prompt = "Commands    " },
          keymaps = { prompt = "Keys    " },
          grep = { hidden = true, ignored = false, title = "Search project", prompt = "Project    " },
          grep_word = { hidden = true, ignored = false, title = "References", prompt = "References    " },
        },
        win = {
          input = { keys = {
            ["<Esc>"] = { "cancel", mode = { "n", "i" } },
            ["<C-p>"] = { "toggle_preview", mode = { "n", "i" } },
          } },
          list = { keys = { ["<C-p>"] = "toggle_preview" } },
          preview = { wo = { number = true, relativenumber = false, wrap = false, cursorline = false } },
        },
      },
    },
  },
}
