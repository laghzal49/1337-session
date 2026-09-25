-- Completion formatting, documentation panel, and insert-mode keybindings.
return {
  {
    'iguanacucumber/magazine.nvim',
    name = 'nvim-cmp',
    url = 'https://github.com/iguanacucumber/magazine.nvim.git',
    opts = function(_, opts)
      local cmp = require('cmp')
      local ui = require('config.ui')
      -- The documentation decorator is optional so completion still loads when
      -- running against an unpatched cmp build.
      pcall(function()
        require('config.documentation').setup()
      end)
      opts.mapping = opts.mapping or cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
      })
      opts.mapping['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_next_item()
        elseif vim.snippet.active({ direction = 1 }) then vim.snippet.jump(1)
        else fallback() end
      end, { 'i', 's' })
      opts.mapping['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_prev_item()
        elseif vim.snippet.active({ direction = -1 }) then vim.snippet.jump(-1)
        else fallback() end
      end, { 'i', 's' })

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
        accent = '#82AAFF',
        match = '#82AAFF',
        panel = '#0E141D',
        selected = '#1B3352',
        selected_text = '#82AAFF',
        selected_match = '#9CCBFF',
        deprecated = '#76839A',
        thumb = '#38557A',
      }
      local function setup_kind_highlights()
        for k, col in pairs(kind_colors) do
          vim.api.nvim_set_hl(0, 'CmpItemKind' .. k, { fg = col, default = false })
        end
        vim.api.nvim_set_hl(0, 'CmpItemKindDefault', { fg = completion_colors.muted, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbr', { fg = completion_colors.text, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrDeprecated', { fg = completion_colors.deprecated, strikethrough = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrMatch', { fg = completion_colors.match, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchFuzzy', { fg = completion_colors.accent, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemMenu', { fg = completion_colors.muted, default = false })
        vim.api.nvim_set_hl(0, 'Pmenu', { bg = completion_colors.panel, fg = completion_colors.text, default = false })
        vim.api.nvim_set_hl(0, 'PmenuSel', { bg = completion_colors.selected, fg = completion_colors.selected_text, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchSelected', { fg = completion_colors.selected_match, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = completion_colors.panel, default = false })
        vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = completion_colors.thumb, default = false })
        vim.api.nvim_set_hl(0, 'CmpGhostText', { fg = '#3A4A5E', italic = true })
      end
      setup_kind_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('CmpKindHighlights', { clear = true }),
        callback = setup_kind_highlights,
      })

      -- Window styling: pure deep surfaces, rounded borders, zero background leakage
      local ui = require('config.ui')
      opts.window = {
        completion = cmp.config.window.bordered({
          border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
          side_padding = 1,
          col_offset = -1,
          scrollbar = true,
          scrolloff = 2,
          winblend = 0,
          max_height = 14,
          winhighlight = 'Normal:BlackDocs,NormalFloat:BlackDocs,FloatBorder:BlackDocsBorder,CursorLine:PmenuSel,Search:None,EndOfBuffer:BlackDocs,ScrollbarThumb:PmenuThumb,ScrollbarTrack:PmenuSbar',
        }),
        documentation = cmp.config.window.bordered({
          border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
          side_padding = 2,
          scrollbar = true,
          winblend = 0,
          winhighlight = 'Normal:BlackDocs,NormalFloat:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle,FloatFooter:BlackDocsHint,Search:None,EndOfBuffer:BlackDocs',
          max_width = math.min(76, ui.max_width),
          max_height = math.max(12, ui.max_height),
        }),
      }
      opts.view = vim.tbl_deep_extend('force', opts.view or {}, { docs = { auto_open = true } })

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

      -- Keep these as public mapping keys; cmp normalizes them internally and
      -- this avoids depending on cmp.utils.keymap (a private module).
      opts.mapping['<C-b>'] = scroll_docs(-4)
      opts.mapping['<C-f>'] = scroll_docs(4)
      opts.mapping['<C-e>'] = cmp.mapping.abort()
      opts.mapping['<C-d>'] = cmp.mapping(function()
        if cmp.visible_docs() then cmp.close_docs() else cmp.open_docs() end
      end, { 'i', 's' })

      opts.formatting = opts.formatting or {}
      opts.formatting.fields = { 'kind', 'abbr', 'menu' }

      local source_labels = {
        nvim_lsp = 'LSP',
        luasnip = 'Snippet',
        buffer = 'Buffer',
        path = 'Path',
        cmdline = 'Command',
        spell = 'Spell',
      }
      local function truncate(text, max_width)
        if not text or vim.fn.strdisplaywidth(text) <= max_width then return text end
        local target = max_width - 1
        local result = vim.fn.strcharpart(text, 0, target)
        while vim.fn.strdisplaywidth(result) > target do
          result = vim.fn.strcharpart(result, 0, vim.fn.strchars(result) - 1)
        end
        return result .. '…'
      end

      -- Use the same symbol family as Aerial; ui.symbol() also supplies the
      -- readable fallback when a terminal does not have a Nerd Font.
      local kinds = {
        Text = ui.symbol('String'), Method = ui.symbol('Method'),
        Function = ui.symbol('Function'), Constructor = ui.symbol('Constructor'),
        Field = ui.symbol('Field'), Variable = ui.symbol('Variable'),
        Class = ui.symbol('Class'), Interface = ui.symbol('Interface'),
        Module = ui.symbol('Module'), Property = ui.symbol('Property'),
        Unit = ui.symbol('Number'), Value = ui.symbol('Constant'),
        Enum = ui.symbol('Enum'), Keyword = ui.symbol('Operator'),
        Snippet = ui.symbol('String'), Color = ui.symbol('Constant'),
        File = ui.symbol('File'), Reference = ui.symbol('Key'),
        Folder = ui.symbol('Module'), EnumMember = ui.symbol('EnumMember'),
        Constant = ui.symbol('Constant'), Struct = ui.symbol('Struct'),
        Event = ui.symbol('Event'), Operator = ui.symbol('Operator'),
        TypeParameter = ui.symbol('TypeParameter'),
      }

      opts.formatting.format = function(entry, item)
        local kind = item.kind
        item.kind = kinds[kind] or ui.icon('file')
        item.kind_hl_group = kinds[kind] and ('CmpItemKind' .. kind) or 'CmpItemKindDefault'

        -- Keep the label readable while retaining cmp's match highlighting.
        item.abbr = truncate(item.abbr, 42)
        if item.deprecated then
          item.abbr_hl_group = 'CmpItemAbbrDeprecated'
        elseif item.abbr and item.abbr:sub(-3) == '…' then
          item.abbr_hl_group = nil
        end

        -- The right-hand column identifies the source, rather than repeating
        -- the kind. This creates a useful kind → source hierarchy.
        local source = entry and entry.source
        local source_name = source and source.name or ''
        local source_label = source_labels[source_name] or source_name
        local detail = item.menu or ''
        if detail ~= '' and detail ~= source_label and detail ~= ('[' .. source_label .. ']') then
          source_label = source_label .. ' · ' .. detail
        end
        item.menu = truncate(source_label, 18)
        return item
      end

      opts.performance = vim.tbl_deep_extend('force', opts.performance or {}, {
        max_view_entries = 16,
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

      opts.experimental = vim.tbl_deep_extend('force', opts.experimental or {}, {
        ghost_text = { hl_group = 'CmpGhostText' },
      })
    end,
  },
}
