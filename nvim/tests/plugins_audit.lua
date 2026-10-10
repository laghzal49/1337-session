-- Run with the full config in a fresh process; first-use loading matters here.
local plugins = require('lazy.core.config').plugins
assert(not plugins['mini.pairs']._.loaded, 'pairing must stay lazy before first use')
vim.api.nvim_exec_autocmds('CmdlineEnter', { pattern = ':' })
assert(plugins['mini.pairs']._.loaded, 'first command line must load configured pairing')
assert(vim.fn.maparg('(', 'c'):find('MiniPairs', 1, true), 'command pairing mapping missing')

-- Both loading orders must preserve TODO navigation.
require('lazy').load({ plugins = { 'todo-comments.nvim', 'mini.bracketed' } })
require('mini.bracketed').setup(require('mini.bracketed').config)
for _, lhs in ipairs({ '[t', ']t' }) do
  assert(vim.fn.maparg(lhs, 'n', false, true).desc:find('TODO'), lhs .. ' must belong to TODO navigation')
end
assert(require('mini.bracketed').config.treesitter.suffix == '', 'duplicate tree navigation mappings enabled')

-- Exercise the visual mapping with a real range, without needing Git history.
require('lazy').load({ plugins = { 'diffview.nvim' } })
local captured
vim.api.nvim_create_user_command('DiffviewFileHistory', function(ctx)
  captured = { ctx.range, ctx.line1, ctx.line2 }
end, { nargs = '*', range = true, force = true })
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three', 'four' })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd('normal! Vj')
local map = vim.fn.maparg('<leader>gf', 'x', false, true)
assert(map.rhs and map.rhs:find("'<,'>", 1, true), 'visual history must forward selection range')
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(map.rhs, true, false, true), 'nx', false)
assert(captured and captured[1] == 2 and captured[2] == 2 and captured[3] == 3,
  'selected lines history did not receive lines 2 through 3')
print('PLUGINS REVIEW PASS: first command pairing, stable TODO keys, selected history range')
