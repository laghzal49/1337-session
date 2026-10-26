local palette = require('config.palette')
-- Two clear information levels: buffer navigation above, editor state below.
return {
  {
    'nvim-lualine/lualine.nvim', event = 'VeryLazy',
    opts = function()
      local s, ui = require('config.surfaces'), require('config.ui')
      local function mode(accent, foreground)
        return { a = { fg = foreground or palette.on_accent, bg = accent, gui = 'NONE' },
          b = { fg = palette.path, bg = s.inset }, c = { fg = s.text, bg = s.tree_panel } }
      end
      local theme = { normal = mode(s.accent), insert = mode(s.teal), visual = mode(s.lilac),
        replace = mode(palette.literal), command = mode(palette.warning), inactive = mode(s.muted) }
      if vim.g.black_color_style == 'electrovoid' then
        local color = require('config.electrovoid').color
        for name, source in pairs({normal='normal',insert='insert',visual='visual',replace='replace',command='normal',inactive='normal'}) do
          theme[name] = mode(color('vim.' .. source .. '.background'), color('vim.' .. source .. '.foreground'))
        end
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
          theme = theme },
        sections = {
          lualine_a = { { 'mode', padding = { left = 1, right = 1 },
              fmt = function(value) return vim.o.columns < 90 and value:sub(1, 1) or value end } },
          lualine_b = { { function()
              local limit = vim.o.columns < 120 and 14 or vim.o.columns < 140 and 24 or 28
              return text(compact(info().name, limit))
            end,
              padding = { left = 2, right = 1 }, cond = wide(78) },
            { function() return text(compact(info().branch, vim.o.columns >= 140 and 24 or 16)) .. (info().dirty and (' ' .. ui.icon('modified')) or '') end,
              icon = ui.icon('branch'), padding = { left = 1, right = 1 },
              cond = function() return vim.o.columns >= 110 and info().branch ~= '' end } },
          lualine_c = { { require('config.symbol_context').component, cond = wide(130), color = { fg = s.lilac } },
            { 'diagnostics', sources = { 'nvim_diagnostic' }, sections = { 'error', 'warn' },
              symbols = { error = 'E ', warn = 'W ' } } },
          lualine_x = {
            { 'searchcount', maxcount = 9999, timeout = 50, cond = wide(85), color = { fg = palette.warning } },
            { function() local task = package.loaded['config.tasks']; return task and task.running and ((ui.accessible and '> ' or '▶ ') .. (vim.o.columns >= 110 and text(compact(task.running.task.name, 20)) or 'TASK')) or '' end, color = { fg = palette.warning } },
            { function() local dap = package.loaded.dap; return dap and dap.session() and (ui.accessible and 'DEBUG' or '● DEBUG') or '' end, color = { fg = s.teal } },
            { function() local reg = vim.fn.reg_recording(); return reg ~= '' and (ui.accessible and 'REC @' or '● REC @') .. reg or '' end, color = { fg = s.accent } },
            { function() return vim.b.bigfile and 'LARGE FILE' or '' end, color = { fg = palette.warning } },
            { function()
                local progress = vim.lsp.status()
                if progress ~= '' then return text(compact(progress, vim.o.columns >= 140 and 36 or 20)) end
                local names, seen = {}, {}
                for _, client in ipairs(vim.lsp.get_clients({bufnr=0})) do
                  if not seen[client.name] then names[#names + 1] = client.name; seen[client.name] = true end
                end
                table.sort(names)
                return #names > 0 and ('LSP ' .. text(compact(table.concat(names, '+'), 24))) or ''
              end, cond = wide(100), color = { fg = s.muted } },
            { 'filetype', icon_only = false, colored = not ui.accessible, icons_enabled = not ui.accessible,
              fmt = function(value) return ({configguide='Guide',stationhealth='Station'})[value] or value end, cond = wide(85) },
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
      local background, selected, indicator = s.tree_panel, s.selected, s.accent
      if vim.g.black_color_style == 'electrovoid' then
        local color = require('config.electrovoid').color
        background, selected, indicator = color('tab.inactive_background'), color('tab.active_background'), color('border.focused')
      end
      for _, key in ipairs({ 'background', 'buffer', 'buffer_visible', 'separator', 'separator_visible', 'fill' }) do
        h[key] = { fg = s.muted, bg = background }
      end
      for _, key in ipairs({ 'buffer_selected', 'separator_selected' }) do
        h[key] = { fg = s.text, bg = selected, bold = false, italic = false }
      end
      h.indicator_selected = { fg = indicator, bg = selected }
      h.modified_selected = { fg = palette.warning, bg = selected }
      return { options = { style_preset = require('bufferline').style_preset.no_bold, mode = 'buffers', numbers = 'ordinal', show_duplicate_prefix = true, max_prefix_length = 12,
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
