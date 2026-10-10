-- Project launch data is JSON, never project-supplied Lua.
local M = {}
local function resolve(value, root)
  if type(value) == 'string' then
    return (value:gsub('%${workspaceFolder}', function() return root end)
      :gsub('%${workspaceFolderBasename}', function() return vim.fs.basename(root) end))
  end
  if type(value) ~= 'table' then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = resolve(item, root) end
  return result
end

function M.path(root)
  return (root or require('config.project').root()) .. '/.vscode/launch.json'
end

local function template(root)
  local ft = vim.bo.filetype
  if ft == 'python' then
    return { name = 'Python: current file', type = 'python', request = 'launch',
      program = '${file}', cwd = '${workspaceFolder}', args = {}, console = 'integratedTerminal' }
  end
  if ft == 'c' or ft == 'cpp' then
    local executable = 'a.out'
    for _, candidate in ipairs({ vim.fs.basename(root), 'build/' .. vim.fs.basename(root), 'a.out' }) do
      if vim.fn.executable(root .. '/' .. candidate) == 1 then executable = candidate; break end
    end
    return { name = 'C/C++: project executable', type = 'gdb', request = 'launch',
      program = '${workspaceFolder}/' .. executable, cwd = '${workspaceFolder}', args = {},
      stopAtBeginningOfMainSubprogram = true }
  end
end

-- Create once. Exclusive open keeps an existing user file intact even if another
-- editor creates it between the check and the write.
function M.ensure(root, allow_empty)
  root = root or require('config.project').root()
  local path = M.path(root)
  if vim.uv.fs_lstat(path) then return path, false end
  local config = template(root)
  if not config and not allow_empty then return path, false, 'Open a Python, C or C++ file to generate a debugger profile' end
  local directory = vim.fs.dirname(path)
  if vim.fn.mkdir(directory, 'p') == 0 and vim.fn.isdirectory(directory) == 0 then
    return path, false, 'Cannot create ' .. directory
  end
  local fd, err = vim.uv.fs_open(path, 'wx', 420)
  if not fd then
    if vim.uv.fs_lstat(path) then return path, false end
    return path, false, 'Cannot create ' .. path .. ': ' .. tostring(err)
  end
  local lines = { '{', '  "version": "0.2.0",', '  "configurations": [' }
  if config then
    local encoded = vim.json.encode(config)
    lines[#lines + 1] = '    ' .. encoded
  end
  lines[#lines + 1] = '  ]'
  lines[#lines + 1] = '}'
  local written, write_err = vim.uv.fs_write(fd, table.concat(lines, '\n') .. '\n', 0)
  vim.uv.fs_close(fd)
  if not written then vim.uv.fs_unlink(path); return path, false, 'Cannot write ' .. path .. ': ' .. tostring(write_err) end
  return path, true
end

function M.read(root)
  root = root or require('config.project').root()
  local path = M.path(root)
  local stat = vim.uv.fs_stat(path)
  if not stat then return {}, nil, path end
  if stat.type ~= 'file' or stat.size > 1024 * 1024 then
    return {}, 'launch.json must be a regular file smaller than 1 MiB', path
  end
  local source_ok, source = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'), { skip_comments = true })
  end)
  if not source_ok then return {}, 'Invalid launch.json: ' .. tostring(source), path end
  if type(source) ~= 'table' or type(source.configurations) ~= 'table' or not vim.islist(source.configurations) then
    return {}, 'launch.json requires a configurations array', path
  end
  local ok, configs = pcall(require('dap.ext.vscode').getconfigs, path)
  if not ok then return {}, tostring(configs), path end
  local result = {}
  for index, config in ipairs(configs) do
    if getmetatable(config) then
      return {}, 'launch.json inputs are not supported; use static args or built-in prompted launches', path
    end
    if type(config) ~= 'table' or type(config.name) ~= 'string' or config.name == ''
      or type(config.type) ~= 'string' or (config.request ~= 'launch' and config.request ~= 'attach') then
      return {}, 'Configuration ' .. index .. ' requires name, type and request (launch/attach)', path
    end
    if config.preLaunchTask or config.postDebugTask then
      return {}, 'VSCode tasks are not run by Neovim; remove preLaunchTask/postDebugTask and build explicitly', path
    end
    config = resolve(config, root)
    if config.type == 'debugpy' then config.type = 'python' end
    if not require('dap').adapters[config.type] then
      return {}, 'No installed debugger adapter for type: ' .. config.type, path
    end
    if config.args ~= nil and (type(config.args) ~= 'table' or not vim.islist(config.args)) then
      return {}, 'Configuration ' .. config.name .. ': args must be an array', path
    end
    for _, arg in ipairs(config.args or {}) do
      if type(arg) ~= 'string' then return {}, 'Configuration ' .. config.name .. ': each argument must be a string', path end
    end
    if config.request == 'launch' and config.type == 'python' and not config.program and not config.module then
      return {}, 'Python launch requires program or module: ' .. config.name, path
    end
    config.cwd = config.cwd or root
    for _, key in ipairs({ 'cwd', 'program' }) do
      local value = config[key]
      if type(value) == 'string' and not value:find('%${') and not vim.startswith(value, '/') then
        config[key] = vim.fs.normalize(root .. '/' .. value)
      end
    end
    if config.type == 'python' and config.request == 'launch' then
      config.pythonPath = config.pythonPath or require('config.debugging').python()
    end
    result[#result + 1] = config
  end
  return result, nil, path
end

function M.list()
  local _, _, create_err = M.ensure()
  if create_err then return {} end
  local configs, err = M.read()
  if err then vim.notify('Project debugger: ' .. err, vim.log.levels.WARN) end
  return configs
end

function M.launch()
  local _, created, create_err = M.ensure()
  if create_err then vim.notify('Project debugger: ' .. create_err, vim.log.levels.WARN); return end
  local configs, err, path = M.read()
  if err then vim.notify('Project debugger: ' .. err, vim.log.levels.WARN); return end
  if #configs == 0 then
    vim.notify('No project launch configurations in ' .. path .. '; use :DebugProjectEdit', vim.log.levels.INFO)
    return
  end
  if created then vim.notify('Created debugger profile: ' .. path, vim.log.levels.INFO) end
  vim.ui.select(configs, { prompt = 'Project debugger', format_item = function(config) return config.name end }, function(config)
    if config then require('dap').run(config) end
  end)
end

function M.edit()
  local path, _, err = M.ensure(nil, true)
  if err then vim.notify('Project debugger: ' .. err, vim.log.levels.WARN); return end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.bo.filetype = 'json'
end

function M.setup()
  require('dap').providers.configs['dap.launch.json'] = M.list
  vim.api.nvim_create_user_command('DebugProjectLaunch', M.launch, { desc = 'Select a project launch.json configuration' })
  vim.api.nvim_create_user_command('DebugProjectEdit', M.edit, { desc = 'Create or edit project .vscode/launch.json' })
  vim.api.nvim_create_user_command('DebugProjectGenerate', function()
    local path, created, err = M.ensure()
    vim.notify(err and ('Project debugger: ' .. err) or
      (created and ('Created debugger profile: ' .. path) or ('Debugger profile already exists: ' .. path)),
      err and vim.log.levels.WARN or vim.log.levels.INFO)
  end, { desc = 'Generate a debugger profile for the current project' })
  vim.api.nvim_create_user_command('DebugProjectCheck', function()
    local _, created, create_err = M.ensure()
    if create_err then vim.notify('Project debugger: ' .. create_err, vim.log.levels.WARN); return end
    local configs, err, path = M.read()
    vim.notify(err and ('Project debugger: ' .. err) or
      ((created and 'Created and checked ' or 'Checked ') .. #configs .. ' project configurations: ' .. path),
      err and vim.log.levels.WARN or vim.log.levels.INFO)
  end, { desc = 'Validate project debug configurations' })
end

return M
