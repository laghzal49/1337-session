-- Root discovery happens once per buffer/path/cwd, never on every redraw.
local M, cache = {}, {}
local markers = { 'ty.toml', 'pyproject.toml', 'pytest.ini', 'requirements.txt', 'package.json',
  'Cargo.toml', 'go.mod', 'GNUmakefile', 'makefile', 'Makefile', '.git' }
function M.root()
  local buf = vim.api.nvim_get_current_buf()
  local name, cwd = vim.api.nvim_buf_get_name(buf), vim.fn.getcwd()
  local key = name .. '\0' .. (cwd or '')
  if not cache[key] then
    if name ~= '' then
      cache[key] = vim.fs.root(name, markers) or cwd
    else
      -- vim.fs.root treats its argument as a file. For an unnamed buffer,
      -- search from the cwd itself so markers in a window-local cwd count.
      local found = vim.fs.find(markers, { path = cwd, upward = true, limit = 1 })
      cache[key] = found[1] and vim.fs.dirname(found[1]) or cwd
    end
  end
  return cache[key]
end
vim.api.nvim_create_autocmd({ 'DirChanged', 'BufFilePost', 'BufWritePost' }, {
  group = vim.api.nvim_create_augroup('BlackProjectRoots', { clear = true }),
  callback = function(ev)
    if ev.event ~= 'BufWritePost' or vim.tbl_contains(markers, vim.fs.basename(ev.file)) then cache = {} end
  end,
})
return M
