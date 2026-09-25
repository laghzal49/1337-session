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
          local width = math.max(24, math.min(110, math.floor(vim.o.columns * 0.82)))
          local height = math.max(6, math.min(32, math.floor(vim.o.lines * 0.70)))
          return {
            anchor = 'NW',
            relative = 'editor',
            border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
            title = '  Search  ',
            title_pos = 'center',
            width = width,
            height = height,
            row = math.max(0, math.floor((vim.o.lines - height) * 0.28)),
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
    opts = function()
      local windows = require('config.tool_layout').files().windows
      local ui = require('config.ui')
      return {
        options = {
          use_as_default_explorer = true,
          permanent_delete = false,
        },
        windows = windows,
        content = {
          -- Sort: directories first, then alphabetical
          sort = function(entries)
            local dirs, files = {}, {}
            for _, e in ipairs(entries) do
              if e.fs_type == 'directory' then dirs[#dirs + 1] = e else files[#files + 1] = e end
            end
            table.sort(dirs, function(a, b) return a.name:lower() < b.name:lower() end)
            table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)
            return vim.list_extend(dirs, files)
          end,
          prefix = function(fs_entry)
            local ok_icons, mini_icons = pcall(require, 'mini.icons')
            if ok_icons then
              local icon, hl = mini_icons.get(fs_entry.fs_type, fs_entry.name)
              return icon .. ' ', hl
            end
            if fs_entry.fs_type == 'directory' then
              return ui.icon('folder') .. ' ', 'MiniFilesDirectoryIcon'
            end
            local ok, devicons = pcall(require, 'nvim-web-devicons')
            if ok then
              local icon, hl = devicons.get_icon(fs_entry.name, fs_entry.ext, { default = true })
              return (icon or ui.icon('file')) .. ' ', hl or 'MiniFilesFileIcon'
            end
            return ui.icon('file') .. ' ', 'MiniFilesFileIcon'
          end,
          filter = function(fs_entry)
            return fs_entry.name ~= '.DS_Store' and fs_entry.name ~= 'thumbs.db'
          end,
        },
      }
    end,
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
      nerd_font = vim.g.have_nerd_font ~= false,
      icons = {
        Array = require('config.ui').symbol('Array'),
        Boolean = require('config.ui').symbol('Boolean'),
        Class = require('config.ui').symbol('Class'),
        Constant = require('config.ui').symbol('Constant'),
        Constructor = require('config.ui').symbol('Constructor'),
        Enum = require('config.ui').symbol('Enum'),
        EnumMember = require('config.ui').symbol('EnumMember'),
        Event = require('config.ui').symbol('Event'),
        Field = require('config.ui').symbol('Field'),
        File = require('config.ui').symbol('File'),
        Function = require('config.ui').symbol('Function'),
        Interface = require('config.ui').symbol('Interface'),
        Key = require('config.ui').symbol('Key'),
        Method = require('config.ui').symbol('Method'),
        Module = require('config.ui').symbol('Module'),
        Namespace = require('config.ui').symbol('Namespace'),
        Null = require('config.ui').symbol('Null'),
        Number = require('config.ui').symbol('Number'),
        Object = require('config.ui').symbol('Object'),
        Operator = require('config.ui').symbol('Operator'),
        Package = require('config.ui').symbol('Package'),
        Property = require('config.ui').symbol('Property'),
        String = require('config.ui').symbol('String'),
        Struct = require('config.ui').symbol('Struct'),
        TypeParameter = require('config.ui').symbol('TypeParameter'),
        Variable = require('config.ui').symbol('Variable'),
        Collapsed = require('config.ui').symbol('Collapsed'),
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
      vim.api.nvim_set_hl(0, 'GlanceWinBarTitle', { bg = s.panel, fg = s.panel_accent, bold = true })
      vim.api.nvim_set_hl(0, 'GlanceWinBarFilename', { bg = s.inset, fg = s.text, bold = true })
      vim.api.nvim_set_hl(0, 'GlanceWinBarFilepath', { bg = s.inset, fg = s.muted })
      vim.api.nvim_set_hl(0, 'GlanceBorderTop', { bg = s.panel, fg = s.edge_bright })
      vim.api.nvim_set_hl(0, 'GlanceListBorderBottom', { bg = s.panel, fg = s.edge_bright })
      vim.api.nvim_set_hl(0, 'GlancePreviewBorderBottom', { bg = s.inset, fg = s.edge_bright })
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
  {
    'nvim-mini/mini.cursorword',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = { delay = 200 },
    config = function(_, opts)
      require('mini.cursorword').setup(opts)
      -- Subtle underline, no background — matches the Perfect Black aesthetic
      vim.api.nvim_set_hl(0, 'MiniCursorword', { underline = true, sp = '#354357' })
      vim.api.nvim_set_hl(0, 'MiniCursorwordCurrent', { underline = true, sp = '#354357' })
    end,
  },
  {
    'nvim-mini/mini.bracketed',
    event = 'VeryLazy',
    opts = {
      buffer = { suffix = 'b' },
      comment = { suffix = 'c' },
      diagnostic = { suffix = 'd' },
      quickfix = { suffix = 'q' },
      treesitter = { suffix = 't' },
      undo = { suffix = '' },
      window = { suffix = '' },
      yank = { suffix = '' },
      file = { suffix = '' },
      indent = { suffix = '' },
      jump = { suffix = '' },
      location = { suffix = '' },
      oldfile = { suffix = '' },
      conflict = { suffix = '' },
    },
  },
  {
    'nvim-mini/mini.move',
    keys = {
      { '<A-j>', mode = { 'n', 'v' }, desc = 'Move line down' },
      { '<A-k>', mode = { 'n', 'v' }, desc = 'Move line up' },
      { '<A-h>', mode = { 'n', 'v' }, desc = 'Move left' },
      { '<A-l>', mode = { 'n', 'v' }, desc = 'Move right' },
    },
    opts = {
      mappings = {
        left = '<A-h>',
        right = '<A-l>',
        down = '<A-j>',
        up = '<A-k>',
        line_left = '<A-h>',
        line_right = '<A-l>',
        line_down = '<A-j>',
        line_up = '<A-k>',
      },
    },
  },
}
