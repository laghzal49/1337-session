local M = { running = false }

function M.plan(root, storage)
  root = vim.uv.fs_realpath(root) or root
  local source = root .. '/.venv'
  local stat = vim.uv.fs_lstat(source)
  if not stat or stat.type ~= 'directory' then return nil, 'Migration needs a real project .venv directory' end
  if vim.fn.filereadable(source .. '/pyvenv.cfg') ~= 1 then return nil, 'Project .venv has no pyvenv.cfg' end
  if not storage or vim.fn.isdirectory(storage) ~= 1 then return nil, 'Local goinfre storage is unavailable' end
  local target = storage .. '/venvs/' .. vim.fs.basename(root) .. '-' .. vim.fn.sha256(root):sub(1, 12)
  if vim.uv.fs_lstat(target) then return nil, 'Migration destination already exists; nothing was overwritten' end
  local script = vim.fn.stdpath('config') .. '/scripts/migrate_venv.py'
  local python = vim.fn.exepath('python3')
  if python == '' then return nil, 'Python 3 is required for migration' end
  return { source = source, target = target, argv = { python, script, '--source', source, '--target', target } }
end

function M.run(plan, callback)
  if M.running then return false, 'An environment migration is already running' end
  M.running = true
  local ok, job = pcall(vim.system, plan.argv, { text = true }, vim.schedule_wrap(function(result)
    M.running = false
    if result.code ~= 0 then
      local message = (result.stderr or ''):gsub('%s+$', '')
      vim.notify('Environment migration failed: ' .. message, vim.log.levels.ERROR)
      if callback then callback(false, message) end
      return
    end
    local decoded, state = pcall(vim.json.decode, result.stdout or '')
    if not decoded or type(state) ~= 'table' or not state.backup then
      vim.notify('Migration returned an invalid result; inspect source and destination', vim.log.levels.ERROR)
      if callback then callback(false, 'Invalid migration result') end
      return
    end
    vim.notify('Environment migrated to ' .. state.target .. '\nOriginal kept at ' .. state.backup
      .. '\nRestart Python language/debug sessions to use it.', vim.log.levels.INFO)
    if callback then callback(true, state) end
  end))
  if not ok then M.running = false; return false, tostring(job) end
  return true
end

function M.open()
  local _, storage = require('config.station').get_goinfre_paths()
  local plan, err = M.plan(require('config.project').root(), storage)
  if not plan then vim.notify(err, vim.log.levels.WARN); return end
  vim.ui.select({ 'Migrate and keep original backup', 'Cancel' }, {
    prompt = 'Move ' .. plan.source .. ' to ' .. plan.target .. '?',
  }, function(choice)
    if choice == 'Migrate and keep original backup' then
      local ok, failure = M.run(plan)
      if not ok then vim.notify(failure, vim.log.levels.WARN) end
    end
  end)
end

return M
