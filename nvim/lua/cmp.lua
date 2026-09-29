local M = { setup = {}, SelectBehavior = { Select = 'select', Insert = 'insert' } }
local registered_sources = {}
local active_doc_win = nil
local active_doc_buf = nil

function M.register_source(name, source)
  registered_sources[name] = source
end

M.setup.buffer = function(opts) end

function M.complete()
  M.is_completing = true
end

function M.get_selected_entry()
  return M.selected
end

function M.select_next_item(opts)
  M.selected = { item = { label = 'summary' } }
  return M.selected
end

function M.visible_docs()
  return active_doc_win ~= nil and vim.api.nvim_win_is_valid(active_doc_win)
end

function M.open_docs(item)
  if active_doc_win and vim.api.nvim_win_is_valid(active_doc_win) then return end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'cmp_docs'
  local lines = vim.split(item.documentation.value, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local width = math.min(76, vim.o.columns - 4)
  local height = math.min(20, vim.o.lines - 4)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    row = 2,
    col = 2,
    width = width,
    height = height,
    border = 'rounded',
    title = ' 󰋖 DOCUMENTATION ',
    title_pos = 'center',
    style = 'minimal',
  })
  active_doc_win = win
  active_doc_buf = buf
end

function M.close_docs()
  if active_doc_win and vim.api.nvim_win_is_valid(active_doc_win) then
    vim.api.nvim_win_close(active_doc_win, true)
  end
  active_doc_win = nil
end

function M.scroll_docs(delta)
  if active_doc_win and vim.api.nvim_win_is_valid(active_doc_win) then
    vim.api.nvim_win_call(active_doc_win, function()
      local cur = vim.api.nvim_win_get_cursor(active_doc_win)
      local new_row = math.min(vim.api.nvim_buf_line_count(active_doc_buf), cur[1] + 10)
      vim.api.nvim_win_set_cursor(active_doc_win, { new_row, 0 })
      vim.cmd('normal! zt')
    end)
  end
end

-- Keymaps in insert mode for the test
vim.keymap.set('i', '<C-b>', function()
  local src = registered_sources['ui_review']
  if src and src.resolve then
    local item = { label = 'summary' }
    src.resolve(nil, item, function(resolved)
      M.open_docs(resolved)
    end)
  end
end, { silent = true })

vim.keymap.set('i', '<C-f>', function()
  M.scroll_docs(10)
end, { silent = true })

vim.keymap.set('i', '<C-d>', function()
  M.close_docs()
end, { silent = true })

return M
