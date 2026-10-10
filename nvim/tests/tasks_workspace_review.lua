local tasks = require('config.tasks')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
vim.fn.writefile({ '{"scripts":{"test":"echo test","lint":"echo lint"}}' }, dir .. '/package.json')
vim.fn.writefile({}, dir .. '/pnpm-lock.yaml')
vim.fn.writefile({ 'all:', '\t@echo ok', 'test:', '\t@echo test' }, dir .. '/Makefile')
vim.fn.writefile({ '[package]' }, dir .. '/Cargo.toml')
local found = tasks.discover(dir)
assert(#found == 8, 'Expected 3 make, 2 package and 3 Cargo tasks')
local names = {}
for _, task in ipairs(found) do names[task.name] = task; assert(task.cwd == dir) end
assert(names['pnpm: test'].argv[3] == 'test')
assert(names['make: test'].argv[2] == '--')
assert(tasks.run({ name = 'fixture success', argv = { 'sh', '-c', 'printf "done\\n"' }, cwd = dir }))
assert(not tasks.run({ name = 'duplicate', argv = { 'sh', '-c', 'true' }, cwd = dir }))
assert(vim.wait(3000, function() return not tasks.running end, 10), 'Task timed out')
assert(table.concat(tasks.output, '\n'):find('done', 1, true))
tasks.rerun()
assert(vim.wait(3000, function() return not tasks.running end, 10))
assert(tasks.run({ name = 'fixture cancel', argv = { 'sleep', '10' }, cwd = dir }))
tasks.stop()
assert(vim.wait(3000, function() return not tasks.running end, 10), 'Cancellation did not finish')
-- A compiler failure should attach relative files to the task root.
vim.fn.writefile({ 'int main() {}' }, dir .. '/source.c')
local previous_efm = vim.bo.errorformat
vim.bo.errorformat = '%f:%l:%c: %m'
assert(tasks.run({ name = 'fixture error', argv = { 'sh', '-c', 'echo "source.c:3:2: bad"; exit 1' }, cwd = dir }))
assert(vim.wait(3000, function() return not tasks.running end, 10))
local qf = vim.fn.getqflist()
assert(qf[1].valid == 1 and qf[1].lnum == 3)
assert(vim.api.nvim_buf_get_name(qf[1].bufnr) == dir .. '/source.c', 'Wrong compiler root')
vim.bo.errorformat = previous_efm
vim.cmd('cclose')
local workspace = require('config.workspace')
local columns = vim.o.columns
vim.o.columns = 80
local editor = vim.api.nvim_get_current_win()
local count = #vim.api.nvim_list_wins()
workspace.enter()
assert(vim.api.nvim_get_current_win() == editor)
assert(#vim.api.nvim_list_wins() == count, 'Narrow workspace opened panels')
-- Reusing a formerly owned sidebar to edit a file must keep the window.
vim.cmd('vnew')
local reused = vim.api.nvim_get_current_win()
workspace.owned_windows[reused] = vim.api.nvim_get_current_buf()
workspace.exit()
assert(vim.api.nvim_win_is_valid(reused), 'Workspace closed a normal editing window')
vim.o.columns = columns
vim.fn.delete(dir, 'rf')
print('TASKS/WORKSPACE: discovery, safe argv, async results, rerun, cancellation, relative diagnostics, adaptive layout and window safety PASS')
