-- Run without plugins: nvim --headless -u NONE -l nvim/tests/session_comfort_review.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/nvim')
vim.g.have_nerd_font = false
require('config.options')
assert(vim.opt.fillchars:get().foldopen == 'v')
assert(vim.opt.fillchars:get().foldclose == '>')
local navigation = require('plugins.navigation')
local found_glance = false
for _, spec in ipairs(navigation) do
  if spec[1] == 'DNLHC/glance.nvim' then
    found_glance = true
    assert(spec.opts().folds.fold_closed == '>')
  end
end
assert(found_glance, 'Glance fold configuration was not checked')
local accessibility = require('config.accessibility')
vim.g.have_nerd_font = true
accessibility.set(true)
assert(vim.opt.fillchars:get().foldopen == 'v')
accessibility.set(false)
assert(vim.opt.fillchars:get().foldopen == '')

local notifications = {}
vim.notify = function(message) notifications[#notifications + 1] = message end
local executable = vim.fn.executable
vim.fn.executable = function(name) return name == 'rg' and 0 or executable(name) end
assert(not require('config.tool_health').require_tool('rg'))
assert(notifications[#notifications]:find('Install ripgrep', 1, true))
assert(require('config.pick').open('grep') == nil, 'missing rg should stop before opening picker')
assert(require('config.pick').fast('grep') == nil, 'missing rg should stop before loading compact picker')
vim.fn.executable = executable

local profiler = require('config.session_profile')
assert(#vim.api.nvim_get_autocmds({ event = 'LspRequest' }) == 0, 'profiling must be opt-in')
profiler.start()
profiler.start() -- restart replaces rather than duplicates handlers
assert(#vim.api.nvim_get_autocmds({ group = 'SessionLiveProfile', event = 'LspRequest' }) == 1)
local function request(id, status)
  vim.api.nvim_exec_autocmds('LspRequest', { data = {
    client_id = 9999, request_id = id,
    request = { type = status, method = 'textDocument/hover' },
  } })
end
request(1, 'pending'); request(1, 'complete')
request(2, 'pending'); request(2, 'cancel'); request(2, 'complete')
local name = 'LSP textDocument/hover'
assert(profiler.snapshot()[name].count == 1, 'cancelled requests must not enter timing averages')
assert(vim.wait(1000, function()
  return profiler.snapshot()['Event-loop delay beyond 100 ms probe'] ~= nil
end), 'probe did not run')
profiler.stop()
local snapshot = profiler.snapshot()
vim.wait(150, function() return false end)
assert(vim.deep_equal(snapshot, profiler.snapshot()), 'stopped timer kept recording')
assert(#vim.api.nvim_get_autocmds({ event = 'LspRequest' }) == 0, 'stop leaked event handlers')
profiler.start()
assert(next(profiler.snapshot()) == nil, 'restart retained stale samples')
profiler.stop()
print('SESSION COMFORT PASS: font fallback, tool failures, profiler lifecycle and cancellation')
