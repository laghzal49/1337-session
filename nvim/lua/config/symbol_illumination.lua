-- Semantic references only after idle. Movement clears bounded marks/request state.
local M = {
  namespace = vim.api.nvim_create_namespace('BlackSymbolIllumination'),
  max_lines = 10000,
  max_bytes = 1024 * 1024,
  max_marks = 96,
  max_results = 384,
}
local group, pending, marked_buf
local generation = 0
local method = 'textDocument/documentHighlight'

function M.clear()
  if not pending and not marked_buf then return end
  generation = generation + 1
  if pending then
    local request = pending
    pending = nil
    if request.id then pcall(request.client.cancel_request, request.client, request.id) end
  end
  if marked_buf and vim.api.nvim_buf_is_valid(marked_buf) then
    vim.api.nvim_buf_clear_namespace(marked_buf, M.namespace, 0, -1)
  end
  marked_buf = nil
end

local function byte_col(buf, pos, encoding, lines)
  if pos.character == 0 then return 0 end
  local line = lines[pos.line]
  if not line then
    line = vim.api.nvim_buf_get_lines(buf, pos.line, pos.line + 1, false)[1] or ''
    lines[pos.line] = line
  end
  return math.min(#line, vim.str_byteindex(line, encoding, pos.character, false))
end

function M.update()
  M.clear()
  if not group or vim.fn.mode() ~= 'n' then return end
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local count = vim.api.nvim_buf_line_count(buf)
  if vim.bo[buf].buftype ~= '' or vim.b[buf].bigfile or count > M.max_lines
    or vim.api.nvim_buf_get_offset(buf, count) > M.max_bytes
    or vim.api.nvim_win_get_config(win).relative ~= '' then return end
  local client = vim.lsp.get_clients({ bufnr = buf, method = method })[1]
  if not client then return end
  local pos = vim.api.nvim_win_get_cursor(win)
  local tick, epoch = vim.api.nvim_buf_get_changedtick(buf), generation
  local request = { client = client }
  pending = request
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  local ok, id = client:request(method, params, function(err, result)
    if epoch ~= generation or pending ~= request then return end
    pending = nil
    if err or type(result) ~= 'table' or not group or not vim.api.nvim_buf_is_valid(buf)
      or not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win
      or vim.api.nvim_get_current_buf() ~= buf or vim.fn.mode() ~= 'n'
      or vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
    local now = vim.api.nvim_win_get_cursor(win)
    if now[1] ~= pos[1] or now[2] ~= pos[2] then return end
    local top, bottom = vim.fn.line('w0') - 1, vim.fn.line('w$') - 1
    local lines, total = {}, 0
    for i = 1, math.min(#result, M.max_results) do
      local range = result[i].range
      local start, finish = range and range.start, range and range['end']
      if start and finish and type(start.line) == 'number' and type(finish.line) == 'number'
        and type(start.character) == 'number' and type(finish.character) == 'number'
        and start.line >= top and finish.line <= bottom and finish.line < count
        and start.character >= 0 and finish.character >= 0 and finish.line >= start.line then
        local converted, first, last = pcall(function()
          return byte_col(buf, start, client.offset_encoding, lines), byte_col(buf, finish, client.offset_encoding, lines)
        end)
        if converted and (finish.line > start.line or last > first) then
          local current = (pos[1] - 1 > start.line or (pos[1] - 1 == start.line and pos[2] >= first))
            and (pos[1] - 1 < finish.line or (pos[1] - 1 == finish.line and pos[2] < last))
          vim.api.nvim_buf_set_extmark(buf, M.namespace, start.line, first, {
            end_row = finish.line, end_col = last,
            hl_group = current and 'BlackSymbolCurrent' or 'BlackSymbolReference', priority = 110,
          })
          marked_buf, total = buf, total + 1
          if total >= M.max_marks then break end
        end
      end
    end
  end, buf)
  if not ok then
    if pending == request then pending = nil end
  else request.id = id end
end

function M.cleanup()
  M.clear()
  if group then vim.api.nvim_del_augroup_by_id(group); group = nil end
end

function M.setup(opts)
  M.cleanup()
  for _, name in ipairs({ 'max_lines', 'max_bytes', 'max_marks', 'max_results' }) do
    if opts and opts[name] then M[name] = math.max(1, math.floor(opts[name])) end
  end
  group = vim.api.nvim_create_augroup('BlackSymbolIllumination', { clear = true })
  vim.api.nvim_create_autocmd('CursorHold', { group = group, callback = M.update })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave', 'WinLeave', 'WinScrolled', 'TextChanged', 'LspDetach' }, {
    group = group, callback = M.clear,
  })
end

return M
