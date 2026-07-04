-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- AUTOFORMAT ON SAVE — explicit, not implied. LazyVim runs conform.nvim on
-- every :w when this is true (its default, pinned here so it can never
-- silently regress): ruff for Python (imports + format, python.lua),
-- stylua for Lua, shfmt for shell — all auto-installed via mason.
-- Toggle per-session with <leader>uf (stock LazyVim keymap).
vim.g.autoformat = true

-- terminal / OS window title follows the current file
vim.opt.title = true
vim.opt.titlestring = "%t %m — nvim"

-- mode-tinted cursor: every shape uses the CarbonCursor group, which the
-- reactive engine (lua/carbon/reactive.lua) repaints live with the mode
-- accent — the actual cursor block morphs purple/cyan/pink/mint/blue with
-- the rest of the UI. The gentle blink is kept exactly as before.
-- (Terminals without cursor-color support just ignore the group — safe.)
vim.opt.guicursor = table.concat({
  "n-v-sv:block-CarbonCursor",
  "i-ci-ve:ver25-CarbonCursor",
  "r-cr-o:hor20-CarbonCursor",
  "c:ver25-CarbonCursor",
  "a:blinkwait700-blinkoff400-blinkon600",
}, ",")

-- scrolling over wrapped lines moves by screen line, not text line (0.10+)
vim.opt.smoothscroll = true

-- completion menu: cap the height so it never swallows the screen
vim.opt.pumheight = 12

-- quieter chrome: no ~ on empty lines, invisible fold filler, nerd-font
-- fold markers in the statuscolumn, diagonal hatch for deleted diff lines
vim.opt.fillchars = {
  eob = " ",
  fold = " ",
  foldopen = "",
  foldclose = "",
  diff = "╱",
}
