local M = {}
local quick = { files = true, buffers = true, recent = true, oldfiles = true, commands = true, keymaps = true }

function M.resize(picker)
  if picker.closed or not picker.layout or picker:is_active() then return end
  local layout = Snacks.picker.config.layout(picker.opts)
  if layout.fullscreen or type(layout.layout.height) ~= "number"
    or layout.layout.height <= 0 or layout.layout.height > 1 then return end
  local preview = not picker.layout:is_hidden("preview")
  layout.hidden = preview and {} or { "preview" }
  local cap = math.min(36, math.floor(vim.o.lines * layout.layout.height))
  local rows = picker.list:count() + 3 -- Input plus filled top/bottom padding.
  if preview then
    local stacked = quick[picker.opts.source] or vim.o.columns < 110
    rows = stacked and rows + 8 or math.max(rows, 12)
  end
  layout.layout.height = math.min(cap, math.max(4, rows))
  picker:set_layout(layout)
end

function M.queue(picker)
  if picker._black_resize_pending or picker.closed then return end
  picker._black_resize_pending = true
  vim.defer_fn(function()
    picker._black_resize_pending = false
    M.resize(picker)
  end, 80)
end

function M.attach(picker)
  if picker._black_layout_attached then return end
  picker._black_layout_attached = true
  local done = picker.matcher.opts.on_done
  picker.matcher.opts.on_done = function(matcher)
    if done then done(matcher) end
    M.queue(picker)
  end
  local resize = vim.api.nvim_create_autocmd("VimResized", { callback = function() M.queue(picker) end })
  local close = picker.opts.on_close
  picker.opts.on_close = function(p)
    pcall(vim.api.nvim_del_autocmd, resize)
    if close then close(p) end
  end
  M.queue(picker)
end

return M
