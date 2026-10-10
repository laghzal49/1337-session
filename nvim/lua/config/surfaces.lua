-- Shared tokens for every interactive panel, derived from the researched palette.
local ui = require("config.ui")
local colors = ui.colors
local c = require('config.palette')

local M = {
  panel = c.panel,
  popup = c.inset,
  tree_panel = c.inset,
  inset = c.inset,
  edge = c.border,
  edge_bright = c.border_strong,
  focus_edge = c.focus_border,
  edge_soft = c.border_soft,
  selected = c.selection,
  selected_bright = c.selection,
  accent = c.focus,
  panel_accent = c.focus,
  text = colors.text,
  muted = c.muted,
  teal = colors.teal,
  lilac = colors.lilac,
  border = c.border,
  error = colors.error,
}

local standard = { focus_edge = M.focus_edge, edge = M.edge, edge_bright = M.edge_bright, edge_soft = M.edge_soft, border = M.border, muted = M.muted, selected = M.selected }
function M.set_accessible(enabled)
  for key, value in pairs(standard) do M[key] = value end
  if enabled then
    M.edge, M.edge_bright, M.edge_soft, M.border = c.path, c.text, c.muted, c.path
    M.muted, M.selected, M.focus_edge = c.path, c.selection, c.path
  end
end
M.set_accessible(ui.accessible)

function M.highlights(accessible)
  if accessible == nil then accessible = ui.accessible end
  local h = {}
  local function groups(names, value)
    for name in names:gmatch("%S+") do h[name] = vim.deepcopy(value) end
  end
  groups('DapUINormal', { bg = M.inset, fg = M.text })
  groups('DapUIFloatNormal', { bg = M.popup, fg = M.text })
  groups('DapUIFloatBorder', { fg = M.focus_edge, bg = M.popup })
  groups('DapUIWinSelect', { fg = M.accent, bg = M.popup })
  groups('DapUIScope DapUIFrameName', { fg = c.callable })
  groups('DapUIType', { fg = c.type })
  groups('BlackDebugLine', { bg = c.inset })
  groups('BlackDebugLineNr', { fg = c.warning })
  groups('DapUIVariable', { fg = c.variable })
  groups('DapUIValue DapUIWatchesValue', { fg = c.text })
  groups('DapUIDecoration DapUILineNumber DapUIUnavailable DapUIWatchesEmpty', { fg = c.muted })
  groups('DapUIModifiedValue', { fg = c.warning })
  groups('DapUIStoppedThread DapUICurrentFrameName DapUIBreakpointsCurrentLine', { fg = c.warning })
  groups('DapUIThread DapUISource DapUIBreakpointsPath DapUIBreakpointsInfo', { fg = c.info })
  groups('DapUIPlayPause DapUIRestart', { fg = c.success })
  groups('DapUIStop DapUIWatchesError', { fg = c.error })
  groups('DapUIStepOver DapUIStepInto DapUIStepBack DapUIStepOut', { fg = c.focus })
  groups('BlackPath', { fg = M.muted, bg = M.tree_panel })
  groups('BlackFileTitle', { fg = M.text, bg = M.tree_panel })
  groups('BlackModified', { fg = c.warning, bg = M.tree_panel })
  groups('BlackYank', { bg = c.focus_bg, fg = c.strong })
  groups('BlackBeacon', { bg = M.selected })
  groups('BlackBeaconNumber', { fg = M.accent })
  groups('BlackActiveSeparator', { fg = M.focus_edge, bg = c.canvas })
  groups('BlackCursorNormal', { fg = c.canvas, bg = colors.cursor })
  groups('BlackCursorInsert', { fg = c.canvas, bg = colors.cursor_insert })
  groups('BlackCursorVisual', { fg = c.canvas, bg = colors.lilac })
  groups('BlackCursorReplace', { fg = c.canvas, bg = colors.error })
  groups('BlackCursorCommand', { fg = c.canvas, bg = colors.cursor_command })
  groups('BlackSymbolReference', { fmt = 'underline', sp = M.edge })
  groups('BlackSymbolCurrent', { fmt = 'underline', sp = M.muted })
  groups("NormalFloat BlackDocs NoiceCmdlinePopup NoicePopupmenu SnacksInputNormal WhichKeyNormal NoicePopup SnacksNotifierHistory", { bg = M.popup, fg = M.text })
  groups("FloatBorder BlackDocsBorder NoiceCmdlinePopupBorder NoicePopupmenuBorder SnacksInputBorder WhichKeyBorder NoicePopupBorder", { bg = M.popup, fg = M.edge_bright })
  groups("FloatTitle BlackDocsTitle NoiceCmdlinePopupTitle SnacksInputTitle", { bg = M.popup, fg = M.accent })
  groups("BlackRule", { fg = c.border_soft })
  groups("BufferLineIndicatorSelected", { fg = M.accent, bg = M.selected })
  groups("BufferLineBufferSelected", { fg = c.strong, bg = M.selected })
  groups("BufferLineModifiedSelected", { fg = c.warning, bg = M.selected })
  groups("BlackDocsHint", { bg = M.popup, fg = M.muted })
  groups("PmenuSel NoicePopupmenuSelected ", { bg = c.popup_selection, fg = c.strong })
  groups("MiniNotifyNormal GlanceListNormal MiniPickNormal AerialNormal", { bg = M.popup, fg = M.text })
  groups("MiniNotifyBorder MiniPickBorder AerialBorder GlanceBorderTop GlanceListBorderBottom GlancePreviewBorderBottom", { bg = M.popup, fg = M.edge_bright })
  groups("GlanceListCursorLine MiniPickMatchCurrent AerialLine", { bg = c.popup_selection, fg = M.text })
  groups("GlancePreviewNormal GlanceWinBarFilename GlanceWinBarFilepath MiniPickPreviewNormal", { bg = M.inset, fg = M.text })
  groups("GlanceListMatch GlancePreviewMatch MiniPickMatchRanges", { fg = M.panel_accent })
  groups("MiniPickPrompt MiniPickPromptPrefix MiniPickPromptCaret MiniPickBorderText MiniPickHeader", { bg = M.popup, fg = M.panel_accent })
  groups("MiniPickPreviewBorder", { bg = M.inset, fg = M.edge_soft })
  groups("MiniPickPreviewLine", { bg = M.selected, fg = M.text })
  groups("MiniPickMatchMarked", { bg = M.selected, fg = M.accent })
  groups("AerialGuide", { fg = M.edge_soft })
  for _, kind in ipairs({ "Cmdline", "Lua", "Search", "Help", "Filter", "Calculator", "Input" }) do
    h["NoiceCmdlinePopupTitle" .. kind] = { bg = M.popup, fg = M.accent }
    h["NoiceCmdlinePopupBorder" .. kind] = { bg = M.popup, fg = M.focus_edge }
  end
  for _, level in ipairs({ "Trace", "Debug", "Info", "Warn", "Error" }) do
    h["SnacksNotifier" .. level] = { bg = M.panel, fg = M.text }
    h["SnacksNotifierBorder" .. level] = { bg = M.panel, fg = M.edge }
    local severity = ({Error=c.error,Warn=c.warning,Info=c.info,Debug=c.keyword,Trace=c.muted})[level]
    h['SnacksNotifierIcon' .. level] = { fg = severity }
    h['SnacksNotifierTitle' .. level] = { fg = severity }
  end

  -- Edgy panel chrome
  groups('EdgyTitle', { bg = c.inset, fg = c.focus })
  groups('EdgyIcon EdgyIconActive', { bg = c.inset, fg = c.focus })
  groups('EdgyWinBar', { bg = c.inset, fg = c.focus })
  groups('EdgyNormal', { bg = c.inset, fg = M.text })
  groups('AerialNormal', { bg = c.inset, fg = M.text })
  groups('AerialLine', { bg = M.selected, fg = c.text })
  -- Trouble panel chrome
  groups('TroubleNormal TroubleNormalNC', { bg = M.panel, fg = M.text })
  groups('TroubleCount', { fg = M.accent })
  
  -- Jump labels: a filled violet badge, distinct from blue navigation.
  groups('FlashLabel', { bg = c.keyword, fg = c.on_accent })
  groups('FlashMatch', { fg = c.callable, bg = c.search_bg })
  groups('FlashCurrent', { fg = c.on_accent, bg = c.warning })
  groups('FlashBackdrop', { fg = M.muted })

  -- WhichKey full suite
  groups('WhichKeySeparator', { fg = M.muted })
  groups('WhichKeyValue',     { fg = M.muted })
  groups('WhichKeyBorder',    { bg = M.popup, fg = M.edge_bright })
  groups('WhichKeyTitle',     { bg = M.popup, fg = M.accent })
  groups('WhichKeyDesc',      { fg = M.text })
  groups('WhichKey',          { fg = M.accent })
  groups('WhichKeyGroup',     { fg = M.text })
  groups('WhichKeyIcon', { fg = M.muted })
  for color, value in pairs(c.icons) do groups('WhichKeyIcon' .. color, { fg = value }) end

  -- TreesitterContext — dark panel bg, subtle italic
  groups('TreesitterContext',           { bg = M.panel, fmt = 'italic' })
  groups('TreesitterContextLineNumber', { bg = M.panel, fg = M.muted })
  groups('TreesitterContextSeparator',  { fg = M.edge })
  groups('TreesitterContextBottom',     { fmt = 'underline', sp = M.edge })

  -- ── blink.cmp kind highlights (all 25 kinds) ─────────────────────────
  -- Mapped 1:1 to Perfect Black palette tokens
  for kind, color in pairs(c.kinds) do
    h['BlinkCmpKind' .. kind] = { fg = color }
    h['Aerial' .. kind] = { fg = color }
  end
  -- blink.cmp doc/menu chrome
  groups('BlinkCmpMenu',        { bg = M.popup, fg = M.text })
  groups('BlinkCmpMenuBorder',  { bg = M.popup, fg = M.focus_edge })
  groups('BlinkCmpMenuSelection',{ bg = c.popup_selection, fg = M.text })
  groups('BlinkCmpDoc BlinkCmpSignatureHelp', { bg = M.popup, fg = M.text })
  groups('BlinkCmpDocBorder BlinkCmpSignatureHelpBorder', { bg = M.popup, fg = M.edge_bright })
  groups('BlinkCmpScrollBar',   { bg = M.inset })
  groups('BlinkCmpScrollBarThumb', { bg = M.edge })
  groups('BlinkCmpLabel',       { fg = M.text })
  groups('BlinkCmpLabelMatch',  { fg = c.strong, fmt = 'underline' })
  groups('BlinkCmpSource',      { fg = M.muted })
  groups('BlinkCmpLabelDetail BlinkCmpLabelDescription', { fg = M.muted })
  groups('BlinkCmpLabelDeprecated', { fg = M.muted, fmt = 'strikethrough' })
  groups('BlinkCmpDocSeparator', { bg = M.inset, fg = M.edge })
  groups('BlinkCmpGhostText',   { fg = M.muted, fmt = 'italic' })

  -- ── Snacks.picker & explorer file tree ─────────────────────────────────
  groups('SnacksPicker',                  { bg = M.popup, fg = c.strong })
  groups('SnacksPickerBorder',            { bg = M.popup, fg = M.edge })
  groups('SnacksPickerTitle',             { bg = M.popup, fg = c.focus })
  groups('SnacksPickerPrompt',            { fg = c.focus })
  groups('SnacksPickerMatch',             { fg = c.strong, bg = c.search_bg })
  groups('SnacksPickerDirectory',         { fg = c.folder })
  groups('SnacksPickerFile',              { fg = c.text })
  groups('SnacksPickerDir',               { fg = c.path })
  groups('SnacksPickerPathIgnored',       { fg = c.muted })
  groups('SnacksPickerPathHidden',        { fg = c.muted })
  groups('SnacksPickerTree',              { fg = M.edge_soft })
  groups('SnacksPickerGitStatusUntracked', { fg = c.info })
  groups('SnacksPickerGitStatusModified',  { fg = c.warning })
  groups('SnacksPickerGitStatusStaged',    { fg = c.success })
  groups('SnacksPickerGitStatusDeleted',   { fg = c.error, fmt = 'strikethrough' })
  groups('SnacksPickerGitStatusIgnored',   { fg = c.muted, fmt = 'italic' })
  groups('SnacksPickerSelected',          { bg = c.focus_bg, fg = c.strong })
  groups('SnacksPickerList',              { bg = M.popup, fg = c.strong })
  groups('SnacksPickerInput',             { bg = c.panel, fg = c.text })
  groups('SnacksExplorerDir',             { fg = c.folder })
  groups('SnacksExplorerFile',            { fg = c.text })

  groups('NoiceFormatProgressDone', { bg = M.selected, fg = M.text })
  groups('NoiceFormatProgressTodo', { bg = M.inset, fg = M.muted })
  groups('NoiceLspProgressTitle', { fg = M.accent })
  groups('NoiceLspProgressClient', { fg = M.panel_accent })
  groups('NoiceLspProgressSpinner', { fg = M.accent })

  -- Completion docs panel polish
  groups('BlackDocsCode', { bg = c.inset, fg = M.text })
  groups('BlackDocsSeparator', { fg = M.edge })
  groups('BlackDocsParam', { fg = c.parameter })
  groups('BlackDocsType', { fg = c.type })
  groups('BlackDocsReturn', { fg = c.success })
  for level, color in ipairs(c.headings) do
    groups('RenderMarkdownH' .. level, { fg = color })
    groups('RenderMarkdownH' .. level .. 'Bg', { bg = M.panel })
  end
  groups('RenderMarkdownCode', { bg = M.inset })
  groups('RenderMarkdownCodeInline', { bg = M.inset, fg = colors.cursor_insert })
  groups('RenderMarkdownBullet RenderMarkdownTableRow', { fg = M.muted })
  groups('RenderMarkdownTableHead', { fg = M.accent })
  groups('LspSignatureActiveParameter', { fg = c.strong, bg = c.focus_bg, fmt = 'underline' })

  -- Prompts use a blue focus edge; reference text stays quietly framed.
  groups('BlackPrompt SnacksInputNormal', { bg = M.popup, fg = c.text })
  groups('BlackPromptBorder SnacksInputBorder', { bg = M.popup, fg = M.focus_edge })
  groups('BlackPromptTitle SnacksInputTitle', { bg = M.popup, fg = M.accent })
  groups('BlackPopupHint FloatFooter', { bg = M.popup, fg = M.muted })
  groups('BlackPopupCommand', {fg=M.accent})
  for name, color in pairs({Error=c.error,Warn=c.warning,Info=c.info,Hint=c.hint}) do
    groups('DiagnosticFloating'..name, {bg=M.popup,fg=color})
  end
  groups('BlinkCmpSignatureHelpActiveParameter', { fg = c.strong, bg = c.focus_bg, fmt = 'underline' })
  groups('SnacksPickerPreview', { bg = c.canvas, fg = c.text })
  groups('SnacksPickerPreviewBorder', { bg = c.canvas, fg = M.edge })
  groups('SnacksPickerListCursorLine', { bg = c.popup_selection })
  groups('SnacksPickerFooter', { bg = M.popup, fg = M.muted })

  -- Snacks input enhanced
  groups('SnacksInputIcon', { bg = M.popup, fg = M.accent })
  groups('SnacksInputPrompt', { bg = M.popup, fg = M.panel_accent })

  -- Mini.icons palette integration
  for color, value in pairs(c.icons) do groups('MiniIcons' .. color, { fg = value }) end

  -- Lazy plugin manager panel
  groups('LazyNormal', { bg = M.panel, fg = M.text })
  groups('LazyButton', { bg = M.inset, fg = M.text })
  groups('LazyButtonActive', { bg = M.selected, fg = M.text })
  groups('LazyH1', { bg = M.accent, fg = c.canvas })
  groups('LazyH2', { fg = M.accent })
  groups('LazySpecial', { fg = M.panel_accent })
  groups('LazyComment', { fg = M.muted })

  -- Mason installer panel
  groups('MasonNormal', { bg = M.panel, fg = M.text })
  groups('MasonHeader', { bg = M.accent, fg = c.canvas })
  groups('MasonHighlight', { fg = M.accent })
  groups('MasonHighlightBlock', { bg = M.accent, fg = c.canvas })
  groups('MasonHighlightBlockBold', { bg = M.accent, fg = c.canvas })
  groups('MasonMuted', { fg = M.muted })
  groups('MasonMutedBlock', { bg = M.inset, fg = M.muted })

  groups('GitStatusStaged', { fg = c.success })
  groups('GitStatusModified', { fg = c.warning })
  groups('GitStatusUntracked', { fg = c.info })
  groups('GitStatusDeleted', { fg = c.error })

  groups('BlackBrandIcon', { fg = c.focus })
  groups('BlackBrand', { fg = c.focus })
  groups('BlackLabel', { fg = c.focus })
  groups('BlackMuted', { fg = M.muted })
  groups('BlackKey', { bg = M.selected, fg = c.strong })
  groups('BlackDashboardKey', { fg = M.teal })
  groups('BlackDashboardHeading', { fg = accessible and c.text or c.path })
  groups('BlackDashboardMeta', { fg = M.muted })
  groups('BlackDashboardPath', { fg = M.text })
  groups('BlackRule', { fg = c.border_soft })
  groups('CursorLine', { bg = c.panel })
  groups('CursorLineNr', { fg = c.focus })
  groups('SnacksDashboardTerminal', { fg = c.muted })
  groups('SnacksDashboardFooter', { fg = c.muted })
  groups('SnacksDashboardHeader', { fg = c.focus })
  groups('SnacksDashboardKey', { fg = c.focus })
  groups('SnacksDashboardDesc', { fg = c.text })
  groups('SnacksDashboardIcon', { fg = c.focus })
  groups('SnacksDashboardSpecial', { fg = c.focus })
  groups('SnacksDashboardDir', { fg = c.muted })
  groups('SnacksDashboardFile', { fg = c.strong })


  if accessible then
    for _, spec in pairs(h) do
      if spec.fmt then spec.fmt = spec.fmt:gsub('italic', '') end
    end
    groups('WinSeparator', { fg = M.edge, bg = c.canvas })
    groups('SnacksDashboardDir SnacksDashboardFooter', { fg = M.muted })
  end
  return h
end
return M
