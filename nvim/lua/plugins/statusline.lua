-- Statusline and bufferline: compact information hierarchy.
return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
      opts.options = opts.options or {}
      local palette = require('onedark.colors')
      local focused_win = vim.api.nvim_get_current_win()
      vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
        group = vim.api.nvim_create_augroup('black_status_focus', { clear = true }),
        callback = function() focused_win = vim.api.nvim_get_current_win() end,
      })
      local function mode(color)
        return {
          a = { bg = '#172333', fg = color, gui = 'bold' },
          b = { bg = '#0A0F16', fg = palette.fg },
          c = { bg = '#0A0F16', fg = palette.fg },
        }
      end
      opts.options.theme = {
        normal = mode(palette.blue), insert = mode(palette.green),
        visual = mode(palette.purple), replace = mode(palette.red),
        command = mode(palette.yellow), inactive = mode(palette.grey),
      }
      opts.options.ignore_focus = { 'minipick', 'minifiles', 'aerial' }
      opts.options.globalstatus = true
      opts.options.component_separators = { left = '', right = '' }
      opts.options.section_separators = { left = '', right = '' }
      opts.sections = {
        lualine_a = {
          { function() return '\u{e0b6}' end, padding = 0,
            color = { fg = '#172333', bg = '#0A0F16' } },
          { 'mode', padding = 0, fmt = function(value)
            local buf = vim.api.nvim_win_is_valid(focused_win) and vim.api.nvim_win_get_buf(focused_win) or 0
            local ft = vim.bo[buf].filetype
            if ft == 'minipick' then return 'SEARCH' end
            if ft == 'minifiles' then return 'FILES' end
            if ft == 'aerial' then return 'SYMBOLS' end
            return vim.o.columns < 90 and value:sub(1, 1) or value
          end },
          { function() return '\u{e0b4}' end, padding = 0,
            color = { fg = '#172333', bg = '#0A0F16' } },
          {
            function() return 'REC @' .. vim.fn.reg_recording() end,
            cond = function() return vim.fn.reg_recording() ~= '' end,
            color = { fg = palette.red, gui = 'bold' },
          },
        },
        lualine_b = {},
        lualine_c = {
          { 'filename', path = 0, icon = '\u{f0f6}', color = { fg = palette.fg, gui = 'bold' }, symbols = { modified = ' +', readonly = ' \u{f033e}', unnamed = 'Untitled' } },
          { 'diagnostics', sources = { 'nvim_diagnostic' }, sections = { 'error', 'warn' },
            symbols = { error = ' \u{f0674} ', warn = ' \u{f071} ' } },
          -- LSP progress indicator: shows what the language server is doing.
          { function()
            local status = vim.lsp.status()
            if status and status ~= '' then
              return '\u{f110} ' .. vim.fn.strcharpart(status:gsub('%s+', ' '), 0, 30)
            end
            return ''
          end,
            color = { fg = palette.light_grey },
          },
        },
        lualine_x = {
          { 'branch', icon = '\u{e725}', color = { fg = palette.light_grey }, cond = function() return vim.o.columns >= 100 end },
          { 'diff', symbols = { added = '+', modified = '~', removed = '\u{2212}' }, cond = function() return vim.o.columns >= 115 end },
        },
        lualine_y = { {
          function() return '\u{2502}' end,
          color = { fg = '#354357', bg = '#0A0F16' },
          padding = 0,
          cond = function() return vim.o.columns >= 90 end,
        } },
        lualine_z = { { function()
          return vim.o.columns < 90 and string.format('%d:%d', vim.fn.line('.'), vim.fn.virtcol('.'))
            or string.format('Ln %d, Col %d', vim.fn.line('.'), vim.fn.virtcol('.'))
        end, color = { bg = '#172333', fg = palette.fg } } },
      }
    end,
  },
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        separator_style = 'thin',
        show_close_icon = false,
        show_buffer_close_icons = false,
        indicator = { style = 'icon', icon = '\u{258e}' },
        max_name_length = 26,
        tab_size = 20,
        enforce_regular_tabs = false,
        always_show_bufferline = false,
        diagnostics = false,
        offsets = {
          { filetype = 'aerial', text = ' \u{f0501}  SYMBOLS', text_align = 'left', separator = true },
        },
      },
    },
  },
}
