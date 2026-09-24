-- Search, file browsing, symbols, and reference inspection.
local ui = require('config.ui')

return {
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
        return { anchor = 'NW', relative = 'editor', border = { '', '\u{2500}', '', '', '', '', '', '' }, width = width, height = height,
          row = math.max(0, math.floor((vim.o.lines - height) * 0.3)), col = math.floor((vim.o.columns - width) / 2) }
      end },
    },
    config = function(_, opts)
      require('mini.pick').setup(opts)
      vim.ui.select = require('mini.pick').ui_select
    end,
  },
  {
    'nvim-mini/mini.files',
    lazy = false,
    keys = {
      { '<leader>e', function()
        local files = require('mini.files')
        if files.close() then return end
        local path = vim.api.nvim_buf_get_name(0)
        files.open(vim.uv.fs_stat(path) and path or require('config.project').root(), true, require('config.tool_layout').files())
      end, desc = 'Files (Mini Files)' },
      { '<leader>fm', function()
        local path = vim.api.nvim_buf_get_name(0)
        require('mini.files').open(vim.uv.fs_stat(path) and path or require('config.project').root(), true, require('config.tool_layout').files())
      end, desc = 'Browse current file (Mini Files)' },
      { '<leader>fM', function() require('mini.files').open(require('config.project').root(), true, require('config.tool_layout').files()) end, desc = 'Browse project (Mini Files)' },
    },
    opts = { options = { use_as_default_explorer = true }, windows = {
      max_number = 3, preview = false, width_focus = 36, width_nofocus = 16,
    } },
  },
  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialNavToggle' },
    keys = { { '<leader>cs', '<cmd>AerialToggle float<cr>', desc = 'Code outline (Aerial)' } },
    opts = {
      layout = { default_direction = 'right', min_width = 22, max_width = 28 },
      show_guides = true,
      guides = { mid_item = '\u{251c}\u{2500}', last_item = '\u{2514}\u{2500}', nested_top = '\u{2502} ', whitespace = '  ' },
    },
  },
  {
    'DNLHC/glance.nvim',
    cmd = 'Glance',
    keys = {
      { '<leader>cgd', '<cmd>Glance definitions<cr>', desc = 'Peek definition' },
      { '<leader>cgr', '<cmd>Glance references<cr>', desc = 'Peek references' },
      { '<leader>cgt', '<cmd>Glance type_definitions<cr>', desc = 'Peek type definition' },
      { '<leader>cgi', '<cmd>Glance implementations<cr>', desc = 'Peek implementation' },
    },
    opts = function() return {
      height = 12,
      border = { enable = false }, theme = { enable = false },
    } end,
  },
}
