local M = {}
local installed = false

local function decorate(win)
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  local config = vim.api.nvim_win_get_config(win)
  if config.relative == "" then return end
  local min_w = 32
  local width = math.max(config.width, min_w)
  local col = config.col
  if col + width + 2 > vim.o.columns then
    col = math.max(0, vim.o.columns - width - 2)
  end
  local footer_text = width >= 38 and " ^B / ^F scroll · ^D close " or " ^D close "
  local win_cfg = {
    title = { { " 󰋖 DOCUMENTATION ", "BlackDocsTitle" } },
    title_pos = "left",
    footer = { { footer_text, "BlackDocsHint" } },
    footer_pos = "right",
  }
  if width ~= config.width or col ~= config.col then
    win_cfg.width = width
    win_cfg.col = col
  end
  local ok = pcall(vim.api.nvim_win_set_config, win, win_cfg)
  if not ok then
    pcall(vim.api.nvim_win_set_config, win, {
      title = { { " 󰋖 DOCUMENTATION ", "BlackDocsTitle" } },
      title_pos = "left",
      footer = { { footer_text, "BlackDocsHint" } },
      footer_pos = "right",
    })
  end
  vim.wo[win].winblend = 0
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
