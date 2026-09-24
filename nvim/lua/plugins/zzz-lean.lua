-- Keep navigation immediate on shared 1337 workstations.
return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = true },
      animate = { enabled = false },
      indent = { enabled = true },
      scroll = { enabled = false },
    },
  },
}
