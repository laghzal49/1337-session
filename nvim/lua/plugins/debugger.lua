return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = { automatic_installation = false },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(name) return name ~= "codelldb" end, opts.ensure_installed or {})
    end,
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      dap.adapters.lldb = { type = "executable", command = "/usr/bin/lldb-dap", name = "lldb" }
      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = {
          {
            name = "Launch executable (LLDB)", type = "lldb", request = "launch",
            program = function() return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file") end,
            cwd = "${workspaceFolder}", stopOnEntry = false, args = {},
          },
        }
      end
    end,
  },
}
