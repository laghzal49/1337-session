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
        },
      }
    end,
  },
  -- Underrated Gem 2: Ultra-lightweight autopairs with Treesitter skip
  {
    'nvim-mini/mini.pairs',
    event = 'InsertEnter',
    opts = {
      modes = { insert = true, command = true, terminal = false },
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      skip_ts = { 'string' },
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
  -- Underrated Gem 5: Inline hex color highlighter
  {
    'nvim-mini/mini.hipatterns',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = function()
      local hi = require('mini.hipatterns')
      return {
        highlighters = {
          hex_color = hi.gen_highlighter.hex_color(),
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
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gD', '<cmd>DiffviewOpen<cr>', desc = 'Git diff view' },
      { '<leader>gH', '<cmd>DiffviewFileHistory %<cr>', desc = 'Current file history' },
    },
    opts = {},
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
