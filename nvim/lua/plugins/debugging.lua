-- Debugging stays entirely off the startup path.
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = { 'rcarriga/nvim-dap-ui', 'nvim-neotest/nvim-nio' },
    keys = {
      { '<F5>', function() require('dap').continue() end, desc = 'Debug continue / start' },
      { '<F10>', function() require('dap').step_over() end, desc = 'Debug step over' },
      { '<F11>', function() require('dap').step_into() end, desc = 'Debug step into' },
      { '<F12>', function() require('dap').step_out() end, desc = 'Debug step out' },
      { '<leader>Dc', function() require('dap').continue() end, desc = 'Continue / start' },
      { '<leader>Db', function() require('dap').toggle_breakpoint() end, desc = 'Breakpoint' },
      { '<leader>DB', function()
        vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(value)
          if value and value ~= '' then require('dap').set_breakpoint(value) end
        end)
      end, desc = 'Conditional breakpoint' },
      { '<leader>Do', function() require('dap').step_over() end, desc = 'Step over' },
      { '<leader>Di', function() require('dap').step_into() end, desc = 'Step into' },
      { '<leader>DO', function() require('dap').step_out() end, desc = 'Step out' },
      { '<leader>Dt', function() require('dap').terminate() end, desc = 'Terminate' },
      { '<leader>Du', function() require('dapui').toggle() end, desc = 'Debug panels' },
      { '<leader>De', function() require('dapui').eval() end, mode = { 'n', 'v' }, desc = 'Evaluate expression' },
      { '<leader>Dr', function() require('dap').repl.toggle() end, desc = 'Debug console' },
    },
    config = function() require('config.debugging').setup() end,
  },
}
