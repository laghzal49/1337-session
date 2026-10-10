local M = {}
local cache, waiting = {}, {}
M.timeout_ms = 1500

-- Read builtin documentation from isolated Python; never import project code.
function M.show(word, fallback, is_current)
  word = word or vim.fn.expand("<cword>")
  fallback = fallback or vim.lsp.buf.hover
  if not word:match("^[%a_][%w_]*$") or vim.fn.executable("python3") ~= 1 then
    return fallback()
  end
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local function display(doc)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win)
      or vim.api.nvim_get_current_win() ~= win or vim.api.nvim_win_get_buf(win) ~= buf
      or vim.api.nvim_buf_get_changedtick(buf) ~= tick
      or not vim.deep_equal(vim.api.nvim_win_get_cursor(win), cursor)
      or (is_current and not is_current()) then return end
    if not doc then return fallback() end
    local lines = { "```python", doc.signature, "```", "" }
    vim.list_extend(lines, vim.split(doc.doc, "\n", { plain = true }))
    require('config.documentation').open(lines, 'Python builtin · ' .. word)
  end
  -- Open after the insert-mode key handler finishes, just like async replies.
  if cache[word] ~= nil then return vim.schedule(function() display(cache[word]) end) end
  if waiting[word] then
    waiting[word][#waiting[word] + 1] = display
    return
  end
  waiting[word] = { display }
  local function finish(doc)
    local callbacks = waiting[word] or {}
    waiting[word] = nil
    for _, callback in ipairs(callbacks) do callback(doc) end
  end
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
  local ok = pcall(vim.system, { "python3", "-I", "-B", "-c", script, word },
    { text = true, timeout = M.timeout_ms }, vim.schedule_wrap(function(result)
    local ok, doc = pcall(vim.json.decode, result.stdout or "")
    if result.code ~= 0 or not ok or type(doc) ~= "table" then
      if result.code == 0 then cache[word] = false end
      finish(false)
      return
    end
    cache[word] = doc
    finish(doc)
  end))
  if not ok then vim.schedule(function() finish(false) end) end
end

return M
