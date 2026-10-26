-- Full configuration, installed native backend and upstream PDF fixture required.
assert(not package.loaded['nvim-gfx.viewer'], 'media renderer loaded during ordinary startup')
vim.cmd('MediaHealth')
local media = require('config.media')
local plugin = assert(require('lazy.core.config').plugins['nvim-gfx'])
local pdf = plugin.dir .. '/tests/fixtures/two-pages.pdf'
local out = vim.fn.tempname()
vim.fn.writefile({},out)
-- Capture the outer-terminal graphics stream while exercising the real Rust
-- process, rather than claiming a headless test can visually inspect a terminal.
local resolve = vim.fn.resolve
vim.fn.resolve = function(path)
  if path == '/proc/self/fd/1' then return out end
  return resolve(path)
end
local supports = media.supported_terminal
media.supported_terminal = function() return true end
local win = vim.api.nvim_get_current_win()
local original = { vim.wo.number, vim.wo.relativenumber, vim.wo.signcolumn }
vim.cmd.edit(vim.fn.fnameescape(pdf))
local reader = require('nvim-gfx.viewer')
assert(reader.is_active(),'PDF did not open via BufReadCmd')
assert(vim.bo.filetype=='nvim-gfx')
assert(vim.wait(5000,function() return vim.api.nvim_buf_get_name(0):find('page 1 / 2',1,true) end), 'PDF first page did not render')
local next_page = vim.fn.maparg('J','n',false,true)
assert(type(next_page.callback)=='function','PDF page key missing')
next_page.callback()
assert(vim.wait(5000,function() return vim.api.nvim_buf_get_name(0):find('page 2 / 2',1,true) end), 'PDF next page did not render')
reader.close('test')
assert(vim.wo[win].number==original[1] and vim.wo[win].relativenumber==original[2]
  and vim.wo[win].signcolumn==original[3], 'reader did not restore editor window options')
assert(vim.fn.getfsize(out)>1000,'native graphics output missing')
local png = vim.fn.stdpath('config') .. '/assets/python.png'
assert(media.open(png),'image did not open')
assert(reader.is_active() and vim.bo.filetype=='nvim-gfx')
local zoom=vim.fn.maparg('+','n',false,true)
assert(type(zoom.callback)=='function')
zoom.callback()
reader.close('test')
media.supported_terminal = function() return false end
vim.cmd.edit(vim.fn.fnameescape(pdf))
assert(vim.wait(5000,function() return vim.bo.filetype=='text' and vim.b.media_source==pdf end), 'PDF text fallback did not open')
assert(not vim.bo.modifiable and vim.bo.buftype=='nofile','PDF text must be read-only')
assert(table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),'\n'):match('%S'),'PDF text extraction empty')
local name = vim.fn.tempname() .. '.png'
vim.fn.writefile({'not really an image'},name)
vim.cmd.edit(vim.fn.fnameescape(name))
assert(vim.bo.buftype=='nofile' and not vim.bo.modifiable, 'unsupported graphics terminal left binary editable')
vim.fn.resolve,media.supported_terminal=resolve,supports
vim.fn.delete(name)
vim.fn.delete(out)
print('MEDIA PASS: lazy load, real Rust PDF pages/graphics, image/zoom, window restore, read-only text fallback')
