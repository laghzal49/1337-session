return {
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      select = {
        lookahead = true,
        selection_modes = {
          ['@parameter.outer'] = 'v',
          ['@function.outer'] = 'V',
          ['@class.outer'] = '<c-v>',
        },
        include_surrounding_whitespace = false,
      },
      move = {
        set_jumps = true,
      },
    },
    config = function(_, opts)
      require('nvim-treesitter-textobjects').setup(opts)

      local select = require('nvim-treesitter-textobjects.select')
      local move = require('nvim-treesitter-textobjects.move')

      -- Select textobjects
      vim.keymap.set({ 'x', 'o' }, 'af', function()
        select.select_textobject('@function.outer', 'textobjects')
      end, { desc = 'Select around function' })

      vim.keymap.set({ 'x', 'o' }, 'if', function()
        select.select_textobject('@function.inner', 'textobjects')
      end, { desc = 'Select inner function' })

      vim.keymap.set({ 'x', 'o' }, 'ac', function()
        select.select_textobject('@class.outer', 'textobjects')
      end, { desc = 'Select around class' })

      vim.keymap.set({ 'x', 'o' }, 'ic', function()
        select.select_textobject('@class.inner', 'textobjects')
      end, { desc = 'Select inner class' })

      vim.keymap.set({ 'x', 'o' }, 'aa', function()
        select.select_textobject('@parameter.outer', 'textobjects')
      end, { desc = 'Select around parameter' })

      vim.keymap.set({ 'x', 'o' }, 'ia', function()
        select.select_textobject('@parameter.inner', 'textobjects')
      end, { desc = 'Select inner parameter' })

      -- Move motions
      vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
        move.goto_next_start('@function.outer', 'textobjects')
      end, { desc = 'Next function start' })

      vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
        move.goto_previous_start('@function.outer', 'textobjects')
      end, { desc = 'Prev function start' })
    end,
    keys = {
      {
        'af',
        mode = { 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
        end,
        desc = 'Select around function',
      },
      {
        'if',
        mode = { 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
        end,
        desc = 'Select inner function',
      },
      {
        'ac',
        mode = { 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
        end,
        desc = 'Select around class',
      },
      {
        'ic',
        mode = { 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
        end,
        desc = 'Select inner class',
      },
      {
        'aa',
        mode = { 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@parameter.outer', 'textobjects')
        end,
        desc = 'Select around parameter',
      },
      {
        'ia',
        mode = { 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@parameter.inner', 'textobjects')
        end,
        desc = 'Select inner parameter',
      },
      {
        ']m',
        mode = { 'n', 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
        end,
        desc = 'Next function start',
      },
      {
        '[m',
        mode = { 'n', 'x', 'o' },
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
        end,
        desc = 'Prev function start',
      },
    },
  },
}
