-- Root discovery happens once per buffer/path/cwd, never on every redraw.
local M, cache = {}, {}
function M.root()
  local buf = vim.api.nvim_get_current_buf()
  local name, cwd = vim.api.nvim_buf_get_name(buf), vim.uv.cwd()
  local key = name .. '\0' .. (cwd or '')
  if not cache[key] then
    cache[key] = vim.fs.root(name ~= '' and name or cwd,
      { 'ty.toml', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'GNUmakefile', 'makefile', 'Makefile', '.git' }) or cwd
  end
  return cache[key]
end
vim.api.nvim_create_autocmd({ 'DirChanged', 'BufFilePost' }, {
  group = vim.api.nvim_create_augroup('BlackProjectRoots', { clear = true }),
  callback = function() cache = {} end,
})
return M
