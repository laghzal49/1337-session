-- Shared tokens for every interactive panel, independent of the code palette.
local M = {
  panel = "#0E141D",
  inset = "#070B10",
  edge = "#2A3649",
  selected = "#1E2F47",
  accent = "#82AAFF",
  text = "#E6E6E6",
  muted = "#8B9BB0",
}

function M.highlights()
  local h = {}
  local function groups(names, value)
    for name in names:gmatch("%S+") do h[name] = vim.deepcopy(value) end
  end
  groups("NormalFloat BlackDocs NoiceCmdlinePopup NoicePopupmenu SnacksInputNormal WhichKeyNormal NoicePopup SnacksNotifierHistory", { bg = M.panel, fg = M.text })
  groups("FloatBorder BlackDocsBorder NoiceCmdlinePopupBorder NoicePopupmenuBorder SnacksInputBorder WhichKeyBorder NoicePopupBorder", { bg = M.panel, fg = M.edge })
  groups("FloatTitle BlackDocsTitle NoiceCmdlinePopupTitle SnacksInputTitle", { bg = M.panel, fg = M.accent, fmt = "bold" })
  groups("BlackRule", { fg = M.edge })
  groups("BufferLineIndicatorSelected", { fg = M.accent, bg = M.selected })
  groups("BufferLineBufferSelected", { fg = M.text, bg = M.selected, fmt = "bold" })
  groups("BufferLineModifiedSelected", { fg = M.accent, bg = M.selected })
  groups("BlackDocsHint", { bg = M.panel, fg = M.muted })
  groups("PmenuSel NoicePopupmenuSelected ", { bg = M.selected, fg = M.text })
  groups("MiniFilesNormal MiniNotifyNormal GlanceListNormal MiniPickNormal AerialNormal", { bg = M.panel, fg = M.text })
  groups("MiniFilesBorder MiniNotifyBorder MiniPickBorder", { bg = M.panel, fg = M.edge })
  groups("MiniFilesTitle MiniFilesTitleFocused MiniFilesBorderModified", { bg = M.panel, fg = M.accent, fmt = "bold" })
  groups("MiniFilesCursorLine GlanceListCursorLine MiniPickMatchCurrent AerialLine", { bg = M.selected, fg = M.text })
  groups("GlancePreviewNormal GlanceWinBarFilename GlanceWinBarFilepath", { bg = M.inset, fg = M.text })
  groups("GlanceListMatch GlancePreviewMatch MiniPickMatchRanges AerialGuide", { fg = M.accent, fmt = "bold" })
  groups("MiniPickPrompt MiniPickBorderText", { bg = M.panel, fg = M.accent, fmt = "bold" })
  groups("MiniPickMatchMarked", { bg = M.selected, fg = M.accent })
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
