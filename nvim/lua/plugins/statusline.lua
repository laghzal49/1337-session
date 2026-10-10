-- Two clear information levels: buffer navigation above, editor state below.
return {
  {
    'nvim-lualine/lualine.nvim', event = 'VeryLazy',
    opts = function()
      local s, ui = require('config.surfaces'), require('config.ui')
      local function mode(accent)
        return { a = { fg = '#000000', bg = accent, gui = 'bold' },
          b = { fg = s.text, bg = s.inset }, c = { fg = s.text, bg = s.tree_panel } }
      end
      local function wide(n) return function() return vim.o.columns >= n end end
      local function info() return require('config.workspace_info').get() end
      -- Function components accept statusline markup; project/tool labels are plain text.
      local function text(value) return (value or ''):gsub('[%c]', '?'):gsub('%%', '%%%%') end
      local function compact(value, limit)
        if vim.fn.strdisplaywidth(value) <= limit then return value end
        local marker = ui.accessible and '.' or '…'
        for length = vim.fn.strchars(value) - 1, 0, -1 do
          local head = vim.fn.strcharpart(value, 0, length)
          if vim.fn.strdisplaywidth(head .. marker) <= limit then return head .. marker end
        end
        return marker
      end
      return {
        options = { globalstatus = true, component_separators = '', section_separators = '',
          disabled_filetypes = { statusline = { 'snacks_dashboard' } },
          refresh = { statusline = 250, tabline = 1000, winbar = 1000 },
          theme = { normal = mode(s.accent), insert = mode(s.teal), visual = mode(s.lilac),
            replace = mode('#FFB86B'), command = mode('#E9C46A'), inactive = mode(s.muted) } },
        sections = {
          lualine_a = { { 'mode', fmt = function(value) return vim.o.columns < 90 and value:sub(1, 1) or value end } },
          lualine_b = { { function()
              local limit = vim.o.columns < 120 and 14 or vim.o.columns < 140 and 24 or 1000
              return text(compact(info().name, limit))
            end,
              cond = wide(78) },
            { function() return text(info().branch) .. (info().dirty and (' ' .. ui.icon('modified')) or '') end,
              icon = ui.icon('branch'), cond = function() return vim.o.columns >= 110 and info().branch ~= '' end } },
          lualine_c = { { require('config.symbol_context').component, cond = wide(130), color = { fg = s.lilac } },
            { 'diagnostics', sources = { 'nvim_diagnostic' }, sections = { 'error', 'warn' },
              symbols = { error = 'E ', warn = 'W ' } } },
          lualine_x = {
            { 'searchcount', maxcount = 9999, timeout = 50, cond = wide(85), color = { fg = '#E9C46A' } },
            { function() local task = package.loaded['config.tasks']; return task and task.running and ((ui.accessible and '> ' or '▶ ') .. (vim.o.columns >= 110 and text(task.running.task.name) or 'TASK')) or '' end, color = { fg = '#E9C46A' } },
            { function() local dap = package.loaded.dap; return dap and dap.session() and (ui.accessible and 'DEBUG' or '● DEBUG') or '' end, color = { fg = s.teal } },
            { function() local reg = vim.fn.reg_recording(); return reg ~= '' and (ui.accessible and 'REC @' or '● REC @') .. reg or '' end, color = { fg = s.accent } },
            { function() return vim.b.bigfile and 'LARGE FILE' or '' end, color = { fg = '#E9C46A' } },
            { function() return text(vim.lsp.status()) end, cond = wide(120), color = { fg = s.muted } },
            { 'filetype', icon_only = false, colored = not ui.accessible, icons_enabled = not ui.accessible, cond = wide(85) },
          },
          lualine_y = { { 'progress', cond = wide(100) } }, lualine_z = { 'location' },
        },
        extensions = { 'quickfix', 'fugitive', 'lazy', 'mason', 'nvim-dap-ui' },
      }
    end,
  },
  {
    'akinsho/bufferline.nvim', event = 'VeryLazy',
    opts = function()
      local s, ui = require('config.surfaces'), require('config.ui')
      local h = {}
      for _, key in ipairs({ 'background', 'buffer', 'buffer_visible', 'separator', 'separator_visible', 'fill' }) do
        h[key] = { fg = s.muted, bg = s.tree_panel }
      end
      for _, key in ipairs({ 'buffer_selected', 'separator_selected' }) do
        h[key] = { fg = s.text, bg = s.selected, bold = true, italic = false }
      end
      h.indicator_selected = { fg = s.accent, bg = s.selected }
      h.modified_selected = { fg = s.teal, bg = s.selected }
      return { options = { mode = 'buffers', numbers = 'ordinal', show_duplicate_prefix = false,
        separator_style = ui.accessible and { '', '' } or 'thin', always_show_bufferline = false,
        show_close_icon = false, show_buffer_close_icons = false, indicator = { style = 'icon', icon = ui.accessible and '|' or '▎' },
        modified_icon = ui.icon('modified'), show_buffer_icons = not ui.accessible, max_name_length = 20, tab_size = 18, diagnostics = false,
        offsets = { { filetype = 'snacks_layout_box', text = 'EXPLORER', text_align = 'left', separator = true },
          { filetype = 'aerial', text = 'SYMBOLS', text_align = 'left', separator = true },
          { filetype = 'dapui_scopes', text = 'DEBUG', text_align = 'left', separator = true } },
      }, highlights = h }
    end,
  },
}
