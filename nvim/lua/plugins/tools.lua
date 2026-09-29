-- Editing tools, quickfix, text objects, and visual utilities.
return {
  { 'smjonas/inc-rename.nvim', cmd = 'IncRename', opts = {} },
  {
    'stevearc/quicker.nvim',
    ft = 'qf',
    keys = { { '<leader>xQ', function() require('quicker').toggle() end, desc = 'Editable quickfix (Quicker)' } },
    opts = { keys = {
      { '>', function() require('quicker').expand({ before = 2, after = 2, add_to_existing = true }) end, desc = 'Expand context' },
      { '<', function() require('quicker').collapse() end, desc = 'Collapse context' },
    } },
  },
  {
    'Wansmer/treesj',
    keys = { { '<leader>cj', function() require('treesj').toggle() end, desc = 'Split/join code structure' } },
    opts = { use_default_keymaps = false, max_join_length = 100 },
  },
  {
    'chrisgrieser/nvim-various-textobjs',
    keys = {
      { 'ii', function() require('various-textobjs').indentation('inner', 'inner') end, mode = { 'o', 'x' }, desc = 'Inner indentation' },
      { 'ai', function() require('various-textobjs').indentation('outer', 'inner') end, mode = { 'o', 'x' }, desc = 'Around indentation' },
      { 'iS', function() require('various-textobjs').subword('inner') end, mode = { 'o', 'x' }, desc = 'Inner subword' },
      { 'aS', function() require('various-textobjs').subword('outer') end, mode = { 'o', 'x' }, desc = 'Around subword' },
    },
    opts = { keymaps = { useDefaults = false } },
  },
  -- Underrated Gem 1: Structural text objects (functions, arguments, classes, blocks)
  {
    'nvim-mini/mini.ai',
    event = 'VeryLazy',
    opts = function()
      local ai = require('mini.ai')
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }),
          f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
          -- HTML / JSX tag text object (at = around tag, it = inner tag)
          t = ai.gen_spec.treesitter({ a = '@tag.outer', i = '@tag.inner' }),
          -- Diagnostic region: around/inner the current diagnostic message
          d = function(ai_type)
            local diags = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
            if vim.tbl_isempty(diags) then return end
            local d = diags[1]
            local from = { line = d.lnum + 1, col = d.col + 1 }
            local to   = { line = (d.end_lnum or d.lnum) + 1, col = (d.end_col or d.col) + 1 }
            return { from = from, to = to }
          end,
        },
      }
    end,
    config = function(_, opts)
      require('mini.ai').setup(opts)
    end,
  },
  -- Lightweight autopairs
  {
    'nvim-mini/mini.pairs',
    event = 'InsertEnter',
    opts = {
      modes = { insert = true, command = true, terminal = false },
    },
  },
  -- Underrated Gem 3: Fast surround management (sa, sd, sr)
  {
    'nvim-mini/mini.surround',
    keys = {
      { 'sa', desc = 'Add surrounding', mode = { 'n', 'v' } },
      { 'sd', desc = 'Delete surrounding' },
      { 'sf', desc = 'Find surrounding' },
      { 'sr', desc = 'Replace surrounding' },
    },
    opts = {
      mappings = {
        add = 'sa',
        delete = 'sd',
        find = 'sf',
        find_left = 'sF',
        highlight = 'sh',
        replace = 'sr',
        update_n_lines = 'sn',
      },
    },
  },
  -- Underrated Gem 4: Interactive text alignment for tables, assignments & params
  {
    'nvim-mini/mini.align',
    keys = {
      { 'ga', mode = { 'n', 'v' }, desc = 'Align text' },
      { 'gA', mode = { 'n', 'v' }, desc = 'Align with preview' },
    },
    opts = {},
  },
  -- Inline hex color highlighter
  {
    'nvim-mini/mini.hipatterns',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = function()
      local hi = require('mini.hipatterns')
      -- Compute a readable fg for a given bg hex string
      local function dark_or_light(hex)
        local r = tonumber(hex:sub(2, 3), 16) or 0
        local g = tonumber(hex:sub(4, 5), 16) or 0
        local b = tonumber(hex:sub(6, 7), 16) or 0
        -- Relative luminance (WCAG formula)
        local lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return lum > 0.45 and '#000000' or '#FFFFFF'
      end

      return {
        highlighters = {
          -- ── Standard 6-digit hex colors ──────────────────────────────
          hex_color = hi.gen_highlighter.hex_color({ priority = 100 }),

          -- ── 8-digit RGBA hex colors (#RRGGBBAA) ───────────────────────
          hex_color_rgba = {
            pattern = '#%x%x%x%x%x%x%x%x%f[%W]',
            group = function(_, match)
              -- Strip alpha; use first 7 chars as the display color
              local hex6 = match:sub(1, 7)
              local fg = dark_or_light(hex6)
              local hl_name = 'HipatHex_' .. hex6:sub(2)
              if vim.fn.hlID(hl_name) == 0 then
                vim.api.nvim_set_hl(0, hl_name, { bg = hex6, fg = fg })
              end
              return hl_name
            end,
            priority = 110,
          },


        },
      }
    end,
  },
  -- Underrated Gem 6: Highlight and search TODO/FIXME/HACK/NOTE comments
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = false,
      highlight = { multiline = false, before = '', after = 'fg', keyword = 'bg' },
      colors = {
        error = { '#FF8FA3' },
        warning = { '#FFD166' },
        info = { '#70D7FF' },
        hint = { '#7FE3C2' },
        default = { '#C7A6FF' },
        test = { '#69AFFF' },
      },
    },
    keys = {
      { '<leader>st', '<cmd>TodoQuickFix<cr>', desc = 'Search TODOs' },
      { ']t', function() require('todo-comments').jump_next() end, desc = 'Next TODO' },
      { '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous TODO' },
    },
  },
  -- Underrated Gem 7: Treesitter-aware commenting with JSX/TSX support
  {
    'folke/ts-comments.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = {
      { '<leader>gD', '<cmd>DiffviewOpen<cr>', desc = 'Git diff view' },
      { '<leader>gH', '<cmd>DiffviewFileHistory %<cr>', desc = 'Current file history' },
      { '<leader>gf', '<cmd>DiffviewFileHistory<cr>', mode = { 'n', 'v' }, desc = 'File history (selection)' },
      { '<leader>gc', '<cmd>DiffviewClose<cr>', desc = 'Close diffview' },
    },
    opts = {
      default_args = {
        DiffviewFileHistory = { '--follow' },
      },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    init = function() require('config.markdown').setup() end,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      { '<leader>um', '<cmd>RenderMarkdown toggle<cr>', ft = 'markdown', desc = 'Toggle Markdown rendering' },
      { '<leader>mr', '<cmd>MarkdownReaderToggle<cr>', ft = 'markdown', desc = 'Toggle Markdown reader mode' },
      { '<leader>mR', '<cmd>MarkdownReaderEnable<cr>', ft = 'markdown', desc = 'Enable Markdown reader mode' },
      { '<leader>mD', '<cmd>MarkdownReaderDisable<cr>', ft = 'markdown', desc = 'Disable Markdown reader mode' },
    },
    opts = {
      -- Keep normal mode calm and readable while still rendering in command and
      -- terminal preview contexts. The file-size guard prevents expensive
      -- decoration from making generated or vendored Markdown unpleasant.
      enabled = true,
      render_modes = { 'n', 'c', 't' },
      debounce = 120,
      max_file_size = 10.0,
      preset = 'none',
      file_types = { 'markdown' },
      anti_conceal = {
        enabled = true,
        above = 0,
        below = 0,
        ignore = {
          code_background = true,
          indent = true,
          link = true,
          sign = true,
          virtual_lines = true,
        },
      },
      heading = {
        enabled = true,
        sign = false,
        icons = {},
        position = 'overlay',
        width = 'block',
        left_pad = 1,
        right_pad = 2,
        border = false,
        backgrounds = {
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg',
          'RenderMarkdownH3Bg',
          'RenderMarkdownH4Bg',
          'RenderMarkdownH5Bg',
          'RenderMarkdownH6Bg',
        },
      },
      code = {
        enabled = true,
        sign = false,
        position = 'left',
        language = true,
        language_name = true,
        language_info = true,
        width = 'full',
        left_pad = 1,
        right_pad = 2,
        border = 'hide',
        disable_background = { 'diff' },
        inline = true,
      },
      checkbox = {
        enabled = true,
      },
      quote = {
        enabled = true,
        repeat_linebreak = false,
      },
      pipe_table = {
        enabled = true,
        preset = 'round',
        style = 'full',
      },
      yaml = { enabled = true },
      win_options = {
        conceallevel = { default = 2, rendered = 3 },
        concealcursor = { default = '', rendered = 'n' },
      },
      horizontal_rule = { enabled = true, border = 'thick' },
      link = { enabled = true, hyperlink = '🔗 ' },
    },
  },
}
