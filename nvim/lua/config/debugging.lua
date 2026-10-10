local M = {}

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

function M.setup()
  local dap, ui = require('dap'), require('dapui')
  ui.setup({
    layouts = {
      { elements = { { id = 'scopes', size = 0.45 }, { id = 'watches', size = 0.25 },
        { id = 'stacks', size = 0.2 }, { id = 'breakpoints', size = 0.1 } }, size = 36, position = 'left' },
      { elements = { 'repl', 'console' }, size = 0.25, position = 'bottom' },
    },
    floating = { border = require('config.ui').border },
  })
  dap.listeners.after.event_initialized.black_debug = function() ui.open() end
  dap.listeners.before.event_terminated.black_debug = function() ui.close() end
  dap.listeners.before.event_exited.black_debug = function() ui.close() end
  dap.listeners.after.disconnect.black_debug = function() ui.close() end
  vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
  vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'CursorLine' })

  dap.adapters.python = function(callback)
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
        local path = vim.fn.input('Executable: ', require('config.project').root() .. '/', 'file')
        if path == '' then return dap.ABORT end
        return vim.fn.fnamemodify(path, ':p')
      end,
      cwd = function() return require('config.project').root() end },
  }
  dap.configurations.c = compiled
  dap.configurations.cpp = vim.deepcopy(compiled)
end

return M
