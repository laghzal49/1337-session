-- A username alone, or an old broken ~/goinfre link, must not enable station mode.
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local link = dir .. '/goinfre'
assert(vim.uv.fs_symlink(dir .. '/missing', link))
assert(vim.fn.isdirectory(link) == 0, 'fixture symlink must be broken')

local saved = {
  user = vim.env.USER,
  station = vim.env.STATION_1337,
  global = vim.g.station_1337,
  expand = vim.fn.expand,
  isdirectory = vim.fn.isdirectory,
  hostname = vim.uv.os_gethostname,
  module = package.loaded['config.station'],
}
local ok, err = xpcall(function()
  vim.env.USER = 'tlaghzal'
  vim.env.STATION_1337 = nil
  vim.g.station_1337 = nil
  vim.fn.expand = function(path, ...)
    if path == '~/goinfre' then return link end
    return saved.expand(path, ...)
  end
  vim.fn.isdirectory = function(path)
    if path == '/goinfre' or path == '/sgoinfre' then return 0 end
    return saved.isdirectory(path)
  end
  vim.uv.os_gethostname = function() return 'ordinary-workstation' end
  package.loaded['config.station'] = nil
  assert(not require('config.station').is_1337(), 'ordinary host falsely detected as a 1337 station')
end, debug.traceback)

vim.env.USER, vim.env.STATION_1337 = saved.user, saved.station
vim.g.station_1337 = saved.global
vim.fn.expand, vim.fn.isdirectory = saved.expand, saved.isdirectory
vim.uv.os_gethostname = saved.hostname
package.loaded['config.station'] = saved.module
vim.fn.delete(dir, 'rf')
assert(ok, err)
print('STATION DETECTION PASS: username and broken goinfre link do not enable station mode')
