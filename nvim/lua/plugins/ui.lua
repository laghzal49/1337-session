-- ============================================================================
-- lua/plugins/ui.lua — MAX visual overhaul built around oxocarbon (v3)
-- ============================================================================
-- SCOPE: visual layers ONLY. Does not touch the picker, LSP servers
-- (basedpyright/conform/nvim-lint — see plugins/python.lua), treesitter
-- config, or editing keymaps. Anything that *reads* LSP/treesitter data here
-- (breadcrumbs, rainbow delimiters, diagnostics counts) is display-only.
--
-- v3 = conflict-free + performance pass:
--   ONE system per job. LazyVim already ships snacks (notifier, indent,
--   explorer, dashboard, statuscolumn, scroll) — v2 duplicated three of
--   those with extra plugins (nvim-notify, neo-tree, indent-blankline).
--   All three are gone; snacks owns those layers now, restyled in Carbon.
--   Every remaining custom plugin declares a lazy trigger (event/ft/cmd),
--   and lua/config/lazy.lua sets defaults.lazy = true, so nothing here
--   loads at startup except the colorscheme.
-- ============================================================================

-- IBM Carbon accent palette (oxocarbon), reused across every layer below.
local carbon = {
  bg = "#161616",
  bg2 = "#262626",
  gray = "#525252",
  cyan = "#3ddbd9",
  blue = "#78a9ff",
  purple = "#be95ff",
  pink = "#ff7eb6",
  mint = "#08bdba",
  green = "#42be65",
  white = "#f2f4f8",
}

return {

  -- ==========================================================================
  -- 1. COLORSCHEME — oxocarbon + Carbon accent layer for every plugin below
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
      vim.opt.fillchars:append({ eob = " " }) -- hide ~ on empty lines

      vim.cmd.colorscheme("oxocarbon")

      -- Accent layer, re-applied on every (re)load of oxocarbon so plugin
      -- groups defined later still land on Carbon colors.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "oxocarbon",
        group = vim.api.nvim_create_augroup("OxocarbonAccents", { clear = true }),
        callback = function()
          local hl = function(g, o) vim.api.nvim_set_hl(0, g, o) end

          -- floats: soft dark panels, Carbon-gray borders
          hl("NormalFloat", { bg = carbon.bg })
          hl("FloatBorder", { fg = carbon.gray, bg = carbon.bg })
          hl("FloatTitle", { fg = carbon.cyan, bg = carbon.bg, bold = true })

          -- indent guides (snacks.indent — no separate plugin)
          hl("SnacksIndent", { fg = carbon.bg2, nocombine = true })
          hl("SnacksIndentScope", { fg = carbon.cyan, nocombine = true })

          -- notifications (snacks.notifier — no separate plugin)
          hl("SnacksNotifierBorderInfo", { fg = carbon.cyan, bg = carbon.bg })
          hl("SnacksNotifierBorderWarn", { fg = carbon.pink, bg = carbon.bg })
          hl("SnacksNotifierBorderError", { fg = carbon.pink, bg = carbon.bg })
          hl("SnacksNotifierBorderDebug", { fg = carbon.gray, bg = carbon.bg })
          hl("SnacksNotifierBorderTrace", { fg = carbon.purple, bg = carbon.bg })
          hl("SnacksNotifierIconInfo", { fg = carbon.cyan })
          hl("SnacksNotifierIconWarn", { fg = carbon.pink })
          hl("SnacksNotifierIconError", { fg = carbon.pink })
          hl("SnacksNotifierTitleInfo", { fg = carbon.cyan, bold = true })
          hl("SnacksNotifierTitleWarn", { fg = carbon.pink, bold = true })
          hl("SnacksNotifierTitleError", { fg = carbon.pink, bold = true })

          -- Snacks picker AND explorer (the explorer is a picker layout, so
          -- these groups style both): Carbon "panel" look
          hl("SnacksPicker", { bg = carbon.bg })
          hl("SnacksPickerBorder", { fg = carbon.gray, bg = carbon.bg })
          hl("SnacksPickerInput", { bg = carbon.bg2 })
          hl("SnacksPickerInputBorder", { fg = carbon.bg2, bg = carbon.bg2 })
          hl("SnacksPickerTitle", { fg = carbon.bg, bg = carbon.pink, bold = true })
          hl("SnacksPickerPreviewTitle", { fg = carbon.bg, bg = carbon.cyan, bold = true })
          hl("SnacksPickerListCursorLine", { bg = carbon.bg2, bold = true })
          hl("SnacksPickerMatch", { fg = carbon.cyan, bold = true })
          hl("SnacksPickerDir", { fg = carbon.gray })
          hl("SnacksPickerPathHidden", { fg = carbon.gray })
          hl("SnacksPickerGitStatusModified", { fg = carbon.blue })
          hl("SnacksPickerGitStatusAdded", { fg = carbon.green })
          hl("SnacksPickerGitStatusUntracked", { fg = carbon.gray })

          -- dashboard
          hl("SnacksDashboardHeader", { fg = carbon.purple })
          hl("SnacksDashboardIcon", { fg = carbon.cyan })
          hl("SnacksDashboardDesc", { fg = carbon.white })
          hl("SnacksDashboardKey", { fg = carbon.pink, bold = true })
          hl("SnacksDashboardFooter", { fg = carbon.gray, italic = true })

          -- noice cmdline
          hl("NoiceCmdlinePopupBorder", { fg = carbon.purple })
          hl("NoiceCmdlinePopupTitle", { fg = carbon.purple, bold = true })
          hl("NoiceCmdlineIcon", { fg = carbon.cyan })

          -- subtle cursorline, bold matching parens
          hl("CursorLine", { bg = "#1c1c1c" })
          hl("MatchParen", { fg = carbon.pink, bold = true, underline = true })

          -- window separators barely-there, Carbon style
          hl("WinSeparator", { fg = carbon.bg2 })

          -- focus dim: inactive windows drop darker so the active pane glows
          hl("NormalNC", { bg = "#101010" })
        end,
      })
      -- fire once for the initial load (autocmd was registered after :colorscheme)
      vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "oxocarbon" })

      -- ======================================================================
      -- ★ CARBON REACTIVE ENGINE — hand-written, no plugin provides this ★
      -- ======================================================================
      -- Pure display logic: timers + highlight groups only. Touches zero
      -- behavior, handlers, or keymaps.

      local function to_rgb(hex)
        return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
      end
      -- blend(a, b, t): t=1 → pure a, t=0 → pure b
      local function blend(a, b, t)
        local ar, ag, ab = to_rgb(a)
        local br, bg_, bb = to_rgb(b)
        return string.format("#%02x%02x%02x",
          math.floor(ar * t + br * (1 - t) + 0.5),
          math.floor(ag * t + bg_ * (1 - t) + 0.5),
          math.floor(ab * t + bb * (1 - t) + 0.5))
      end

      -- ── 1) MODE-REACTIVE ACCENTS ─────────────────────────────────────────
      -- The whole UI re-tints with the current mode:
      --   normal=purple · insert=cyan · visual=pink · replace=mint · cmd=blue
      local mode_accent = {
        n = carbon.purple, i = carbon.cyan, v = carbon.pink, V = carbon.pink,
        ["\22"] = carbon.pink, R = carbon.mint, c = carbon.blue, t = carbon.green,
      }
      local function apply_accent(mode)
        local a = mode_accent[mode] or carbon.purple
        local hl = function(g, o) vim.api.nvim_set_hl(0, g, o) end
        hl("CursorLine", { bg = blend(a, carbon.bg, 0.09) }) -- faint accent glow
        hl("CursorLineNr", { fg = a, bold = true })
        hl("SnacksIndentScope", { fg = a, nocombine = true })
        hl("MatchParen", { fg = a, bold = true, underline = true })
        hl("WinSeparator", { fg = blend(a, carbon.bg, 0.35) })
        hl("FloatBorder", { fg = blend(a, carbon.bg, 0.65), bg = carbon.bg })
        hl("NoiceCmdlinePopupBorder", { fg = a })
        hl("ModeMsg", { fg = a, bold = true })
        hl("Visual", { bg = blend(carbon.pink, carbon.bg, 0.18) })
      end
      vim.api.nvim_create_autocmd("ModeChanged", {
        group = vim.api.nvim_create_augroup("CarbonReactiveMode", { clear = true }),
        callback = function()
          apply_accent(vim.v.event.new_mode:sub(1, 1))
        end,
      })
      apply_accent("n") -- initial paint

      -- ── 2) YANK PULSE ────────────────────────────────────────────────────
      -- Yanked region flashes pink and FADES out over 12 frames instead of
      -- the stock flat flash. (vim.hl is 0.11+; vim.highlight before that.)
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("CarbonYankPulse", { clear = true }),
        callback = function()
          local hilite = vim.hl or vim.highlight
          hilite.on_yank({ higroup = "CarbonYank", timeout = 400 })
          local frames, i = 12, 0
          local timer = vim.uv.new_timer()
          timer:start(0, 30, vim.schedule_wrap(function()
            i = i + 1
            vim.api.nvim_set_hl(0, "CarbonYank", {
              bg = blend(carbon.pink, carbon.bg, 1 - i / frames),
              fg = carbon.white,
            })
            vim.cmd.redraw()
            if i >= frames and not timer:is_closing() then
              timer:stop(); timer:close()
            end
          end))
        end,
      })

      -- ── 3) LIVING DASHBOARD ──────────────────────────────────────────────
      -- The ASCII header continuously melts through the Carbon palette while
      -- the dashboard is open; timer stops the moment you leave it, so it
      -- costs zero once you're editing.
      local hues = { carbon.purple, carbon.cyan, carbon.mint, carbon.pink, carbon.blue }
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("CarbonLivingDash", { clear = true }),
        pattern = "snacks_dashboard",
        callback = function(ev)
          local timer = vim.uv.new_timer()
          local t = 0
          timer:start(0, 60, vim.schedule_wrap(function()
            t = t + 0.02
            local pos = t % #hues
            local i = math.floor(pos) + 1
            local nxt = (i % #hues) + 1
            vim.api.nvim_set_hl(0, "SnacksDashboardHeader", {
              fg = blend(hues[nxt], hues[i], pos - math.floor(pos)),
            })
            vim.cmd.redraw()
          end))
          vim.api.nvim_create_autocmd({ "BufWipeout", "BufLeave" }, {
            buffer = ev.buf,
            once = true,
            callback = function()
              if not timer:is_closing() then timer:stop(); timer:close() end
            end,
          })
        end,
      })
    end,
  },

  -- LazyVim re-applies its own colorscheme post-startup; override or it
  -- clobbers oxocarbon with tokyonight.
  { "LazyVim/LazyVim", opts = { colorscheme = "oxocarbon" } },

  -- ==========================================================================
  -- 2. ICONS — nvim-web-devicons everywhere
  -- ==========================================================================
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = { default = true, color_icons = true },
  },

  -- ==========================================================================
  -- 3. STATUSLINE — lualine, rounded "bubble" sections, LSP + diagnostics
  -- ==========================================================================
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- opts as a function returning a fresh table => fully REPLACES LazyVim's
    -- default lualine config instead of deep-merging with it
    opts = function()
      -- display-only: lists attached client names, touches no LSP config
      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then return "" end
        local names = {}
        for _, c in ipairs(clients) do
          names[#names + 1] = c.name
        end
        return " " .. table.concat(names, " · ")
      end

      return {
        options = {
          theme = "auto", -- oxocarbon ships a lualine theme; auto picks it up
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" }, -- rounded bubbles
          disabled_filetypes = { statusline = { "snacks_dashboard", "alpha" } },
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
              color = { fg = carbon.purple },
            },
            {
              function() return require("noice").api.status.mode.get() end, -- "recording @q"
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = { fg = carbon.pink },
            },
            {
              "diagnostics",
              symbols = { error = " ", warn = " ", info = " ", hint = " " },
            },
            { lsp_clients, color = { fg = carbon.gray } },
          },
          lualine_y = { { "filetype", icon_only = false }, "progress" },
          lualine_z = { { "location", separator = { left = "", right = "" } } },
        },
        extensions = { "lazy", "quickfix", "man" },
      }
    end,
  },

  -- ==========================================================================
  -- 4. WINBAR BREADCRUMBS — dropbar.nvim (NEW)
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
  --    smooth scroll, statuscolumn (ONE plugin owns all of these; v2 used
  --    nvim-notify + indent-blankline + neo-tree for three of them)
  -- ==========================================================================
  {
    "folke/snacks.nvim",
    opts = {
      -- indent guides + animated scope (replaces indent-blankline;
      -- SnacksIndent/SnacksIndentScope colors set in the accent layer,
      -- scope re-tinted per mode by the reactive engine)
      indent = {
        enabled = true,
        indent = { char = "▏" },
        scope = { enabled = true, char = "▏" },
      },
      -- notifications (replaces nvim-notify; noice routes through vim.notify)
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
      -- Styled by the SnacksPicker* groups in the accent layer; show
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
          header = [[
  ▄██████▄  ▀████    ▐████▀  ▄██████▄
 ███    ███   ███▌   ████▀  ███    ███
 ███    ███    ███  ▐███    ███    ███
 ███    ███    ▀███▄███▀    ███    ███
 ███    ███    ████▀██▄     ███    ███
 ███    ███   ▐███  ▀███    ███    ███
 ███    ███  ▄███     ███▄  ███    ███
  ▀██████▀  ████       ███▄  ▀██████▀ ]],
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
    },
  },

  -- ==========================================================================
  -- 7. CMDLINE / MESSAGES / LSP DOC RENDERING — noice.nvim
  -- ==========================================================================
  -- CAVEAT (honest one): noice restyles LSP hover/signature by swapping the
  -- markdown RENDERING path — your servers, conform, and nvim-lint are
  -- untouched; only the output windows change. Set lsp.override entries to
  -- false for zero interception. Notifications go through vim.notify →
  -- snacks.notifier (no nvim-notify; one notification system).
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
    -- OPTIONAL + NEW keymap, namespaced under <leader>u. Delete if unwanted.
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
      for i, color in ipairs({ carbon.cyan, carbon.purple, carbon.pink, carbon.blue, carbon.mint }) do
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
      cursor_color = carbon.cyan,
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
--   nyoom-engineering/oxocarbon.nvim        colorscheme + Carbon accent layer
--   Bekaboo/dropbar.nvim                    winbar breadcrumbs (needs nvim 0.10+)
--   HiPhish/rainbow-delimiters.nvim         Carbon rainbow brackets
--   brenoprata10/nvim-highlight-colors      inline color swatches
--   MeanderingProgrammer/render-markdown.nvim  pretty markdown rendering
--   sphamba/smear-cursor.nvim               cursor trail (pure flair, deletable)
-- OVERRIDDEN (ship with LazyVim; restyled here):
--   LazyVim/LazyVim                         colorscheme = "oxocarbon"
--   nvim-lualine/lualine.nvim               full replacement, bubble sections
--   folke/snacks.nvim                       dashboard + notifier + indent +
--                                           explorer styling + smooth scroll +
--                                           statuscolumn — ONE system per job
--   akinsho/bufferline.nvim                 slant + ordinal numbers
--   folke/noice.nvim                        floating cmdline, LSP doc borders,
--                                           progress spinner
--                                           + ONE optional new keymap <leader>un
--   nvim-tree/nvim-web-devicons             default icons on
--
-- REMOVED in v3 (duplicated a snacks module already shipped by LazyVim):
--   rcarriga/nvim-notify        → snacks.notifier owns notifications
--   nvim-neo-tree/neo-tree.nvim → snacks explorer owns the file tree
--                                 (also dropped plenary/nui-for-neo-tree deps
--                                 and the startup-time eager load)
--   lukas-reineke/indent-blankline.nvim → snacks.indent owns guides
--
-- HAND-WRITTEN (no plugin — unique to this config, in the oxocarbon block):
--   ★ Carbon Reactive engine:
--     mode-reactive UI tinting · animated fading yank pulse ·
--     living gradient dashboard header · inactive-window focus dim
-- ============================================================================
