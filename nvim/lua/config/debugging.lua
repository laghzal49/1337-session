local M = {}

function M.refresh_signs()
  local icon = require('config.ui').icon
  vim.fn.sign_define('DapBreakpoint', { text = icon('breakpoint'), texthl = 'DiagnosticError' })
  vim.fn.sign_define('DapBreakpointCondition', { text = icon('breakpoint_condition'), texthl = 'DiagnosticWarn' })
  vim.fn.sign_define('DapStopped', { text = icon('debug_stopped'), texthl = 'DiagnosticOk', linehl = 'CursorLine' })
end

function M.python()
  local root = require('config.project').root()
  for _, path in ipairs({
    root .. '/.venv/bin/python',
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
  local ok, result = pcall(vim.fn.input, label, default or '', completion or '')
  if not ok or result == '' then return require('dap').ABORT end
  return result
end

function M.arguments()
  local ok, value = pcall(vim.fn.input, 'Arguments (quote paths with spaces): ')
  if not ok then return require('dap').ABORT end
  local args, err = M.parse_args(value)
  if not args then
    vim.notify(err, vim.log.levels.WARN)
    return require('dap').ABORT
  end
  return args
end

function M.setup()
  local dap, ui = require('dap'), require('dapui')
  ui.setup({
    layouts = {
      { elements = { { id = 'scopes', size = 0.45 }, { id = 'watches', size = 0.25 },
        { id = 'stacks', size = 0.2 }, { id = 'breakpoints', size = 0.1 } }, size = math.min(36, math.max(22, math.floor(vim.o.columns * 0.25))), position = 'left' },
      { elements = { 'repl', 'console' }, size = math.min(12, math.max(5, math.floor(vim.o.lines * 0.25))), position = 'bottom' },
    },
    floating = { border = require('config.ui').border },
  })
  dap.listeners.after.event_initialized.black_debug = function() ui.open() end
  -- Session closure also covers adapter crashes and failed initialization.
  -- Preserve panels while another parent/child session is still active.
  dap.listeners.on_session.black_debug = function(_, active)
    if not active then
      vim.schedule(function()
        if not dap.session() then ui.close() end
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
    if vim.fn.executable('gdb') == 0 then
      vim.notify('C/C++ debugger needs GDB 14+ with DAP support; see :ConfigGuide', vim.log.levels.WARN)
      return
    end
    callback({ type = 'executable', command = 'gdb', args = { '--interpreter=dap', '--eval-command', 'set print pretty on' } })
  end
  local compiled = {
    { name = 'C/C++: launch executable', type = 'gdb', request = 'launch', stopAtBeginningOfMainSubprogram = true,
      program = function()
        local path = M.prompt('Executable: ', require('config.project').root() .. '/', 'file')
        if path == dap.ABORT then return dap.ABORT end
        path = vim.fn.expand(path)
        if vim.fn.executable(path) ~= 1 or vim.fn.isdirectory(path) == 1 then
          vim.notify('Choose an executable built with debug symbols (-g)', vim.log.levels.WARN)
          return dap.ABORT
        end
        return vim.fn.fnamemodify(path, ':p')
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
end

return M
