-- Optional tools load on their command/key; feedback loads after startup.
return {
  { import = "lazyvim.plugins.extras.editor.inc-rename" },
  {
    "nvim-mini/mini.files",
    keys = {
      { "<leader>fm", function()
        local path = vim.api.nvim_buf_get_name(0)
        require("mini.files").open(vim.uv.fs_stat(path) and path or LazyVim.root(), true, require("config.tool_layout").files())
      end, desc = "Browse current file (Mini Files)" },
      { "<leader>fM", function() require("mini.files").open(LazyVim.root(), true, require("config.tool_layout").files()) end, desc = "Browse project (Mini Files)" },
    },
    opts = { options = { use_as_default_explorer = false }, windows = {
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
  { "xzbdmw/colorful-menu.nvim", lazy = true, opts = { max_width = 38 } },
  { "nvim-cmp", dependencies = { "xzbdmw/colorful-menu.nvim" } },
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
    "bassamsdata/namu.nvim",
    cmd = "Namu",
    keys = {
      { "<leader>cs", "<cmd>Namu symbols<cr>", desc = "Symbol navigator (Namu)" },
      { "<leader>cS", "<cmd>Namu workspace<cr>", desc = "Workspace symbols (Namu)" },
    },
    opts = { namu_symbols = { options = { window = {
      min_width = 20, max_width = 90, max_height = 30,
      width_ratio = 0.8, height_ratio = 0.6, padding = 1,
      border = "none", title_prefix = "", show_footer = false,
    } } } },
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
  {
    "chrisgrieser/nvim-lsp-endhints",
    event = "LspAttach",
    main = "lsp-endhints",
    -- Respect LazyVim's existing <leader>uh toggle, rather than force hints on.
    opts = { autoEnableHints = false, label = { truncateAtChars = 30 } },
  },
}
