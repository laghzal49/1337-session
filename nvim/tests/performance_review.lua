-- Full integration: nvim --headless '+lua dofile("nvim/tests/performance_review.lua")' '+qa!'
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/nvim')
local performance = require('config.performance')
performance.setup()
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.bo[buf].filetype = 'lua'
assert(not performance.large(), 'normal buffer classified as large')
assert(not performance.large(0), 'current-buffer sentinel failed')
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/mini.hipatterns')
local hipatterns = require('mini.hipatterns')
hipatterns.setup({ highlighters = { todo = { pattern = 'TODO', group = 'Todo' } } })
hipatterns.enable(buf)
vim.wait(20, function() return false end)
assert(vim.tbl_contains(hipatterns.get_enabled_buffers(), buf), 'decoration fixture did not attach')
local context_refreshed = false
local previous_context = package.loaded['treesitter-context']
local previous_enable
if previous_context then
  if not previous_context.enabled() then previous_context.enable() end
  previous_enable = previous_context.enable
  previous_context.enable = function()
    context_refreshed = true
    previous_enable()
  end
else
  package.loaded['treesitter-context'] = {
    enabled = function() return true end,
    enable = function() context_refreshed = true end,
  }
end
local lines = {}
for i = 1, 20001 do lines[i] = 'x' end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
assert(performance.large(buf), 'line budget missed small-byte generated file')
local started = vim.uv.hrtime()
for _ = 1, 10000 do assert(performance.large(buf)) end
local check_ms = (vim.uv.hrtime() - started) / 1e6
performance.guard(buf)
-- Real installed parsers may already have queued work during fixture growth.
-- This is a completion assertion, not a latency benchmark.
assert(vim.wait(5000, function() return context_refreshed end), 'context attachment was not reevaluated')
if previous_context then previous_context.enable = previous_enable end
package.loaded['treesitter-context'] = previous_context
assert(vim.b[buf].bigfile and vim.b[buf].performance_guard, 'growth guard did not classify buffer')
assert(vim.b[buf].minihipatterns_disable, 'pattern decorations were not permanently disabled')
assert(not vim.tbl_contains(hipatterns.get_enabled_buffers(), buf), 'existing pattern attachment survived growth')
assert(vim.b[buf].snacks_indent == false and vim.b[buf].snacks_scope == false, 'indent/scope decorations remain enabled')
assert(vim.wo.foldmethod == 'manual', 'growth guard did not suppress expensive folds')
assert(not vim.diagnostic.is_enabled({ bufnr = buf }), 'growth guard did not suppress diagnostics')
local bytes = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(bytes, 0, -1, false, { string.rep('x', performance.max_bytes + 1) })
assert(performance.large(bytes), 'byte budget missed single-line generated file')
local normal = vim.api.nvim_create_buf(true, false)
assert(not performance.large(normal), 'large-file state leaked to normal buffer')
vim.bo[normal].buftype = 'nofile'
vim.api.nvim_buf_set_lines(normal, 0, -1, false, lines)
assert(not performance.large(normal), 'special buffer was guarded')
print(vim.json.encode({ checks = 'passed', size_checks = 10000, size_check_total_ms = check_ms }))
