-- Unified UI layer: Snacks (all opts), Noice, Edgy, Which-Key, Trouble,
-- Gitsigns, devicons, Mini Notify, Tiny Inline Diagnostic.
-- All Snacks opts consolidated here — no scattered overrides.
local ui = require('config.ui')

return {
  -- ── Icons ────────────────────────────────────────────────────────────
  {
    'nvim-tree/nvim-web-devicons',
    lazy = false,
    priority = 1000,
    opts = {
      default = true, color_icons = false, strict = true,
      override = {
        default_icon = { icon = '󰈚', color = '#A9B9D6', cterm_color = '248', name = 'Default' },
      },
      override_by_extension = {
        py = { icon = '󰌠', name = 'Python', color = '#7FE3C2' },
        lua = { icon = '󰢱', name = 'Lua', color = '#C7A6FF' },
        c = { icon = '', name = 'C', color = '#70D7FF' },
        cpp = { icon = '', name = 'Cpp', color = '#70D7FF' },
        json = { icon = '', name = 'Json', color = '#FFD166' },
        md = { icon = '', name = 'Markdown', color = '#69AFFF' },
        sh = { icon = '', name = 'Shell', color = '#B8E986' },
      },
    },
  },

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
      scroll = { enabled = false },
      indent = {
        enabled = true,
        animate = { enabled = false },
        indent = { char = '│', only_current = true },
        scope = { enabled = true, only_current = true, char = '│' },
      },
      zen = {
        toggles = { dim = false, git_signs = false, mini_diff_signs = false },
        show = { statusline = true, tabline = false },
        win = { width = 100, backdrop = { transparent = false, blend = 0 } },
      },
      terminal = {
        win = { position = 'bottom', height = 0.30, border = 'rounded', wo = { winbar = '  Terminal' } },
      },
      input = {
        enabled = true,
        icon = ' ',
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
        signature = { enabled = true, auto_open = { enabled = false } },
      },
      notify = { enabled = false },
      cmdline = {
        format = {
          cmdline = { icon = '', title = ' COMMAND ' },
          lua = { icon = '󰢱', title = ' LUA ' },
          search_down = { icon = '󰍉', title = ' SEARCH FORWARD ' },
          search_up = { icon = '󰍉', title = ' SEARCH BACKWARD ' },
          help = { icon = '󰋖', title = ' HELP ' },
          filter = { icon = '󰞷', title = ' SHELL ' },
        },
      },
      views = {
        cmdline_popup = {
          win_options = { winblend = ui.blend },
          position = { row = '50%', col = '50%' },
          size = { min_width = 46, width = 'auto', max_width = 72, height = 'auto' },
          border = { style = 'rounded', padding = { 0, 2 } },
        },
        popupmenu = {
          win_options = { winblend = ui.blend },
          border = { style = 'rounded', padding = { 0, 2 } },
          size = { max_height = 10 },
          scrollbar = true,
        },
        cmdline_popupmenu = {
          position = 'auto',
          border = { style = 'rounded', padding = { 0, 2 } },
          win_options = { winblend = ui.blend },
          size = { max_height = 10 },
          scrollbar = true,
        },
        hover = {
          border = { style = 'rounded', padding = { 0, 2 } },
          size = { max_width = ui.max_width, max_height = ui.max_height },
          win_options = { wrap = true, linebreak = true, winblend = ui.blend,
            winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle' },
        },
        popup = {
          win_options = { winblend = ui.blend },
          border = { style = ui.border, padding = { 0, 2 } },
          size = { width = ui.max_width, height = ui.max_height },
        },
      },
    },
  },

  -- ── Panel layout (Edgy) ──────────────────────────────────────────────
  {
    'folke/edgy.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
      opts.animate = { enabled = false }
      opts.options = {
        left = { size = 28 },
        right = { size = 26 },
        bottom = { size = 12 },
        top = { size = 8 },
      }
      opts.left = {}
      opts.right = {
        { title = ' 󰅩  SYMBOLS', ft = 'aerial', size = { width = 26 } },
      }
      opts.bottom = {
        { title = '   TERMINAL', ft = 'snacks_terminal', size = { height = 0.30 },
          filter = function(_, win) return vim.api.nvim_win_get_config(win).relative == '' end },
        { title = ' 󰒡  RESULTS', ft = 'qf', size = { height = 0.25 } },
        { title = ' 󰅚  DIAGNOSTICS', ft = 'trouble', size = { height = 0.25 } },
        { title = ' 󰋖  HELP', ft = 'help', size = { height = 0.35 } },
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
      delay = 200,
      win = { border = ui.border, padding = { 0, 1 }, wo = { winblend = ui.blend } },
      spec = {
        { '<leader>a', group = 'AI / Copilot' },
        { '<leader>f', group = 'Find' },
        { '<leader>s', group = 'Search' },
        { '<leader>c', group = 'Code' },
        { '<leader>g', group = 'Git' },
        { '<leader>u', group = 'Toggle' },
        { '<leader>x', group = 'Trouble' },
        { '<leader>b', group = 'Buffer' },
        { '<leader>w', group = 'Window' },
        { '<leader>q', group = 'Session' },
        { '<leader>d', group = 'Debug' },
      },
    },
  },

  -- ── Trouble (diagnostics panel) ──────────────────────────────────────
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    opts = {
      modes = {
        symbols = { focus = true, auto_preview = false, win = { position = 'right', size = 32 } },
        diagnostics = { win = { position = 'bottom', size = 0.25 } },
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
