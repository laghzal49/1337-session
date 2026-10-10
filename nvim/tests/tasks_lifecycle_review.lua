require('lazy').load({ plugins = { 'snacks.nvim' } })
local tasks, workspace = require('config.tasks'), require('config.workspace')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
assert(tasks.run({ name = 'noisy', cwd = dir, argv = { 'python3', '-c', "print('x' * (2 * 1024 * 1024))" } }))
assert(vim.wait(5000, function() return not tasks.running end, 10))
local output = table.concat(tasks.output, '\n')
assert(#output < 1024 * 1024 + 1000, 'Unbounded task output')
assert(output:find('truncated', 1, true), 'Missing truncation indicator')
tasks.show_output()
local count, output_win, buf = #vim.api.nvim_list_wins(), vim.api.nvim_get_current_win(), tasks.output_buf
tasks.show_output()
assert(#vim.api.nvim_list_wins() == count and vim.api.nvim_get_current_win() == output_win, 'Duplicate output windows')
vim.api.nvim_win_close(output_win, true)
assert(not vim.api.nvim_buf_is_valid(buf), 'Output scratch buffer leaked')
assert(tasks.run({ name = 'newline flood', cwd = dir, argv = { 'python3', '-c', "print('\\n' * 200000)" } }))
assert(vim.wait(5000, function() return not tasks.running end, 10))
assert(#tasks.output < 5010, 'Unbounded output line count')
assert(#vim.fn.getqflist() < 5010, 'Unbounded quickfix line count')
-- A program ignoring graceful termination must not block future tasks forever.
local marker = dir .. '/ready'
assert(tasks.run({ name = 'ignore term', cwd = dir, argv = { 'python3', '-c',
  "import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); open('ready','w').close(); time.sleep(20)" } }))
assert(vim.wait(2000, function() return vim.fn.filereadable(marker) == 1 end, 10))
tasks.stop(); tasks.stop()
assert(vim.wait(3000, function() return not tasks.running end, 10), 'SIGKILL escalation failed')
-- POSIX cancellation terminates ordinary descendants holding inherited pipes.
if vim.fn.has('win32') == 0 then
  local child_marker = dir .. '/child-pid'
  assert(tasks.run({ name = 'process tree', cwd = dir, argv = { 'python3', '-c',
    "import subprocess,signal,time,sys; p=subprocess.Popen(['sleep','20']); signal.signal(signal.SIGTERM,lambda *_:(p.wait(),sys.exit(0))); open('child-pid','w').write(str(p.pid)); time.sleep(20)" } }))
  assert(vim.wait(2000, function() return vim.fn.filereadable(child_marker) == 1 end, 10))
  local child_pid = tonumber(vim.fn.readfile(child_marker)[1])
  tasks.stop()
  local completed = vim.wait(3000, function() return not tasks.running end, 10)
  local dead = vim.uv.kill(child_pid, 0) ~= 0
  if not dead then vim.uv.kill(child_pid, 9) end -- Cleanup even if a regression fails.
  assert(completed and dead, 'TaskStop left a descendant alive / pipe handles blocked')
end
-- Existing explorers belong to the user and survive workspace exit.
vim.o.columns, vim.o.lines = 160, 40
local explorer = Snacks.explorer({ focus = false })
assert(vim.wait(2000, function() return explorer.shown end, 10))
workspace.enter(); workspace.exit()
assert(not explorer.closed, 'Workspace closed preexisting explorer')
vim.wait(100); explorer:close(); vim.wait(100)
local count_before = #vim.api.nvim_list_wins()
workspace.enter()
local pending = workspace.explorer
assert(pending, 'Workspace failed to retain pending picker')
workspace.exit()
assert(vim.wait(2000, function() return pending.closed end, 10), 'Immediate exit did not cancel pending picker')
vim.wait(250)
assert(#vim.api.nvim_list_wins() == count_before, 'Late explorer leaked after immediate exit')
-- Immediate re-entry reclaims a pending explorer instead of losing the sidebar.
workspace.enter(); local reclaimed = workspace.explorer; workspace.exit(); workspace.enter()
assert(workspace.explorer == reclaimed, 'Immediate re-entry lost pending explorer')
assert(vim.wait(2000, function() return reclaimed.shown end, 10))
vim.wait(100)
assert(not reclaimed.closed, 'Retirement closed reclaimed explorer')
workspace.exit(); vim.wait(100)
-- Deferred close rechecks windows repurposed after exit was requested.
workspace.enter(); local protected = workspace.explorer
assert(vim.wait(2000, function() return protected.shown end, 10))
local protected_win = protected.list.win.win
local protected_buf = protected.list.win.buf
protected.list.win.opts.fixbuf = false
workspace.exit()
local edited = vim.api.nvim_create_buf(true, false)
vim.api.nvim_win_set_buf(protected_win, edited)
vim.wait(100)
assert(vim.api.nvim_win_is_valid(protected_win) and not protected.closed, 'Deferred exit closed repurposed editor')
-- Restore the picker window before explicitly closing the test fixture.
vim.api.nvim_win_set_buf(protected_win, protected_buf)
protected.list.win.opts.fixbuf = true
vim.wait(100); protected:close(); vim.wait(100)
-- Cross-session callbacks cannot claim the next workspace session.
workspace.enter(); local first = workspace.explorer; workspace.exit()
vim.wait(100)
workspace.enter(); local second = workspace.explorer
assert(second and second ~= first)
assert(vim.wait(2000, function() return second.shown end, 10))
assert(first.closed and not second.closed)
vim.cmd('botright new')
local auxiliary = vim.api.nvim_get_current_win()
local auxiliary_buf = vim.api.nvim_get_current_buf()
vim.bo[auxiliary_buf].buftype = 'nofile'
workspace.owned_windows[auxiliary] = auxiliary_buf
workspace.exit()
assert(not vim.api.nvim_win_is_valid(auxiliary), 'Explorer ownership blocked other panel cleanup'); vim.wait(100)
vim.fn.delete(dir, 'rf')
print('TASK LIFECYCLE: bounded capture, output reuse/wipe, termination escalation, existing explorer preservation, immediate exit and session isolation PASS')
