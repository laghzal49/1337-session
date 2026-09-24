local M = {}

function M.setup()
  if M.installed then return end
  M.installed = true
  local original = vim.diagnostic.handlers.signs
  local namespace = vim.api.nvim_create_namespace("perfect_black_diagnostic_signs")
  local buffers = {}
  local function allowed(diagnostic, severity)
    if not severity then return true end
    local function value(s) return type(s) == "string" and vim.diagnostic.severity[s:upper()] or s end
    if type(severity) ~= "table" then return diagnostic.severity == value(severity) end
    return diagnostic.severity <= (value(severity.min) or vim.diagnostic.severity.HINT)
      and diagnostic.severity >= (value(severity.max) or vim.diagnostic.severity.ERROR)
  end

  local function render(buf)
    if not vim.api.nvim_buf_is_valid(buf) then buffers[buf] = nil; return end
    local lines, opts = {}, nil
    for _, source in pairs(buffers[buf] or {}) do
      opts = source.opts
      for _, diagnostic in ipairs(source.diagnostics) do
        local old = lines[diagnostic.lnum]
        if not old or diagnostic.severity < old.severity then lines[diagnostic.lnum] = diagnostic end
      end
    end
    original.hide(namespace, buf)
    if opts then
      opts = vim.deepcopy(opts)
      if type(opts.signs) == "table" then opts.signs.severity = nil end
      original.show(namespace, buf, vim.tbl_values(lines), opts)
    end
  end

  vim.diagnostic.handlers.signs = {
    show = function(ns, buf, diagnostics, opts)
      buffers[buf] = buffers[buf] or {}
      local severity = type(opts.signs) == "table" and opts.signs.severity or nil
      buffers[buf][ns] = {
        diagnostics = vim.tbl_filter(function(d) return allowed(d, severity) end, diagnostics), opts = opts,
      }
      render(buf)
    end,
    hide = function(ns, buf)
      if buffers[buf] then buffers[buf][ns] = nil end
      render(buf)
    end,
  }
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup("perfect_black_diagnostic_signs", { clear = true }),
    callback = function(event) buffers[event.buf] = nil end,
  })
end

return M
