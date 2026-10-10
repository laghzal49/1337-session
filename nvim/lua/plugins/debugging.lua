-- Debugging stays entirely off the startup path.
return {
  {
    'mfussenegger/nvim-dap',
    cmd = { 'Debug', 'DebugStart', 'DebugTarget', 'DebugRestart', 'DebugWatch', 'DebugProjectLaunch', 'DebugProjectEdit', 'DebugProjectGenerate', 'DebugProjectCheck' },
    dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio' },
    keys = {
      { '<F5>', function() require('config.debug_launch').start() end, desc = 'Debug continue / start' },
      { '<F10>', function() require('config.debug_launch').step('step_over') end, desc = 'Debug step over' },
      { '<F11>', function() require('config.debug_launch').step('step_into') end, desc = 'Debug step into' },
      { '<F12>', function() require('config.debug_launch').step('step_out') end, desc = 'Debug step out' },
      { '<leader>Dc', function() require('config.debug_launch').start() end, desc = 'Continue / start' },
      { '<leader>Db', function() require('dap').toggle_breakpoint() end, desc = 'Breakpoint' },
      { '<leader>DB', function()
        vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(value)
          if value and value ~= '' then require('dap').set_breakpoint(value) end
        end)
      end, desc = 'Conditional breakpoint' },
      { '<leader>Do', function() require('config.debug_launch').step('step_over') end, desc = 'Step over' },
      { '<leader>Di', function() require('config.debug_launch').step('step_into') end, desc = 'Step into' },
      { '<leader>DO', function() require('config.debug_launch').step('step_out') end, desc = 'Step out' },
      { '<leader>Df', function() require('config.debug_launch').pick() end, desc = 'Choose debug target / arguments' },
      { '<leader>DD', '<cmd>Debug<CR>', desc = 'Debugger actions' },
      { '<leader>DR', function() require('config.debug_launch').rerun() end, desc = 'Restart / rerun project' },
      { '<leader>DC', function() require('config.debug_launch').step('run_to_cursor') end, desc = 'Run to cursor' },
      { '<leader>Dw', function() require('config.debug_launch').watch() end, desc = 'Add watch expression' },
      { '<S-F5>', function() require('dap').terminate() end, desc = 'Stop debugging' },
      { '<leader>Dg', '<cmd>DebugProjectGenerate<CR>', desc = 'Generate project debugger profile' },
      { '<leader>Dj', function() require('config.debug_projects').edit() end, desc = 'Edit project launch.json' },
      { '<leader>Dh', '<cmd>DebugProjectCheck<CR>', desc = 'Check project launch.json' },
      { '<leader>Dl', function() require('config.debug_launch').rerun() end, desc = 'Run last debug configuration' },
      { '<leader>Dp', function() require('dap').pause() end, desc = 'Pause execution' },
      { '<leader>Dx', function() require('dap').clear_breakpoints() end, desc = 'Clear all breakpoints' },
      { '<leader>DL', function()
        vim.ui.input({ prompt = 'Logpoint message (use {expression}): ' }, function(value)
          if value and value ~= '' then require('dap').set_breakpoint(nil, nil, value) end
        end)
      end, desc = 'Logpoint' },
      { '<leader>Dt', function() require('dap').terminate() end, desc = 'Terminate' },
      { '<leader>Du', function() require('config.debug_panels').toggle() end, desc = 'Debug panels' },
      { '<leader>Dv', function() require('config.debug_panels').inspect('watches') end, desc = 'Watch expressions' },
      { '<leader>DS', function() require('config.debug_panels').inspect('stacks') end, desc = 'Call stack' },
      { '<leader>De', function() require('dapui').eval() end, mode = { 'n', 'v' }, desc = 'Evaluate expression' },
      { '<leader>Dr', function() require('dap').repl.toggle() end, desc = 'Debug console' },
    },
    config = function() require('config.debugging').setup() end,
  },
}
