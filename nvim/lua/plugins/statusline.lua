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
      return {
        options = { globalstatus = true, component_separators = '', section_separators = '',
          disabled_filetypes = { statusline = { 'snacks_dashboard' } },
          refresh = { statusline = 250, tabline = 1000, winbar = 1000 },
          theme = { normal = mode(s.accent), insert = mode(s.teal), visual = mode(s.lilac),
            replace = mode('#FFB86B'), command = mode('#E9C46A'), inactive = mode(s.muted) } },
        sections = {
          lualine_a = { { 'mode', fmt = function(value) return vim.o.columns < 90 and value:sub(1, 1) or value end } },
          lualine_b = { { function() return text(info().name) end, cond = wide(100) },
            { function() return text(info().branch) .. (info().dirty and ' •' or '') end,
              icon = ui.icon('branch'), cond = function() return vim.o.columns >= 100 and info().branch ~= '' end } },
          lualine_c = { { 'filename', path = 1, symbols = { modified = ' ●', readonly = ' [RO]', unnamed = 'Untitled' } },
            { require('config.symbol_context').component, cond = wide(130), color = { fg = s.lilac } },
            { 'diagnostics', sources = { 'nvim_diagnostic' }, sections = { 'error', 'warn' },
              symbols = { error = 'E ', warn = 'W ' } } },
          lualine_x = {
            { 'searchcount', maxcount = 9999, timeout = 50, cond = wide(85), color = { fg = '#E9C46A' } },
            { function() local task = package.loaded['config.tasks']; return task and task.running and ('▶ ' .. (vim.o.columns >= 110 and text(task.running.task.name) or 'TASK')) or '' end, color = { fg = '#E9C46A' } },
            { function() local dap = package.loaded.dap; return dap and dap.session() and '● DEBUG' or '' end, color = { fg = s.teal } },
            { function() local reg = vim.fn.reg_recording(); return reg ~= '' and '● REC @' .. reg or '' end, color = { fg = s.accent } },
            { function() return vim.b.bigfile and 'LARGE FILE' or '' end, color = { fg = '#E9C46A' } },
            { function() return text(vim.lsp.status()) end, cond = wide(120), color = { fg = s.muted } },
            { 'filetype', icon_only = false, cond = wide(85) },
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
      local s = require('config.surfaces')
      local h = {}
      for _, key in ipairs({ 'background', 'buffer', 'buffer_visible', 'separator', 'separator_visible', 'fill' }) do
        h[key] = { fg = s.muted, bg = s.tree_panel }
      end
      for _, key in ipairs({ 'buffer_selected', 'separator_selected' }) do
        h[key] = { fg = s.text, bg = s.selected, bold = true, italic = false }
      end
      h.indicator_selected = { fg = s.accent, bg = s.selected }
      h.modified_selected = { fg = s.teal, bg = s.selected }
      return { options = { mode = 'buffers', separator_style = 'thin', always_show_bufferline = false,
        show_close_icon = false, show_buffer_close_icons = false, indicator = { style = 'icon', icon = '▎' },
        modified_icon = '●', max_name_length = 24, tab_size = 20, diagnostics = false,
        offsets = { { filetype = 'snacks_layout_box', text = 'EXPLORER', text_align = 'left', separator = true },
          { filetype = 'aerial', text = 'SYMBOLS', text_align = 'left', separator = true },
          { filetype = 'dapui_scopes', text = 'DEBUG', text_align = 'left', separator = true } },
      }, highlights = h }
    end,
  },
}
