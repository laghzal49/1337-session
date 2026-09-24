return {
  { "saghen/blink.cmp", enabled = false },
  {
    "iguanacucumber/magazine.nvim",
    name = "nvim-cmp",
    url = "https://github.com/iguanacucumber/magazine.nvim.git",
    opts = function(_, opts)
      local cmp = require("cmp")
      require("config.documentation").setup()
      opts.window = {
        completion = cmp.config.window.bordered({ border = "rounded", side_padding = 1, winblend = require("config.ui").blend, winhighlight = "Normal:BlackDocs,FloatBorder:BlackDocsBorder,CursorLine:PmenuSel,Search:None" }),
        documentation = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle,FloatFooter:BlackDocsHint",
          winblend = require("config.ui").blend,
          max_width = 68,
          max_height = require("config.ui").max_height,
        }),
      }
      opts.view = vim.tbl_deep_extend("force", opts.view or {}, { docs = { auto_open = false } })
      -- Ctrl-B/F scroll documentation; Ctrl-D opens or closes it.
      local function scroll_docs(delta)
        return cmp.mapping(function(fallback)
          if cmp.visible_docs() then
            cmp.scroll_docs(delta)
          elseif cmp.visible() then
            cmp.open_docs()
          else
            return fallback()
          end
        end, { "i", "s" })
      end
      -- LazyVim's preset already canonicalizes keys (e.g. <C-B>). Normalize
      -- overrides too, so duplicate spellings cannot randomly restore defaults.
      local normalize = require("cmp.utils.keymap").normalize
      opts.mapping[normalize("<C-b>")] = scroll_docs(-4)
      opts.mapping[normalize("<C-f>")] = scroll_docs(4)
      opts.mapping[normalize("<C-e>")] = cmp.mapping.abort()
      opts.mapping[normalize("<C-d>")] = cmp.mapping(function()
        if cmp.visible_docs() then cmp.close_docs() else cmp.open_docs() end
      end, { "i", "s" })
      opts.formatting = opts.formatting or {}
      opts.formatting.fields = { "kind", "abbr", "menu" }
      local kinds = {
        Text = "", Method = "", Function = "", Constructor = "",
        Field = "", Variable = "", Class = "", Interface = "",
        Module = "", Property = "", Unit = "", Value = "",
        Enum = "", Keyword = "", Snippet = "", Color = "",
        File = "", Reference = "", Folder = "", EnumMember = "",
        Constant = "", Struct = "", Event = "", Operator = "", TypeParameter = "",
      }
      opts.formatting.format = function(entry, item)
        local kind = item.kind
        item.kind = (kinds[kind] or "") .. " "
        if vim.fn.strdisplaywidth(item.abbr) > 38 then
          local text = vim.fn.strcharpart(item.abbr, 0, 37)
          while vim.fn.strdisplaywidth(text) > 37 do
            text = vim.fn.strcharpart(text, 0, vim.fn.strchars(text) - 1)
          end
          item.abbr = text .. "…"
        end
        item.menu = kind
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
