-- Real BufWritePre -> Ruff -> disk, including project settings and opt-outs.
assert(vim.fn.executable('ruff') == 1, 'Ruff must be installed')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
vim.fn.writefile({ '[tool.ruff]', 'unsafe-fixes = true', '[tool.ruff.lint]',
  'select = ["E4", "E7", "E9", "F"]' }, dir .. '/pyproject.toml')
vim.cmd.edit(dir .. '/main.py')
vim.bo.filetype = 'python'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  'import sys', 'import os', 'import json', '',
  'def example( ):', '    unused = 1', "    print(f'ready',os.name,sys.version)",
})
vim.cmd.write()
local text = table.concat(vim.fn.readfile(dir .. '/main.py'), '\n')
assert(text:match('^import os\nimport sys\n'), 'imports were not sorted')
assert(not text:find('import json', 1, true), 'unused import was not fixed')
assert(text:find('def example():', 1, true) and text:find('print("ready", os.name, sys.version)', 1, true),
  'safe fix and formatting pipeline did not complete: ' .. text)
assert(text:find('unused = 1', 1, true), 'unsafe F841 fix was applied automatically')
vim.cmd.write()
assert(text == table.concat(vim.fn.readfile(dir .. '/main.py'), '\n'), 'second save changed clean output')

vim.fn.writefile({ '[tool.ruff.lint]', 'ignore = ["F401"]' }, dir .. '/pyproject.toml')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'import os', "print( 'hi' )" })
vim.cmd.write()
assert(vim.fn.readfile(dir .. '/main.py')[1] == 'import os', 'project ignores were overwritten')
vim.g.autoformat = false
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "print( 'untouched' )" })
vim.cmd.write()
assert(vim.fn.readfile(dir .. '/main.py')[1] == "print( 'untouched' )", 'format toggle ignored')
vim.g.autoformat = true
vim.b.autoformat = false
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "print( 'buffer opt out' )" })
vim.cmd.write()
assert(vim.fn.readfile(dir .. '/main.py')[1] == "print( 'buffer opt out' )", 'buffer opt-out ignored')
vim.b.autoformat = nil
vim.cmd.enew()
vim.fn.delete(dir, 'rf')
print('PYTHON SAVE PASS: real safe fixes, import sorting, formatting, idempotence, project ignores, unsafe-fix protection and opt-outs')
