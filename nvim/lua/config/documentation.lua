local M = {}
local installed = false

local function decorate(win)
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local config = vim.api.nvim_win_get_config(win)
  if config.relative == "" or config.width < 28 then return end
  vim.api.nvim_win_set_config(win, {
    title = { { "  DOCUMENTATION ", "BlackDocsTitle" } }, title_pos = "left",
    footer = { { config.width >= 42 and " C-b / C-f scroll · C-d close " or " C-d close ", "BlackDocsHint" } },
    footer_pos = "right",
  })
end

function M.setup()
  if installed then return end
  -- The pinned cmp fork has no docs-open event. Hook this one rendering method
  -- so labels follow resolved content and resizing, without timers or polling.
  local view = require("cmp.view.docs_view")
  local open = view.open
  view.open = function(self, ...)
    local result = open(self, ...)
    decorate(self.window.win)
    return result
  end
  installed = true
end
return M
