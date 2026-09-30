-- Full-config test using an asynchronous in-process LSP transport.
local illumination = require('config.symbol_illumination')
illumination.setup()
vim.cmd('enew!')
vim.bo.filetype = 'semantic_review'
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  'local value = 1', 'print(value)', '', 'local value = 2', 'print(value)', 'outside',
})
vim.api.nvim_win_set_cursor(0, { 1, 7 })
local function marks(target)
  return vim.api.nvim_buf_get_extmarks(target or buf, illumination.namespace, 0, -1, { details = true })
end
illumination.update()
assert(#marks() == 0, 'no-LSP buffer received text-match highlights')

local waiting, serial, canceled, closed = {}, 0, 0, false
local client_id = vim.lsp.start({
  name = 'semantic-review',
  cmd = function(dispatchers)
    return {
      request = function(method, params, callback)
        serial = serial + 1
        if method == 'initialize' then
          vim.schedule(function() callback(nil, { capabilities = {
            textDocumentSync = 1, documentHighlightProvider = true, positionEncoding = 'utf-16',
          } }) end)
        elseif method == 'textDocument/documentHighlight' then
          waiting[#waiting + 1] = { callback = callback, params = params, id = serial }
        else vim.schedule(function() callback(nil, nil) end) end
        return true, serial
      end,
      notify = function(method)
        if method == '$/cancelRequest' then canceled = canceled + 1 end
        return true
      end,
      is_closing = function() return closed end,
      terminate = function() closed = true; dispatchers.on_exit(0, 0) end,
    }
  end,
}, { bufnr = buf })
assert(vim.wait(1500, function()
  local client = vim.lsp.get_client_by_id(client_id)
  return client and client.initialized
end), 'test highlight LSP did not initialize')
local function range(row, first, last)
  return { range = { start = { line = row, character = first }, ['end'] = { line = row, character = last } }, kind = 1 }
end
local references = { range(0, 6, 11), range(1, 6, 11) }
local function respond(result, index)
  local request = table.remove(waiting, index or 1)
  assert(request, 'idle did not dispatch documentHighlight')
  vim.schedule(function() request.callback(nil, result or references) end)
end
local started = vim.uv.hrtime()
illumination.update()
local dispatch_ms = (vim.uv.hrtime() - started) / 1e6
assert(#waiting == 1 and waiting[1].params.position.line == 0)
started = vim.uv.hrtime()
respond()
assert(vim.wait(200, function() return #marks() == 2 end), 'asynchronous references did not render')
local response_ms = (vim.uv.hrtime() - started) / 1e6
local actual = marks()
assert(actual[1][4].hl_group == 'BlackSymbolCurrent', vim.inspect(actual))
assert(actual[2][4].hl_group == 'BlackSymbolReference', vim.inspect(actual))
assert(actual[1][2] == 0 and actual[2][2] == 1, 'same-named variable from another scope was illuminated')

vim.api.nvim_exec_autocmds('CursorMoved', {})
assert(#marks() == 0, 'movement did not clear immediately')
illumination.update()
vim.api.nvim_exec_autocmds('InsertEnter', {})
assert(canceled > 0, 'insert did not cancel the pending request')
respond()
vim.wait(30, function() return false end)
assert(#marks() == 0, 'late insert reply reintroduced marks')

illumination.update()
vim.api.nvim_win_set_cursor(0, { 2, 7 })
respond()
vim.wait(30, function() return false end)
assert(#marks() == 0, 'stale cursor position reply rendered')
vim.api.nvim_win_set_cursor(0, { 1, 7 })
illumination.update()
vim.api.nvim_buf_set_text(buf, 5, 0, 5, 0, { 'edited ' })
respond()
vim.wait(30, function() return false end)
assert(#marks() == 0, 'stale changedtick reply rendered')

illumination.update()
local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(other)
respond()
vim.wait(30, function() return false end)
assert(#marks() == 0 and #marks(other) == 0, 'buffer switch leaked semantic marks')
vim.api.nvim_set_current_buf(buf)

-- The most recent idle request must win even if responses arrive out of order.
illumination.update()
illumination.update()
assert(#waiting == 2)
respond(references, 2)
assert(vim.wait(200, function() return #marks() == 2 end))
respond({ range(3, 6, 11) })
vim.wait(30, function() return false end)
assert(#marks() == 2 and marks()[1][2] == 0, 'older response overwrote current scope')

-- Cap both displayed marks and inspected results. Off-screen ranges stay absent.
illumination.setup({ max_marks = 2, max_results = 4 })
illumination.update()
respond({ range(0, 6, 11), range(1, 6, 11), range(3, 6, 11), range(4, 6, 11) })
assert(vim.wait(200, function() return #marks() == 2 end), 'mark cap not respected')
illumination.clear()
local viewport_lines = {}
for i = 1, 100 do viewport_lines[i] = 'local value = 1' end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, viewport_lines)
vim.api.nvim_win_set_cursor(0, { 1, 7 })
vim.cmd('normal! zt')
illumination.update()
respond({ range(0, 6, 11), range(80, 6, 11) })
assert(vim.wait(200, function() return #marks() == 1 end), 'off-screen references were rendered')
illumination.clear()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'é value' })
vim.api.nvim_win_set_cursor(0, { 1, 4 })
illumination.update()
respond({ range(0, 2, 7) })
assert(vim.wait(200, function() return #marks() == 1 end))
assert(marks()[1][3] == 3 and marks()[1][4].end_col == 8, 'UTF-16 character positions were not converted to bytes')
illumination.clear()
local lines = {}
for i = 1, 10001 do lines[i] = 'local value = 1' end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
local dispatched = #waiting
illumination.update()
assert(#waiting == dispatched and #marks() == 0, 'large line-count guard dispatched a request')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.rep('x', 1024 * 1024 + 1) })
illumination.update()
assert(#waiting == dispatched, 'large byte-size guard dispatched a request')

-- Benchmark the actual movement callback while idle: no requests/marks to clear.
started = vim.uv.hrtime()
for _ = 1, 100000 do illumination.clear() end
local empty_clear_ms = (vim.uv.hrtime() - started) / 1e6
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'local value = 1', 'print(value)' })
vim.api.nvim_win_set_cursor(0, { 1, 7 })
started = vim.uv.hrtime()
for _ = 1, 1000 do vim.api.nvim_exec_autocmds('CursorMoved', { group = 'BlackSymbolIllumination' }) end
local movement_events_ms = (vim.uv.hrtime() - started) / 1e6
local baseline_group = vim.api.nvim_create_augroup('SemanticMovementBaseline', { clear = true })
vim.api.nvim_create_autocmd('CursorMoved', { group = baseline_group, callback = function() end })
started = vim.uv.hrtime()
for _ = 1, 1000 do vim.api.nvim_exec_autocmds('CursorMoved', { group = baseline_group }) end
local baseline_events_ms = (vim.uv.hrtime() - started) / 1e6
vim.api.nvim_del_augroup_by_id(baseline_group)
illumination.update()
respond()
assert(vim.wait(200, function() return #marks() == 2 end))
started = vim.uv.hrtime()
illumination.clear()
local marked_clear_ms = (vim.uv.hrtime() - started) / 1e6
illumination.update()
illumination.cleanup()
respond()
vim.wait(30, function() return false end)
assert(#marks() == 0, 'cleanup allowed a pending response to recreate marks')
local group_exists = pcall(vim.api.nvim_get_autocmds, { group = 'BlackSymbolIllumination' })
assert(not group_exists, 'cleanup left autocmd group')
vim.lsp.get_client_by_id(client_id):stop(true)
vim.api.nvim_buf_delete(other, { force = true })
print(string.format('SEMANTIC: scope, asynchronous dispatch, no LSP, move/insert/switch, stale replies, viewport/UTF-16/bounds and cleanup PASS; dispatch %.3fms, scheduled response %.3fms, idle clear 100k %.3fms, 1k movement events %.3fms (empty callback baseline %.3fms), two-mark clear %.3fms',
  dispatch_ms, response_ms, empty_clear_ms, movement_events_ms, baseline_events_ms, marked_clear_ms))
illumination.setup({ max_marks = 96, max_results = 384 })
