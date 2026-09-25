vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- Add any additional options here

-- A black, opaque canvas with one compact status row and one tab row.
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.number = true
-- Keep one sign slot; add a second when multiple signs share a line.
vim.opt.signcolumn = "auto:1-2"
vim.opt.statuscolumn = "" -- Native rendering honors the dynamic sign width.
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.showmode = false
vim.opt.showcmd = false
vim.opt.ruler = false
vim.opt.shortmess:append({ I = true, W = true, c = true })
vim.opt.timeoutlen = 350
vim.opt.updatetime = 250
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.opt.fillchars:append({ eob = " ", fold = " ", foldopen = "", foldclose = "", foldsep = " ", vert = "│", diff = " " })

-- Stable visual anchors; a short completion menu keeps code visible.
vim.opt.pumheight = 8
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,line"
vim.opt.numberwidth = 2
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }

vim.opt.winborder = require("config.ui").border


vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.wrap = false
vim.opt.synmaxcol = 300

-- Keep the current split visually anchored without making other splits compete
-- for attention. Preserve window-local highlighting used by floating panels.
local focus_group = vim.api.nvim_create_augroup("BlackWindowFocus", { clear = true })
local function update_window_focus()
  local current = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
      vim.wo[win].cursorline = win == current
      vim.wo[win].cursorlineopt = win == current and "number,line" or "number"
      vim.wo[win].winhighlight = win == current
        and "Normal:Normal,NormalNC:NormalNC,StatusLine:StatusLine,StatusLineNC:StatusLineNC"
        or "Normal:NormalNC,NormalNC:NormalNC,StatusLine:StatusLineNC,StatusLineNC:StatusLineNC"
    end
  end
end
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "WinLeave" }, {
  group = focus_group,
  callback = update_window_focus,
})
