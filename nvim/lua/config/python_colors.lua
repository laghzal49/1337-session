-- Lightweight Python declaration-color fallback.
-- Syntax/Tree-sitter captures are still used normally; these window-local
-- matches guarantee class, function and __init__ names remain distinct when
-- a Python parser is missing or an LSP overrides its captures.
local M = {}
local groups = {
  NvimzPyClassName = '#c792ea',
  NvimzPyFunctionName = '#82aaff',
  NvimzPyMethodName = '#4fd6be',
  NvimzPyConstructorName = '#ffcb6b',
}
local patterns = {
  { 'NvimzPyClassName', [[^\s*class\s\+\zs\h\w*]], 16 },
  { 'NvimzPyFunctionName', [[^\s*def\s\+\zs\h\w*]], 16 },
  { 'NvimzPyMethodName', [[^\s\+def\s\+\zs\h\w*]], 17 },
  { 'NvimzPyConstructorName', [[^\s*def\s\+\zs__init__\>]], 22 },
}
local function highlights()
  for name, color in pairs(groups) do
    vim.api.nvim_set_hl(0, name, { fg = color, bold = true })
  end
end
local function update_window(win)
  if not vim.api.nvim_win_is_valid(win) then return end
  vim.api.nvim_win_call(win, function()
    local buf = vim.api.nvim_get_current_buf()
    local old = vim.w.nvimz_python_matches or {}
    if vim.w.nvimz_python_match_buf == buf and #old == #patterns then return end
    for _, id in ipairs(old) do pcall(vim.fn.matchdelete, id) end
    vim.w.nvimz_python_matches = {}
    vim.w.nvimz_python_match_buf = nil
    if vim.bo[buf].filetype ~= 'python' or vim.bo[buf].buftype ~= '' then return end
    if require('config.performance').large(buf) then return end
    local ids = {}
    for _, spec in ipairs(patterns) do
      ids[#ids + 1] = vim.fn.matchadd(spec[1], spec[2], spec[3])
    end
    vim.w.nvimz_python_matches, vim.w.nvimz_python_match_buf = ids, buf
  end)
end
function M.setup()
  highlights()
  local group = vim.api.nvim_create_augroup('NvimzPythonDeclarationColors', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = highlights })
  vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter', 'WinEnter' }, {
    group = group,
    callback = function(args)
      local win = vim.fn.bufwinid(args.buf)
      if win ~= -1 then update_window(win) end
    end,
  })
  update_window(vim.api.nvim_get_current_win())
end
return M
