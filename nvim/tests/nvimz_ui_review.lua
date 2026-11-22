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
-- Regression for TextChangedI picker crash: preview APIs reject embedded LF.
assert(picker.sanitize_line('before\nafter') == 'before after',
  'picker preview sanitizer must flatten embedded newlines')
assert(picker.sanitize_line('before\r\nafter\tend') == 'before  after  end',
  'picker must normalize CRLF and tabs')
assert(not picker.sanitize_line('x\nmore'):find('\n', 1, true),
  'picker must not pass newlines into nvim_buf_set_lines')
local oil = require('config.nvimz_files')
assert(type(oil.toggle) == 'function', 'Oil explorer mapping missing')
local ui = require('config.palette')
assert(ui.canvas == '#0b1210' and ui.focus == '#61afef', 'nvimz palette mismatch')
assert(type(require('config.performance').large) == 'function',
  'original bigfile performance guard missing')
-- Legacy documentation and docstring integrations must not reactivate.
assert(vim.fn.exists(':Docs') == 0 and vim.fn.exists(':DocsUpdate') == 0,
  'unused offline Docs commands still registered')
assert(vim.fn.maparg('<leader>dk', 'n') == '', 'legacy docs keymap still registered')
assert(vim.fn.maparg('gK', 'n') == '', 'deep Docs keymap still registered')
local cfg = require('lazy.core.config').plugins
assert(not cfg['neogen'] or not cfg['neogen'].enabled, 'unused neogen still enabled')
local function fg(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false }).fg
end
assert(fg('@type.definition') ~= fg('@function'), 'class and function look identical')
assert(fg('@function') ~= fg('@function.method.special'),
  '__init__ and regular functions look identical')
assert(fg('@function.method') ~= fg('@function'),
  'method and regular function look identical')
local q = vim.fn.readfile(vim.fn.stdpath('config') .. '/after/queries/python/highlights.scm')
assert(table.concat(q, '\\n'):find('__init__', 1, true),
  'Python constructor query missing')
print('nvimz UI and Python colors PASS (without unused Docs UI)')
