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
    end,
    keys = (function()
      local keys = {}
      for key, capture in pairs({ af = '@function.outer', ['if'] = '@function.inner', ac = '@class.outer', ic = '@class.inner', aa = '@parameter.outer', ia = '@parameter.inner' }) do
        keys[#keys + 1] = { key, mode = { 'x', 'o' }, function()
          require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
        end, desc = 'Select ' .. capture }
      end
      for key, method in pairs({ [']m'] = 'goto_next_start', ['[m'] = 'goto_previous_start' }) do
        keys[#keys + 1] = { key, mode = { 'n', 'x', 'o' }, function()
          require('nvim-treesitter-textobjects.move')[method]('@function.outer', 'textobjects')
        end, desc = key == ']m' and 'Next function start' or 'Previous function start' }
      end
      return keys
    end)(),
  },
}
