-- Regression guard for the balanced Rose theme and statusline chrome.
-- Run with full config: NVIM_COLOR_STYLE=rose nvim --headless
--   +'lua dofile("nvim/tests/rose_polish_review.lua")' +qa!
local c = require('config.palette')
assert(vim.g.black_color_style == 'rose', 'test requires NVIM_COLOR_STYLE=rose')
local hex = function(color) return tonumber(color:sub(2), 16) end
local function luminance(color)
  local rgb = hex(color)
  local sum = 0
  for i, weight in ipairs({0.2126, 0.7152, 0.0722}) do
    local x = math.floor(rgb / 256 ^ (3 - i)) % 256 / 255
    sum = sum + weight * (x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4)
  end
  return sum
end
local function ratio(fg, bg)
  local a, b = luminance(fg), luminance(bg)
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
end
assert(c.variable ~= c.string and c.parameter ~= c.variable and c.success ~= c.string,
  'rose syntax, parameter and success roles must be distinguishable')
assert(c.canvas == '#000000', 'keep the pure-black editing background')
assert(vim.api.nvim_get_hl(0, {name='CursorLine',link=false}).bg == hex(c.line),
  'active line must use the dedicated rose line surface')
for _, role in ipairs({'variable', 'parameter', 'member', 'string', 'callable',
  'keyword', 'type', 'text', 'muted', 'gutter', 'comment'}) do
  assert(ratio(c[role], c.line) >= 4.5, role .. ' unreadable on active line')
end
local config = require('plugins.statusline')[1].opts()
assert(config.options.theme.normal.a.bg == c.focus,
  'NORMAL mode capsule must use rose focus')
assert(config.options.theme.normal.a.fg == c.on_accent,
  'mode label must contrast with its colored background')
assert(ratio(c.on_accent, c.focus) >= 4.5, 'mode capsule is unreadable')
local code = vim.api.nvim_get_hl(0, {name='@variable',link=false})
assert(code.fg == hex(c.variable), 'Tree-sitter variable color diverges')
print('ROSE POLISH PASS: semantic colors, contrast, active line and statusline capsule')
