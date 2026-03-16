return {
  { "saghen/blink.cmp", enabled = false },
  {
    "iguanacucumber/magazine.nvim",
    name = "nvim-cmp",
    url = "https://github.com/iguanacucumber/magazine.nvim.git",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.window = {
        completion = cmp.config.window.bordered({ border = require("config.ui").border, side_padding = 1, winblend = require("config.ui").blend, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None" }),
        documentation = cmp.config.window.bordered({
          border = require("config.ui").border,
          winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          winblend = require("config.ui").blend,
          max_width = require("config.ui").max_width,
          max_height = require("config.ui").max_height,
        }),
      }
      opts.view = vim.tbl_deep_extend("force", opts.view or {}, { docs = { auto_open = true } })
      opts.mapping["<C-e>"] = cmp.mapping.abort()
      opts.mapping["<C-d>"] = cmp.mapping(function()
        if cmp.visible_docs() then cmp.close_docs() else cmp.open_docs() end
      end, { "i", "s" })
      opts.formatting = opts.formatting or {}
      local format = opts.formatting.format
      opts.formatting.format = function(entry, item)
        item = format and format(entry, item) or item
        local labels = { nvim_lsp = "LSP", buffer = "Buffer", path = "Path", snippets = "Snippet", lazydev = "Lua" }
        item.menu = labels[entry.source.name] or entry.source.name
        return item
      end
      opts.performance = vim.tbl_deep_extend("force", opts.performance or {}, {
        max_view_entries = 40,
      })
      for _, source in ipairs(opts.sources or {}) do
        if source.name == "buffer" then
          source.option = vim.tbl_deep_extend("force", source.option or {}, {
            get_bufnrs = function()
              local buf = vim.api.nvim_get_current_buf()
              local size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
              return size >= 0 and size <= 1024 * 1024 and { buf } or {}
            end,
          })
        end
      end
      opts.experimental = { ghost_text = false }
    end,
  },
}
