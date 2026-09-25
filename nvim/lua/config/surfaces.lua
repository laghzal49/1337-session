-- Shared tokens for every interactive panel, independent of the code palette.
local ui = require("config.ui")
local colors = ui.colors

local M = {
  panel = "#0E141D",
  tree_panel = "#0C1718",
  inset = "#070B10",
  edge = colors.border,
  edge_bright = colors.teal,
  edge_soft = colors.border_soft,
  selected = colors.selection,
  selected_bright = colors.selection_bright,
  accent = "#69AFFF",
  panel_accent = colors.teal,
  text = colors.text,
  muted = "#61708A",
  teal = colors.teal,
  lilac = colors.lilac,
  border = colors.border,
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
  groups("MiniFilesNormal", { bg = M.tree_panel, fg = M.text })
  groups("MiniFilesDirectory MiniFilesDirectoryIcon", { fg = M.panel_accent, fmt = "bold" })
  groups("MiniFilesFile MiniFilesFileIcon", { fg = M.text })
  groups("MiniFilesSymlink", { fg = M.accent, fmt = "italic" })
  groups("MiniNotifyNormal GlanceListNormal MiniPickNormal AerialNormal", { bg = M.panel, fg = M.text })
  groups("MiniFilesBorderModified", { bg = M.tree_panel, fg = M.panel_accent, fmt = "bold" })
  groups("MiniFilesBorder", { bg = M.tree_panel, fg = M.edge_bright })
  groups("MiniNotifyBorder MiniPickBorder AerialBorder GlanceBorderTop GlanceListBorderBottom GlancePreviewBorderBottom", { bg = M.panel, fg = M.edge_bright })
  groups("MiniFilesTitle", { bg = M.tree_panel, fg = M.panel_accent, fmt = "bold" })
  groups("MiniFilesTitleFocused", { bg = M.selected_bright, fg = M.text, fmt = "bold" })
  groups("MiniFilesCursorLine GlanceListCursorLine MiniPickMatchCurrent AerialLine", { bg = M.selected_bright, fg = M.text, fmt = "bold" })
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
  return h
end
return M
