local markdown = require('config.markdown')
vim.cmd.enew()
vim.bo.filetype = 'markdown'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# Title', '', 'Short paragraph.' })
assert(not markdown.large(0))
local before = { spell = vim.wo.spell, foldmethod = vim.wo.foldmethod, wrap = vim.wo.wrap }
assert(markdown.enable())
assert(not vim.wo.spell and vim.wo.foldmethod == 'manual' and vim.wo.wrap)
vim.cmd.enew()
vim.bo.filetype = 'lua'
assert(vim.wo.spell == before.spell and vim.wo.foldmethod == before.foldmethod and vim.wo.wrap == before.wrap,
  'reader window options leaked into code')
vim.cmd.enew()
local lines = {}
for i = 1, markdown.max_lines + 1 do lines[i] = '## Section ' .. i end
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.bo.filetype = 'markdown'
assert(markdown.large(0))
markdown.guard(vim.api.nvim_get_current_buf())
assert(vim.b.black_markdown_large and vim.wo.foldmethod == 'manual')
assert(not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], 'large Markdown retained TS highlighter')
vim.cmd.enew()
vim.bo.filetype = 'lua'
assert(vim.wo.foldmethod == before.foldmethod, 'large Markdown fold mode leaked into code')
print('MARKDOWN: reader restoration and large-file guard PASS')
