-- ============================================================================
-- lua/carbon/reactive.lua — ★ CARBON REACTIVE v5: the living layer ★
-- ============================================================================
-- Hand-written, unique to this config. Everything here is display-only:
-- highlight groups + tweens on the Pulse clock (carbon/pulse.lua). Zero
-- keymaps, zero handlers, zero behavior changes.
--
--   · MODE MORPH    the whole UI *animates* between mode accents — a 150ms
--                   eased cross-fade instead of an instant snap. Cursorline,
--                   line number, indent scope, matchparen, float borders,
--                   window separators, and the actual CURSOR BLOCK all ride
--                   the same wave: normal=purple · insert=cyan · visual=pink
--                   · replace=mint · cmdline=blue · terminal=green
--
--   · TYPING HEAT   a keystroke-velocity meter. Each keypress feeds a heat
--                   value (0..1) that decays when you pause; the cursorline
--                   glow intensifies with it, and lualine shows it as a live
--                   spark (▁▂▃▄▅▆▇█) that climbs from gray to the mode
--                   accent while you're in flow. The editor breathes with
--                   your typing speed.
--
--   · YANK PULSE    yanked text flashes pink and eases out over 400ms
--                   instead of the stock flat flash.
--
--   · FOCUS FADE    switching splits animates the window you left down
--                   into the inactive dim instead of cutting instantly.
--
--   · LIVING DASH   the "1337" dashboard header melts through the palette;
--                   its tween is cancelled the moment you leave, so it
--                   costs zero once you're editing.
--
-- The hot path is honest: a keypress does ONE arithmetic bump; the clock
-- only spins while something is visibly animating (see pulse.lua).
-- ============================================================================

local palette = require("carbon.palette")
local pulse = require("carbon.pulse")
local C = palette.colors
local blend, ease = palette.blend, palette.ease

local M = {}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- ──────────────────────────────────────────────────────────────────────────
-- Reactive state
-- ──────────────────────────────────────────────────────────────────────────
local mode_accent = {
  n = C.purple,
  i = C.cyan,
  v = C.pink,
  V = C.pink,
  ["\22"] = C.pink, -- CTRL-V blockwise
  R = C.mint,
  c = C.blue,
  t = C.green,
}

local current = C.purple -- the accent painted right now (mid-morph included)
local heat = 0 -- 0..1 typing velocity, decays when you pause

-- Paint every accent-reactive group in one color. Called per animation
-- frame — blend() is memoized, so steady-state frames are pure lookups.
local function paint(accent)
  current = accent
  hl("CursorLine", { bg = blend(accent, C.bg, 0.07 + 0.09 * heat) })
  hl("CursorLineNr", { fg = accent, bold = true })
  hl("CarbonCursor", { fg = C.bg, bg = accent }) -- the real cursor block (guicursor)
  hl("SnacksIndentScope", { fg = accent, nocombine = true })
  hl("MatchParen", { fg = accent, bold = true, underline = true })
  hl("WinSeparator", { fg = blend(accent, C.bg, 0.35) })
  hl("FloatBorder", { fg = blend(accent, C.bg, 0.65), bg = C.bg })
  hl("NoiceCmdlinePopupBorder", { fg = accent })
  hl("ModeMsg", { fg = accent, bold = true })
end

-- ──────────────────────────────────────────────────────────────────────────
-- 1) MODE MORPH — eased cross-fade between mode accents
-- ──────────────────────────────────────────────────────────────────────────
local function on_mode_changed(new_mode)
  local target = mode_accent[new_mode:sub(1, 1)] or C.purple
  if target == current then
    return -- v↔V↔CTRL-V etc: same accent, don't wake the clock
  end
  local from = current
  pulse.start("mode", 150, function(p)
    paint(blend(target, from, ease(p)))
  end, function()
    paint(target)
  end)
end

-- ──────────────────────────────────────────────────────────────────────────
-- 2) TYPING HEAT — keystroke velocity → glow + statusline spark
-- ──────────────────────────────────────────────────────────────────────────
local SPARKS = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local spark = SPARKS[1]

--- lualine component: the live activity spark. Idle = gray "▁"; sustained
--- typing climbs the bar and tints it toward the current mode accent.
function M.heat_spark()
  return spark
end

--- lualine color for the spark. MUST be used as a color *function* — lualine
--- snapshots the colors of a highlight-group NAME once when it builds its
--- highlights, so a group repainted per frame would never show; a color
--- function is re-evaluated on every statusline refresh instead.
function M.heat_color()
  return { fg = blend(current, C.gray, heat), bg = C.bg }
end

local function ensure_decay()
  if heat <= 0 then
    return
  end
  pulse.start("heat", math.huge, function()
    heat = math.max(heat - 0.025, 0) -- full cool-down ≈ 1.3s after you stop
    spark = SPARKS[math.max(math.ceil(heat * #SPARKS), 1)]
    paint(current)
    -- the spark is statusline CONTENT, not just color: re-evaluate it while
    -- (and only while) the heat animation is live. This lets lualine keep
    -- its slow default poll — zero statusline churn when idle.
    vim.cmd.redrawstatus()
    if heat <= 0 then
      pulse.stop("heat") -- lets the clock sleep again
    end
  end)
end

local heat_scheduled = false
local function on_key()
  -- HOT PATH: runs on every keypress — pure arithmetic only. The tween
  -- (re)registration is deferred and coalesced via vim.schedule.
  heat = math.min(heat + 0.09, 1)
  if not heat_scheduled then
    heat_scheduled = true
    vim.schedule(function()
      heat_scheduled = false
      ensure_decay()
    end)
  end
end

-- ──────────────────────────────────────────────────────────────────────────
-- 3) YANK PULSE — pink flash that eases out instead of cutting off
-- ──────────────────────────────────────────────────────────────────────────
local function yank_pulse()
  local hilite = vim.hl or vim.highlight -- vim.hl is 0.11+
  hilite.on_yank({ higroup = "CarbonYank", timeout = 400 })
  pulse.start("yank", 400, function(p)
    hl("CarbonYank", { bg = blend(C.pink, C.bg, 1 - ease(p)), fg = C.white })
  end)
end

-- ──────────────────────────────────────────────────────────────────────────
-- 4) FOCUS FADE — the window you leave dissolves into the dark
-- ──────────────────────────────────────────────────────────────────────────
-- NormalNC (all inactive windows) animates from full brightness down to the
-- resting dim instead of cutting instantly, so switching splits reads as
-- the old window sinking away. One 220ms tween per switch; skipped entirely
-- when there's nothing to dim.
local DIM = "#101010"
local function focus_fade()
  if #vim.api.nvim_tabpage_list_wins(0) < 2 then
    return -- single window: NormalNC is invisible, don't wake the clock
  end
  pulse.start("focus", 220, function(p)
    hl("NormalNC", { bg = blend(DIM, C.bg, ease(p)) })
  end)
end

-- ──────────────────────────────────────────────────────────────────────────
-- 5) LIVING DASHBOARD — header melts through the Carbon palette
-- ──────────────────────────────────────────────────────────────────────────
local hues = { C.purple, C.cyan, C.mint, C.pink, C.blue }
local function dashboard_gradient(buf)
  pulse.start("dash", math.huge, function(elapsed)
    local pos = (elapsed / 1200) % #hues -- one hue every 1.2s
    local i = math.floor(pos) + 1
    local nxt = (i % #hues) + 1
    hl("SnacksDashboardHeader", { fg = blend(hues[nxt], hues[i], pos - i + 1) })
  end)
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufLeave" }, {
    buffer = buf,
    once = true,
    callback = function()
      pulse.stop("dash")
    end,
  })
end

-- ──────────────────────────────────────────────────────────────────────────
-- Static Carbon accent layer (non-reactive groups), re-applied whenever
-- oxocarbon (re)loads so plugin groups always resolve against Carbon.
-- ──────────────────────────────────────────────────────────────────────────
local function apply_static()
  -- floats: soft dark panels (border color is owned by paint())
  hl("NormalFloat", { bg = C.bg })
  hl("FloatTitle", { fg = C.cyan, bg = C.bg, bold = true })

  -- indent guides (snacks.indent; scope color owned by paint())
  hl("SnacksIndent", { fg = C.bg2, nocombine = true })

  -- notifications (snacks.notifier)
  hl("SnacksNotifierBorderInfo", { fg = C.cyan, bg = C.bg })
  hl("SnacksNotifierBorderWarn", { fg = C.pink, bg = C.bg })
  hl("SnacksNotifierBorderError", { fg = C.pink, bg = C.bg })
  hl("SnacksNotifierBorderDebug", { fg = C.gray, bg = C.bg })
  hl("SnacksNotifierBorderTrace", { fg = C.purple, bg = C.bg })
  hl("SnacksNotifierIconInfo", { fg = C.cyan })
  hl("SnacksNotifierIconWarn", { fg = C.pink })
  hl("SnacksNotifierIconError", { fg = C.pink })
  hl("SnacksNotifierTitleInfo", { fg = C.cyan, bold = true })
  hl("SnacksNotifierTitleWarn", { fg = C.pink, bold = true })
  hl("SnacksNotifierTitleError", { fg = C.pink, bold = true })

  -- Snacks picker AND explorer (the explorer is a picker layout)
  hl("SnacksPicker", { bg = C.bg })
  hl("SnacksPickerBorder", { fg = C.gray, bg = C.bg })
  hl("SnacksPickerInput", { bg = C.bg2 })
  hl("SnacksPickerInputBorder", { fg = C.bg2, bg = C.bg2 })
  hl("SnacksPickerTitle", { fg = C.bg, bg = C.pink, bold = true })
  hl("SnacksPickerPreviewTitle", { fg = C.bg, bg = C.cyan, bold = true })
  hl("SnacksPickerListCursorLine", { bg = C.bg2, bold = true })
  hl("SnacksPickerMatch", { fg = C.cyan, bold = true })
  hl("SnacksPickerDir", { fg = C.gray })
  hl("SnacksPickerPathHidden", { fg = C.gray })
  hl("SnacksPickerGitStatusModified", { fg = C.blue })
  hl("SnacksPickerGitStatusAdded", { fg = C.green })
  hl("SnacksPickerGitStatusUntracked", { fg = C.gray })

  -- dashboard (header color is owned by the living-gradient tween)
  hl("SnacksDashboardHeader", { fg = C.purple })
  hl("SnacksDashboardIcon", { fg = C.cyan })
  hl("SnacksDashboardDesc", { fg = C.white })
  hl("SnacksDashboardKey", { fg = C.pink, bold = true })
  hl("SnacksDashboardFooter", { fg = C.gray, italic = true })

  -- noice cmdline (popup border color is owned by paint())
  hl("NoiceCmdlinePopupTitle", { fg = C.purple, bold = true })
  hl("NoiceCmdlineIcon", { fg = C.cyan })

  -- visual selection: fixed pink wash regardless of mode accent
  hl("Visual", { bg = blend(C.pink, C.bg, 0.18) })

  -- focus dim: inactive windows drop darker so the active pane glows
  -- (the focus-fade tween animates this group on every window switch)
  hl("NormalNC", { bg = DIM })

  -- completion menu (blink.cmp): Carbon panel, cyan fuzzy matches
  hl("Pmenu", { bg = C.bg })
  hl("PmenuSel", { bg = C.bg2, bold = true })
  hl("PmenuThumb", { bg = C.gray })
  hl("BlinkCmpMenu", { bg = C.bg })
  hl("BlinkCmpMenuBorder", { fg = C.gray, bg = C.bg })
  hl("BlinkCmpMenuSelection", { bg = C.bg2, bold = true })
  hl("BlinkCmpLabelMatch", { fg = C.cyan, bold = true })
  hl("BlinkCmpDoc", { bg = C.bg })
  hl("BlinkCmpDocBorder", { fg = C.gray, bg = C.bg })
  hl("BlinkCmpSignatureHelpBorder", { fg = C.gray, bg = C.bg })

  -- which-key menu: pink keys, purple groups, quiet chrome
  hl("WhichKey", { fg = C.pink, bold = true })
  hl("WhichKeyGroup", { fg = C.purple })
  hl("WhichKeyDesc", { fg = C.white })
  hl("WhichKeySeparator", { fg = C.gray })
  hl("WhichKeyTitle", { fg = C.cyan, bold = true })
  hl("WhichKeyNormal", { bg = C.bg })
  hl("WhichKeyBorder", { fg = C.gray, bg = C.bg })

  -- dropbar breadcrumbs: quiet gray trail, cyan current symbol, Carbon menu
  hl("DropBarIconUISeparator", { fg = C.gray })
  hl("DropBarMenuFloatBorder", { fg = C.gray, bg = C.bg })
  hl("DropBarMenuNormalFloat", { bg = C.bg })
  hl("DropBarMenuCurrentContext", { bg = C.bg2, bold = true })
  hl("DropBarMenuHoverEntry", { bg = C.bg2 })
  hl("DropBarMenuHoverIcon", { fg = C.cyan })

  paint(current) -- restore the reactive groups the colorscheme just reset
end

-- ──────────────────────────────────────────────────────────────────────────
-- Wire-up. Called once from the oxocarbon spec in plugins/ui.lua.
-- ──────────────────────────────────────────────────────────────────────────
function M.setup()
  local group = vim.api.nvim_create_augroup("CarbonReactive", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    pattern = "oxocarbon",
    callback = apply_static,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      on_mode_changed(vim.v.event.new_mode)
    end,
  })

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = yank_pulse,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = focus_fade,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "snacks_dashboard",
    callback = function(ev)
      dashboard_gradient(ev.buf)
    end,
  })

  vim.on_key(on_key, vim.api.nvim_create_namespace("carbon_heat"))

  apply_static() -- initial paint (ColorScheme already fired before setup)
end

return M
