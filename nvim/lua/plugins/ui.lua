-- ============================================================================
-- lua/plugins/ui.lua — THE ABSOLUTE UI (v5) — oxocarbon + Carbon Pulse
-- ============================================================================
-- SCOPE: visual layers ONLY. Does not touch the picker, LSP servers
-- (basedpyright/conform/nvim-lint — see plugins/python.lua), treesitter
-- config, or editing keymaps. Anything that *reads* LSP/treesitter data here
-- (breadcrumbs, rainbow delimiters, diagnostics counts) is display-only.
--
-- v5 = the Carbon Pulse refactor — one heartbeat for the whole UI:
--   · all hand-written animation moved into a real library, lua/carbon/
--       carbon/palette.lua   colors + MEMOIZED blend() + easing
--       carbon/pulse.lua     ★ single-clock tween engine: every animation
--                            shares ONE 30fps timer that stops when idle —
--                            v4 ran a separate timer + redraw per animation
--       carbon/reactive.lua  the living layer (below)
--   · MODE MORPH: the UI now *animates* between mode accents (150ms eased
--     cross-fade) instead of snapping — including the actual cursor block
--     (guicursor → CarbonCursor, tinted live per mode)
--   · TYPING HEAT (new, nobody has this): a keystroke-velocity meter — the
--     cursorline glow intensifies while you type fast and cools when you
--     pause, and lualine carries a live spark (▁▂▃▄▅▆▇█) that climbs from
--     gray to the mode accent while you're in flow
--   · yank pulse + living dashboard gradient now ride the same clock
--   · lualine's LSP-client readout is cached per buffer (recomputed only on
--     LspAttach/LspDetach instead of every statusline redraw)
--
-- Carried forward from v3/v4: ONE system per job (snacks owns notifier,
-- indent, explorer, dashboard, statuscolumn, scroll), everything lazy-loads
-- (defaults.lazy = true in config/lazy.lua), per-mode lualine theme,
-- "1337" dashboard, diagnostics float that names its source, bufferline
-- with cyan underline + pink modified dot.
--
-- KEYMAPS: unchanged. The only mapping this file has ever added is
-- <leader>un (dismiss notifications), kept exactly as-is.
-- ============================================================================

local C = require("carbon.palette").colors

return {

  -- ==========================================================================
  -- 1. COLORSCHEME — oxocarbon, then hand the visuals to Carbon Reactive
  -- ==========================================================================
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = false,
    priority = 1000, -- load-order: must beat all UI plugins so their highlight
    -- links resolve against oxocarbon, not the default scheme
    config = function()
      vim.opt.background = "dark" -- oxocarbon reads &background; set it first

      -- global visual polish (options only, no behavior change)
      vim.opt.cursorline = true
      vim.opt.pumblend = 10 -- slightly translucent completion menu
      vim.opt.winblend = 0

      vim.cmd.colorscheme("oxocarbon")

      -- static accents + mode morph + typing heat + yank pulse + living
      -- dashboard — all of it lives in lua/carbon/reactive.lua now
      require("carbon.reactive").setup()
    end,
  },

  -- LazyVim re-applies its own colorscheme post-startup; override or it
  -- clobbers oxocarbon with tokyonight.
  { "LazyVim/LazyVim", opts = { colorscheme = "oxocarbon" } },

  -- Diagnostics DESIGN (display-only, merged into LazyVim's diagnostics
  -- opts): rounded float panel that always names its source — with three
  -- producers on Python buffers (basedpyright, flake8, mypy) you want to
  -- know who's talking. Zero changes to how diagnostics are produced.
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        severity_sort = true,
        float = { border = "rounded", source = true },
      },
    },
  },

  -- ==========================================================================
  -- 2. ICONS — nvim-web-devicons everywhere
  -- ==========================================================================
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = { default = true, color_icons = true },
  },

  -- ==========================================================================
  -- 3. STATUSLINE — lualine: bubbles, per-mode Carbon theme, typing spark
  -- ==========================================================================
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- opts as a function returning a fresh table => fully REPLACES LazyVim's
    -- default lualine config instead of deep-merging with it
    opts = function()
      -- Attached-LSP readout, CACHED per buffer: v4 walked the client list
      -- and built a fresh string on every statusline redraw; now it's a
      -- table lookup, recomputed only when a client attaches/detaches.
      local lsp_cache = {}
      vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
        group = vim.api.nvim_create_augroup("CarbonLualineLsp", { clear = true }),
        callback = function(ev)
          lsp_cache[ev.buf] = nil
        end,
      })
      vim.api.nvim_create_autocmd("BufDelete", {
        group = "CarbonLualineLsp",
        callback = function(ev)
          lsp_cache[ev.buf] = nil
        end,
      })
      local function lsp_clients()
        local buf = vim.api.nvim_get_current_buf()
        local cached = lsp_cache[buf]
        if cached then
          return cached
        end
        local names = {}
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
          names[#names + 1] = c.name
        end
        cached = #names > 0 and (" " .. table.concat(names, " · ")) or ""
        lsp_cache[buf] = cached
        return cached
      end

      -- Carbon per-mode statusline theme: the a/z bubbles recolor with the
      -- SAME accent map as the reactive engine (normal=purple, insert=cyan,
      -- visual=pink, replace=mint, cmd=blue, term=green), so the statusline
      -- and the rest of the UI breathe together.
      local function mode_theme(accent)
        return {
          a = { fg = C.bg, bg = accent, gui = "bold" },
          b = { fg = C.white, bg = C.bg2 },
          c = { fg = C.gray, bg = C.bg },
          x = { fg = C.gray, bg = C.bg },
          y = { fg = C.white, bg = C.bg2 },
          z = { fg = C.bg, bg = accent, gui = "bold" },
        }
      end

      return {
        options = {
          theme = {
            normal = mode_theme(C.purple),
            insert = mode_theme(C.cyan),
            visual = mode_theme(C.pink),
            replace = mode_theme(C.mint),
            command = mode_theme(C.blue),
            terminal = mode_theme(C.green),
            inactive = {
              a = { fg = C.gray, bg = C.bg },
              b = { fg = C.gray, bg = C.bg },
              c = { fg = C.gray, bg = C.bg },
            },
          },
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" }, -- rounded bubbles
          disabled_filetypes = { statusline = { "snacks_dashboard", "alpha" } },
          refresh = { statusline = 100 }, -- keeps the typing spark fluid
        },
        sections = {
          lualine_a = { { "mode", separator = { left = "", right = "" } } },
          lualine_b = {
            { "branch", icon = "" },
            {
              "diff",
              symbols = { added = " ", modified = " ", removed = " " },
            },
          },
          lualine_c = {
            { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[scratch]" } },
          },
          lualine_x = {
            -- noice statusline components: showcmd + macro recording indicator
            {
              function() return require("noice").api.status.command.get() end,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.command.has()
              end,
              color = { fg = C.purple },
            },
            {
              function() return require("noice").api.status.mode.get() end, -- "recording @q"
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = { fg = C.pink },
            },
            {
              "diagnostics",
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            },
            { lsp_clients, color = { fg = C.gray } },
            -- ★ the typing-heat spark: gray "▁" at rest, climbs the bar and
            -- tints toward the mode accent while you're in flow
            {
              function() return require("carbon.reactive").heat_spark() end,
              color = "CarbonPulseHeat",
              padding = { left = 1, right = 1 },
            },
          },
          lualine_y = { { "filetype", icon_only = false }, "progress" },
          lualine_z = { { "location", separator = { left = "", right = "" } } },
        },
        extensions = { "lazy", "quickfix", "man" },
      }
    end,
  },

  -- ==========================================================================
  -- 4. WINBAR BREADCRUMBS — dropbar.nvim
  -- ==========================================================================
  -- Sticky path + symbol trail at the top of each window. Reads LSP/treesitter
  -- symbols for DISPLAY only — registers no handlers, changes no config.
  -- Requires nvim 0.10+. Fully mouse/keyboard-optional; adds no keymaps.
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      bar = { update_debounce = 100 },
      icons = { ui = { bar = { separator = "  " } } },
    },
  },

  -- ==========================================================================
  -- 5. SNACKS — dashboard, notifier, indent guides, explorer styling,
  --    smooth scroll, statuscolumn (ONE plugin owns all of these)
  -- ==========================================================================
  {
    "folke/snacks.nvim",
    opts = {
      -- indent guides + animated scope (SnacksIndent color is static Carbon;
      -- the scope line is re-tinted per mode by the reactive engine)
      indent = {
        enabled = true,
        indent = { char = "▏" },
        scope = { enabled = true, char = "▏" },
      },
      -- notifications (noice routes through vim.notify; one system)
      notifier = {
        enabled = true,
        timeout = 3000,
        top_down = false, -- rise from the bottom
        style = "compact",
      },
      scroll = { enabled = true }, -- buttery smooth scrolling (visual only)
      statuscolumn = {
        enabled = true, -- unified sign/number/fold column, no behavior change
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = { open = true, git_hl = true },
      },
      -- explorer: LazyVim's default (snacks picker layout, <leader>e).
      -- Styled by the SnacksPicker* groups in carbon/reactive.lua; show
      -- dotfiles softly dimmed instead of hidden.
      picker = {
        sources = {
          explorer = {
            hidden = true,
            layout = { preset = "sidebar", preview = false },
          },
        },
      },
      dashboard = {
        preset = {
          -- "1337" — this IS the 1337-session config; the living-gradient
          -- tween from the reactive engine plays across it
          header = [[
 ██╗██████╗ ██████╗ ███████╗
███║╚════██╗╚════██╗╚════██║
╚██║ █████╔╝ █████╔╝    ██╔╝
 ██║ ╚═══██╗ ╚═══██╗   ██╔╝
 ██║██████╔╝██████╔╝   ██║
 ╚═╝╚═════╝ ╚═════╝    ╚═╝
    s  e  s  s  i  o  n]],
          keys = {
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "g", desc = "Grep Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 2 },
          { section = "recent_files", icon = " ", title = "Recent", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },

  -- ==========================================================================
  -- 6. BUFFERLINE — slant separators, ordinal numbers
  -- ==========================================================================
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        separator_style = "slant",
        numbers = "ordinal",
        diagnostics = "nvim_lsp", -- display-only readout
        diagnostics_indicator = function(count) return " " .. count end,
        always_show_bufferline = false,
        indicator = { style = "underline" },
        offsets = {
          {
            filetype = "snacks_layout_box", -- the snacks explorer sidebar
            text = " Explorer",
            highlight = "Directory",
            text_align = "left",
            separator = true,
          },
        },
      },
      -- Carbon touches: selected buffer bold with a cyan underline
      -- indicator; modified dot in pink (same pink as the yank pulse)
      highlights = {
        buffer_selected = { bold = true, italic = false },
        indicator_selected = { fg = C.cyan, sp = C.cyan, underline = true },
        modified = { fg = C.pink },
        modified_visible = { fg = C.pink },
        modified_selected = { fg = C.pink },
      },
    },
  },

  -- ==========================================================================
  -- 7. CMDLINE / MESSAGES / LSP DOC RENDERING — noice.nvim
  -- ==========================================================================
  -- CAVEAT (honest one): noice restyles LSP hover/signature by swapping the
  -- markdown RENDERING path — your servers, conform, and nvim-lint are
  -- untouched; only the output windows change. Set lsp.override entries to
  -- false for zero interception. Notifications go through vim.notify →
  -- snacks.notifier (one notification system).
  {
    "folke/noice.nvim",
    event = "VeryLazy", -- load-order: after colorscheme (priority 1000) so
    -- highlights link right. Do NOT make this lazy=false.
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      cmdline = {
        view = "cmdline_popup", -- floating centered cmdline
        format = {
          cmdline = { icon = "" },
          search_down = { icon = " " },
          search_up = { icon = " " },
          lua = { icon = "" },
          help = { icon = "󰋖" },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        progress = { enabled = true }, -- mini LSP progress spinner, bottom-right
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true, -- rounded borders on hover/signature docs
        inc_rename = false,
      },
      views = {
        cmdline_popup = {
          position = { row = "35%", col = "50%" },
          size = { width = 60 },
          border = { style = "rounded" },
        },
        mini = { win_options = { winblend = 0 } },
      },
      routes = {
        -- declutter: file-written + search-count messages go to the mini view
        { filter = { event = "msg_show", find = "%d+L, %d+B" }, view = "mini" },
        { filter = { event = "msg_show", find = "^[/?]" }, skip = true },
      },
    },
    -- The one keymap this file has ever added, kept as-is.
    keys = {
      { "<leader>un", "<cmd>Noice dismiss<cr>", desc = "Dismiss notifications (noice)" },
    },
  },

  -- ==========================================================================
  -- 8. RAINBOW DELIMITERS — nested brackets in Carbon accents
  -- ==========================================================================
  -- Uses treesitter parse trees for DISPLAY only; does not touch your
  -- nvim-treesitter config or parsers.
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- Carbon-ordered rainbow: cyan → purple → pink → blue → mint
      for i, color in ipairs({ C.cyan, C.purple, C.pink, C.blue, C.mint }) do
        vim.api.nvim_set_hl(0, "RainbowDelimiterCarbon" .. i, { fg = color })
      end
      vim.g.rainbow_delimiters = {
        highlight = {
          "RainbowDelimiterCarbon1", "RainbowDelimiterCarbon2", "RainbowDelimiterCarbon3",
          "RainbowDelimiterCarbon4", "RainbowDelimiterCarbon5",
        },
      }
    end,
  },

  -- ==========================================================================
  -- 9. INLINE COLOR SWATCHES — hex/rgb/hsl rendered as their color
  -- ==========================================================================
  {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      render = "virtual", -- ● swatch next to the value; "background" also nice
      virtual_symbol = "●",
      enable_tailwind = true,
    },
  },

  -- ==========================================================================
  -- 10. PRETTY MARKDOWN — headings, tables, checkboxes rendered in-buffer
  -- ==========================================================================
  -- Display-only treesitter consumer; raw text returns the moment you edit
  -- the line. No keymaps, no behavior change.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      heading = { icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " } },
      code = { style = "full", border = "thin" },
      bullet = { icons = { "●", "○", "◆", "◇" } },
    },
  },

  -- ==========================================================================
  -- 11. CURSOR TRAIL (pure flair) — smear-cursor
  -- ==========================================================================
  -- GPU-shader-style smear when the cursor jumps. 100% cosmetic; if it's too
  -- much, delete this block — nothing depends on it.
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      cursor_color = C.cyan,
      stiffness = 0.8, -- snappy, not floaty
      trailing_stiffness = 0.5,
      distance_stop_animating = 0.5,
    },
  },
}

-- ============================================================================
-- PLUGINS THIS FILE ADDS / OVERRIDES (diff against stock LazyVim)
-- ============================================================================
-- NEW (not in stock LazyVim):
--   nyoom-engineering/oxocarbon.nvim        colorscheme
--   Bekaboo/dropbar.nvim                    winbar breadcrumbs (needs nvim 0.10+)
--   HiPhish/rainbow-delimiters.nvim         Carbon rainbow brackets
--   brenoprata10/nvim-highlight-colors      inline color swatches
--   MeanderingProgrammer/render-markdown.nvim  pretty markdown rendering
--   sphamba/smear-cursor.nvim               cursor trail (pure flair, deletable)
-- OVERRIDDEN (ship with LazyVim; restyled here):
--   LazyVim/LazyVim                         colorscheme = "oxocarbon"
--   nvim-lualine/lualine.nvim               bubbles, per-mode theme, cached
--                                           LSP readout, typing-heat spark
--   folke/snacks.nvim                       dashboard + notifier + indent +
--                                           explorer styling + smooth scroll +
--                                           statuscolumn — ONE system per job
--   akinsho/bufferline.nvim                 slant + ordinal numbers
--   folke/noice.nvim                        floating cmdline, LSP doc borders,
--                                           progress spinner
--                                           + the one keymap: <leader>un
--   nvim-tree/nvim-web-devicons             default icons on
--
-- HAND-WRITTEN (no plugin — unique to this config, in lua/carbon/):
--   ★ Carbon Pulse    single-clock tween engine — every animation shares one
--                     30fps timer that stops the instant nothing animates
--   ★ Carbon Reactive mode-morph cross-fades · typing-heat glow + statusline
--                     spark · fading yank pulse · living dashboard gradient ·
--                     mode-tinted cursor block · inactive-window focus dim
-- ============================================================================
