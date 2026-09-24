-- Python uses ty for language features and Ruff for linting and formatting.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {
          enabled = true,
          mason = false,
          cmd = { "ty", "server" },
          settings = { ty = vim.empty_dict() },
          root_dir = require("config.python_environment").root_dir,
          before_init = require("config.python_environment").before_init,
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
        },
        ruff = {
          on_attach = function(client)
            -- Let ty provide Python hover information.
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },
}
