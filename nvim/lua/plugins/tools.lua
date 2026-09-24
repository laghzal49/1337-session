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
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gD', '<cmd>DiffviewOpen<cr>', desc = 'Git diff view' },
      { '<leader>gH', '<cmd>DiffviewFileHistory %<cr>', desc = 'Current file history' },
    },
    opts = {},
  },
  { 'mfussenegger/nvim-dap', cmd = { 'DapContinue', 'DapToggleBreakpoint' }, keys = {
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Breakpoint' },
    { '<leader>dc', function() require('dap').continue() end, desc = 'Continue debugger' },
  } },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<leader>um', '<cmd>RenderMarkdown toggle<cr>', ft = 'markdown', desc = 'Toggle Markdown rendering' },
      { '<leader>mr', '<cmd>RenderMarkdown toggle<cr>', ft = 'markdown', desc = 'Markdown reader mode' },
    },
    opts = {
      file_types = { 'markdown' },
      heading = { sign = false, icons = {}, width = 'block', right_pad = 2 },
      code = { sign = false, width = 'block', right_pad = 2, left_pad = 1 },
      checkbox = { enabled = true },
    },
  },
}
