return {
  { 'folke/snacks.nvim', opts = { picker = { enabled = false }, explorer = { enabled = false } } },
  { 'nvim-mini/mini.extra', lazy = true, opts = {} },
  {
    'nvim-mini/mini.pick', cmd = 'Pick', dependencies = { 'nvim-mini/mini.extra' },
    keys = (function()
      local result = {}
      local maps = {
        { '<leader><space>', 'files', 'Find files' }, { '<leader>ff', 'files', 'Find files' },
        { '<leader>/', 'grep', 'Search project' }, { '<leader>sg', 'grep', 'Search project' },
        { '<leader>,', 'buffers', 'Buffers' }, { '<leader>fb', 'buffers', 'Buffers' },
        { '<leader>fr', 'oldfiles', 'Recent files' }, { '<leader>:', 'command_history', 'Command history' },
        { '<leader>sC', 'commands', 'Commands' }, { '<leader>sk', 'keymaps', 'Keymaps' },
        { '<leader>sh', 'help', 'Help' }, { '<leader>sd', 'diagnostic', 'Diagnostics' },
        { '<leader>ss', 'document_symbol', 'Find document symbol' },
        { '<leader>cS', 'workspace_symbol_live', 'Find workspace symbol' },
        { '<leader>sS', 'workspace_symbol_live', 'Find workspace symbol' },
        { '<leader>sr', 'resume', 'Resume search' },
      }
      for _, map in ipairs(maps) do
        local command = map[2]
        result[#result + 1] = { map[1], function() require('config.pick').open(command) end, desc = map[3] }
      end
      result[#result + 1] = { '<leader>fc', function() require('config.pick').open('files', { cwd = vim.fn.stdpath('config') }) end, desc = 'Find config file' }
      return result
    end)(),
    opts = {
      mappings = { toggle_preview = '<C-p>', move_up = '<C-k>', move_down = '<C-j>', mark = '<Tab>', mark_all = '<C-a>' },
      window = { config = function()
        local width = math.max(1, math.min(100, vim.o.columns - 6))
        local height = math.max(1, math.min(28, math.floor(vim.o.lines * 0.65)))
        return { anchor = 'NW', relative = 'editor', border = { '', '─', '', '', '', '', '', '' }, width = width, height = height,
          row = math.max(0, math.floor((vim.o.lines - height) * 0.3)), col = math.floor((vim.o.columns - width) / 2) }
      end },
    },
    config = function(_, opts)
      require('mini.pick').setup(opts)
      vim.ui.select = require('mini.pick').ui_select
    end,
  },
}
