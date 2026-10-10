-- Run with the full config; fixtures never modify repository files.
local plugins = require('lazy.core.config').plugins
assert(not plugins['blink.cmp']._.loaded, 'completion loaded before it was needed')
assert(not plugins['nvim-treesitter']._.loaded, 'parser manager loaded on empty startup')
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local small, large = dir .. '/small.lua', dir .. '/large.json'
vim.fn.writefile({ 'local answer = 42', 'return answer', '-- last place' }, small)
vim.fn.writefile({ string.rep('x', 1024 * 1024 + 1) }, large)
vim.cmd.edit(small)
assert(plugins['nvim-treesitter']._.loaded, 'parser manager did not load on first read')
vim.api.nvim_buf_set_mark(0, '"', 3, 0, {})
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_exec_autocmds('BufReadPost', { buffer = 0 })
assert(vim.api.nvim_win_get_cursor(0)[1] == 3, 'last place not restored')
vim.api.nvim_exec_autocmds('InsertEnter', {})
assert(plugins['blink.cmp']._.loaded, 'completion did not load on insert')
local toggle = vim.fn.maparg('<leader>ud', 'n', false, true).callback
assert(vim.diagnostic.is_enabled({ bufnr = 0 }))
toggle()
assert(not vim.diagnostic.is_enabled({ bufnr = 0 }))
toggle()
assert(vim.diagnostic.is_enabled({ bufnr = 0 }))
vim.cmd.edit(large)
assert(vim.bo.filetype == 'bigfile' and vim.b.bigfile, 'large JSON not guarded')
assert(vim.wo.foldmethod == 'manual', 'large file kept parser folding')
assert(vim.b.completion == false, 'large file kept automatic completion')
assert(not vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], 'large file parser started')
require('lazy').load({ plugins = { 'conform.nvim' } })
local opts = require('lazy.core.plugin').values(plugins['conform.nvim'], 'opts', false)
assert(opts.format_on_save(vim.api.nvim_get_current_buf()) == nil, 'large file autoformatted')
vim.cmd.edit(small)
assert(vim.bo.filetype == 'lua' and not vim.b.bigfile, 'large flag leaked to small file')
assert(opts.format_on_save(vim.api.nvim_get_current_buf()) ~= nil, 'small file lost formatting')
assert(not require('config.station').is_1337(), 'repository path falsely detected a cluster')
vim.g.station_1337 = true
local station = require('config.station')
station.init()
assert(vim.wait(5000, function() return not station.state.running end), 'station scan hung')
for _, item in ipairs(station.state.items) do
  if item.id == 'home_quota' then assert(item.details ~= 'available', 'quota scan did not parse df') end
end
vim.g.station_1337 = false
vim.cmd.enew()
vim.fn.delete(dir, 'rf')
print('RESPONSIVENESS: lazy first-use, cursor restore, diagnostics, bigfile isolation, station scan PASS')
