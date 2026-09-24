require("config.diagnostic_signs").setup()

require("config.tool_layout").setup()

-- Snacks normally starts guides on BufReadPost; new unsaved files need them too.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('NewFileIndentGuides', { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype == '' then Snacks.indent.enable() end
  end,
})
