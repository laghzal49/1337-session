local M = {}

function M.refresh_signs()
  local icon = require('config.ui').icon
  vim.fn.sign_define('DapBreakpoint', { text = icon('breakpoint'), texthl = 'DiagnosticError' })
  vim.fn.sign_define('DapBreakpointCondition', { text = icon('breakpoint_condition'), texthl = 'DiagnosticWarn' })
  vim.fn.sign_define('DapStopped', { text = icon('debug_stopped'), texthl = 'DiagnosticWarn', linehl = 'BlackDebugLine', numhl = 'BlackDebugLineNr' })
end

function M.python(root)
  root = root or require('config.project').root()
  local chosen, reason = require('config.python_environment').interpreter(vim.uv.fs_realpath(root) or root)
  if reason == 'project override' or reason == 'configured override' then return chosen end
  for _, path in ipairs({
    root .. '/.venv/bin/python',
    root .. '/venv/bin/python',
    vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. '/bin/python') or '',
  }) do
    if vim.fn.executable(path) == 1 then return path end
  end
  return vim.fn.exepath('python3')
end

-- Parse shell-like arguments without invoking a shell. Quoted paths stay intact.
function M.parse_args(input)
  local args, word, quote, escaped, started = {}, '', nil, false, false
  for char in input:gmatch('.') do
    if escaped then
      -- In double quotes a backslash only escapes quote, backslash, dollar or backtick.
      if quote == '"' and not char:match('["\\$`]') then word = word .. '\\' end
      word, escaped, started = word .. char, false, true
    elseif char == '\\' and quote ~= "'" then escaped, started = true, true
    elseif quote then
      if char == quote then quote = nil else word = word .. char end
    elseif char == '"' or char == "'" then quote, started = char, true
    elseif char:match('%s') then
      if started then args[#args + 1], word, started = word, '', false end
    else word, started = word .. char, true end
  end
  if quote or escaped then return nil, 'Unclosed quote or trailing escape' end
  if started then args[#args + 1] = word end
  return args
end

function M.prompt(label, default, completion)
  return coroutine.create(function(co)
    vim.ui.input({ prompt = label, default = default or '', completion = completion }, function(result)
      coroutine.resume(co, result and result ~= '' and result or require('dap').ABORT)
    end)
  end)
end

function M.arguments()
  return coroutine.create(function(co)
    vim.ui.input({ prompt = 'Arguments (quote paths with spaces): ' }, function(value)
      local args, err
      if value ~= nil then args, err = M.parse_args(value) end
      if err then vim.notify(err, vim.log.levels.WARN) end
      coroutine.resume(co, args or require('dap').ABORT)
    end)
  end)
end

local gdb_checked = {}
function M.gdb(callback)
  local command = vim.g.debug_gdb or vim.fn.exepath('gdb')
  if command == '' or vim.fn.executable(command) ~= 1 then
    vim.notify('C/C++ debugging needs GDB 14+ built with Python/DAP support. Set vim.g.debug_gdb to its path.', vim.log.levels.WARN)
    return
  end
  local stat = vim.uv.fs_stat(command)
  local key = command .. ':' .. (stat and stat.mtime.sec or '')
  if gdb_checked[key] then callback(command); return end
  -- --nx avoids project/user init scripts during this capability check.
  vim.system({ command, '--quiet', '--nx', '--batch', '-ex', 'python import gdb.dap' },
    { text = true, timeout = 5000 }, vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify('GDB at ' .. command .. ' cannot provide DAP. Use GDB 14+ with Python support; '
          .. 'set vim.g.debug_gdb to a newer binary. See :ConfigGuide.', vim.log.levels.WARN)
        return
      end
      gdb_checked[key] = true
      callback(command)
    end))
end

function M.setup()
  local dap, ui = require('dap'), require('dapui')
  ui.setup({
    force_buffers = false,
    layouts = {
      { elements = { { id = 'scopes', size = 0.45 }, { id = 'watches', size = 0.25 },
        { id = 'stacks', size = 0.2 }, { id = 'breakpoints', size = 0.1 } }, size = 0.25, position = 'left' },
      { elements = { 'repl', 'console' }, size = 0.25, position = 'bottom' },
      { elements = { 'scopes' }, size = 0.3, position = 'bottom' },
    },
    floating = { border = require('config.ui').border },
  })
  local panels = require('config.debug_panels')
  panels.setup()
  dap.listeners.after.event_initialized.black_debug = panels.open
  -- Session closure also covers adapter crashes and failed initialization.
  -- Preserve panels while another parent/child session is still active.
  dap.listeners.on_session.black_debug = function(_, active)
    if not active then
      vim.schedule(function()
        if not dap.session() then panels.close() end
      end)
    end
  end
  M.refresh_signs()

  dap.adapters.python = function(callback, config)
    if config.request == 'attach' and config.connect then
      callback({ type = 'server', host = config.connect.host, port = config.connect.port })
      return
    end
    local dedicated = vim.fn.stdpath('data') .. '/debugpy/bin/python'
    local python = vim.g.debugpy_python or (vim.fn.executable(dedicated) == 1 and dedicated or M.python())
    if python == '' or vim.fn.executable(python) ~= 1 then
      vim.notify('Python debugger: install Python and debugpy; see :ConfigGuide', vim.log.levels.WARN)
      return
    end
    vim.system({ python, '-c', 'import debugpy' }, { text = true, timeout = 3000 }, vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify('debugpy is missing from ' .. python .. '; see :ConfigGuide for setup', vim.log.levels.WARN)
        return
      end
      callback({ type = 'executable', command = python, args = { '-m', 'debugpy.adapter' } })
    end))
  end
  dap.configurations.python = {
    { name = 'Python: current file', type = 'python', request = 'launch', program = '${file}',
      cwd = function() return require('config.project').root() end,
      pythonPath = M.python, console = 'integratedTerminal', justMyCode = true },
  }
  local python_base = dap.configurations.python[1]
  local with_args = vim.deepcopy(python_base)
  with_args.name, with_args.args = 'Python: current file with arguments', M.arguments
  local module = vim.deepcopy(with_args)
  module.name, module.program = 'Python: module with arguments', nil
  module.module = function() return M.prompt('Python module (e.g. pytest): ') end
  dap.configurations.python[#dap.configurations.python + 1] = with_args
  dap.configurations.python[#dap.configurations.python + 1] = module
  dap.configurations.python[#dap.configurations.python + 1] = {
    name = 'Python: attach to debugpy (localhost:5678)', type = 'python', request = 'attach',
    connect = { host = '127.0.0.1', port = 5678 }, justMyCode = true,
  }
  dap.adapters.gdb = function(callback)
    M.gdb(function(command)
      callback({ type = 'executable', command = command, args = { '--interpreter=dap', '--eval-command', 'set print pretty on' } })
    end)
  end
  local compiled = {
    { name = 'C/C++: launch executable', type = 'gdb', request = 'launch', stopAtBeginningOfMainSubprogram = true,
      program = function()
        return M.prompt('Compiled program (-g): ', require('config.project').root() .. '/', 'file')
      end,
      cwd = function() return require('config.project').root() end },
  }
  compiled[1].args = M.arguments
  compiled[#compiled + 1] = { name = 'C/C++: attach to process', type = 'gdb', request = 'attach',
    pid = function() return require('dap.utils').pick_process() end,
    cwd = function() return require('config.project').root() end }
  dap.configurations.c = compiled
  dap.configurations.cpp = vim.deepcopy(compiled)
  require('config.debug_projects').setup()
  require('config.debug_launch').setup()
end

return M
