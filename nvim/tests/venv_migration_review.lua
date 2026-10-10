local migration = require('config.venv_migration')
local root = vim.fn.tempname()
vim.fn.mkdir(root .. '/project/.venv', 'p')
vim.fn.mkdir(root .. '/storage', 'p')
vim.fn.writefile({ 'home = /usr/bin' }, root .. '/project/.venv/pyvenv.cfg')
vim.fn.writefile({ 'original' }, root .. '/project/.venv/keep')
local plan = assert(migration.plan(root .. '/project', root .. '/storage'))
assert(plan.target:find(vim.fn.sha256(root .. '/project'):sub(1, 12), 1, true), 'migration target differs from station rebuild')
local notify, messages = vim.notify, {}
vim.notify = function(message) messages[#messages + 1] = message end
local done, success, state
assert(migration.run(plan, function(ok, result) done, success, state = true, ok, result end))
local repeated, err = migration.run(plan)
assert(not repeated and err:find('already running'), 'concurrent editor migration allowed')
assert(vim.wait(5000, function() return done end, 10), 'migration completion timeout')
assert(success and vim.uv.fs_readlink(plan.source) == plan.target, 'migration failed to publish link')
assert(vim.fn.filereadable(state.backup .. '/keep') == 1, 'original backup missing')
assert(not migration.plan(root .. '/project', root .. '/storage'), 'existing symlink should not migrate again')
vim.notify = notify
vim.fn.delete(root, 'rf')
print('VENV MIGRATION PASS: editor plan, async execution, duplicate rejection, link and backup')
