local lifecycle = require('config.docs_lifecycle')
local store = require('config.docs_store')
local original_manifest, original_update = store.manifest, lifecycle.update
local original_stat = vim.uv.fs_stat
local calls = 0
lifecycle.update = function(name, quiet)
  assert(name == 'all' and quiet == true)
  calls = calls + 1
end
vim.g.black_docs_auto_update = false
store.manifest = function() error('disabled check read manifest') end
lifecycle.check()
assert(calls == 0)
vim.g.black_docs_auto_update = true
store.manifest = function() return nil end
lifecycle.check()
assert(calls == 1, 'missing docs did not schedule update')
vim.uv.fs_stat = function() return { type = "file" } end
local fresh = { schema = 1, docsets = {} }
for _, name in ipairs({ 'python', 'c', 'cpp', 'lua', 'bash', 'cmake' }) do
  fresh.docsets[name] = { updated_at = os.time(), root = "fixture" }
end
store.manifest = function() return fresh end
lifecycle.check()
assert(calls == 1, 'fresh docs caused update')
fresh.docsets.python.updated_at = os.time() - 8 * 86400
lifecycle.check()
assert(calls == 2, 'stale docs did not update')
vim.g.black_docs_max_age_days = 30
lifecycle.check()
assert(calls == 2, 'configured age ignored')
fresh.docsets.lua = nil
lifecycle.check()
assert(calls == 3, 'missing individual docset ignored')
fresh.docsets.lua = { updated_at = os.time(), root = 'fixture' }
vim.uv.fs_stat = function() return nil end
lifecycle.check()
assert(calls == 4, 'missing index file ignored')
-- Setup must defer checking and use a one-shot timer, with explicit cleanup.
local original_timer = vim.uv.new_timer
local scheduled, stopped, closed
vim.uv.new_timer = function()
  return { start = function(_, delay, repeat_ms, callback)
    assert(delay == 5000 and repeat_ms == 0)
    scheduled = callback
  end, stop = function() stopped = true end, close = function() closed = true end }
end
lifecycle.setup()
if vim.v.vim_did_enter == 0 then vim.api.nvim_exec_autocmds('VimEnter', {}) end
assert(scheduled and calls == 4, 'automatic check ran during startup')
lifecycle.cleanup()
assert(stopped and closed, 'scheduled check timer leaked')
vim.uv.new_timer = original_timer
vim.uv.fs_stat = original_stat
store.manifest, lifecycle.update = original_manifest, original_update
vim.g.black_docs_auto_update = false
vim.g.black_docs_max_age_days = 7
assert(vim.fn.exists(':DocsUpdate') == 2 and vim.fn.exists(':DocsBrowse') == 2 and vim.fn.exists(':DocsHealth') == 2)
assert(vim.fn.exists(':Docs') == 2 and vim.fn.exists(':Devdocs') == 2 and vim.fn.exists(':DevdocsUpdate') == 2)
local original_browse, original_health = lifecycle.browse, lifecycle.health
local routed
lifecycle.browse = function(args) routed = 'browse:' .. args end
lifecycle.health = function() routed = 'health' end
lifecycle.update = function(args) routed = 'update:' .. args end
vim.cmd('Docs python Path'); assert(routed == 'browse:python Path')
vim.cmd('Docs browse lua string.gsub'); assert(routed == 'browse:lua string.gsub')
vim.cmd('Docs update python'); assert(routed == 'update:python')
vim.cmd('Docs health'); assert(routed == 'health')
vim.cmd('Devdocs python Path'); assert(routed == 'browse:python Path')
vim.cmd('DevdocsUpdate lua'); assert(routed == 'update:lua')
lifecycle.browse, lifecycle.health, lifecycle.update = original_browse, original_health, original_update
lifecycle.cleanup()
print('DOCS LIFECYCLE: missing/stale/fresh/disabled checks, configurable age and commands PASS')
