local tasks = require('config.tasks')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir .. '/src', 'p')
for _, file in ipairs({ 'src/main.rs', 'src/main.ts', 'src/main.go', 'tests.py' }) do vim.fn.writefile({ '' }, dir .. '/' .. file) end
local fixtures = {
  { runner = 'cargo', output = 'error[E0425]: missing name\n  --> src/main.rs:3:7\nwarning: unused variable\n  --> src/main.rs:6:2', count = 2, line = 3, col = 7, text = 'missing name' },
  { runner = 'npm', output = 'src/main.ts(4,2): error TS2322: wrong type\nsrc/main.ts:8:3 - error TS2345: wrong argument', count = 2, line = 4, col = 2, text = 'wrong type' },
  { runner = 'pnpm', output = dir .. '/src/main.ts\n  9:4  warning  unused symbol  no-unused-vars', count = 1, line = 9, col = 4, text = 'unused symbol' },
  { runner = 'go', output = '# sample\nsrc/main.go:12:5: undefined: value', count = 1, line = 12, col = 5, text = 'undefined' },
  { runner = 'python', output = '  File "tests.py", line 14, in test_example\nValueError: broken input', count = 1, line = 14, col = 0, text = 'broken input' },
  { runner = 'python', output = 'tests.py:20: AssertionError', count = 1, line = 20, col = 0, text = 'AssertionError' },
  { runner = 'make', output = 'generated.c:22:4: warning: unused value', count = 1, line = 22, col = 4, text = 'unused value', severity = 'W' },
  { runner = 'npm', output = 'src/main.ts(23,5): warning TS9999: unused type', count = 1, line = 23, col = 5, text = 'unused type', severity = 'W' },
  { runner = 'make', output = 'generated.c:21:3: failed', count = 1, line = 21, col = 3, text = 'failed' },
}
local efm = '%f:%l:%c: %m,%f:%l: %m'
for _, fixture in ipairs(fixtures) do
  local items = tasks.parse_errors({ runner = fixture.runner, cwd = dir }, fixture.output, efm)
  assert(#items == fixture.count, fixture.runner .. ': expected ' .. fixture.count .. ' errors, got ' .. #items)
  local item = items[1]
  assert(item.lnum == fixture.line and item.col == fixture.col and item.text:find(fixture.text, 1, true), vim.inspect(item))
  assert(item.filename:sub(1, #dir + 1) == dir .. '/', 'Runner error escaped project root')
  if fixture.severity then
    vim.fn.setqflist({}, ' ', { items = items })
    assert(vim.fn.getqflist()[1].type == fixture.severity, 'Quickfix warning severity lost')
  end
end
local editor = vim.api.nvim_get_current_win()
assert(tasks.run({ name = 'stream fixture', cwd = dir, argv = { 'python3', '-u', '-c',
  "import time; print('first chunk',flush=True); time.sleep(.4); print('second chunk',flush=True); time.sleep(1); print('finished',flush=True)" } }))
tasks.show_output()
local output_buf = tasks.output_buf
local output_win = vim.api.nvim_get_current_win()
vim.api.nvim_set_current_win(editor)
local function buffer_contains(text)
  return table.concat(vim.api.nvim_buf_get_lines(output_buf, 3, -1, false), '\n'):find(text, 1, true) ~= nil
end
assert(vim.wait(1000, function() return buffer_contains('second chunk') end, 10), 'Log did not stream before completion')
assert(tasks.running, 'Streaming assertion ran only after task completion')
assert(vim.api.nvim_win_get_cursor(output_win)[1] == vim.api.nvim_buf_line_count(output_buf), 'Live logs did not follow the bottom')
vim.api.nvim_win_set_cursor(output_win, { 1, 0 })
assert(vim.api.nvim_get_current_win() == editor, 'Streaming stole editor focus')
local count = #vim.api.nvim_list_wins()
assert(vim.wait(3000, function() return not tasks.running end, 10))
assert(buffer_contains('finished'), 'Final output missing')
assert(vim.api.nvim_win_get_cursor(output_win)[1] == 1, 'Streaming disrupted reading older lines')
assert(vim.api.nvim_get_current_win() == editor and #vim.api.nvim_list_wins() == count, 'Completion duplicated live panel or stole focus')
for _, win in ipairs(vim.fn.win_findbuf(output_buf)) do vim.api.nvim_win_close(win, true) end
assert(tasks.output_buf == nil, 'Closed output panel retained stale buffer reference')
assert(tasks.run({ name = 'closed stream', cwd = dir, argv = { 'python3', '-u', '-c',
  "import time; print('opening',flush=True); time.sleep(.4); print('after close',flush=True); time.sleep(.4)" } }))
tasks.show_output()
for _, win in ipairs(vim.fn.win_findbuf(tasks.output_buf)) do vim.api.nvim_win_close(win, true) end
local preserved_output = tasks.output
vim.wait(550)
assert(tasks.running and not tasks.running.refresh_pending, 'Closed output panel still scheduled live refreshes')
assert(tasks.output == preserved_output, 'Closed output panel performed hidden log rendering')
assert(vim.wait(2000, function() return not tasks.running end, 10))
assert(table.concat(vim.list_slice(tasks.output, 4), '\n'):find('after close', 1, true), 'Closed panel lost retained output')
vim.fn.delete(dir, 'rf')
print('TASK STREAMING: runner parsing, project cwd/missing generated files, output before completion, batched updates and focus preservation PASS')
