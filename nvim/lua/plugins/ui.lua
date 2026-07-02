-- ============================================================================
-- lua/plugins/ui.lua — MAX visual overhaul built around oxocarbon (v2)
-- ============================================================================
-- SCOPE: visual layers ONLY. Does not touch the picker, LSP servers
-- (basedpyright/ruff/conform/nvim-lint), treesitter config, or editing
-- keymaps. Anything that *reads* LSP/treesitter data here (breadcrumbs,
-- rainbow delimiters, diagnostics counts) is display-only.
--
-- NOTE: this config is a LazyVim starter — lualine / bufferline / noice /
-- notify / neo-tree / snacks / devicons already ship upstream; those specs
-- below MERGE/OVERRIDE the LazyVim ones. Genuinely new plugins are listed in
-- the diff block at the bottom.
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

          -- indent guides
          hl("IblIndent", { fg = carbon.bg2, nocombine = true })
          hl("IblScope", { fg = carbon.cyan, nocombine = true })

          -- notify borders in Carbon accents
          hl("NotifyINFOBorder", { fg = carbon.cyan })
          hl("NotifyWARNBorder", { fg = carbon.pink })
          hl("NotifyERRORBorder", { fg = carbon.pink })
          hl("NotifyDEBUGBorder", { fg = carbon.gray })
          hl("NotifyTRACEBorder", { fg = carbon.purple })

          -- Snacks picker (LazyVim's default picker): Carbon "panel" look
          -- (highlights ONLY — zero changes to picker config or behavior)
          hl("SnacksPicker", { bg = carbon.bg })
          hl("SnacksPickerBorder", { fg = carbon.gray, bg = carbon.bg })
          hl("SnacksPickerInput", { bg = carbon.bg2 })
          hl("SnacksPickerInputBorder", { fg = carbon.bg2, bg = carbon.bg2 })
          hl("SnacksPickerTitle", { fg = carbon.bg, bg = carbon.pink, bold = true })
          hl("SnacksPickerPreviewTitle", { fg = carbon.bg, bg = carbon.cyan, bold = true })
          hl("SnacksPickerListCursorLine", { bg = carbon.bg2, bold = true })
          hl("SnacksPickerMatch", { fg = carbon.cyan, bold = true })

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
        hl("IblScope", { fg = a, nocombine = true })
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
      -- the stock flat flash.
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("CarbonYankPulse", { clear = true }),
        callback = function()
          vim.hl.on_yank({ higroup = "CarbonYank", timeout = 400 })
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
      -- the dashboard is open; timer stops the moment you leave it.
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
        extensions = { "neo-tree", "lazy", "quickfix", "man" },
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
  -- 5. FILE EXPLORER UI — neo-tree v3, visual config only (no keys defined)
  -- ==========================================================================
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    opts = {
      popup_border_style = "rounded",
      window = { position = "left", width = 34 },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
          indent_marker = "│",
          last_indent_marker = "└",
          highlight = "IblIndent",
        },
        icon = { folder_closed = "", folder_open = "", folder_empty = "" },
        modified = { symbol = "●" },
        git_status = {
          symbols = {
            added = "", modified = "", deleted = "✖", renamed = "󰁕",
            untracked = "", ignored = "", unstaged = "󰄱", staged = "", conflict = "",
          },
        },
      },
      filesystem = {
        filtered_items = { visible = true, hide_dotfiles = false }, -- soft-dim, don't hide
        use_libuv_file_watcher = true, -- keeps the tree visually in sync
        -- LazyVim's snacks explorer already handles `nvim <dir>` (netrw
        -- replacement); without this, BOTH explorers open on `nvim .`
        hijack_netrw_behavior = "disabled",
      },
    },
  },

  -- ==========================================================================
  -- 6. DASHBOARD + SMOOTH SCROLL + STATUSCOLUMN — snacks.nvim
  -- ==========================================================================
  -- Buttons use the snacks picker (LazyVim's default); nothing new wired into
  -- search. scroll/statuscolumn are pure rendering. snacks.indent disabled
  -- because ibl (below) owns indent guides.
  {
    "folke/snacks.nvim",
    opts = {
      indent = { enabled = false }, -- ibl owns guides; avoid doubles
      scroll = { enabled = true }, -- buttery smooth scrolling (visual only)
      statuscolumn = {
        enabled = true, -- unified sign/number/fold column, no behavior change
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = { open = true, git_hl = true },
      },
      dashboard = {
        preset = {
          -- TODO: replace with your own ASCII header
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
  -- 7. BUFFERLINE — slant separators, ordinal numbers
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
          { filetype = "neo-tree", text = " Explorer", highlight = "Directory", text_align = "left", separator = true },
        },
      },
    },
  },

  -- ==========================================================================
  -- 8. CMDLINE / MESSAGES / LSP DOC RENDERING — noice.nvim + nvim-notify
  -- ==========================================================================
  -- CAVEAT (honest one): noice restyles LSP hover/signature by swapping the
  -- markdown RENDERING path — your servers, conform, and nvim-lint are
  -- untouched; only the output windows change. Set lsp.override entries to
  -- false for zero interception.
  {
    "rcarriga/nvim-notify",
    opts = {
      stages = "fade_in_slide_out",
      timeout = 3000,
      render = "wrapped-compact",
      top_down = false,
      background_colour = carbon.bg,
      max_width = 60,
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy", -- load-order: after colorscheme (priority 1000) so
    -- highlights link right. Do NOT make this lazy=false.
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
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
  -- 9. INDENT GUIDES — ibl, scope in Carbon cyan
  -- ==========================================================================
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "▏", highlight = "IblIndent" },
      scope = { enabled = true, highlight = "IblScope", show_start = false, show_end = false },
      exclude = {
        filetypes = { "help", "snacks_dashboard", "alpha", "neo-tree", "lazy", "mason", "noice" },
      },
    },
  },

  -- ==========================================================================
  -- 10. RAINBOW DELIMITERS (NEW) — nested brackets in Carbon accents
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
  -- 11. INLINE COLOR SWATCHES (NEW) — hex/rgb/hsl rendered as their color
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
  -- 12. PRETTY MARKDOWN (NEW) — headings, tables, checkboxes rendered in-buffer
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
  -- 13. CURSOR TRAIL (NEW, pure flair) — smear-cursor
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
-- PLUGINS THIS FILE ADDS / OVERRIDES (diff against your current config)
-- ============================================================================
-- NEW (not in stock LazyVim):
--   nyoom-engineering/oxocarbon.nvim        colorscheme + Carbon accent layer
--   lukas-reineke/indent-blankline.nvim     indent guides (snacks.indent off)
--   Bekaboo/dropbar.nvim                    winbar breadcrumbs (needs nvim 0.10+)
--   HiPhish/rainbow-delimiters.nvim         Carbon rainbow brackets
--   brenoprata10/nvim-highlight-colors      inline color swatches
--   MeanderingProgrammer/render-markdown.nvim  pretty markdown rendering
--   sphamba/smear-cursor.nvim               cursor trail (pure flair, deletable)
-- OVERRIDDEN (ship with LazyVim; restyled here):
--   LazyVim/LazyVim                         colorscheme = "oxocarbon"
--   nvim-lualine/lualine.nvim               full replacement, bubble sections
--   nvim-neo-tree/neo-tree.nvim             visual opts merge
--   folke/snacks.nvim                       dashboard + smooth scroll +
--                                           statuscolumn, indent disabled
--   akinsho/bufferline.nvim                 slant + ordinal numbers
--   folke/noice.nvim                        floating cmdline, LSP doc borders,
--                                           progress spinner
--                                           + ONE optional new keymap <leader>un
--   rcarriga/nvim-notify                    fade/wrapped-compact/bottom-up
--   nvim-tree/nvim-web-devicons             default icons on
-- DEPENDENCIES pulled in if missing: plenary.nvim, nui.nvim
--
-- HAND-WRITTEN (no plugin — unique to this config, in the oxocarbon block):
--   ★ Carbon Reactive engine:
--     mode-reactive UI tinting · animated fading yank pulse ·
--     living gradient dashboard header · inactive-window focus dim
-- ============================================================================
