local M = {}
function M.root()
  return vim.fs.root(0, { "ty.toml", "pyproject.toml", "Cargo.toml", "go.mod", "Makefile", ".git" }) or vim.uv.cwd()
end
return M
