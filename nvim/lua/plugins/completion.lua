-- Blink.cmp completion configuration matching the Perfect Black palette
return {
  { 'iguanacucumber/magazine.nvim', enabled = false },
  {
    'saghen/blink.cmp',
    version = 'v1.10.2',
    lazy = false,
    opts = {
      keymap = {
        preset = 'none',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
      },

      completion = {
        menu = {
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
          scrollbar = true,
          scrolloff = 2,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = 'rounded',
            winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
          },
        },
      },

      signature = {
        enabled = true,
        window = {
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
        },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
    config = function(_, opts)
      local function setup_blink_highlights()
        local panel = '#0E141D'
        local selected = '#1B3352'
        local border = '#38557A'
        local text = '#D7E3FF'
        local accent = '#82AAFF'
        local muted = '#61708A'

        vim.api.nvim_set_hl(0, 'BlinkCmpMenu', { bg = panel, fg = text, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { bg = panel, fg = border, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpMenuSelection', { bg = selected, fg = accent, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpScrollBarThumb', { bg = border, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpScrollBarGutter', { bg = panel, default = false })

        vim.api.nvim_set_hl(0, 'BlinkCmpDoc', { bg = panel, fg = text, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder', { bg = panel, fg = border, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpDocSeparator', { bg = panel, fg = border, default = false })

        vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelp', { bg = panel, fg = text, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelpBorder', { bg = panel, fg = border, default = false })

        vim.api.nvim_set_hl(0, 'BlinkCmpLabel', { fg = text, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpLabelMatch', { fg = accent, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpLabelDeprecated', { fg = '#76839A', strikethrough = true, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpLabelDetail', { fg = muted, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpLabelDescription', { fg = muted, default = false })
        vim.api.nvim_set_hl(0, 'BlinkCmpGhostText', { fg = '#3A4A5E', italic = true, default = false })

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
        for kind, col in pairs(kind_colors) do
          vim.api.nvim_set_hl(0, 'BlinkCmpKind' .. kind, { fg = col, default = false })
        end
        vim.api.nvim_set_hl(0, 'BlinkCmpKind', { fg = muted, default = false })

        vim.api.nvim_set_hl(0, 'Pmenu', { bg = panel, fg = text, default = false })
        vim.api.nvim_set_hl(0, 'PmenuSel', { bg = selected, fg = accent, bold = true, default = false })
        vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = panel, default = false })
        vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = border, default = false })
      end

      setup_blink_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('BlinkBlackHighlights', { clear = true }),
        callback = setup_blink_highlights,
      })

      require('blink.cmp').setup(opts)
    end,
  },
}
