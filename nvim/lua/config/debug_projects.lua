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
  local configs, err = M.read()
  if err then vim.notify('Project debugger: ' .. err, vim.log.levels.WARN) end
  return configs
end

function M.launch()
  local configs, err, path = M.read()
  if err then vim.notify('Project debugger: ' .. err, vim.log.levels.WARN); return end
  if #configs == 0 then
    vim.notify('No project launch configurations in ' .. path .. '; use :DebugProjectEdit', vim.log.levels.INFO)
    return
  end
  vim.ui.select(configs, { prompt = 'Project debugger', format_item = function(config) return config.name end }, function(config)
    if config then require('dap').run(config) end
  end)
end

function M.edit()
  local path = M.path()
  if not vim.uv.fs_stat(path) then
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile(vim.split([=[{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: project file",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "cwd": "${workspaceFolder}",
      "args": [],
      "console": "integratedTerminal"
    },
    {
      "name": "C/C++: project executable",
      "type": "gdb",
      "request": "launch",
      "program": "${workspaceFolder}/a.out",
      "cwd": "${workspaceFolder}",
      "args": [],
      "stopAtBeginningOfMainSubprogram": true
    }
  ]
}]=], '\n'), path)
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.bo.filetype = 'json'
end

function M.setup()
  require('dap').providers.configs['dap.launch.json'] = M.list
  vim.api.nvim_create_user_command('DebugProjectLaunch', M.launch, { desc = 'Select a project launch.json configuration' })
  vim.api.nvim_create_user_command('DebugProjectEdit', M.edit, { desc = 'Create or edit project .vscode/launch.json' })
  vim.api.nvim_create_user_command('DebugProjectCheck', function()
    local configs, err, path = M.read()
    vim.notify(err and ('Project debugger: ' .. err) or (#configs .. ' project configurations: ' .. path),
      err and vim.log.levels.WARN or vim.log.levels.INFO)
  end, { desc = 'Validate project debug configurations' })
end

return M
