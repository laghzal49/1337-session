-- Unified UI layer: Snacks (all opts), Noice, Edgy, Which-Key, Trouble,
-- Gitsigns, devicons, Mini Notify, Tiny Inline Diagnostic.
-- All Snacks opts consolidated here — no scattered overrides.
local ui = require('config.ui')

local function refresh_panel_icons()
  if _G.Snacks and Snacks.config then
    local picker = Snacks.config.picker
    if picker then
      if picker.sources and picker.sources.explorer then
        picker.sources.explorer.title = ' ' .. ui.icon('folder') .. ' Explorer '
      end
      if picker.icons and picker.icons.files then
        picker.icons.files.dir = vim.g.have_nerd_font == false and 'D ' or ui.icon('folder') .. ' '
        picker.icons.files.dir_open = vim.g.have_nerd_font == false and 'D/ ' or ui.icon('folder_open') .. ' '
        picker.icons.files.file = vim.g.have_nerd_font == false and 'F ' or ui.icon('file') .. ' '
      end
    end
    if Snacks.config.terminal and Snacks.config.terminal.win then
      Snacks.config.terminal.win.title = ' ' .. ui.icon('terminal') .. ' Terminal '
    end
  end
  local noice = package.loaded['noice.config']
  local hover = noice and noice.options and noice.options.views and noice.options.views.hover
  if hover and hover.border and hover.border.text then
    hover.border.text.top = ' ' .. ui.icon('read') .. ' Documentation '
  end
  -- Noice can still be waiting for VeryLazy when the preset changes.
  local lazy_config = package.loaded['lazy.core.config']
  local spec = lazy_config and lazy_config.plugins and lazy_config.plugins['noice.nvim']
  local deferred = spec and type(spec.opts) == 'table' and spec.opts.views and spec.opts.views.hover
  if deferred and deferred.border and deferred.border.text then
    deferred.border.text.top = ' ' .. ui.icon('read') .. ' Documentation '
  end
end

return {
  -- ── Icons (mini.icons — best-in-class icon provider) ─────────────────
  {
    'nvim-mini/mini.icons',
    lazy = false,
    priority = 1100,
    opts = {
      style = vim.g.have_nerd_font == false and 'ascii' or 'glyph',
      -- Use the Perfect Black palette for file type icon colors
      file = {
        ['.gitignore'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
        ['Makefile'] = { glyph = '󱁤', hl = 'MiniIconsYellow' },
        ['Dockerfile'] = { glyph = '󰡨', hl = 'MiniIconsCyan' },
        ['docker-compose.yml'] = { glyph = '󰡨', hl = 'MiniIconsCyan' },
      },
      filetype = {
        python = { glyph = '󰌠', hl = 'MiniIconsYellow' },
        lua = { glyph = '󰢱', hl = 'MiniIconsBlue' },
        c = { glyph = '󰙱', hl = 'MiniIconsCyan' },
        cpp = { glyph = '󰙲', hl = 'MiniIconsCyan' },
        rust = { glyph = '󱘗', hl = 'MiniIconsOrange' },
        javascript = { glyph = '󰌞', hl = 'MiniIconsYellow' },
        typescript = { glyph = '󰛦', hl = 'MiniIconsBlue' },
        markdown = { glyph = '󰍔', hl = 'MiniIconsBlue' },
        json = { glyph = '󰘦', hl = 'MiniIconsYellow' },
        yaml = { glyph = '', hl = 'MiniIconsAzure' },
        toml = { glyph = '', hl = 'MiniIconsAzure' },
        html = { glyph = '󰌝', hl = 'MiniIconsOrange' },
        css = { glyph = '󰌜', hl = 'MiniIconsBlue' },
        sh = { glyph = '', hl = 'MiniIconsGreen' },
        go = { glyph = '󰟓', hl = 'MiniIconsCyan' },
      },
      lsp = {},
      default = { directory = { glyph = ui.icon('folder'), hl = 'MiniIconsBlue' } },
    },
    config = function(_, opts)
      local icons = require('mini.icons')
      -- Built-in special directories (nvim, .git, Downloads...) otherwise keep
      -- unrelated green/orange colors even when the default folder is blue.
      opts.directory = opts.directory or {}
      for _, name in ipairs(icons.list('directory')) do
        opts.directory[name] = vim.tbl_extend('force', opts.directory[name] or {}, { hl = 'MiniIconsBlue' })
      end
      icons.setup(opts)
      -- Make mini.icons the global icon provider — replaces nvim-web-devicons
      icons.mock_nvim_web_devicons()
      for name, color in pairs(require('config.palette').icons) do
        vim.api.nvim_set_hl(0, 'MiniIcons' .. name, { fg = color })
      end
    end,
  },

  -- ── Snacks (all features consolidated) ───────────────────────────────
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 1000,
    init = function()
      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('BlackPanelIcons', { clear = true }),
        pattern = 'BlackUIPresetChanged',
        callback = refresh_panel_icons,
      })
    end,
    opts = {
      bigfile = { enabled = true, size = 1024 * 1024,
        setup = function(ctx) require('config.performance').guard(ctx.buf) end },
      quickfile = { enabled = true },
      dashboard = require('config.dashboard'),
      explorer = {
        enabled = true,
        replace_netrw = true,
      },
      picker = {
        enabled = true,
        formatters = { file = { git_status_hl = false } },
        layout = { preset = function() return vim.o.columns >= 110 and 'default' or 'vertical' end },
        layouts = {
          default = { layout = {
            box = 'horizontal', width = 0.88, min_width = 0, height = 0.78,
            {
              box = 'vertical', border = true, title = ' {title} {live} {flags} ',
              footer = ' Enter open · Tab mark · Alt-P preview · Esc close ',
              { win = 'input', height = 1, border = 'bottom' },
              { win = 'list', border = 'none' },
            },
            { win = 'preview', title = ' {preview:Preview} ', border = true, width = 0.36 },
          } },
          vertical = { layout = {
            box = 'vertical', border = true, width = 0.92, min_width = 0,
            height = 0.84, min_height = 0, title = ' {title} {live} {flags} ',
            footer = ' Enter open · Esc close ',
            { win = 'input', height = 1, border = 'bottom' },
            { win = 'list', border = 'none' },
            { win = 'preview', title = ' {preview:Preview} ', height = 0.36, border = 'top' },
          } },
        },
        icons = { files = {
          dir = vim.g.have_nerd_font == false and 'D ' or ui.icon('folder') .. ' ',
          dir_open = vim.g.have_nerd_font == false and 'D/ ' or ui.icon('folder_open') .. ' ',
          file = vim.g.have_nerd_font == false and 'F ' or ui.icon('file') .. ' ',
        } },
        win = { input = { keys = { ['<Esc>'] = { 'close', mode = { 'n', 'i' } } } } },
        sources = {
          explorer = {
            title = ' ' .. ui.icon('folder') .. ' Explorer ',
            layout = function()
              if vim.o.columns < 80 then
                return { preset = 'ivy_split', preview = false,
                  layout = { height = 0.35, min_height = 4 } }
              end
              return { preset = 'sidebar', preview = false,
                layout = { width = math.min(34, math.floor(vim.o.columns * 0.3)), min_width = 0 } }
            end,
          },
        },
      },
      notifier = { enabled = false },
      animate = { enabled = true, fps = 60 },
      scroll = {
        enabled = true,
        animate = { duration = { step = 6, total = 80 }, easing = 'outQuad' },
        animate_repeat = { delay = 100, duration = { step = 3, total = 40 }, easing = 'linear' },
        filter = function(buf)
          return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false
            and vim.bo[buf].buftype ~= 'terminal'
            and not vim.b[buf].bigfile and not vim.b[buf].performance_guard
        end,
      },
      indent = {
        enabled = true,
        animate = { enabled = false },
        indent = { char = '▏', only_current = false, hl = 'SnacksIndent' },
        scope = { enabled = true, only_current = true, char = '▎', hl = 'SnacksIndentScope' },
        chunk = { enabled = false, only_current = true, hl = 'SnacksIndentScope',
          char = { corner_top = '╭', corner_bottom = '╰', horizontal = '─', vertical = '│', arrow = '>' } },
      },
      zen = {
        toggles = { dim = true, git_signs = false, mini_diff_signs = false, diagnostics = false },
        show = { statusline = false, tabline = false },
        win = { width = 90, backdrop = { transparent = false, blend = 40 } },
      },
      terminal = {
        win = {
          position = 'float',
          border = 'rounded',
          width = 0.85,
          height = 0.80,
          backdrop = 60,
          title = ' ' .. ui.icon('terminal') .. ' Terminal ',
          title_pos = 'center',
          wo = { number = false, relativenumber = false, signcolumn = 'no',
            winhighlight = vim.g.black_color_style == 'electrovoid'
              and 'Normal:SnacksTerminal,NormalFloat:SnacksTerminal' or nil },
          keys = { term_normal = false }, -- Existing EscEsc owns terminal-mode exit.
        },
      },
      input = {
        enabled = true,
        icon = ui.icon('command') .. ' ',
        icon_pos = 'title',
        expand = false,
        prompt_pos = 'title',
        win = {
          border = ui.border,
          width = function() return math.max(1, math.min(60, vim.o.columns - 6)) end,
          row = false,
          title_pos = 'left',
          footer = { { ' Enter confirm · Esc cancel ', 'BlackPopupHint' } },
          footer_pos = 'right',
          wo = { winblend = ui.blend },
          keys = { i_esc = { '<Esc>', { 'cmp_close', 'cancel' }, mode = 'i', expr = true } },
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
        require('config.terminal').toggle()
      end, desc = 'Terminal' },
      { '<leader>gL', function()
        require('config.pick').open('git_commits')
      end, desc = 'History' },
      { '<leader>n', function() require('config.notifications').history() end, desc = 'Notifications' },
      { '<leader>un', function() require('config.notifications').dismiss() end, desc = 'Dismiss Notices' },
    },
  },

  -- ── Noice (command palette and popups) ───────────────────────────────
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    config = function(_, opts)
      require('noice').setup(opts)
      vim.api.nvim_create_autocmd('VimResized', {
        group = vim.api.nvim_create_augroup('BlackNoiceLayout', { clear = true }),
        callback = vim.schedule_wrap(function()
          -- The pinned Noice/Nui versions do not reflow mounted views on resize.
          -- Reuse their layout methods so messages and command text stay intact.
          local router = package.loaded['noice.message.router']
          if not router then return end
          for view in pairs(router.get_views()) do
            local popup = view.view or view -- Mini messages own a child Nui view.
            if popup.is_mounted and popup:is_mounted() then
              popup:check_options()
              popup:update_layout()
            end
          end
        end),
      })
    end,
    opts = {
      popupmenu = { enabled = false }, -- Blink owns command suggestions; one menu.
      presets = { inc_rename = true, command_palette = true },
      lsp = {
        progress = { enabled = false }, -- The statusline owns LSP progress.
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
        -- Blink owns automatic signature help.
        signature = { enabled = false },
        -- We handle hover manually via keybind; noice should not intercept it
        hover = { enabled = false },
      },
      notify = { enabled = false },
      cmdline = {
        format = {
          cmdline = { icon = ui.icon('command'), title = ' Command ' },
          lua = { icon = ui.icon('lua'), title = ' LUA ' },
          search_down = { icon = ui.icon('search'), title = ' Search forward ' },
          search_up = { icon = ui.icon('search'), title = ' Search backward ' },
          help = { icon = ui.icon('help'), title = ' Help ' },
          filter = { icon = ui.icon('shell'), title = ' Shell ' },
        },
      },
      views = {
        cmdline_popup = {
          win_options = { winblend = 0, winhighlight = 'Normal:BlackPrompt,FloatBorder:BlackPromptBorder,FloatTitle:BlackPromptTitle' },
          position = { row = '30%', col = '50%' },
          size = { width = 'auto', min_width = 28, height = 1 },
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 0, 1 },
            text = { top_align='left', bottom=' Enter apply · Esc close ', bottom_align='right' } },
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
          view = 'popup',
          border = {
            style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
            text = { top = ' ' .. ui.icon('read') .. ' Documentation ', top_align = 'center' },
            padding = { 0, 2 },
          },
          size = { max_width = 80, max_height = 24 },
          win_options = { wrap = true, linebreak = true, winblend = 0,
            winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle' },
        },
        popup = {
          win_options = { winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder' },
          border = { style = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }, padding = { 1, 2 },
            text = { top=' Messages ',top_align='left',bottom=' q close ',bottom_align='right' } },
          size = { width = '75%', height = '60%' },
        },
        -- Mini notification-style messages at bottom-right
        mini = {
          win_options = { wrap = true, linebreak = true, winblend = 0, winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder' },
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
    opts = function() return require('config.black_deck').options() end,
    config = function(_, opts)
      require('which-key').setup(opts)
      require('config.black_deck').setup()
    end,
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
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Project Diagnostics' },
      { '<leader>xw', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Workspace Diagnostics' },
      { '<leader>xd', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix' },
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
      { ']g', function() require('gitsigns').next_hunk() end, desc = 'Next git hunk' },
      { '[g', function() require('gitsigns').prev_hunk() end, desc = 'Prev git hunk' },
      { '<leader>gb', '<cmd>Gitsigns toggle_current_line_blame<cr>', desc = 'Blame' },
      { '<leader>gB', function() require('gitsigns').blame_line({ full = true }) end, desc = 'Blame Details' },
      { '<leader>gp', function() require('gitsigns').preview_hunk() end, desc = 'Preview hunk' },
      { '<leader>gr', function() require('gitsigns').reset_hunk() end, desc = 'Reset hunk' },
      { '<leader>gs', function() require('gitsigns').stage_hunk() end, desc = 'Stage hunk' },
      { '<leader>gS', function() require('gitsigns').stage_buffer() end, desc = 'Stage buffer' },
      { '<leader>gR', function() require('gitsigns').reset_buffer() end, desc = 'Reset buffer' },
      { '<leader>gd', function() require('gitsigns').diffthis() end, desc = 'Diff' },
      { 'ih', function() require('gitsigns').select_hunk() end, mode = { 'o', 'x' }, desc = 'Inner git hunk' },
      { 'ah', function() require('gitsigns').select_hunk() end, mode = { 'o', 'x' }, desc = 'Around git hunk' },
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
        show_code = true, use_icons_from_diagnostic = true,
        overflow = { mode = 'wrap', padding = 2 },
        multilines = { enabled = true, always_show = false },
        show_all_diags_on_cursorline = true,
        enable_on_insert = false, enable_on_select = false,
      },
    },
  },
}
