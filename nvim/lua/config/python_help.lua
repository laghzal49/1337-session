local M = {}

-- Read builtin documentation from isolated Python; never import project code.
function M.show()
  local word = vim.fn.expand("<cword>")
  if not word:match("^[%a_][%w_]*$") or vim.fn.executable("python3") ~= 1 then
    return vim.lsp.buf.hover()
  end
  local buf = vim.api.nvim_get_current_buf()
  local script = [[
import builtins, inspect, json, sys
name = sys.argv[1]
obj = vars(builtins).get(name)
if obj is None:
    print("null")
else:
    try:
        signature = name + str(inspect.signature(obj))
    except (TypeError, ValueError):
        signature = name
    print(json.dumps({"signature": signature, "doc": inspect.getdoc(obj) or ""}))
]]
  vim.system({ "python3", "-I", "-B", "-c", script, word }, { text = true }, vim.schedule_wrap(function(result)
    if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then return end
    local ok, doc = pcall(vim.json.decode, result.stdout or "")
    if result.code ~= 0 or not ok or type(doc) ~= "table" then
      vim.lsp.buf.hover()
      return
    end
    local lines = { "```python", doc.signature, "```", "" }
    vim.list_extend(lines, vim.split(doc.doc, "\n", { plain = true }))
    vim.lsp.util.open_floating_preview(lines, "markdown", {
      border = require("config.ui").border, title = " Python builtin help ",
      max_width = require("config.ui").max_width, max_height = require("config.ui").max_height, focus_id = "python_builtin_help",
    })
  end))
end

return M
