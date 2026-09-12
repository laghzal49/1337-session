return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = {
        lualine_a = { {
          "mode",
          fmt = function(s)
            return "󰘧 " .. s
          end,
        } },
        lualine_b = { { "branch", icon = "" }, "diff" },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "New file" } },
          { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " } },
        },
        lualine_x = {
          {
            function()
              local names = {}
              for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                names[#names + 1] = client.name
              end
              table.sort(names)
              return #names > 0 and (" " .. table.concat(names, " · ")) or ""
            end,
            cond = function()
              return vim.o.columns > 120
            end,
          },
          { "filetype", icon_only = false },
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      }
    end,
  },
}
