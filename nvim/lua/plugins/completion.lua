-- Completion formatting, documentation panel, and insert-mode keybindings.
return {
  {
    'iguanacucumber/magazine.nvim',
    name = 'nvim-cmp',
    url = 'https://github.com/iguanacucumber/magazine.nvim.git',
    opts = function(_, opts)
      local cmp = require('cmp')
      require('config.documentation').setup()
      opts.mapping = opts.mapping or cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
      })

      -- Dedicated kind highlight definitions matching the Perfect Black palette
      local kind_colors = {
        Text = '#A9B9D6',
        Method = '#69AFFF',
        Function = '#69AFFF',
        Constructor = '#7FE3C2',
        Field = '#70D7FF',
        Variable = '#E6B3FF',
        Class = '#E8D48B',
        Interface = '#93D68F',
        Module = '#7FD4C4',
        Property = '#B8D7F0',
        Unit = '#A0A0A0',
        Value = '#E8D48B',
        Enum = '#E8D48B',
        EnumMember = '#93D68F',
        Keyword = '#C7A6FF',
        Snippet = '#93D68F',
        Color = '#E88B8B',
        File = '#7FB4F5',
        Reference = '#C4A7E7',
        Folder = '#7FB4F5',
        Constant = '#E88B8B',
        Struct = '#E8D48B',
        Event = '#C4A7E7',
        Operator = '#7FD4C4',
        TypeParameter = '#93D68F',
      }
      local completion_colors = {
        text = '#D7E3FF',
        muted = '#61708A',
        accent = '#69AFFF',
        match = '#82AAFF',
        panel = '#0E141D',
        selected = '#1D3B63',
        thumb = '#496B9A',
      }
      local function setup_kind_highlights()
        for k, col in pairs(kind_colors) do
          vim.api.nvim_set_hl(0, 'CmpItemKind' .. k, { fg = col, default = false })
        end
        vim.api.nvim_set_hl(0, 'CmpItemKindDefault', { fg = completion_colors.muted, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbr', { fg = completion_colors.text, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrDeprecated', { fg = completion_colors.muted, strikethrough = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrMatch', { fg = completion_colors.match, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchFuzzy', { fg = completion_colors.accent, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemMenu', { fg = completion_colors.muted, default = false })
        vim.api.nvim_set_hl(0, 'Pmenu', { bg = completion_colors.panel, fg = completion_colors.text, default = false })
        vim.api.nvim_set_hl(0, 'PmenuSel', { bg = completion_colors.selected, fg = completion_colors.text, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = completion_colors.panel, default = false })
        vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = completion_colors.thumb, default = false })
      end
      setup_kind_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('CmpKindHighlights', { clear = true }),
        callback = setup_kind_highlights,
      })

      -- Window styling: pure deep surfaces, rounded borders, zero background leakage
      opts.window = {
        completion = cmp.config.window.bordered({
          border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
          side_padding = 1,
          col_offset = 0,
          scrollbar = false,
          winblend = require('config.ui').blend,
          winhighlight = 'Normal:BlackDocs,NormalFloat:BlackDocs,FloatBorder:BlackDocsBorder,CursorLine:PmenuSel,Search:None,EndOfBuffer:BlackDocs',
        }),
        documentation = cmp.config.window.bordered({
          border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
          side_padding = 1,
          scrollbar = false,
          winblend = require('config.ui').blend,
          winhighlight = 'Normal:BlackDocs,NormalFloat:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle,FloatFooter:BlackDocsHint,Search:None,EndOfBuffer:BlackDocs',
          max_width = 68,
          max_height = require('config.ui').max_height,
        }),
      }
      opts.view = vim.tbl_deep_extend('force', opts.view or {}, { docs = { auto_open = false } })

      local function scroll_docs(delta)
        return cmp.mapping(function(fallback)
          if cmp.visible_docs() then
            cmp.scroll_docs(delta)
          elseif cmp.visible() then
            cmp.open_docs()
          else
            return fallback()
          end
        end, { 'i', 's' })
      end

      local normalize = require('cmp.utils.keymap').normalize
      opts.mapping[normalize('<C-b>')] = scroll_docs(-4)
      opts.mapping[normalize('<C-f>')] = scroll_docs(4)
      opts.mapping[normalize('<C-e>')] = cmp.mapping.abort()
      opts.mapping[normalize('<C-d>')] = cmp.mapping(function()
        if cmp.visible_docs() then cmp.close_docs() else cmp.open_docs() end
      end, { 'i', 's' })

      opts.formatting = opts.formatting or {}
      opts.formatting.fields = { 'kind', 'abbr', 'menu' }

      -- Authentic VS Code Codicon glyphs from JetBrains Mono Nerd Font
      local kinds = {
        Text = '\u{ea73}',          -- 
        Method = '\u{ea8c}',        -- 
        Function = '\u{ea8c}',      -- 
        Constructor = '\u{ea8c}',   -- 
        Field = '\u{eb5f}',         -- 
        Variable = '\u{ea88}',      -- 
        Class = '\u{eb5b}',         -- 
        Interface = '\u{eb61}',     -- 
        Module = '\u{ea8b}',        -- 
        Property = '\u{eb65}',      -- 
        Unit = '\u{ea96}',          -- 
        Value = '\u{ea95}',         -- 
        Enum = '\u{ea95}',          -- 
        Keyword = '\u{eb62}',       -- 
        Snippet = '\u{eb66}',       -- 
        Color = '\u{eb5c}',         -- 
        File = '\u{ea7b}',          -- 
        Reference = '\u{ea74}',     -- 
        Folder = '\u{ea83}',        -- 
        EnumMember = '\u{eb5e}',    -- 
        Constant = '\u{eb5d}',      -- 
        Struct = '\u{ea91}',        -- 
        Event = '\u{ea86}',         -- 
        Operator = '\u{eb64}',      -- 
        TypeParameter = '\u{ea92}', -- 
      }

      opts.formatting.format = function(entry, item)
        local kind = item.kind
        item.kind = kinds[kind] or '\u{ea73}'
        item.kind_hl_group = 'CmpItemKind' .. (kind or 'Default')

        -- Truncate overly long item labels with ellipsis '…'
        local max_abbr = 38
        if item.abbr and vim.fn.strdisplaywidth(item.abbr) > max_abbr then
          local target = max_abbr - 1
          local text = vim.fn.strcharpart(item.abbr, 0, target)
          while vim.fn.strdisplaywidth(text) > target do
            text = vim.fn.strcharpart(text, 0, vim.fn.strchars(text) - 1)
          end
          item.abbr = text .. '…'
          item.abbr_hl_group = nil
        end

        -- Clean menu column with truncation bounds
        local max_menu = 14
        local menu = kind or ''
        if vim.fn.strdisplaywidth(menu) > max_menu then
          local target = max_menu - 1
          local text = vim.fn.strcharpart(menu, 0, target)
          while vim.fn.strdisplaywidth(text) > target do
            text = vim.fn.strcharpart(text, 0, vim.fn.strchars(text) - 1)
          end
          menu = text .. '…'
        end
        item.menu = menu
        return item
      end

      opts.performance = vim.tbl_deep_extend('force', opts.performance or {}, {
        max_view_entries = 40,
      })

      for _, source in ipairs(opts.sources or {}) do
        if source.name == 'buffer' then
          source.option = vim.tbl_deep_extend('force', source.option or {}, {
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
