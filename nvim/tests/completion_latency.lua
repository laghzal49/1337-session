-- Real Blink/LSP integration with a deliberately slow completion response.
vim.cmd.enew()
vim.bo.filetype = "text"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "summary_local", "" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
local closed, serial = false, 0
_G.completion_latency_stats = {}
local client = vim.lsp.start({
  name = "completion-latency-review",
  cmd = function(dispatchers)
    return {
      request = function(method, _, callback)
        serial = serial + 1
        if method == "initialize" then
          vim.schedule(function()
            callback(nil, { capabilities = { textDocumentSync = 1, completionProvider = {} } })
          end)
        elseif method == "textDocument/completion" then
          vim.defer_fn(function()
            if not closed then
              callback(nil, { isIncomplete = false, items = { { label = "summary_lsp", kind = 6 } } })
            end
          end, 600)
        else
          vim.schedule(function() callback(nil, nil) end)
        end
        return true, serial
      end,
      notify = function() return true end,
      is_closing = function() return closed end,
      terminate = function() closed = true; dispatchers.on_exit(0, 0) end,
    }
  end,
})
assert(vim.wait(1500, function()
  local c = vim.lsp.get_client_by_id(client)
  return c and c.initialized
end), "Slow review LSP did not initialize")
_G.completion_latency_client = client
vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpShow", once = true,
  callback = function()
    local stats = completion_latency_stats
    stats.first_ms = (vim.uv.hrtime() - stats.started) / 1e6
    stats.first_source = require("blink.cmp").get_items()[1].source_id
  end,
})
completion_latency_stats.started = vim.uv.hrtime()
