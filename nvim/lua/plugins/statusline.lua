-- Statusline and bufferline: compact information hierarchy.
return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
      opts.options = opts.options or {}
      local palette = require('onedark.colors')
      local ui = require('config.ui')
      local black = '#0A0F16'
      local active = '#172333'
      local inactive = '#0D131C'
      local focused_win = vim.api.nvim_get_current_win()
      vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
        group = vim.api.nvim_create_augroup('black_status_focus', { clear = true }),
        callback = function() focused_win = vim.api.nvim_get_current_win() end,
      })
      local function focused()
        return vim.api.nvim_get_current_win() == focused_win
      end
      local function mode(color, is_inactive)
        local background = is_inactive and inactive or black
        local foreground = is_inactive and palette.grey or palette.fg
        return {
          a = { bg = is_inactive and inactive or active, fg = is_inactive and palette.grey or color, gui = 'bold' },
          b = { bg = background, fg = foreground },
          c = { bg = background, fg = foreground },
          x = { bg = background, fg = foreground },
          y = { bg = background, fg = foreground },
          z = { bg = background, fg = foreground },
        }
      end
      local copilot_cache = { at = 0, state = 'unavailable' }
      local function project_name()
        local root = vim.fs.root(0, { 'ty.toml', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'Makefile', '.git' })
          or (vim.uv or vim.loop).cwd()
        local name = vim.fn.fnamemodify(root, ':t')
        return name ~= '' and name or root
      end
      local function formatter_name()
        local ok, conform = pcall(require, 'conform')
        if not ok or type(conform.list_formatters) ~= 'function' then return '' end
        local ok_formatters, formatters = pcall(conform.list_formatters, 0)
        if not ok_formatters or not formatters or #formatters == 0 then return '' end
        local formatter = formatters[1]
        return formatter.name or formatter
      end
      local function reader_mode()
        return vim.bo.filetype == 'markdown' and vim.wo.wrap and vim.wo.linebreak and vim.wo.conceallevel == 3
      end
      local function copilot_state()
        local now = (vim.uv or vim.loop).now()
        if now - copilot_cache.at < 250 then return copilot_cache.state end
        copilot_cache.at = now

        local ok, client = pcall(require, 'copilot.client')
        if not ok or type(client.is_disabled) ~= 'function' then
          copilot_cache.state = 'unavailable'
          return copilot_cache.state
        end
        local ok_disabled, disabled = pcall(client.is_disabled)
        if not ok_disabled then
          copilot_cache.state = 'unavailable'
          return copilot_cache.state
        end
        if disabled then
          copilot_cache.state = 'disabled'
          return copilot_cache.state
        end

        local api = package.loaded['copilot.api']
        local status = api and api.status and api.status.data and api.status.data.status
        copilot_cache.state = status == 'InProgress' and 'working' or 'ready'
        return copilot_cache.state
      end
      opts.options.theme = {
        normal = mode(palette.blue),
        insert = mode(palette.green),
        visual = mode(palette.purple),
        replace = mode(palette.red),
        command = mode(palette.yellow),
        inactive = mode(palette.grey, true),
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
            color = { fg = active, bg = black },
          },
          {
            'mode',
            padding = { left = 1, right = 1 },
            fmt = function(value)
              local win_buf = vim.api.nvim_win_is_valid(focused_win) and vim.api.nvim_win_get_buf(focused_win)
                or vim.api.nvim_get_current_buf()
              local ft = vim.bo[win_buf].filetype

              local tool_modes = {
                minipick = 'SEARCH',
                minifiles = 'FILES',
                aerial = 'SYMBOLS',
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
            color = { fg = active, bg = black },
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
            function() return ui.icon('workspace') .. ' ' .. project_name() end,
            color = { fg = palette.light_grey },
            cond = function() return vim.o.columns >= 100 end,
          },
          {
            'filename',
            path = 1,
            icon = ui.icon('file'),
            color = function()
              return { fg = focused() and palette.fg or palette.grey, gui = 'bold' }
            end,
            symbols = {
              modified = ' ' .. ui.icon('modified'),
              readonly = ' ' .. ui.icon('lock'),
              unnamed = 'Untitled',
            },
          },
          {
            'diagnostics',
            sources = { 'nvim_diagnostic' },
            sections = { 'error', 'warn', 'hint', 'info' },
            symbols = {
              error = ' ' .. ui.icon('error') .. ' ',
              warn = ' ' .. ui.icon('warn') .. ' ',
              hint = ' ' .. ui.icon('hint') .. ' ',
              info = ' ' .. ui.icon('info') .. ' ',
            },
            color = function() return { fg = focused() and palette.light_grey or palette.grey } end,
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
            color = function() return { fg = focused() and palette.light_grey or palette.grey } end,
          },
        },
        lualine_x = {
          {
            'branch',
            icon = ui.icon('branch'),
            color = function() return { fg = focused() and palette.light_grey or palette.grey } end,
            cond = function() return vim.o.columns >= 100 end,
          },
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then return '' end
              return ui.icon('symbols') .. ' ' .. (#clients == 1 and clients[1].name or (#clients .. ' LSP'))
            end,
            color = function() return { fg = focused() and palette.cyan or palette.grey } end,
            cond = function() return vim.o.columns >= 105 end,
          },
          {
            function()
              local formatter = formatter_name()
              return formatter ~= '' and ui.icon('command') .. ' ' .. formatter or ''
            end,
            color = { fg = palette.green },
            cond = function() return vim.o.columns >= 115 and formatter_name() ~= '' end,
          },
          {
            'diff',
            symbols = { added = '+', modified = '~', removed = '−' },
            cond = function() return vim.o.columns >= 125 end,
          },
          {
            function()             return reader_mode() and (ui.icon('read') .. ' READ') or '' end,
            color = { fg = palette.purple },
            cond = function() return vim.o.columns >= 105 and reader_mode() end,
          },
          {
            function()
              local encoding = vim.bo.fileencoding
              return encoding == '' and vim.o.encoding or encoding
            end,
            color = { fg = palette.light_grey },
            cond = function() return vim.o.columns >= 125 end,
          },
          {
            function()
              return ({
                unavailable = '',
                disabled = '',
                working = '',
                ready = '',
              })[copilot_state()]
            end,
            color = function()
              local state = copilot_state()
              if state == 'disabled' or state == 'unavailable' then return { fg = '#555555' } end
              if not focused() then return { fg = palette.grey } end
              if state == 'working' then return { fg = '#E8D48B' } end
              return { fg = '#82AAFF' }
            end,
            cond = function() return vim.o.columns >= 85 end,
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
            color = function()
              return { bg = focused() and active or inactive, fg = focused() and palette.fg or palette.grey }
            end,
          },
          {
            function() return '' end,
            padding = 0,
            color = { fg = active, bg = black },
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
