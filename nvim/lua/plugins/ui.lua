-- Unified UI layer: Snacks (all opts), Noice, Edgy, Which-Key, Trouble,
-- Gitsigns, devicons, Mini Notify, Tiny Inline Diagnostic.
-- All Snacks opts consolidated here — no scattered overrides.
local ui = require('config.ui')

return {
  -- ── Icons (mini.icons — best-in-class icon provider) ─────────────────
  {
    'nvim-mini/mini.icons',
    lazy = false,
    priority = 1000,
    opts = {
      style = 'glyph',
      -- Use the Perfect Black palette for file type icon colors
      file = {
        ['.gitignore'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
        ['Makefile'] = { glyph = '', hl = 'MiniIconsYellow' },
        ['Dockerfile'] = { glyph = '󰡨', hl = 'MiniIconsCyan' },
        ['docker-compose.yml'] = { glyph = '󰡨', hl = 'MiniIconsCyan' },
      },
      filetype = {
        python = { glyph = '󰌠', hl = 'MiniIconsGreen' },
        lua = { glyph = '󰢱', hl = 'MiniIconsPurple' },
        c = { glyph = '', hl = 'MiniIconsCyan' },
        cpp = { glyph = '', hl = 'MiniIconsCyan' },
        rust = { glyph = '󱘗', hl = 'MiniIconsOrange' },
        javascript = { glyph = '󰌞', hl = 'MiniIconsYellow' },
        typescript = { glyph = '󰛦', hl = 'MiniIconsCyan' },
        markdown = { glyph = '󰍔', hl = 'MiniIconsBlue' },
        json = { glyph = '', hl = 'MiniIconsYellow' },
        yaml = { glyph = '', hl = 'MiniIconsAzure' },
        toml = { glyph = '', hl = 'MiniIconsAzure' },
        html = { glyph = '', hl = 'MiniIconsOrange' },
        css = { glyph = '', hl = 'MiniIconsBlue' },
        sh = { glyph = '', hl = 'MiniIconsGreen' },
        go = { glyph = '󰟓', hl = 'MiniIconsCyan' },
      },
      lsp = {},
      default = {},
    },
    config = function(_, opts)
      local icons = require('mini.icons')
      icons.setup(opts)
      -- Make mini.icons the global icon provider — replaces nvim-web-devicons
      icons.mock_nvim_web_devicons()
      -- Set up custom highlight colors matching Perfect Black palette
      vim.api.nvim_set_hl(0, 'MiniIconsAzure', { fg = '#70D7FF' })
      vim.api.nvim_set_hl(0, 'MiniIconsBlue', { fg = '#69AFFF' })
      vim.api.nvim_set_hl(0, 'MiniIconsCyan', { fg = '#70D7FF' })
      vim.api.nvim_set_hl(0, 'MiniIconsGreen', { fg = '#7FE3C2' })
      vim.api.nvim_set_hl(0, 'MiniIconsGrey', { fg = '#A9B9D6' })
      vim.api.nvim_set_hl(0, 'MiniIconsOrange', { fg = '#FF9E64' })
      vim.api.nvim_set_hl(0, 'MiniIconsPurple', { fg = '#C7A6FF' })
      vim.api.nvim_set_hl(0, 'MiniIconsRed', { fg = '#FF8FA3' })
      vim.api.nvim_set_hl(0, 'MiniIconsYellow', { fg = '#FFD166' })
    end,
  },
  -- Compatibility shim — plugins that require nvim-web-devicons will use mini.icons
  { 'nvim-tree/nvim-web-devicons', lazy = true, enabled = vim.g.have_nerd_font ~= false },

  -- ── Snacks (all features consolidated) ───────────────────────────────
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 900,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      dashboard = require('config.dashboard'),
      explorer = { enabled = false },
      picker = { enabled = false },
      notifier = { enabled = false },
      animate = { enabled = false },
      scroll = {
        enabled = true,
        animate = { duration = { step = 10, total = 100 } },
      },
      indent = {
        enabled = true,
        animate = { enabled = false },
        indent = { char = '▏', only_current = false, hl = 'SnacksIndent' },
        scope = { enabled = true, only_current = true, char = '▎', hl = 'SnacksIndentScope' },
        chunk = { enabled = true, only_current = true, hl = 'SnacksIndentScope',
          char = { corner_top = '╭', corner_bottom = '╰', horizontal = '─', vertical = '│', arrow = '>' } },
      },
      zen = {
        toggles = { dim = true, git_signs = false, mini_diff_signs = false, diagnostics = false },
        show = { statusline = false, tabline = false },
        win = { width = 90, backdrop = { transparent = false, blend = 40 } },
      },
      image = { enabled = true },
      terminal = {
        win = { position = 'bottom', height = 0.30, border = 'rounded', wo = { winbar = '  Terminal' } },
      },
      input = {
        enabled = true,
        icon = ui.icon('command') .. ' ',
        prompt_pos = 'title',
        win = {
          border = ui.border,
          width = 60,
          row = false,
          title_pos = 'center',
          wo = { winblend = ui.blend },
        },
      },
      styles = {
        notification = { border = ui.border, wo = { winblend = ui.blend, wrap = true } },
        notification_history = {
          position = 'bottom', height = 0.35, width = 0, border = 'none',
          wo = { wrap = true, winblend = 0, winbar = '  Notification history · q to close' },
        },
      },
    },
    keys = {
      { '<leader>ft', function()
        Snacks.terminal(nil, { cwd = require('config.project').root() })
      end, desc = 'Project terminal' },
      { '<leader>gL', function()
        require('config.pick').open('git_commits')
      end, desc = 'Git commit history' },
      { '<leader>n', function() require('config.notifications').history() end, desc = 'Notification history drawer' },
      { '<leader>un', function() require('config.notifications').dismiss() end, desc = 'Dismiss notifications' },
    },
  },

  -- ── Noice (command palette and popups) ───────────────────────────────
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {
      presets = { inc_rename = true, command_palette = true },
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
        signature = {
          enabled = true,
          auto_open = { enabled = false },
          view = 'signature',
        },
        hover = {
          enabled = true,
          silent = true,
          view = 'hover',
        },
      },
      notify = { enabled = false },
      cmdline = {
        format = {
          cmdline = { icon = ui.icon('command'), title = ' COMMAND ' },
          lua = { icon = ui.icon('lua'), title = ' LUA ' },
          search_down = { icon = ui.icon('search'), title = ' SEARCH FORWARD ' },
          search_up = { icon = ui.icon('search'), title = ' SEARCH BACKWARD ' },
          help = { icon = ui.icon('help'), title = ' HELP ' },
          filter = { icon = ui.icon('shell'), title = ' SHELL ' },
        },
      },
      views = {
        cmdline_popup = {
          win_options = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle' },
          position = { row = '38%', col = '50%' },
          size = { min_width = 50, width = 'auto', max_width = 80, height = 'auto' },
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 2 } },
        },
        popupmenu = {
          win_options = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,CursorLine:PmenuSel' },
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 2 } },
          size = { max_height = 12 },
          scrollbar = false,
        },
        cmdline_popupmenu = {
          position = 'auto',
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 2 } },
          win_options = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,CursorLine:PmenuSel' },
          size = { max_height = 12 },
          scrollbar = false,
        },
        hover = {
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 2 } },
          size = { max_width = 80, max_height = 24 },
          win_options = { wrap = true, linebreak = true, winblend = 0,
            winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle' },
          title = ' 󰈙 Documentation ',
          title_pos = 'center',
        },
        signature = {
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 2 } },
          size = { max_width = 80, max_height = 14 },
          win_options = { wrap = true, linebreak = true, winblend = 0,
            winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle' },
          title = ' 󰅩 Signature Help ',
          title_pos = 'center',
        },
        popup = {
          win_options = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder' },
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 2 } },
          size = { width = 76, height = 22 },
        },
        -- Mini notification-style messages at bottom-right
        mini = {
          win_options = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder' },
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' } },
          timeout = 3000,
        },
      },
      routes = {
        -- Hide "written" messages
        { filter = { event = 'msg_show', kind = '', find = 'written' }, opts = { skip = true } },
        -- Hide search count messages (we show them in statusline)
        { filter = { event = 'msg_show', kind = 'search_count' }, opts = { skip = true } },
        -- Send long messages to a split instead of blocking
        { filter = { event = 'msg_show', min_height = 10 }, view = 'split' },
      },
    },
  },

  -- ── Panel layout (Edgy) ──────────────────────────────────────────────
  {
    'folke/edgy.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
      local icon = ui.icon
      opts.animate = { enabled = false }
      opts.options = {
        left = { size = 28 },
        right = { size = 26 },
        bottom = { size = 12 },
        top = { size = 8 },
      }
      opts.left = {}
      opts.right = {
        { title = ' ' .. icon('symbols') .. '  SYMBOLS', ft = 'aerial', size = { width = 26 } },
      }
      opts.bottom = {
        { title = ' ' .. icon('terminal') .. '  TERMINAL', ft = 'snacks_terminal', size = { height = 0.30 },
          filter = function(_, win) return vim.api.nvim_win_get_config(win).relative == '' end },
        { title = ' ' .. icon('info') .. '  RESULTS', ft = 'qf', size = { height = 0.25 } },
        { title = ' ' .. icon('diagnostics') .. '  DIAGNOSTICS', ft = 'trouble', size = { height = 0.25 } },
        { title = ' ' .. icon('help') .. '  HELP', ft = 'help', size = { height = 0.35 } },
      }
      opts.top = {}
    end,
  },

  -- ── Which-Key (with group labels) ────────────────────────────────────
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'helix',
      delay = 180,
      icons = {
        breadcrumb = '»',
        separator = '│',
        group = ' ',
        mappings = false,
      },
      win = {
        border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
        padding = { 1, 2 },
        title = true,
        title_pos = 'center',
        wo = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle' },
      },
      layout = {
        align = 'center',
        spacing = 4,
      },
      spec = {
        { '<leader>a', group = ' AI / Copilot', icon = '' },
        { '<leader>f', group = ' Find', icon = '󰍉' },
        { '<leader>s', group = ' Search', icon = '' },
        { '<leader>c', group = ' Code', icon = '󰅩' },
        { '<leader>g', group = ' Git', icon = '󰊢' },
        { '<leader>u', group = ' Toggle', icon = '' },
        { '<leader>x', group = ' Trouble', icon = '󰅚' },
        { '<leader>b', group = ' Buffer', icon = '󰓩' },
        { '<leader>w', group = ' Window', icon = '' },
        { '<leader>q', group = ' Session', icon = '󰗈' },
        { '<leader>d', group = ' Debug', icon = '' },
        { '<leader>m', group = ' Markdown', icon = '󰍔' },
      },
    },
  },

  -- ── Trouble (diagnostics panel) ──────────────────────────────────────
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    opts = {
      modes = {
        symbols = { focus = true, auto_preview = false, win = { position = 'right', size = 34 } },
        diagnostics = { win = { position = 'bottom', size = 0.25 } },
      },
      icons = {
        indent = {
          top = '│ ',
          middle = '├╴',
          last = '└╴',
          fold_open = ' ',
          fold_closed = ' ',
          ws = '  ',
        },
      },
    },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Project diagnostics' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix diagnostics' },
    },
  },

  -- ── Gitsigns ─────────────────────────────────────────────────────────
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add          = { text = '▎' },
        change       = { text = '▎' },
        delete       = { text = '▁' },
        topdelete    = { text = '▔' },
        changedelete = { text = '▎' },
        untracked    = { text = '┆' },
      },
      signs_staged_enable = false,
      preview_config = { border = ui.border, style = 'minimal', relative = 'cursor', row = 0, col = 1 },
      current_line_blame = false,
      current_line_blame_opts = { virt_text = true, virt_text_pos = 'eol', delay = 500 },
      current_line_blame_formatter = '  <author>, <author_time:%R> · <summary>',
    },
    keys = {
      { '<leader>gb', '<cmd>Gitsigns toggle_current_line_blame<cr>', desc = 'Toggle git blame' },
      { '<leader>gp', '<cmd>Gitsigns preview_hunk<cr>', desc = 'Preview hunk' },
      { '<leader>gr', '<cmd>Gitsigns reset_hunk<cr>', desc = 'Reset hunk' },
      { '<leader>gs', '<cmd>Gitsigns stage_hunk<cr>', desc = 'Stage hunk' },
    },
  },

  -- ── Mini Notify (replaces Snacks notifier) ───────────────────────────
  {
    'nvim-mini/mini.notify',
    event = 'VeryLazy',
    config = function() require('config.notifications').setup() end,
  },

  -- ── Tiny Inline Diagnostic ───────────────────────────────────────────
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'minimal',
      options = {
        throttle = 80, show_source = { enabled = true },
        multilines = { enabled = true, always_show = false },
        show_all_diags_on_cursorline = true,
        enable_on_insert = false, enable_on_select = false,
      },
    },
  },
}
