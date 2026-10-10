-- Fresh-process review: gs actions load lazily and leave Flash s immediate.
local plugins = require('lazy.core.config').plugins
assert(not plugins['mini.surround']._.loaded, 'surround must remain lazy')
for _, lhs in ipairs({ 'gsa', 'gsd', 'gsr', 'gsf', 'gsF', 'gsh', 'gsn' }) do
  assert(vim.fn.maparg(lhs, 'n') ~= '', 'missing lazy surround trigger: ' .. lhs)
end
for _, mode in ipairs({ 'n', 'x', 'o' }) do
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    assert(not (map.lhs:sub(1, 1) == 's' and #map.lhs > 1),
      'mapping delays Flash s: ' .. map.lhs)
  end
end

-- Exercise each operation as the first lazy trigger in a separate process via
-- -c "lua vim.g.surround_audit_action='delete'" before this file, if desired.
local action = vim.g.surround_audit_action or 'add'
local cases = {
  add = { 'hello', 'gsaiw)', '(hello)' },
  delete = { '(hello)', 'gsd)', 'hello' },
  replace = { '(hello)', 'gsr)"', '"hello"' },
  find = { '(hello)', 'gsf)', '(hello)' },
}
local case = assert(cases[action], 'unknown surround test action')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { case[1] })
vim.api.nvim_win_set_cursor(0, { 1, action == 'add' and 0 or 1 })
vim.cmd('normal ' .. case[2])
assert(plugins['mini.surround']._.loaded, action .. ' failed to lazy-load surround')
assert(vim.api.nvim_get_current_line() == case[3], action .. ' did not edit correctly')
if action == 'find' then
  assert(vim.api.nvim_win_get_cursor(0)[2] == 6, 'find did not land on closing surround')
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'hello' })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd('normal! viw')
vim.cmd('normal gsa"')
assert(vim.api.nvim_get_current_line() == '"hello"', 'visual gsa did not surround selection')

-- Measure mapped single-key dispatch with a long timeout to expose prefix
-- regressions; substitute only Flash's interactive UI, keeping the real map.
require('lazy').load({ plugins = { 'flash.nvim' } })
local flash = require('flash')
local jump, timeoutlen, calls = flash.jump, vim.o.timeoutlen, 0
flash.jump = function() calls = calls + 1 end
vim.o.timeoutlen = 1000
local started = vim.uv.hrtime()
vim.api.nvim_feedkeys('s', 'mx', false)
local elapsed = (vim.uv.hrtime() - started) / 1e6
flash.jump, vim.o.timeoutlen = jump, timeoutlen
assert(calls == 1, 'single s did not invoke Flash')
assert(elapsed < 200, 'single s waited for a mapping prefix: ' .. elapsed .. 'ms')
assert(vim.fn.maparg('S', 'n', false, true).desc == 'Flash Treesitter', 'S Flash mapping changed')
print(('SURROUND AUDIT PASS: first-use %s, gs triggers, immediate Flash s (%.2fms)'):format(action, elapsed))
