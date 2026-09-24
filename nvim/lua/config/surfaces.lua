-- Shared tokens for every interactive panel, independent of the code palette.
local M = {
  panel = "#10151C",
  inset = "#0A0F16",
  edge = "#354357",
  selected = "#243B59",
  accent = "#82AAFF",
  text = "#E6E6E6",
  muted = "#A0AFC1",
}

function M.highlights()
  local h = {}
  local function groups(names, value)
    for name in names:gmatch("%S+") do h[name] = vim.deepcopy(value) end
  end
  groups("NormalFloat BlackDocs SnacksPickerBox SnacksPickerInput SnacksPickerList NoiceCmdlinePopup NoicePopupmenu SnacksInputNormal WhichKeyNormal NoicePopup SnacksNotifierHistory", { bg = M.panel, fg = M.text })
  groups("FloatBorder BlackDocsBorder SnacksPickerBoxBorder NoiceCmdlinePopupBorder NoicePopupmenuBorder SnacksInputBorder WhichKeyBorder NoicePopupBorder", { bg = M.panel, fg = M.edge })
  groups("FloatTitle BlackDocsTitle SnacksPickerBoxTitle SnacksPickerInputTitle NoiceCmdlinePopupTitle SnacksInputTitle", { bg = M.panel, fg = M.accent, fmt = "bold" })
  groups("SnacksPickerBoxFooter BlackDocsHint", { bg = M.panel, fg = M.muted })
  groups("SnacksPickerPreview NeoTreeNormal NeoTreeNormalNC", { bg = M.inset, fg = M.text })
  groups("SnacksPickerPreviewBorder", { bg = M.inset, fg = M.inset })
  groups("SnacksPickerPreviewTitle", { bg = M.inset, fg = M.muted })
  groups("SnacksPickerListCursorLine PmenuSel NoicePopupmenuSelected NeoTreeCursorLine", { bg = M.selected, fg = M.text })
  groups("SnacksPickerSearch", { bg = M.selected, fg = M.accent, fmt = "bold" })
  groups("SnacksPickerPreviewCursorLine", { bg = "#172333" })
  groups("SnacksPickerPrompt SnacksPickerMatch", { fg = M.accent, fmt = "bold" })
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
