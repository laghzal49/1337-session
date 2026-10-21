-- Exercise rendered annotations and guide behavior, not only plugin options.
require('lazy').load({plugins={'todo-comments.nvim','nvim-lspconfig'}})
local config = require('todo-comments.config')
assert(vim.wait(1000, function() return config.loaded end), 'TODO plugin did not initialize')
vim.cmd('enew!')
local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].filetype = 'lua'
vim.api.nvim_buf_set_lines(buf,0,-1,false,{
  '-- TODO add validation', '-- TODO(owner): add tests', '-- FIXME: failure',
  '-- NOTE this is intentional', 'local text = "TODO: not a comment"', '-- TODOS is an ordinary word',
})
vim.treesitter.start(buf, 'lua')
vim.treesitter.get_parser(buf):parse()
local todo = require('todo-comments.highlight')
todo.highlight(buf,0,5)
local rows = {}
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf,config.ns,0,-1,{details=true})) do rows[mark[2]]=true end
for row=0,3 do assert(rows[row], 'missing comment annotation on row '..row) end
assert(not rows[4] and not rows[5], 'TODO highlight leaked into a string or longer word')
local variable = vim.api.nvim_get_hl(0,{name='@variable',link=false})
local semantic = vim.api.nvim_get_hl(0,{name='@lsp.type.variable',link=false})
assert(variable.fg == semantic.fg, 'LSP changes variable brightness')
assert(variable.fg == tonumber(require('config.palette').variable:sub(2),16) and not variable.bold and not semantic.bold, 'variable color must match configured palette without bold with LSP')
local ns = vim.api.nvim_create_namespace('readability_diagnostics')
vim.diagnostic.set(ns,buf,{{lnum=0,col=0,message='Example type mismatch',code='TYPE001',severity=1,source='review'}})
local float_buf, float_win = vim.diagnostic.open_float(buf,{scope='buffer',focus=false})
assert(float_buf and table.concat(vim.api.nvim_buf_get_lines(float_buf,0,-1,false),'\n'):find('TYPE001',1,true), 'diagnostic code missing from popup')
vim.api.nvim_win_close(float_win,true)
vim.diagnostic.reset(ns)
local guide = require('config.cheatsheet')
local win = guide.show()
local lines = vim.api.nvim_buf_get_lines(guide.buf_nr,0,-1,false)
assert(lines[1] == 'Everyday Controls', 'guide starts with an infrequent workflow')
assert(not table.concat(lines,'\n'):find('`',1,true), 'guide exposes Markdown key markup')
local map = vim.fn.maparg(']]','n',false,true)
map.callback()
assert(vim.api.nvim_get_current_line():find('File Explorer',1,true), 'next section failed')
vim.o.columns=40; vim.o.lines=20
vim.api.nvim_exec_autocmds('VimResized',{})
local frame = vim.api.nvim_win_get_config(win)
assert(frame.width <= 36 and frame.height <= 16 and vim.wo[win].wrap, 'guide does not fit narrow screens')
assert(vim.api.nvim_get_current_line():find('File Explorer',1,true), 'resize lost selected section')
local previous = vim.fn.maparg('[[','n',false,true)
previous.callback()
assert(vim.api.nvim_get_current_line() == 'Everyday Controls', 'previous section failed')
guide.close()
assert(not vim.api.nvim_buf_is_valid(guide.buf_nr or -1), 'guide buffer leaked')
print('READABILITY PASS: real TODO annotations, bright LSP variables, diagnostic codes, guide navigation and resize')
