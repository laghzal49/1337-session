return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    },
    config = function(_, opts)
      local harpoon = require('harpoon')
      harpoon:setup(opts)

      local function add_current_file()
        local name = vim.fn.expand('%:t')
        if name == '' then
          vim.notify('Cannot add unnamed buffer to Harpoon', vim.log.levels.WARN, { title = 'Harpoon' })
          return
        end
        harpoon:list():add()
        vim.notify('󰛢 Added to Harpoon: ' .. name, vim.log.levels.INFO, { title = 'Harpoon' })
      end

      local function toggle_menu()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end

      local function select_index(idx)
        local item = harpoon:list():get(idx)
        if item and item.value then
          harpoon:list():select(idx)
        else
          vim.notify('Harpoon slot ' .. idx .. ' is empty', vim.log.levels.WARN, { title = 'Harpoon' })
        end
      end

      -- User commands for terminal/cmdline invocation
      vim.api.nvim_create_user_command('Harpoon', toggle_menu, { desc = 'Toggle Harpoon menu' })
      vim.api.nvim_create_user_command('HarpoonMenu', toggle_menu, { desc = 'Toggle Harpoon menu' })
      vim.api.nvim_create_user_command('HarpoonAdd', add_current_file, { desc = 'Add file to Harpoon' })

      -- Keymaps
      vim.keymap.set('n', '<leader>a', add_current_file, { desc = 'Add file to Harpoon' })
      vim.keymap.set('n', '<leader>ha', add_current_file, { desc = 'Add file to Harpoon' })
      vim.keymap.set('n', '<C-e>', toggle_menu, { desc = 'Toggle Harpoon quick menu' })
      vim.keymap.set('n', '<leader>hh', toggle_menu, { desc = 'Toggle Harpoon menu' })
      vim.keymap.set('n', '<leader>hm', toggle_menu, { desc = 'Toggle Harpoon menu' })

      -- Slot navigation (both <leader>1-4 and <leader>h1-4)
      for i = 1, 4 do
        vim.keymap.set('n', '<leader>' .. i, function() select_index(i) end, { desc = 'Harpoon file ' .. i })
        vim.keymap.set('n', '<leader>h' .. i, function() select_index(i) end, { desc = 'Harpoon file ' .. i })
      end

      -- Next / prev navigation
      vim.keymap.set('n', '<C-S-N>', function() harpoon:list():next() end, { desc = 'Harpoon next file' })
      vim.keymap.set('n', '<C-S-P>', function() harpoon:list():prev() end, { desc = 'Harpoon prev file' })
      vim.keymap.set('n', '<leader>hn', function() harpoon:list():next() end, { desc = 'Harpoon next file' })
      vim.keymap.set('n', '<leader>hp', function() harpoon:list():prev() end, { desc = 'Harpoon prev file' })
    end,
  },
}
