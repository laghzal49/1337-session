-- Offline: nvim --headless -u NONE -l nvim/tests/portable_runtime_review.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/nvim')
local original_has, original_path = vim.fn.has, vim.env.PATH
package.loaded['config.lazy'] = true -- exercise init without downloading plugins
for _, windows in ipairs({ false, true }) do
  vim.fn.has = function(feature)
    if feature == 'win32' then return windows and 1 or 0 end
    return original_has(feature)
  end
  for _, inherited in ipairs({ '', '/example/bin' }) do
    vim.env.PATH = inherited
    dofile('nvim/init.lua')
    local suffix = inherited == '' and '' or ((windows and ';' or ':') .. inherited)
    assert(vim.env.PATH == vim.fn.stdpath('data') .. '/mason/bin' .. suffix)
  end
end
vim.fn.has, vim.env.PATH = original_has, original_path

local original_directory, original_host = vim.fn.isdirectory, vim.uv.os_gethostname
vim.fn.isdirectory = function() return 0 end
vim.g.station_1337 = nil
vim.env.STATION_1337 = nil
for host, expected in pairs({ ['laptop42'] = false, ['desktop-1337'] = false,
  ['42-workstation'] = true, ['1337-cluster'] = true, ['c1r2p3'] = true }) do
  vim.uv.os_gethostname = function() return host end
  package.loaded['config.station'] = nil
  assert(require('config.station').is_1337() == expected, host)
end
vim.env.STATION_1337 = '0'
assert(not require('config.station').is_1337(), 'explicit opt-out must override cached detection')
vim.g.station_1337 = true
assert(require('config.station').is_1337(), 'explicit global override must take precedence')
vim.g.station_1337 = nil
vim.fn.isdirectory, vim.uv.os_gethostname = original_directory, original_host

-- Exercise the real health provider without bootstrapping the full config.
local messages = {}
for _, name in ipairs({ 'start', 'ok', 'info', 'warn', 'error' }) do
  vim.health[name] = function(message) messages[#messages + 1] = message end
end
require('health.session').check()
assert(#messages >= 15, 'health report incomplete')
print('PORTABLE RUNTIME PASS: PATH, station overrides, host detection, health report')
