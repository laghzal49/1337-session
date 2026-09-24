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
          x = { bg = '#0A0F16', fg = palette.fg },
          y = { bg = '#0A0F16', fg = palette.fg },
          z = { bg = '#0A0F16', fg = palette.fg },
        }
      end
      opts.options.theme = {
        normal = mode(palette.blue),
        insert = mode(palette.green),
        visual = mode(palette.purple),
        replace = mode(palette.red),
        command = mode(palette.yellow),
        inactive = mode(palette.grey),
      }
      opts.options.ignore_focus = { 'minipick', 'minifiles', 'aerial' }
      opts.options.globalstatus = true
      opts.options.component_separators = { left = '', right = '' }
      opts.options.section_separators = { left = '', right = '' }
      opts.sections = {
        lualine_a = {
          {
            function() return '' end,
            padding = 0,
            color = { fg = '#172333', bg = '#0A0F16' },
          },
          {
            'mode',
            padding = { left = 1, right = 1 },
            fmt = function(value)
              local cur_buf = vim.api.nvim_get_current_buf()
              local cur_ft = vim.bo[cur_buf].filetype
              local win_buf = vim.api.nvim_win_is_valid(focused_win) and vim.api.nvim_win_get_buf(focused_win) or 0
              local win_ft = vim.bo[win_buf].filetype
              local ft = (cur_ft ~= '' and cur_ft) or win_ft

              local tool_modes = {
                minipick = 'SEARCH',
                snacks_picker_input = 'SEARCH',
                minifiles = 'FILES',
                aerial = 'SYMBOLS',
                ['neotest-summary'] = 'TESTS',
                trouble = 'DIAGNOSTICS',
                qf = 'RESULTS',
                help = 'HELP',
              }
              if tool_modes[ft] then
                local m = tool_modes[ft]
                return vim.o.columns < 90 and m:sub(1, 1) or m
              end

              local mode_names = {
                ['NORMAL'] = 'NORMAL',
                ['O-PENDING'] = 'NORMAL',
                ['INSERT'] = 'INSERT',
                ['VISUAL'] = 'VISUAL',
                ['V-LINE'] = 'VISUAL',
                ['V-BLOCK'] = 'VISUAL',
                ['SELECT'] = 'SELECT',
                ['S-LINE'] = 'SELECT',
                ['S-BLOCK'] = 'SELECT',
                ['REPLACE'] = 'REPLACE',
                ['V-REPLACE'] = 'REPLACE',
                ['COMMAND'] = 'COMMAND',
                ['EX'] = 'COMMAND',
                ['MORE'] = 'COMMAND',
                ['CONFIRM'] = 'COMMAND',
                ['TERMINAL'] = 'TERMINAL',
              }
              local name = mode_names[value] or value
              return vim.o.columns < 90 and name:sub(1, 1) or name
            end,
          },
          {
            function() return '' end,
            padding = 0,
            color = { fg = '#172333', bg = '#0A0F16' },
          },
          {
            function() return 'REC @' .. vim.fn.reg_recording() end,
            cond = function() return vim.fn.reg_recording() ~= '' end,
            color = { fg = palette.red, gui = 'bold' },
            padding = { left = 1, right = 0 },
          },
        },
        lualine_b = {},
        lualine_c = {
          {
            'filename',
            path = 1,
            icon = '',
            color = { fg = palette.fg, gui = 'bold' },
            symbols = {
              modified = ' ●',
              readonly = ' 󰌾',
              unnamed = 'Untitled',
            },
          },
          {
            'diagnostics',
            sources = { 'nvim_diagnostic' },
            sections = { 'error', 'warn' },
            symbols = { error = '  ', warn = '  ' },
          },
          -- LSP status spinner/indicator: clean animated braille progress
          {
            function()
              local status = vim.lsp.status()
              if status and status ~= '' then
                local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
                local now = (vim.uv or vim.loop).now()
                local idx = math.floor(now / 100) % #spinner_frames + 1
                local clean = status:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
                return spinner_frames[idx] .. ' ' .. vim.fn.strcharpart(clean, 0, 30)
              end
              return ''
            end,
            color = { fg = palette.light_grey },
          },
        },
        lualine_x = {
          {
            'branch',
            icon = '',
            color = { fg = palette.light_grey },
            cond = function() return vim.o.columns >= 100 end,
          },
          {
            'diff',
            symbols = { added = '+', modified = '~', removed = '−' },
            cond = function() return vim.o.columns >= 115 end,
          },
        },
        lualine_y = {},
        lualine_z = {
          {
            function() return '' end,
            padding = 0,
            color = { fg = '#172333', bg = '#0A0F16' },
          },
          {
            function()
              return vim.o.columns < 90 and string.format('%d:%d', vim.fn.line('.'), vim.fn.virtcol('.'))
                or string.format('Ln %d, Col %d', vim.fn.line('.'), vim.fn.virtcol('.'))
            end,
            padding = { left = 1, right = 1 },
            color = { bg = '#172333', fg = palette.fg },
          },
          {
            function() return '' end,
            padding = 0,
            color = { fg = '#172333', bg = '#0A0F16' },
          },
        },
      }
    end,
  },
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        mode = 'buffers',
        separator_style = 'thin',
        show_close_icon = false,
        show_buffer_close_icons = false,
        indicator = {
          style = 'icon',
          icon = '▎',
        },
        modified_icon = '●',
        max_name_length = 26,
        tab_size = 20,
        enforce_regular_tabs = false,
        always_show_bufferline = false,
        diagnostics = false,
        offsets = {
          {
            filetype = 'aerial',
            text = ' 󰅩  SYMBOLS',
            text_align = 'left',
            separator = true,
          },
        },
      },
      highlights = {
        indicator_selected = {
          fg = '#82AAFF',
          bg = '#1E2F47',
        },
        buffer_selected = {
          fg = '#E6E6E6',
          bg = '#1E2F47',
          bold = true,
          italic = false,
        },
        modified_selected = {
          fg = '#82AAFF',
          bg = '#1E2F47',
        },
        separator = {
          fg = '#1E2836',
          bg = '#0A0F16',
        },
        separator_visible = {
          fg = '#1E2836',
          bg = '#0A0F16',
        },
        separator_selected = {
          fg = '#1E2836',
          bg = '#1E2F47',
        },
        offset_separator = {
          fg = '#354357',
          bg = '#0A0F16',
        },
      },
    },
  },
}
