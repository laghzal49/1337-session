-- Run with the full config: nvim --headless '+lua dofile("nvim/tests/redesign_review.lua")' +qa!
local project = require('config.project')
local info = require('config.workspace_info')
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. '/nested', 'p')
vim.fn.writefile({'[project]', 'name="redesign-review"'}, tmp .. '/pyproject.toml')
vim.fn.writefile({'return 1'}, tmp .. '/nested/title%test.lua')
local original_cwd = vim.uv.cwd()
vim.cmd.edit(vim.fn.fnameescape(tmp .. '/nested/title%test.lua'))
assert(project.root() == tmp, 'file picker must discover parent project root')
require('config.editor_ui').update()
local rendered = vim.api.nvim_eval_statusline(vim.wo.winbar, {winid = 0, use_winbar = true}).str
assert(rendered:find('title%%test.lua'), 'winbar must escape literal percent filenames')
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'return 2'})
require('config.editor_ui').update()
assert(vim.wo.winbar:find('BlackModified', 1, true), 'modified title indicator missing')
-- Hold the async completion so repeat refreshes can prove no probe fan-out.
local system, callback, calls = vim.system, nil, 0
vim.system = function(_, _, done) calls = calls + 1; callback = done; return {} end
local entry = info.get(tmp)
entry.checked, entry.pending = nil, nil
info.refresh(tmp, true)
info.refresh(tmp, true)
assert(calls == 1 and entry.pending, 'parallel Git probes must be coalesced')
callback({code = 0, stdout = '## review-branch...origin/review-branch\n M tracked.lua\n'})
assert(vim.wait(1000, function() return calls == 2 end), 'write during probe must schedule a fresh snapshot')
callback({code = 0, stdout = '## review-branch...origin/review-branch\n M tracked.lua\n'})
assert(vim.wait(1000, function() return not entry.pending end), 'Git callback did not finish')
assert(entry.branch == 'review-branch' and entry.dirty, 'Git branch/status parsing failed')
info.refresh(tmp)
assert(calls == 2, 'five-second cache must avoid repeat process spawn')
info.refresh(tmp, true)
assert(calls == 3, 'forced refresh must bypass age cache')
callback({code = 128, stdout = ''})
assert(vim.wait(1000, function() return not entry.pending end))
assert(entry.branch == '' and entry.dirty == false, 'failed probes must clear obsolete Git state')
vim.system = function() error('spawn failure') end
info.refresh(tmp, true)
assert(not entry.pending, 'spawn failures must not leave a permanently pending probe')
vim.system = system
vim.cmd.enew({bang = true})
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(tmp, 'rf')
print('REDESIGN REVIEW PASS: project roots, escaped/modified titles, async coalescing, Git cache and failure recovery')
