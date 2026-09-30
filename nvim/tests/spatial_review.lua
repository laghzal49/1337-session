-- Run with the full config; no parser or LSP mocks for symbol extraction.
local cursor = require('config.cursor_ui')
local focus = require('config.focus_ui')
local symbol = require('config.symbol_context')
cursor.setup()
focus.setup()
symbol.setup()
vim.cmd('enew!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'first', 'second', 'third', 'fourth', 'fifth' })
local ns = cursor.namespace
for name, id in pairs(vim.api.nvim_get_namespaces()) do
  if name:lower():find('beacon', 1, true) then ns = id end
end
local function marks(buf)
  return vim.api.nvim_buf_get_extmarks(buf or 0, assert(ns, 'beacon namespace missing'), 0, -1, {})
end
cursor.cleanup()
cursor.setup()
cursor.flash()
assert(#marks() == 1, 'explicit destination beacon missing')
assert(vim.wait(600, function() return #marks() == 0 end), 'beacon did not expire')
for row = 1, 5 do
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  cursor.flash()
  assert(#marks() == 1, 'rapid jump leaked an extmark')
end
assert(vim.wait(600, function() return #marks() == 0 end), 'rapid jump timer did not expire')
local before = cursor.snapshot()
vim.api.nvim_win_set_cursor(0, { 1, 0 })
cursor.after(before)
assert(#marks() == 1, 'changed navigation destination was not emphasized')
cursor.cleanup()
assert(#marks() == 0, 'cleanup left an extmark')
cursor.setup()
vim.cmd('normal! jkhjl')
assert(#marks() == 0, 'ordinary movement triggered a beacon')
local first_buf = vim.api.nvim_get_current_buf()
vim.cmd('enew!')
vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
assert(vim.wait(100, function() return #marks() == 1 end), 'buffer switch beacon missing')
assert(#marks(first_buf) == 0, 'old buffer retained a beacon')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'first', 'second', 'third' })
local diagnostic_ns = vim.api.nvim_create_namespace('spatial_beacon_review')
vim.diagnostic.set(diagnostic_ns, 0, { { lnum = 2, col = 0, severity = 2, message = 'destination' } })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local diagnostic_map = vim.fn.maparg(']d', 'n', false, true)
assert(type(diagnostic_map.callback) == 'function', 'diagnostic mapping overridden: ' .. vim.inspect(diagnostic_map))
diagnostic_map.callback()
assert(vim.wait(200, function() return vim.api.nvim_win_get_cursor(0)[1] == 3 and #marks() == 1 end), 'diagnostic mapping beacon missing')
vim.diagnostic.reset(diagnostic_ns)
for _, win in ipairs(vim.api.nvim_list_wins()) do
  if vim.api.nvim_win_get_config(win).relative ~= '' then vim.api.nvim_win_close(win, true) end
end
vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '.lua')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local location = { uri = vim.uri_from_bufnr(0), range = {
  start = { line = 2, character = 0 }, ['end'] = { line = 2, character = 0 },
} }
vim.schedule(function() vim.lsp.util.show_document(location, 'utf-8', { focus = true }) end)
assert(vim.wait(200, function() return vim.api.nvim_win_get_cursor(0)[1] == 3 and #marks() == 1 end), 'asynchronous LSP destination beacon missing')
vim.fn.setqflist({}, 'r', { items = { { bufnr = vim.api.nvim_get_current_buf(), lnum = 1, col = 1 },
  { bufnr = vim.api.nvim_get_current_buf(), lnum = 3, col = 1 } } })
vim.cmd.cfirst()
cursor.clear()
local quickfix_map = vim.fn.maparg(']q', 'n', false, true)
assert(type(quickfix_map.callback) == 'function', 'quickfix beacon mapping overridden: ' .. vim.inspect(quickfix_map))
quickfix_map.callback()
assert(vim.api.nvim_win_get_cursor(0)[1] == 3 and #marks() == 1, 'native quickfix jump beacon missing')
cursor.cleanup()
print('BEACON: destination, expiry, rapid replacement, movement exclusion, buffer switch, diagnostic mapping, async LSP and cleanup PASS')

local gc = vim.o.guicursor:lower()
assert(gc:match('n[^:]*:block'), gc)
assert(gc:match('i[^:]*:ver%d+'), gc)
assert(gc:match('r[^:]*:hor%d+'), gc)
assert(gc:match('v[^:]*:block'), gc)
assert(gc:match('c[^:]*:'), gc)
print('MODE CURSOR: normal/visual block, insert bar, replace underline, command shape PASS')

local function fixture(ft, lines, row, expected)
  vim.cmd('enew!')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = ft
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok, parser = pcall(vim.treesitter.get_parser, 0, lang)
  assert(ok and parser, 'installed ' .. lang .. ' parser is required for this integration test')
  parser:parse()
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  symbol.update()
  local value = vim.b.current_symbol or ''
  assert(type(value) == 'string', vim.inspect(value))
  if expected then assert(value:find(expected, 1, true), ft .. ': ' .. value)
  else assert(value == '', 'top-level symbol should be empty: ' .. value) end
end
fixture('python', { 'class Outer:', '    class Bm25:', '        def search(self):', '            return 42', '', 'value = 1' }, 4, 'Bm25.search')
vim.api.nvim_win_set_cursor(0, { 6, 0 })
symbol.update()
assert((vim.b.current_symbol or '') == '', 'Python top-level retained a method')
fixture('python', { 'def tokenize(text):', '    return text.split()' }, 2, 'tokenize')
fixture('python', { 'class Bm25:', '    value = 42' }, 2, 'Bm25')
fixture('c', { 'char **ft_split(char const *s, char c)', '{', '    return 0;', '}' }, 3, 'ft_split')
fixture('lua', { 'local M = {}', 'function M.open()', '  return true', 'end', 'return M' }, 3, 'M.open')
vim.cmd('enew!')
vim.bo.filetype = 'spatial_missing_parser'
symbol.update()
assert((vim.b.current_symbol or '') == '', 'missing parser must produce no capsule')
-- Exercise the real Aerial cache API without initiating an LSP request.
require('lazy').load({ plugins = { 'aerial.nvim' } })
require('aerial').get_location(true)
local aerial_data = require('aerial.data')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'cached function', 'body', 'outside' })
aerial_data.set_symbols(0, { { name = 'cached_function', kind = 'Function', level = 0,
  lnum = 1, col = 0, end_lnum = 2, end_col = 4 } })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
symbol.update()
assert((vim.b.current_symbol or ''):find('cached_function', 1, true), 'existing Aerial symbol cache was not reused')
vim.api.nvim_win_set_cursor(0, { 3, 0 })
symbol.update()
assert((vim.b.current_symbol or '') == '', 'Aerial closest preceding symbol leaked into top-level capsule')
aerial_data.delete_buf(0)
local huge = {}
for i = 1, 10001 do huge[i] = 'local v = 1' end
vim.api.nvim_buf_set_lines(0, 0, -1, false, huge)
vim.bo.filetype = 'lua'
vim.b.current_symbol = 'stale'
symbol.update()
assert((vim.b.current_symbol or '') == '', 'large-file guard retained a symbol')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep('x', 1024 * 1024 + 1) })
vim.b.current_symbol = 'stale'
symbol.update()
assert((vim.b.current_symbol or '') == '', 'byte-size guard retained a symbol')
-- Statusline rendering must read the cache, never invoke symbol sources.
vim.b.current_symbol = 'cached capsule'
local columns = vim.o.columns
vim.o.columns = 140
local originals = { vim.lsp.buf_request_sync, vim.lsp.buf_request, vim.treesitter.get_parser }
local function forbidden() error('statusline rendering called a symbol source') end
vim.lsp.buf_request_sync, vim.lsp.buf_request, vim.treesitter.get_parser = forbidden, forbidden, forbidden
local render_ok, render_err = pcall(function()
  for _ = 1, 1000 do assert(symbol.component() == 'cached capsule') end
  vim.o.columns = 80
  assert(symbol.component() == '', 'narrow terminal retained symbol capsule')
  vim.o.columns = 140
  vim.b.current_symbol = 'percent%name'
  assert(symbol.component() == 'percent%%name', 'symbol name leaked statusline formatting')
end)
vim.lsp.buf_request_sync, vim.lsp.buf_request, vim.treesitter.get_parser = unpack(originals)
vim.o.columns = columns
assert(render_ok, render_err)
print('SYMBOL: real Python nested method/top-level/function, C, Lua, missing parser, large guard and cached render PASS')

vim.cmd('enew!')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'code' })
vim.cmd.vsplit()
local right = vim.api.nvim_get_current_win()
vim.cmd('wincmd h')
local left = vim.api.nvim_get_current_win()
focus.update()
local function separator(win)
  return vim.wo[win].winhighlight:match('WinSeparator:([^,]+)')
end
local active_left = separator(left)
assert(active_left and active_left:find('Active'), 'left split lacks active separator: ' .. vim.wo[left].winhighlight)
assert(not (separator(right) or ''):find('Active'), 'inactive right split has an active edge')
vim.api.nvim_set_current_win(right)
focus.update()
assert((separator(left) or ''):find('Active'), 'right split left-edge owner was not emphasized')
assert(not (separator(right) or ''):find('Active'), 'right split drew an unused outside edge')
-- Existing panel mappings must survive edge installation and focus changes.
vim.wo[right].winhighlight = 'Normal:EdgyNormal,NormalNC:EdgyNormal,WinBar:EdgyWinBar'
local panel = vim.api.nvim_create_buf(false, true)
vim.api.nvim_win_set_buf(right, panel)
focus.update()
assert(vim.wo[right].winhighlight:find('Normal:EdgyNormal', 1, true), vim.wo[right].winhighlight)
assert(vim.wo[right].winhighlight:find('WinBar:EdgyWinBar', 1, true), vim.wo[right].winhighlight)
vim.api.nvim_set_current_win(left)
focus.update()
assert(vim.wo[right].winhighlight:find('Normal:EdgyNormal', 1, true), 'inactive panel normal mapping lost')
focus.cleanup()
assert(not vim.wo[left].winhighlight:find('Active'), 'cleanup left an active separator')
vim.cmd('only!')
cursor.setup()
focus.setup()
symbol.setup()
print('FOCUS: native edge ownership, focus transfer, panel highlight preservation and cleanup PASS')
