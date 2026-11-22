-- Regression: Python is colored even before an optional Tree-sitter parser is installed.
assert(vim.g.black_color_style == 'nvimz', 'requires NVIM_COLOR_STYLE=nvimz')
assert(vim.fn.exists('g:syntax_on') == 1, 'bundled Vim syntax fallback disabled')
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_name(buf, '/tmp/nvimz_highlight_review.py')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'def greeting(name):',
  '    return "Hello " + name',
  'print(greeting("Python"))',
})
vim.bo[buf].filetype = 'python'
vim.cmd('syntax sync fromstart')
local syntax_id = vim.fn.synID(1, 1, 1)
assert(syntax_id ~= 0,
  'Python def keyword has no Vim syntax group: highlighting would be mostly white')
local hl_name = vim.fn.synIDattr(syntax_id, 'name')
assert(hl_name ~= '',
  'Python syntax group name missing')
print('PYTHON SYNTAX PASS: def keyword uses ' .. hl_name)
