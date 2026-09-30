-- Run with the full config from the repository root.
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
vim.fn.writefile({ '[project]', 'name = "terminal-review"' }, dir .. '/pyproject.toml')
vim.fn.writefile({ 'print("ready")' }, dir .. '/main.py')
vim.cmd.edit(dir .. '/main.py')

assert(vim.wo.number and vim.wo.relativenumber)
local terminal = require('config.terminal')
assert(terminal.toggle())
local shell = assert(Snacks.terminal.list()[1])
assert(vim.b[shell.buf].snacks_terminal.cwd == dir)
assert(not vim.wo[shell.win].number and not vim.wo[shell.win].relativenumber)
assert(vim.fn.maparg('<Esc>', 't', false, true).buffer ~= 1,
  'Snacks single-Esc timer must not compete with double-Esc')
local escape = vim.fn.maparg('<Esc><Esc>', 't', false, true)
assert(escape.buffer == 1 and escape.rhs == '<C-\\><C-n>', vim.inspect(escape))
assert(terminal.toggle(), 'toggle from inside terminal failed')
assert(not shell:win_valid() and #Snacks.terminal.list() == 1, 'toggle opened another shell')

local command = Snacks.terminal.open('cat', { cwd = dir })
assert(terminal.toggle(), 'command terminal could not hide')
assert(not command:win_valid() and #Snacks.terminal.list() == 2, 'command terminal toggle opened another shell')
command:close()

vim.fn.chansend(vim.b[shell.buf].terminal_job_id, 'exit\n')
assert(vim.wait(3000, function() return not shell:buf_valid() end, 50), 'shell did not exit')
vim.fn.delete(dir, 'rf')
print('TERMINAL: project root, relative numbers, focus/hide, shell exit PASS')
