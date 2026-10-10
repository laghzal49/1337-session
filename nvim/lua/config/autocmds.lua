require("config.diagnostic_signs").setup()

-- Snacks normally starts guides on BufReadPost; new unsaved files need them too.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('NewFileIndentGuides', { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype == '' and vim.bo[ev.buf].filetype ~= 'bigfile' then Snacks.indent.enable() end
  end,
})

-- Share Snacks' early classification with idle semantic helpers.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('BlackBigfile', { clear = true }),
  pattern = 'bigfile',
  callback = function(ev) vim.b[ev.buf].bigfile = true end,
})

-- Keep your place across sessions; skip commit messages and transient buffers.
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('BlackLastPosition', { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' or vim.bo[ev.buf].filetype == 'gitcommit' then return end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf)
      and vim.api.nvim_win_get_cursor(0)[1] == 1 then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- One short beacon on the actual yanked region, without notification spam.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('BlackYankFeedback', { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = 'BlackYank', timeout = 180, on_visual = true })
  end,
})
