-- Headless smoke test: the nvimz UI must load without removing the IDE.
assert(vim.g.black_color_style == 'nvimz', 'nvimz must be the default preset')
assert(vim.g.colors_name == 'nvimz', 'nvimz colorscheme did not load')
assert(vim.fn.hlexists('NvimzStatusLocation') == 1, 'statusline highlights missing')
assert(vim.fn.hlexists('NormalFloat') == 1, 'floating window highlight missing')
assert(vim.fn.hlexists('BlinkCmpMenu') == 1, 'completion highlight missing')
assert(vim.o.showtabline == 0, 'bufferline remains visible')
assert(vim.o.relativenumber == false, 'nvimz uses absolute line numbers')
assert(vim.o.statusline:find('config.nvimz_statusline', 1, true),
  'nvimz statusline is not active')
local dashboard = require('config.nvimz_dashboard')
assert(type(dashboard.open_if_empty) == 'function', 'nvimz dashboard missing')
local picker = require('config.nvimz_picker')
assert(type(picker.files) == 'function' and type(picker.grep) == 'function',
  'native file or grep picker missing')
local oil = require('config.nvimz_files')
assert(type(oil.toggle) == 'function', 'Oil explorer mapping missing')
local ui = require('config.palette')
assert(ui.canvas == '#0b1210' and ui.focus == '#61afef', 'nvimz palette mismatch')
assert(type(require('config.performance').large) == 'function',
  'original bigfile performance guard missing')
print('nvimz UI smoke test PASS')
