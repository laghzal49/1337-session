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
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "ruff" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {
          enabled = true,
          mason = false,
          cmd = { "ty", "server" },
          settings = { ty = {} },
          before_init = function(_, config)
            -- Standalone scripts may use packages installed with pip --user.
            -- Project roots and activated environments keep their own search paths.
            if
              (config.root_dir and config.root_dir ~= vim.fn.expand("~"))
              or vim.env.VIRTUAL_ENV
              or vim.env.CONDA_PREFIX
            then
              return
            end
            if vim.fn.isdirectory(vim.fn.getcwd() .. "/.venv") == 1 then
              return
            end
            local result = vim.system({ "python3", "-m", "site", "--user-site" }, { text = true }):wait()
            local path = vim.trim(result.stdout or "")
            if result.code == 0 and vim.fn.isdirectory(path) == 1 then
              config.settings.ty = vim.tbl_deep_extend("force", config.settings.ty or {}, {
                configuration = { environment = { ["extra-paths"] = { path } } },
              })
            end
          end,
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
