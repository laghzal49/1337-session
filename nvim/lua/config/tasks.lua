-- Project-aware background jobs. No shell interpolation or startup dependencies.
local M = { running = nil, last = nil, output = nil }

function M.discover(root)
  root = root or require('config.project').root()
  local tasks = {}
  local function add(name, argv)
    tasks[#tasks + 1] = { name = name, argv = argv, cwd = root }
  end
  local function exists(path) return vim.fn.filereadable(root .. '/' .. path) == 1 end
  if exists('Makefile') or exists('makefile') or exists('GNUmakefile') then
    add('make: default', { 'make' })
    for _, target in ipairs(require('config.makefile').parse(require('config.makefile').find_makefile(root))) do
      add('make: ' .. target.name, { 'make', '--', target.name })
    end
  end
  if exists('package.json') then
    local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(root .. '/package.json'), '\n'))
    if ok and type(package) == 'table' and type(package.scripts) == 'table' then
      local manager = exists('pnpm-lock.yaml') and 'pnpm' or (exists('yarn.lock') and 'yarn' or 'npm')
      for _, name in ipairs(vim.tbl_keys(package.scripts)) do add(manager .. ': ' .. name, { manager, 'run', name }) end
    end
  end
  if exists('Cargo.toml') then
    add('cargo: check', { 'cargo', 'check' }); add('cargo: test', { 'cargo', 'test' }); add('cargo: build', { 'cargo', 'build' })
  end
  if exists('go.mod') then
    add('go: test', { 'go', 'test', './...' }); add('go: build', { 'go', 'build', './...' })
  end
  if exists('pyproject.toml') or exists('pytest.ini') or exists('requirements.txt') then
    local python = vim.fn.executable(root .. '/.venv/bin/python') == 1 and root .. '/.venv/bin/python' or 'python3'
    add('python: tests', { python, '-m', 'pytest' })
    if vim.fn.executable('ruff') == 1 then add('python: lint', { 'ruff', 'check', '.' }) end
  end
  table.sort(tasks, function(a, b) return a.name < b.name end)
  return tasks
end

function M.show_output()
  if not M.output then vim.notify('No task output yet', vim.log.levels.INFO); return end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'log'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.output)
  vim.bo[buf].modifiable = false
  vim.cmd('botright 12split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, desc = 'Close task output' })
end

function M.run(task)
  if M.running then vim.notify('A task is running. Use :TaskStop first.', vim.log.levels.WARN); return false end
  if not task or not task.argv or #task.argv == 0 then return false end
  if vim.fn.executable(task.argv[1]) ~= 1 then
    vim.notify('Task tool missing: ' .. task.argv[1], vim.log.levels.ERROR); return false
  end
  M.last = vim.deepcopy(task)
  local started = vim.uv.hrtime()
  local token = { task = task, stopped = false, efm = vim.o.errorformat }
  M.running = token
  vim.notify('Running ' .. task.name, vim.log.levels.INFO, { title = 'Project tasks' })
  local ok, job = pcall(vim.system, task.argv, { cwd = task.cwd, text = true }, function(result)
    vim.schedule(function()
      if M.running ~= token then return end
      M.running = nil
      local output = (result.stdout or '') .. '\n' .. (result.stderr or '')
      output = output:gsub('\27%[[%d;]*[%a]', '')
      M.output = { '$ ' .. table.concat(task.argv, ' '), 'cwd: ' .. task.cwd, '' }
      vim.list_extend(M.output, vim.split(output, '\n', { trimempty = false }))
      -- Compiler paths are relative to the task root, not the active editor cwd.
      local lines = vim.split(output, '\n')
      table.insert(lines, 1, '__TASK_CWD__:' .. task.cwd)
      vim.fn.setqflist({}, ' ', { title = task.name, lines = lines,
        efm = '%D__TASK_CWD__:%f,' .. token.efm })
      local items = vim.fn.getqflist()
      if items[1] and items[1].text == '__TASK_CWD__:' .. task.cwd then table.remove(items, 1) end
      vim.fn.setqflist(items, 'r')
      local valid = 0
      for _, item in ipairs(items) do if item.valid == 1 then valid = valid + 1 end end
      local status = token.stopped and 'stopped' or (result.code == 0 and 'passed' or ('failed (' .. result.code .. ')'))
      vim.notify(('%s %s · %.2fs'):format(task.name, status, (vim.uv.hrtime() - started) / 1e9),
        result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN, { title = 'Project tasks' })
      if result.code ~= 0 and not token.stopped then
        if valid > 0 then vim.cmd('botright copen') else M.show_output() end
      end
    end)
  end)
  if not ok then M.running = nil; vim.notify(tostring(job), vim.log.levels.ERROR); return false end
  token.job = job
  return true
end

function M.stop()
  if M.running and M.running.job then M.running.stopped = true; M.running.job:kill(15) end
end
function M.rerun()
  if M.last then M.run(M.last) else M.pick() end
end
function M.pick(name)
  local tasks = M.discover()
  if name and name ~= '' then
    for _, task in ipairs(tasks) do if task.name == name then return M.run(task) end end
    vim.notify('Unknown task: ' .. name, vim.log.levels.WARN); return
  end
  if #tasks == 0 then
    vim.notify('No Make, package.json, Cargo, Go or Python tasks found in project root', vim.log.levels.INFO); return
  end
  vim.ui.select(tasks, { prompt = 'Run project task', format_item = function(task) return task.name end }, function(task)
    if task then M.run(task) end
  end)
end
return M
