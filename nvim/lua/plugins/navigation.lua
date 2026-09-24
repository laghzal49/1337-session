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
      mappings = {
        stop = '<Esc>',
        toggle_preview = '<C-p>',
        move_up = '<C-k>',
        move_down = '<C-j>',
        mark = '<Tab>',
        mark_all = '<C-a>',
      },
      window = {
        prompt_prefix = ' 󰍉 ',
        prompt_caret = '▏',
        config = function()
          local width = math.max(20, math.min(100, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.8))))
          local height = math.max(5, math.min(28, math.floor(vim.o.lines * 0.65)))
          return {
            anchor = 'NW',
            relative = 'editor',
            border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
            title = '  Find  ',
            title_pos = 'center',
            width = width,
            height = height,
            row = math.max(0, math.floor((vim.o.lines - height) * 0.3)),
            col = math.floor((vim.o.columns - width) / 2),
          }
        end,
      },
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
    opts = {
      options = { use_as_default_explorer = true },
      windows = {
        max_number = 3,
        preview = false,
        width_focus = 36,
        width_nofocus = 16,
      },
    },
  },
  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialNavToggle' },
    keys = { { '<leader>cs', '<cmd>AerialToggle float<cr>', desc = 'Code outline (Aerial)' } },
    opts = {
      layout = { default_direction = 'right', min_width = 24, max_width = 32 },
      float = {
        border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
        relative = 'cursor',
        max_height = 0.8,
        min_height = { 8, 0.1 },
      },
      show_guides = true,
      guides = {
        mid_item = '├─',
        last_item = '└─',
        nested_top = '│ ',
        whitespace = '  ',
      },
      nerd_font = true,
      icons = {
        Array = '󱡠',
        Boolean = '󰨙',
        Class = '󰆧',
        Constant = '󰏿',
        Constructor = '',
        Enum = '',
        EnumMember = '',
        Event = '',
        Field = '',
        File = '󰈙',
        Function = '󰊕',
        Interface = '',
        Key = '󰌋',
        Method = '󰊕',
        Module = '',
        Namespace = '󰦮',
        Null = '󰟢',
        Number = '󰎠',
        Object = '',
        Operator = '󰆕',
        Package = '',
        Property = '',
        String = '',
        Struct = '󰆼',
        TypeParameter = '󰗴',
        Variable = '󰀫',
        Collapsed = '',
      },
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
    opts = function()
      return {
        height = math.max(12, math.min(16, math.floor(vim.o.lines * 0.4))),
        border = {
          enable = true,
          top_char = '─',
          bottom_char = '─',
          left_char = '│',
          right_char = '│',
          top_left_char = '╭',
          top_right_char = '╮',
          bottom_left_char = '╰',
          bottom_right_char = '╯',
        },
        list = {
          position = 'right',
          width = 0.33,
        },
        theme = {
          enable = false,
        },
        winbar = {
          enable = true,
        },
        folds = {
          fold_closed = '',
          fold_open = '',
          folded = true,
        },
        indent_lines = {
          enable = true,
          icon = '│',
        },
      }
    end,
    config = function(_, opts)
      require('glance').setup(opts)
      local s = require('config.surfaces')
      vim.api.nvim_set_hl(0, 'GlanceWinBarTitle', { bg = s.panel, fg = s.accent, bold = true })
      vim.api.nvim_set_hl(0, 'GlanceWinBarFilename', { bg = s.inset, fg = s.text, bold = true })
      vim.api.nvim_set_hl(0, 'GlanceWinBarFilepath', { bg = s.inset, fg = s.muted })
      vim.api.nvim_set_hl(0, 'GlanceBorderTop', { bg = s.panel, fg = s.edge })
      vim.api.nvim_set_hl(0, 'GlanceListBorderBottom', { bg = s.panel, fg = s.edge })
      vim.api.nvim_set_hl(0, 'GlancePreviewBorderBottom', { bg = s.inset, fg = s.edge })
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      labels = 'asdfghjklqwertyuiopzxcvbnm',
      search = { mode = 'exact' },
      modes = {
        char = { enabled = true }, -- enhance f, F, t, T with multi-line preview
      },
    },
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
    },
  },
}
