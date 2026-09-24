return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = require("config.dashboard"),
      zen = {
        toggles = { dim = false, git_signs = false, mini_diff_signs = false },
        show = { statusline = true, tabline = false },
        win = { width = 100, backdrop = { transparent = false, blend = 0 } },
      },
      indent = {
        animate = { enabled = not vim.g.reduce_motion, duration = { step = 10, total = 110 } },
        scope = { only_current = true },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        update_in_insert = false,
        severity_sort = true,
        virtual_text = {
          spacing = 2, prefix = "●", source = false,
          severity = { min = vim.diagnostic.severity.ERROR },
          format = function(diagnostic)
            local message = diagnostic.message:gsub("%s+", " ")
            return vim.fn.strchars(message) > 65 and (vim.fn.strcharpart(message, 0, 62) .. "…") or message
          end,
        },
        float = { border = require("config.ui").border, source = "if_many", header = "", max_width = 80, focusable = true },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = "thin",
        show_close_icon = false,
        show_buffer_close_icons = false,
        indicator = { style = "underline" },
        max_name_length = 26,
        tab_size = 20,
        enforce_regular_tabs = false,
        always_show_bufferline = false,
        diagnostics = false,
        offsets = {
          { filetype = "neo-tree", text = " 󰉋  FILES", text_align = "left", separator = true },
          { filetype = "aerial", text = " 󰅩  SYMBOLS", text_align = "left", separator = true },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local palette = require("onedark.colors")
      local function mode(color)
        return {
          a = { bg = color, fg = palette.bg0, gui = "bold" },
          b = { bg = palette.bg1, fg = palette.fg },
          c = { bg = palette.bg1, fg = palette.fg },
        }
      end
      opts.options.theme = {
        normal = mode(palette.blue), insert = mode(palette.green),
        visual = mode(palette.purple), replace = mode(palette.red),
        command = mode(palette.yellow), inactive = mode(palette.grey),
      }
      opts.options.ignore_focus = { "neo-tree", "snacks_picker_input", "snacks_picker_list", "snacks_picker_preview" }
      opts.options.globalstatus = true
      opts.options.component_separators = { left = "", right = "" }
      opts.options.section_separators = { left = "", right = "" }
      opts.sections = {
        lualine_a = {
          { "mode", fmt = function(value) return vim.o.columns < 90 and value:sub(1, 1) or value end },
          {
            function() return "REC @" .. vim.fn.reg_recording() end,
            cond = function() return vim.fn.reg_recording() ~= "" end,
            color = { fg = palette.red, gui = "bold" },
          },
        },
        lualine_b = { { "branch", icon = "", cond = function() return vim.o.columns >= 90 end } },
        lualine_c = {
          { "filename", path = 0, color = { fg = palette.fg, gui = "bold" }, symbols = { modified = " ●", readonly = " ", unnamed = "[Untitled]" } },
          { "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" },
            symbols = { error = " ", warn = " " } },
        },
        lualine_x = {
          {
            function()
              local names = {}
              for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                if client.name ~= "ruff" then names[#names + 1] = client.name end
              end
              table.sort(names)
              return #names > 0 and ("  " .. table.concat(names, " · ")) or ""
            end,
            cond = function() return vim.o.columns >= 115 end,
            color = { fg = palette.grey },
          },
          { "filetype", colored = false, cond = function() return vim.o.columns >= 90 end },
        },
        lualine_y = {},
        lualine_z = { { "location", color = { bg = palette.bg1, fg = palette.light_grey } } },
      }
    end,
  },
  {
    "folke/trouble.nvim",
    opts = {
      modes = {
        symbols = {
          focus = true,
          auto_preview = false,
          win = { position = "right", size = 32 },
        },
        diagnostics = {
          win = { position = "bottom", size = 0.25 },
        },
      },
    },
  },
}
