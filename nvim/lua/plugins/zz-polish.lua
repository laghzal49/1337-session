return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        width = 52,
        preset = {
          header = "N E O V I M\n\nWorkspace",
          keys = {
            { icon = " ", key = "f", desc = "Find a file", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "g", desc = "Search project", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "n", desc = "New buffer", action = ":ene | startinsert" },
            { icon = " ", key = "s", desc = "Resume session", section = "session" },
            { icon = " ", key = "c", desc = "Configuration", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "󰒲 ", key = "l", desc = "Plugins", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header", padding = 2 },
          { section = "keys", gap = 1, padding = 2 },
          { text = "Space u z  ·  Focus     Space /  ·  Search", align = "center", padding = 1 },
        },
      },
      zen = {
        toggles = { dim = false, git_signs = false, mini_diff_signs = false },
        show = { statusline = true, tabline = false },
        win = { width = 100, backdrop = { transparent = false, blend = 0 } },
      },
      indent = {
        animate = { duration = { step = 12, total = 180 } },
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
        tab_size = 22,
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diag)
          local parts = {}
          if diag.error then parts[#parts + 1] = " " .. diag.error end
          if diag.warning then parts[#parts + 1] = " " .. diag.warning end
          return table.concat(parts, " ")
        end,
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local palette = require("onedark.colors")
      local function mode(color)
        return {
          a = { bg = palette.bg2, fg = color, gui = "bold" },
          b = { bg = palette.bg2, fg = palette.fg },
          c = { bg = palette.bg_d, fg = palette.fg },
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
          "mode",
          {
            function() return "REC @" .. vim.fn.reg_recording() end,
            cond = function() return vim.fn.reg_recording() ~= "" end,
            color = { fg = palette.red, gui = "bold" },
          },
        },
        lualine_b = { { "branch", icon = "", cond = function() return vim.o.columns >= 90 end } },
        lualine_c = {
          { "filename", path = 1, shorting_target = 35, symbols = { modified = " ●", readonly = " ", unnamed = "[Untitled]" } },
          { "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" },
            symbols = { error = " ", warn = " " } },
        },
        lualine_x = { { "diff", cond = function() return vim.o.columns >= 100 end }, { "filetype", colored = true } },
        lualine_y = { { "progress", cond = function() return vim.o.columns >= 80 end } },
        lualine_z = { "location" },
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
