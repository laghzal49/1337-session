-- Integration regression for the TextChangedI picker preview crash.
-- Must run under the user's real plugin configuration (not mocked APIs).
local picker = require('config.nvimz_picker')
assert(picker.sanitize_line('a\nb') == 'a b', 'newline sanitization failed')
assert(picker.sanitize_line('a\r\nb') == 'a  b', 'CRLF sanitization failed')

local old_cols, old_lines = vim.o.columns, vim.o.lines
vim.o.columns, vim.o.lines = 38, 12
local ok_small, err_small = pcall(picker.buffers)
vim.o.columns, vim.o.lines = old_cols, old_lines
assert(ok_small, 'small terminal crashed picker: ' .. tostring(err_small))

local source = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(source)
vim.api.nvim_buf_set_name(source, vim.fn.tempname() .. 'Demo.py')
vim.api.nvim_buf_set_lines(source, 0, -1, false, { 'class Demo:', '    def method(self):', '        return 1' })
vim.bo[source].filetype = 'python'

local ok_open, err_open = pcall(picker.buffers)
assert(ok_open, 'buffer picker failed to open: ' .. tostring(err_open))
local input, preview
for _, win in ipairs(vim.api.nvim_list_wins()) do
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= '' then
    local title = type(cfg.title) == 'table' and cfg.title[1] and cfg.title[1][1] or cfg.title
    if title and title:find('Buffers', 1, true) then input = vim.api.nvim_win_get_buf(win) end
    if title and title:find('Preview', 1, true) then preview = vim.api.nvim_win_get_buf(win) end
  end
end
assert(input and preview, 'three-pane picker windows missing')
local before = table.concat(vim.api.nvim_buf_get_lines(preview, 0, -1, false), '\n')
assert(before:find('class Demo:', 1, true), 'preview did not display source buffer')

-- A literal LF in the source buffer is how Neovim represents NUL-backed
-- content. TextChangedI must not pass it through to nvim_buf_set_lines().
vim.api.nvim_buf_set_lines(source, 0, 1, false, { 'class Demo:\0embedded' })
vim.api.nvim_buf_set_lines(input, 0, -1, false, { 'Demo.py' })
local ok_change, err_change = pcall(vim.api.nvim_exec_autocmds, 'TextChangedI', { buffer = input })
assert(ok_change, 'TextChangedI preview crashed: ' .. tostring(err_change))
-- The buffer list filters by filename, not by code contents.
-- Reopen after a buffer edit to force a new preview and exercise LF sanitization.
picker.close_picker()
vim.api.nvim_set_current_buf(source)
local ok_reopen, err_reopen = pcall(picker.buffers)
assert(ok_reopen, 'picker failed to reopen after edit: ' .. tostring(err_reopen))
local fresh_preview
for _, win in ipairs(vim.api.nvim_list_wins()) do
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= '' then
    local title = type(cfg.title) == 'table' and cfg.title[1] and cfg.title[1][1] or cfg.title
    if title and title:find('Preview', 1, true) then
      fresh_preview = vim.api.nvim_win_get_buf(win)
    end
  end
end
assert(fresh_preview, 'reopened preview window missing')
local final = table.concat(vim.api.nvim_buf_get_lines(fresh_preview, 0, -1, false), '\n')
assert(final:find('class Demo: embedded', 1, true),
  'buffer preview failed to safely flatten embedded NUL/LF: ' .. vim.inspect(final))
picker.close_picker()
assert(not vim.api.nvim_buf_is_valid(fresh_preview), 'picker preview buffer leaked after close')
print('NVIMZ PICKER REGRESSION PASS: open, type, preview, close, small terminal')
