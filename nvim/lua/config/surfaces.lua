-- Shared tokens for every interactive panel, independent of the code palette.
local ui = require("config.ui")
local colors = ui.colors
local c = require('config.palette')

local M = {
  panel = c.panel,
  tree_panel = c.inset,
  inset = c.inset,
  edge = "#303440",
  edge_bright = "#606777",
  edge_soft = "#252934",
  selected = c.selection,
  selected_bright = "#352B3B",
  accent = c.focus,
  panel_accent = c.focus,
  text = colors.text,
  muted = c.muted,
  teal = colors.teal,
  lilac = colors.lilac,
  border = "#303440",
  error = colors.error,
}

local standard = { edge = M.edge, edge_bright = M.edge_bright, edge_soft = M.edge_soft, border = M.border, muted = M.muted, selected = M.selected }
function M.set_accessible(enabled)
  for key, value in pairs(standard) do M[key] = value end
  if enabled then
    M.edge, M.edge_bright, M.edge_soft, M.border = '#A9B9D6', '#D7E3FF', '#9299A9', '#A9B9D6'
    M.muted, M.selected = '#B8C4DA', '#34323E'
  end
end
M.set_accessible(ui.accessible)

function M.highlights(accessible)
  if accessible == nil then accessible = ui.accessible end
  local h = {}
  local function groups(names, value)
    for name in names:gmatch("%S+") do h[name] = vim.deepcopy(value) end
  end
  groups('DapUIFloatNormal', { bg = M.panel, fg = M.text })
  groups('DapUIFloatBorder DapUIWinSelect', { fg = M.accent, bg = M.panel })
  groups('DapUIScope', { fg = c.callable })
  groups('DapUIType', { fg = c.type })
  groups('DapUIValue DapUIDecoration', { fg = M.text })
  groups('DapUIStoppedThread DapUIThread', { fg = M.teal })
  groups('BlackPath', { fg = M.muted, bg = M.tree_panel })
  groups('BlackFileTitle', { fg = M.text, bg = M.tree_panel, fmt = 'bold' })
  groups('BlackModified', { fg = M.teal, bg = M.tree_panel })
  groups('BlackYank', { bg = '#4E121D', fg = '#FFFFFF' })
  groups('BlackBeacon', { bg = M.selected })
  groups('BlackBeaconNumber', { fg = M.accent, fmt = 'bold' })
  groups('BlackActiveSeparator', { fg = M.accent, bg = '#000000' })
  groups('BlackCursorNormal', { fg = '#000000', bg = colors.cursor })
  groups('BlackCursorInsert', { fg = '#000000', bg = colors.cursor_insert })
  groups('BlackCursorVisual', { fg = '#000000', bg = colors.lilac })
  groups('BlackCursorReplace', { fg = '#000000', bg = colors.error })
  groups('BlackCursorCommand', { fg = '#000000', bg = colors.cursor_command })
  groups('BlackSymbolReference', { fmt = 'underline', sp = M.edge })
  groups('BlackSymbolCurrent', { fmt = 'underline', sp = M.muted })
  groups("NormalFloat BlackDocs NoiceCmdlinePopup NoicePopupmenu SnacksInputNormal WhichKeyNormal NoicePopup SnacksNotifierHistory", { bg = M.panel, fg = M.text })
  groups("FloatBorder BlackDocsBorder NoiceCmdlinePopupBorder NoicePopupmenuBorder SnacksInputBorder WhichKeyBorder NoicePopupBorder", { bg = M.panel, fg = M.edge_bright })
  groups("FloatTitle BlackDocsTitle NoiceCmdlinePopupTitle SnacksInputTitle", { bg = M.panel, fg = M.accent, fmt = "bold" })
  groups("BlackRule", { fg = "#8B0018" })
  groups("BufferLineIndicatorSelected", { fg = M.accent, bg = M.selected })
  groups("BufferLineBufferSelected", { fg = "#FFFFFF", bg = M.selected, fmt = "bold" })
  groups("BufferLineModifiedSelected", { fg = M.accent, bg = M.selected })
  groups("BlackDocsHint", { bg = M.panel, fg = M.muted })
  groups("PmenuSel NoicePopupmenuSelected ", { bg = M.selected, fg = "#FFFFFF" })
  groups("MiniNotifyNormal GlanceListNormal MiniPickNormal AerialNormal", { bg = M.panel, fg = M.text })
  groups("MiniNotifyBorder MiniPickBorder AerialBorder GlanceBorderTop GlanceListBorderBottom GlancePreviewBorderBottom", { bg = M.panel, fg = M.edge_bright })
  groups("GlanceListCursorLine MiniPickMatchCurrent AerialLine", { bg = M.selected, fg = M.text, fmt = "bold" })
  groups("GlancePreviewNormal GlanceWinBarFilename GlanceWinBarFilepath MiniPickPreviewNormal", { bg = M.inset, fg = M.text })
  groups("GlanceListMatch GlancePreviewMatch MiniPickMatchRanges", { fg = M.panel_accent, fmt = "bold" })
  groups("MiniPickPrompt MiniPickPromptPrefix MiniPickPromptCaret MiniPickBorderText MiniPickHeader", { bg = M.panel, fg = M.panel_accent, fmt = "bold" })
  groups("MiniPickPreviewBorder", { bg = M.inset, fg = M.edge_soft })
  groups("MiniPickPreviewLine", { bg = M.selected, fg = M.text })
  groups("MiniPickMatchMarked", { bg = M.selected, fg = M.accent, fmt = "bold" })
  groups("AerialGuide", { fg = M.edge_soft })
  for _, kind in ipairs({ "Cmdline", "Lua", "Search", "Help", "Filter", "Calculator", "Input" }) do
    h["NoiceCmdlinePopupTitle" .. kind] = { bg = M.panel, fg = M.accent, fmt = "bold" }
  end
  for _, level in ipairs({ "Trace", "Debug", "Info", "Warn", "Error" }) do
    h["SnacksNotifier" .. level] = { bg = M.panel, fg = M.text }
    h["SnacksNotifierBorder" .. level] = { bg = M.panel, fg = M.edge }
  end

  -- Edgy panel chrome
  groups('EdgyTitle', { bg = '#0A0A0E', fg = c.focus, fmt = 'bold' })
  groups('EdgyIcon EdgyIconActive', { bg = '#0A0A0E', fg = c.focus })
  groups('EdgyWinBar', { bg = '#0A0A0E', fg = c.focus, fmt = 'bold' })
  groups('EdgyNormal', { bg = '#0A0A0E', fg = M.text })
  groups('AerialNormal', { bg = '#0A0A0E', fg = M.text })
  groups('AerialLine', { bg = M.selected, fg = c.text, fmt = 'bold' })
  groups('AerialClass AerialStruct AerialInterface AerialEnum', {fg=c.type})
  groups('AerialFunction AerialMethod', {fg=c.callable})
  groups('AerialVariable', {fg=c.variable, fmt='bold'})
  groups('AerialProperty AerialField', {fg=c.member})
  -- Trouble panel chrome
  groups('TroubleNormal TroubleNormalNC', { bg = M.panel, fg = M.text })
  groups('TroubleCount', { fg = M.accent, fmt = 'bold' })
  
  -- Flash jump labels — hot pink bg, white fg for maximum contrast
  groups('FlashLabel', { bg = '#FF8FA3', fg = '#000000', fmt = 'bold' })
  groups('FlashMatch', { fg = M.accent })
  groups('FlashCurrent', { fg = M.text, fmt = 'bold' })
  groups('FlashBackdrop', { fg = M.muted })

  -- WhichKey full suite
  groups('WhichKeySeparator', { fg = M.muted })
  groups('WhichKeyValue',     { fg = M.muted })
  groups('WhichKeyBorder',    { bg = M.panel, fg = M.edge_bright })
  groups('WhichKeyTitle',     { bg = M.panel, fg = M.accent, fmt = 'bold' })
  groups('WhichKeyDesc',      { fg = M.text })
  groups('WhichKey',          { fg = M.accent, fmt = 'bold' })
  groups('WhichKeyGroup',     { fg = M.text, fmt = 'bold' })
  groups('WhichKeyIcon', { fg = M.muted })
  for color, value in pairs({ Red = '#FF8FA3', Orange = '#FF9E64', Yellow = '#FFD166',
    Green = '#7FE3C2', Cyan = '#70D7FF', Azure = '#70D7FF', Blue = '#69AFFF', Purple = '#C7A6FF' }) do
    groups('WhichKeyIcon' .. color, { fg = value })
  end

  -- TreesitterContext — dark panel bg, subtle italic
  groups('TreesitterContext',           { bg = M.panel, fmt = 'italic' })
  groups('TreesitterContextLineNumber', { bg = M.panel, fg = M.muted })
  groups('TreesitterContextSeparator',  { fg = M.edge })
  groups('TreesitterContextBottom',     { fmt = 'underline', sp = M.edge })

  -- ── blink.cmp kind highlights (all 25 kinds) ─────────────────────────
  -- Mapped 1:1 to Perfect Black palette tokens
  local blink_kinds = {
    Text=c.text, Method=c.callable, Function=c.callable, Constructor=c.type,
    Field=c.member, Variable=c.variable, Class=c.type, Interface=c.type,
    Module=c.type, Property=c.member, Unit=c.literal, Value=c.literal,
    Enum=c.type, Keyword=c.keyword, Snippet=c.info, Color=c.member,
    File=c.text, Reference=c.info, Folder=c.folder, EnumMember=c.literal,
    Constant=c.type, Struct=c.type, Event=c.literal, Operator=c.punctuation,
    TypeParameter=c.type,
  }
  for kind, color in pairs(blink_kinds) do
    h['BlinkCmpKind' .. kind] = { fg = color }
  end
  -- blink.cmp doc/menu chrome
  groups('BlinkCmpMenu',        { bg = M.panel, fg = M.text })
  groups('BlinkCmpMenuBorder',  { bg = M.panel, fg = M.edge_bright })
  groups('BlinkCmpMenuSelection',{ bg = M.selected, fg = M.text, fmt = 'bold' })
  groups('BlinkCmpDoc BlinkCmpSignatureHelp', { bg = M.panel, fg = M.text })
  groups('BlinkCmpDocBorder BlinkCmpSignatureHelpBorder', { bg = M.panel, fg = M.edge_bright })
  groups('BlinkCmpScrollBar',   { bg = M.inset })
  groups('BlinkCmpScrollBarThumb', { bg = M.edge })
  groups('BlinkCmpLabel',       { fg = M.text })
  groups('BlinkCmpLabelMatch',  { fg = '#FFFFFF', fmt = 'bold,underline' })
  groups('BlinkCmpSource',      { fg = M.muted })
  groups('BlinkCmpLabelDetail BlinkCmpLabelDescription', { fg = M.muted })
  groups('BlinkCmpLabelDeprecated', { fg = M.muted, fmt = 'strikethrough' })
  groups('BlinkCmpDocSeparator', { bg = M.inset, fg = M.edge })
  groups('BlinkCmpGhostText',   { fg = M.muted, fmt = 'italic' })

  -- ── Snacks.picker & explorer file tree ─────────────────────────────────
  groups('SnacksPicker',                  { bg = M.panel, fg = '#FFFFFF' })
  groups('SnacksPickerBorder',            { bg = M.panel, fg = M.edge })
  groups('SnacksPickerTitle',             { bg = M.panel, fg = c.focus, fmt = 'bold' })
  groups('SnacksPickerPrompt',            { fg = c.focus, fmt = 'bold' })
  groups('SnacksPickerMatch',             { fg = '#FFFFFF', bg = '#5C0F1D', fmt = 'bold' })
  groups('SnacksPickerDirectory',         { fg = '#70D7FF', fmt = 'bold' })
  groups('SnacksPickerFile',              { fg = '#FFFFFF' })
  groups('SnacksPickerDir',               { fg = c.path })
  groups('SnacksPickerPathIgnored',       { fg = c.muted })
  groups('SnacksPickerPathHidden',        { fg = c.muted })
  groups('SnacksPickerTree',              { fg = M.edge })
  groups('SnacksPickerGitStatusUntracked', { fg = c.info, fmt = 'bold' })
  groups('SnacksPickerGitStatusModified',  { fg = '#FFD166', fmt = 'bold' })
  groups('SnacksPickerGitStatusStaged',    { fg = '#7FE3C2', fmt = 'bold' })
  groups('SnacksPickerGitStatusDeleted',   { fg = c.focus, fmt = 'strikethrough' })
  groups('SnacksPickerGitStatusIgnored',   { fg = c.muted, fmt = 'italic' })
  groups('SnacksPickerSelected',          { bg = '#4A101A', fg = '#FFFFFF', fmt = 'bold' })
  groups('SnacksPickerList',              { bg = M.panel, fg = '#FFFFFF' })
  groups('SnacksPickerInput',             { bg = M.panel, fg = '#FFFFFF' })
  groups('SnacksExplorerDir',             { fg = '#70D7FF', fmt = 'bold' })
  groups('SnacksExplorerFile',            { fg = '#FFFFFF' })

  groups('NoiceFormatProgressDone', { bg = M.selected, fg = M.text })
  groups('NoiceFormatProgressTodo', { bg = M.inset, fg = M.muted })
  groups('NoiceLspProgressTitle', { fg = M.accent })
  groups('NoiceLspProgressClient', { fg = M.panel_accent })
  groups('NoiceLspProgressSpinner', { fg = M.accent })

  -- Completion docs panel polish
  groups('BlackDocsCode', { bg = '#070B10', fg = M.text })
  groups('BlackDocsSeparator', { fg = M.edge })
  groups('BlackDocsParam', { fg = M.accent, fmt = 'bold' })
  groups('BlackDocsType', { fg = M.teal })
  groups('BlackDocsReturn', { fg = '#7FE3C2' })
  groups('RenderMarkdownH1 RenderMarkdownH2', { fg = M.accent, fmt = 'bold' })
  groups('RenderMarkdownH3 RenderMarkdownH4', { fg = M.lilac, fmt = 'bold' })
  groups('RenderMarkdownH1Bg RenderMarkdownH2Bg RenderMarkdownH3Bg RenderMarkdownH4Bg', { bg = M.panel })
  groups('RenderMarkdownCode', { bg = M.inset })
  groups('RenderMarkdownCodeInline', { bg = M.inset, fg = colors.cursor_insert })
  groups('RenderMarkdownBullet RenderMarkdownTableRow', { fg = M.muted })
  groups('RenderMarkdownTableHead', { fg = M.accent, fmt = 'bold' })
  groups('LspSignatureActiveParameter', { fg = '#FFFFFF', bg = '#4A101A', fmt = 'bold,underline' })

  -- Snacks input enhanced
  groups('SnacksInputIcon', { bg = M.panel, fg = M.accent })
  groups('SnacksInputPrompt', { bg = M.panel, fg = M.panel_accent, fmt = 'bold' })

  -- Mini.icons palette integration
  groups('MiniIconsAzure', { fg = '#70D7FF' })
  groups('MiniIconsBlue', { fg = '#69AFFF' })
  groups('MiniIconsCyan', { fg = '#70D7FF' })
  groups('MiniIconsGreen', { fg = '#7FE3C2' })
  groups('MiniIconsGrey', { fg = '#A9B9D6' })
  groups('MiniIconsOrange', { fg = '#FF9E64' })
  groups('MiniIconsPurple', { fg = '#C7A6FF' })
  groups('MiniIconsRed', { fg = '#FF8FA3' })
  groups('MiniIconsYellow', { fg = '#FFD166' })

  -- Lazy plugin manager panel
  groups('LazyNormal', { bg = M.panel, fg = M.text })
  groups('LazyButton', { bg = M.inset, fg = M.text })
  groups('LazyButtonActive', { bg = M.selected, fg = M.text, fmt = 'bold' })
  groups('LazyH1', { bg = M.accent, fg = '#000000', fmt = 'bold' })
  groups('LazyH2', { fg = M.accent, fmt = 'bold' })
  groups('LazySpecial', { fg = M.panel_accent })
  groups('LazyComment', { fg = M.muted })

  -- Mason installer panel
  groups('MasonNormal', { bg = M.panel, fg = M.text })
  groups('MasonHeader', { bg = M.accent, fg = '#000000', fmt = 'bold' })
  groups('MasonHighlight', { fg = M.accent })
  groups('MasonHighlightBlock', { bg = M.accent, fg = '#000000' })
  groups('MasonHighlightBlockBold', { bg = M.accent, fg = '#000000', fmt = 'bold' })
  groups('MasonMuted', { fg = M.muted })
  groups('MasonMutedBlock', { bg = M.inset, fg = M.muted })

  groups('GitStatusStaged', { fg = '#7FE3C2', fmt = 'bold' })
  groups('GitStatusModified', { fg = '#FFD166', fmt = 'bold' })
  groups('GitStatusUntracked', { fg = c.info, fmt = 'bold' })
  groups('GitStatusDeleted', { fg = c.focus, fmt = 'bold' })

  groups('BlackBrandIcon', { fg = '#FF1744' })
  groups('BlackBrand', { fg = c.focus, fmt = 'bold' })
  groups('BlackLabel', { fg = c.focus, fmt = 'bold' })
  groups('BlackMuted', { fg = M.muted })
  groups('BlackKey', { bg = M.selected, fg = '#FFFFFF', fmt = 'bold' })
  groups('BlackDashboardKey', { fg = M.teal, fmt = 'bold' })
  groups('BlackDashboardHeading', { fg = accessible and '#D7E3FF' or '#A9B9D6', fmt = 'bold' })
  groups('BlackDashboardMeta', { fg = M.muted })
  groups('BlackDashboardPath', { fg = M.text })
  groups('BlackRule', { fg = '#8B0018' })
  groups('CursorLine', { bg = '#111218' })
  groups('CursorLineNr', { fg = c.focus, fmt = 'bold' })
  groups('SnacksDashboardTerminal', { fg = c.muted })
  groups('SnacksDashboardFooter', { fg = c.muted })
  groups('SnacksDashboardHeader', { fg = c.focus, fmt = 'bold' })
  groups('SnacksDashboardKey', { fg = c.focus, fmt = 'bold' })
  groups('SnacksDashboardDesc', { fg = '#D7E3FF' })
  groups('SnacksDashboardIcon', { fg = c.focus })
  groups('SnacksDashboardSpecial', { fg = c.focus, fmt = 'bold' })
  groups('SnacksDashboardDir', { fg = c.muted })
  groups('SnacksDashboardFile', { fg = '#FFFFFF' })


  if accessible then
    for _, spec in pairs(h) do
      if spec.fmt then spec.fmt = spec.fmt:gsub('italic', '') end
    end
    groups('WinSeparator', { fg = M.edge, bg = '#000000' })
    groups('SnacksDashboardDir SnacksDashboardFooter', { fg = M.muted })
  end
  return h
end
return M
