-- Editing tools, quickfix, and version control integration.
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
    },
    opts = {
      file_types = { 'markdown' },
      heading = { sign = false, icons = {}, width = 'block', right_pad = 2 },
      code = { sign = false, width = 'block', right_pad = 2, left_pad = 1 },
      checkbox = { enabled = true },
    },
  },
}
