-- Shared tokens for every interactive panel, independent of the code palette.
local ui = require("config.ui")
local colors = ui.colors

local M = {
  panel = "#0E0E14",
  tree_panel = "#0A0A0F",
  inset = "#07070B",
  edge = "#5C1522",
  edge_bright = "#FF2E4C",
  edge_soft = "#3D101A",
  selected = "#380D14",
  selected_bright = "#4E121D",
  accent = "#FF2E4C",
  panel_accent = "#FF3B56",
  text = colors.text,
  muted = "#7A5A62",
  teal = colors.teal,
  lilac = colors.lilac,
  border = "#5C1522",
  error = colors.error,
}

function M.highlights()
  local h = {}
  local function groups(names, value)
    for name in names:gmatch("%S+") do h[name] = vim.deepcopy(value) end
  end
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
  groups("GlanceListMatch GlancePreviewMatch MiniPickMatchRanges AerialGuide AerialClass AerialFunction AerialMethod AerialVariable", { fg = M.panel_accent, fmt = "bold" })
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
  groups('EdgyTitle', { bg = '#0A0A0E', fg = '#FF4D6D', fmt = 'bold' })
  groups('EdgyIcon EdgyIconActive', { bg = '#0A0A0E', fg = '#FF2E4C' })
  groups('EdgyWinBar', { bg = '#0A0A0E', fg = '#FF4D6D', fmt = 'bold' })
  groups('EdgyNormal', { bg = '#0A0A0E', fg = M.text })
  groups('AerialNormal', { bg = '#0A0A0E', fg = M.text })
  groups('AerialLine', { bg = '#3D0D14', fg = '#FF4D6D', fmt = 'bold' })
  -- Trouble panel chrome
  groups('TroubleNormal TroubleNormalNC', { bg = M.panel, fg = M.text })
  groups('TroubleCount', { fg = M.accent, fmt = 'bold' })
  
  -- Flash jump labels — hot pink bg, white fg for maximum contrast
  groups('FlashLabel', { bg = '#FF8FA3', fg = '#FFFFFF', fmt = 'bold' })
  groups('FlashMatch', { fg = M.accent })
  groups('FlashCurrent', { fg = M.text, fmt = 'bold' })
  groups('FlashBackdrop', { fg = M.muted })

  -- WhichKey full suite
  groups('WhichKeySeparator', { fg = M.edge })
  groups('WhichKeyValue',     { fg = M.muted })
  groups('WhichKeyBorder',    { bg = M.panel, fg = M.edge_bright })
  groups('WhichKeyTitle',     { bg = M.panel, fg = M.accent, fmt = 'bold' })
  groups('WhichKeyDesc',      { fg = M.text })

  -- TreesitterContext — dark panel bg, subtle italic
  groups('TreesitterContext',           { bg = M.panel, fmt = 'italic' })
  groups('TreesitterContextLineNumber', { bg = M.panel, fg = M.muted })
  groups('TreesitterContextSeparator',  { fg = M.edge })
  groups('TreesitterContextBottom',     { fmt = 'underline', sp = M.edge })

  -- ── blink.cmp kind highlights (all 25 kinds) ─────────────────────────
  -- Mapped 1:1 to Perfect Black palette tokens
  local blink_kinds = {
    Text          = M.text,
    Method        = '#69AFFF',
    Function      = '#69AFFF',
    Constructor   = '#7FE3C2',
    Field         = '#70D7FF',
    Variable      = '#E6B3FF',
    Class         = '#E8D48B',
    Interface     = '#7FE3C2',
    Module        = M.text,
    Property      = '#70D7FF',
    Unit          = '#FF9E64',
    Value         = '#B8E986',
    Enum          = '#7FE3C2',
    Keyword       = M.lilac,
    Snippet       = '#70D7FF',
    Color         = '#FF8FA3',
    File          = M.text,
    Reference     = M.accent,
    Folder        = M.accent,
    EnumMember    = '#70D7FF',
    Constant      = M.text,
    Struct        = '#7FE3C2',
    Event         = '#FF9E64',
    Operator      = '#70D7FF',
    TypeParameter = '#7FE3C2',
  }
  for kind, color in pairs(blink_kinds) do
    h['BlinkCmpKind' .. kind] = { fg = color }
  end
  -- blink.cmp doc/menu chrome
  groups('BlinkCmpMenu',        { bg = M.panel, fg = M.text })
  groups('BlinkCmpMenuBorder',  { bg = M.panel, fg = M.edge_bright })
  groups('BlinkCmpMenuSelection',{ bg = M.selected, fg = M.text, fmt = 'bold' })
  groups('BlinkCmpDoc',         { bg = M.inset, fg = M.text })
  groups('BlinkCmpDocBorder',   { bg = M.inset, fg = M.edge })
  groups('BlinkCmpScrollBar',   { bg = M.inset })
  groups('BlinkCmpScrollBarThumb', { bg = M.edge })
  groups('BlinkCmpLabel',       { fg = M.text })
  groups('BlinkCmpLabelMatch',  { fg = '#FFFFFF', fmt = 'bold,underline' })
  groups('BlinkCmpSource',      { fg = M.muted })
  groups('BlinkCmpGhostText',   { fg = M.muted, fmt = 'italic' })

  -- ── Harpoon2 window chrome ────────────────────────────────────────────
  groups('HarpoonWindow', { bg = M.panel, fg = M.text })
  groups('HarpoonBorder', { bg = M.panel, fg = M.edge_bright })
  groups('HarpoonTitle',  { bg = M.panel, fg = M.accent, fmt = 'bold' })

  -- ── Snacks.picker & explorer file tree ─────────────────────────────────
  groups('SnacksPicker',                  { bg = M.panel, fg = '#FFFFFF' })
  groups('SnacksPickerBorder',            { bg = M.panel, fg = '#5C1522' })
  groups('SnacksPickerTitle',             { bg = M.panel, fg = '#FF2E4C', fmt = 'bold' })
  groups('SnacksPickerPrompt',            { fg = '#FF2E4C', fmt = 'bold' })
  groups('SnacksPickerMatch',             { fg = '#FFFFFF', bg = '#5C0F1D', fmt = 'bold' })
  groups('SnacksPickerDirectory',         { fg = '#FF4D6D', fmt = 'bold' })
  groups('SnacksPickerFile',              { fg = '#FFFFFF' })
  groups('SnacksPickerDir',               { fg = '#C4A0A6' })
  groups('SnacksPickerPathIgnored',       { fg = '#8A6A72' })
  groups('SnacksPickerPathHidden',        { fg = '#8A6A72' })
  groups('SnacksPickerTree',              { fg = '#7A222F' })
  groups('SnacksPickerGitStatusUntracked', { fg = '#FF4D6D', fmt = 'bold' })
  groups('SnacksPickerGitStatusModified',  { fg = '#FFD166', fmt = 'bold' })
  groups('SnacksPickerGitStatusStaged',    { fg = '#7FE3C2', fmt = 'bold' })
  groups('SnacksPickerGitStatusDeleted',   { fg = '#FF2E4C', fmt = 'strikethrough' })
  groups('SnacksPickerGitStatusIgnored',   { fg = '#8A6A72', fmt = 'italic' })
  groups('SnacksPickerSelected',          { bg = '#4A101A', fg = '#FFFFFF', fmt = 'bold' })
  groups('SnacksPickerList',              { bg = M.panel, fg = '#FFFFFF' })
  groups('SnacksPickerInput',             { bg = M.panel, fg = '#FFFFFF' })
  groups('SnacksExplorerDir',             { fg = '#FF4D6D', fmt = 'bold' })
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
  groups('MiniIconsRed', { fg = '#FF2E4C' })
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
  groups('GitStatusUntracked', { fg = '#FF4D6D', fmt = 'bold' })
  groups('GitStatusDeleted', { fg = '#FF2E4C', fmt = 'bold' })

  groups('BlackBrandIcon', { fg = '#FF1744' })
  groups('BlackBrand', { fg = '#FF2E4C', fmt = 'bold' })
  groups('BlackLabel', { fg = '#FF4D6D', fmt = 'bold' })
  groups('BlackMuted', { fg = '#A8606B' })
  groups('BlackKey', { bg = '#4A0E17', fg = '#FF4D6D', fmt = 'bold' })
  groups('BlackRule', { fg = '#8B0018' })
  groups('CursorLine', { bg = '#180A0E' })
  groups('CursorLineNr', { fg = '#FF2E4C', fmt = 'bold' })
  groups('SnacksDashboardTerminal', { fg = '#A8606B' })
  groups('SnacksDashboardFooter', { fg = '#A8606B' })
  groups('SnacksDashboardHeader', { fg = '#FF2E4C', fmt = 'bold' })
  groups('SnacksDashboardKey', { fg = '#FF4D6D', fmt = 'bold' })
  groups('SnacksDashboardDesc', { fg = '#D7E3FF' })
  groups('SnacksDashboardIcon', { fg = '#FF4D6D' })
  groups('SnacksDashboardSpecial', { fg = '#FF2E4C', fmt = 'bold' })
  groups('SnacksDashboardDir', { fg = '#A8606B' })
  groups('SnacksDashboardFile', { fg = '#FFFFFF' })


  return h
end
return M
