-- Shared tokens for every interactive panel, independent of the code palette.
local ui = require("config.ui")
local colors = ui.colors

local M = {
  panel = "#0E141D",
  tree_panel = "#0A0F17",
  inset = "#070B10",
  edge = "#38557A",
  edge_bright = "#4FD1C5",
  edge_soft = "#2A3F5C",
  selected = "#1B3352",
  selected_bright = "#1B3352",
  accent = "#82AAFF",
  panel_accent = "#4FD1C5",
  text = colors.text,
  muted = "#61708A",
  teal = colors.teal,
  lilac = colors.lilac,
  border = "#38557A",
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
  groups("BlackRule", { fg = M.edge })
  groups("BufferLineIndicatorSelected", { fg = M.accent, bg = M.selected })
  groups("BufferLineBufferSelected", { fg = M.text, bg = M.selected, fmt = "bold" })
  groups("BufferLineModifiedSelected", { fg = M.accent, bg = M.selected })
  groups("BlackDocsHint", { bg = M.panel, fg = M.muted })
  groups("PmenuSel NoicePopupmenuSelected ", { bg = M.selected, fg = M.text })
  local tree_bg = "#080C14"
  local tree_border = "#24364D"
  local tree_cursor = "#18283D"
  local tree_title_focused = "#1C314C"

  groups("MiniFilesNormal", { bg = tree_bg, fg = "#D7E3FF" })
  groups("MiniFilesBorder", { bg = tree_bg, fg = tree_border })
  groups("MiniFilesBorderModified", { bg = tree_bg, fg = "#FFD166", fmt = "bold" })
  groups("MiniFilesCursorLine", { bg = tree_cursor, fg = "#FFFFFF", fmt = "bold" })
  groups("MiniFilesTitle", { bg = tree_bg, fg = "#61708A", fmt = "bold" })
  groups("MiniFilesTitleFocused", { bg = tree_title_focused, fg = "#82AAFF", fmt = "bold" })
  groups("MiniFilesTitleCount", { bg = tree_bg, fg = "#61708A" })
  groups("MiniFilesDirectory", { fg = "#D7E3FF", fmt = "bold" })
  groups("MiniFilesDirectoryIcon", { fg = "#69AFFF" })
  groups("MiniFilesFile", { fg = "#A9B9D6" })
  groups("MiniFilesFileIcon", { fg = "#70D7FF" })
  groups("MiniFilesSymlink", { fg = "#C7A6FF", fmt = "italic" })
  groups("MiniFilesPathSep", { fg = tree_border })

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
  groups('EdgyTitle', { bg = '#0E141D', fg = '#7FE3C2', fmt = 'bold' })
  groups('EdgyIcon EdgyIconActive', { bg = '#0E141D', fg = '#69AFFF' })
  groups('EdgyWinBar', { bg = '#0E141D', fg = '#7FE3C2', fmt = 'bold' })
  groups('EdgyNormal', { bg = '#0E141D', fg = M.text })
  groups('AerialNormal', { bg = '#0E141D', fg = M.text })
  groups('AerialLine', { bg = '#1E2F47', fg = '#7FE3C2', fmt = 'bold' })
  -- Trouble panel chrome
  groups('TroubleNormal TroubleNormalNC', { bg = M.panel, fg = M.text })
  groups('TroubleCount', { fg = M.accent, fmt = 'bold' })
  
  -- Flash jump labels
  groups('FlashLabel', { bg = M.accent, fg = '#000000', fmt = 'bold' })
  groups('FlashMatch', { fg = M.panel_accent })
  groups('FlashCurrent', { fg = M.text, fmt = 'bold' })
  groups('FlashBackdrop', { fg = M.muted })
  
  -- WhichKey enhanced
  groups('WhichKeySeparator', { fg = M.edge })
  groups('WhichKeyValue', { fg = M.muted })
  
  -- Treesitter context line
  groups('TreesitterContextSeparator', { fg = M.edge })

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
  groups('LspSignatureActiveParameter', { fg = '#FFFFFF', bg = '#1F3F6B', fmt = 'bold,underline' })

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
  groups('GitStatusUntracked', { fg = '#70D7FF', fmt = 'bold' })
  groups('GitStatusDeleted', { fg = '#FF8FA3', fmt = 'bold' })

  groups('BlackBrandIcon', { fg = '#69AFFF' })
  groups('BlackBrand', { fg = '#C7A6FF', fmt = 'bold' })
  groups('BlackKey', { bg = '#1E2F47', fg = '#FFFFFF', fmt = 'bold' })
  groups('SnacksDashboardTerminal', { fg = '#61708A' })
  groups('SnacksDashboardFooter', { fg = '#61708A' })
  
  return h
end
return M
