-- nvimz-inspired visual layer: Tokyo Night + shared Perfect Black UI tokens.
-- Keeps all existing editor features while making every panel use the same palette.
vim.cmd.colorscheme('tokyonight-night')
vim.g.colors_name = 'nvimz'

local c = require('config.palette')
local s = require('config.surfaces')
local hi = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end

-- Existing UI highlights are token-driven. Translate the older fmt convention
-- to native highlight attributes when applying them over Tokyo Night.
for name, spec in pairs(s.highlights()) do
  local opts = vim.deepcopy(spec)
  if opts.fmt then
    for token in opts.fmt:gmatch('[^,]+') do
      token = vim.trim(token)
      if token == 'bold' or token == 'italic' or token == 'underline'
        or token == 'undercurl' or token == 'strikethrough' then
        opts[token] = true
      end
    end
    opts.fmt = nil
  end
  hi(name, opts)
end

local groups = {
  Normal = { fg = c.text, bg = c.canvas },
  NormalNC = { fg = c.text, bg = c.canvas },
  NormalFloat = { fg = c.text, bg = c.popup },
  FloatBorder = { fg = c.border, bg = c.popup },
  FloatTitle = { fg = c.focus, bg = c.popup, bold = true },
  WinSeparator = { fg = c.border_soft, bg = c.canvas },
  CursorLine = { bg = c.line },
  CursorLineNr = { fg = c.focus, bold = true },
  LineNr = { fg = c.gutter },
  SignColumn = { bg = c.canvas },
  FoldColumn = { bg = c.canvas, fg = c.gutter },
  WinBar = { fg = c.path, bg = c.canvas },
  WinBarNC = { fg = c.muted, bg = c.canvas },
  StatusLine = { fg = c.text, bg = c.panel },
  StatusLineNC = { fg = c.muted, bg = c.inset },
  TabLine = { fg = c.muted, bg = c.inset },
  TabLineSel = { fg = c.strong, bg = c.selection },
  TabLineFill = { bg = c.inset },
  Pmenu = { fg = c.text, bg = c.popup },
  PmenuSel = { fg = c.strong, bg = c.selection },
  PmenuBorder = { fg = c.border, bg = c.popup },
  Visual = { bg = c.selection },
  Search = { fg = c.search_text, bg = c.search_bg },
  IncSearch = { fg = c.on_accent, bg = c.focus, bold = true },
  Directory = { fg = c.focus },
  SnacksDashboardHeader = { fg = c.focus, bold = true },
  SnacksDashboardDesc = { fg = c.text },
  SnacksDashboardIcon = { fg = c.focus },
  SnacksDashboardFooter = { fg = c.muted },
  SnacksDashboardKey = { fg = c.keyword, bold = true },
  SnacksDashboardSpecial = { fg = c.focus },
  SnacksDashboardDir = { fg = c.muted },
  SnacksIndent = { fg = c.guide },
  SnacksIndentScope = { fg = c.border },
  BufferLineFill = { bg = c.inset },
  BufferLineBackground = { fg = c.muted, bg = c.inset },
  BufferLineBufferSelected = { fg = c.strong, bg = c.selection },
  BufferLineIndicatorSelected = { fg = c.focus, bg = c.selection },
  TreesitterContext = { bg = c.panel },
  TreesitterContextLineNumber = { fg = c.muted, bg = c.panel },
  BlinkCmpMenu = { fg = c.text, bg = c.popup },
  BlinkCmpMenuBorder = { fg = c.border, bg = c.popup },
  BlinkCmpMenuSelection = { fg = c.strong, bg = c.selection },
  BlinkCmpDoc = { fg = c.text, bg = c.popup },
  BlinkCmpDocBorder = { fg = c.border, bg = c.popup },
  SnacksPickerBorder = { fg = c.border, bg = c.panel },
  SnacksPickerTitle = { fg = c.focus, bg = c.panel },
  SnacksPickerInput = { fg = c.text, bg = c.panel },
  SnacksPickerList = { fg = c.text, bg = c.panel },
  SnacksPickerPreview = { fg = c.text, bg = c.inset },
  SnacksPickerListCursorLine = { fg = c.strong, bg = c.selection },
}
for name, opts in pairs(groups) do hi(name, opts) end
