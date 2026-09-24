-- Optional tools load on their command/key; feedback loads after startup.
return {
  { "smjonas/inc-rename.nvim", cmd = "IncRename", opts = {} },
  {
    "nvim-mini/mini.files",
    lazy = false,
    keys = {
      { "<leader>e", function()
        local files = require("mini.files")
        if files.close() then return end
        local path = vim.api.nvim_buf_get_name(0)
        files.open(vim.uv.fs_stat(path) and path or require("config.project").root(), true, require("config.tool_layout").files())
      end, desc = "Files (Mini Files)" },
      { "<leader>fm", function()
        local path = vim.api.nvim_buf_get_name(0)
        require("mini.files").open(vim.uv.fs_stat(path) and path or require("config.project").root(), true, require("config.tool_layout").files())
      end, desc = "Browse current file (Mini Files)" },
      { "<leader>fM", function() require("mini.files").open(require("config.project").root(), true, require("config.tool_layout").files()) end, desc = "Browse project (Mini Files)" },
    },
    opts = { options = { use_as_default_explorer = true }, windows = {
      max_number = 3, preview = false, width_focus = 36, width_nofocus = 16,
    } },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    opts = {
      preset = "minimal",
      options = {
        throttle = 80, show_source = { enabled = true },
        multilines = { enabled = true, always_show = false },
        show_all_diags_on_cursorline = true,
        enable_on_insert = false, enable_on_select = false,
      },
    },
  },
  { "neovim/nvim-lspconfig", opts = { diagnostics = { virtual_text = false, virtual_lines = false } } },
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    keys = { { "<leader>xQ", function() require("quicker").toggle() end, desc = "Editable quickfix (Quicker)" } },
    opts = { keys = {
      { ">", function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end, desc = "Expand context" },
      { "<", function() require("quicker").collapse() end, desc = "Collapse context" },
    } },
  },
  {
    "nvim-mini/mini.notify",
    event = "VeryLazy",
    config = function() require("config.notifications").setup() end,
  },
  { "folke/snacks.nvim", opts = { notifier = { enabled = false } } },
  { "folke/noice.nvim", opts = { notify = { enabled = false } } },
  {
    "DNLHC/glance.nvim",
    cmd = "Glance",
    keys = {
      { "<leader>cgd", "<cmd>Glance definitions<cr>", desc = "Peek definition" },
      { "<leader>cgr", "<cmd>Glance references<cr>", desc = "Peek references" },
      { "<leader>cgt", "<cmd>Glance type_definitions<cr>", desc = "Peek type definition" },
      { "<leader>cgi", "<cmd>Glance implementations<cr>", desc = "Peek implementation" },
    },
    opts = function() return {
      height = 12,
      border = { enable = false }, theme = { enable = false },
    } end,
  },
  {
    "Wansmer/treesj",
    keys = { { "<leader>cj", function() require("treesj").toggle() end, desc = "Split/join code structure" } },
    opts = { use_default_keymaps = false, max_join_length = 100 },
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    keys = {
      { "ii", function() require("various-textobjs").indentation("inner", "inner") end, mode = { "o", "x" }, desc = "Inner indentation" },
      { "ai", function() require("various-textobjs").indentation("outer", "inner") end, mode = { "o", "x" }, desc = "Around indentation" },
      { "iS", function() require("various-textobjs").subword("inner") end, mode = { "o", "x" }, desc = "Inner subword" },
      { "aS", function() require("various-textobjs").subword("outer") end, mode = { "o", "x" }, desc = "Around subword" },
    },
    opts = { keymaps = { useDefaults = false } },
  },
}
