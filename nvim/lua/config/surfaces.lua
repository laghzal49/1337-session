-- Shared tokens for every interactive panel, independent of the code palette.
local M = {
  panel = "#0E141D",
  tree_panel = "#0C1718",
  inset = "#070B10",
  edge = "#25334A",
  edge_bright = "#4FD1C5",
  edge_soft = "#2A5961",
  selected = "#14263D",
  selected_bright = "#164B4A",
  accent = "#69AFFF",
  panel_accent = "#4FD1C5",
  text = "#D7E3FF",
  muted = "#61708A",
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
  groups("MiniFilesNormal", { bg = M.tree_panel, fg = M.text })
  groups("MiniNotifyNormal GlanceListNormal MiniPickNormal AerialNormal", { bg = M.panel, fg = M.text })
  groups("MiniFilesDirectory MiniFilesDirectoryIcon", { fg = M.panel_accent, fmt = "bold" })
  groups("MiniFilesFile MiniFilesFileIcon MiniFilesSymlink", { fg = M.text })
  groups("MiniFilesBorderModified", { bg = M.panel, fg = M.panel_accent, fmt = "bold" })
  groups("MiniFilesBorder", { bg = M.tree_panel, fg = M.edge_bright })
  groups("MiniNotifyBorder MiniPickBorder AerialBorder GlanceBorderTop GlanceListBorderBottom GlancePreviewBorderBottom", { bg = M.panel, fg = M.edge_bright })
  groups("MiniFilesTitle MiniFilesTitleFocused MiniFilesBorderModified", { bg = M.tree_panel, fg = M.panel_accent, fmt = "bold" })
  groups("MiniFilesCursorLine GlanceListCursorLine MiniPickMatchCurrent AerialLine", { bg = M.selected_bright, fg = M.text, fmt = "bold" })
  groups("GlancePreviewNormal GlanceWinBarFilename GlanceWinBarFilepath MiniPickPreviewNormal", { bg = M.inset, fg = M.text })
  groups("GlanceListMatch GlancePreviewMatch MiniPickMatchRanges AerialGuide AerialClass AerialFunction AerialMethod AerialVariable", { fg = M.panel_accent, fmt = "bold" })
  groups("MiniPickPrompt MiniPickPromptPrefix MiniPickPromptCaret MiniPickBorderText MiniPickHeader MiniFilesTitleFocused", { bg = M.panel, fg = M.panel_accent, fmt = "bold" })
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
  return h
end
return M
