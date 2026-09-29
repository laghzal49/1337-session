return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function(_, opts)
      require('harpoon'):setup(opts)
    end,
    keys = {
      {
        '<leader>a',
        function()
          require('harpoon'):list():add()
        end,
        desc = 'Add buffer to Harpoon',
      },
      {
        '<C-e>',
        function()
          local h = require('harpoon')
          h.ui:toggle_quick_menu(h:list())
        end,
        desc = 'Toggle Harpoon quick menu',
      },
      {
        '<leader>1',
        function()
          require('harpoon'):list():select(1)
        end,
        desc = 'Harpoon select buffer 1',
      },
      {
        '<leader>2',
        function()
          require('harpoon'):list():select(2)
        end,
        desc = 'Harpoon select buffer 2',
      },
      {
        '<leader>3',
        function()
          require('harpoon'):list():select(3)
        end,
        desc = 'Harpoon select buffer 3',
      },
      {
        '<leader>4',
        function()
          require('harpoon'):list():select(4)
        end,
        desc = 'Harpoon select buffer 4',
      },
      {
        '<C-S-N>',
        function()
          require('harpoon'):list():next()
        end,
        desc = 'Harpoon next buffer',
      },
      {
        '<C-S-P>',
        function()
          require('harpoon'):list():prev()
        end,
        desc = 'Harpoon prev buffer',
      },
    },
  },
}
