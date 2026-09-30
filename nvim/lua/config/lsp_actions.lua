local M = {}

function M.locations(method, always_pick)
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local before = require('config.cursor_ui').snapshot()
  local tag = { tagname = vim.fn.expand('<cword>'), from = { buf, before.pos[1], before.pos[2] + 1, 0 } }
  local function on_list(data)
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win
      or vim.api.nvim_get_current_buf() ~= buf or vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
    if #data.items == 0 then vim.notify('No ' .. method:gsub('_', ' ') .. ' found', vim.log.levels.INFO); return end
    -- Native LSP quickfix entries use filename; MiniPick destinations use path.
    for _, item in ipairs(data.items) do
      item.path = item.path or item.filename
      local path = item.path and vim.fn.fnamemodify(item.path, ':~:.') or ''
      item.text = string.format('%s:%d:%d │ %s', path, item.lnum or 1, item.col or 1, item.text or '')
    end
    local pick = require('mini.pick')
    local function choose(item)
      if not item then return end
      vim.cmd("normal! m'")
      vim.fn.settagstack(win, { items = { tag } }, 't')
      pick.default_choose(item)
      require('config.cursor_ui').after(before)
    end
    if #data.items == 1 and not always_pick then return choose(data.items[1]) end
    pick.start({ source = { name = method:gsub('_', ' '), items = data.items,
      cwd = require('config.project').root(), choose = choose } })
  end
  if method == 'references' then vim.lsp.buf.references(nil, { on_list = on_list })
  else vim.lsp.buf[method]({ on_list = on_list }) end
end

-- Preview only the edits already supplied by the server. No speculative resolve
-- requests, file reads, application of edits, or invented command effects.
function M.preview(action)
  local lines = { action.action.title, '' }
  local edit = action.action.edit or {}
  local count = 0
  local function append(uri, edits)
    for _, change in ipairs(edits) do
      if change.range and type(change.newText) == 'string' then
        count = count + 1
        if count > 32 then return end
        local first, last = change.range.start, change.range['end']
        lines[#lines + 1] = string.format('%s:%d:%d–%d:%d · replacement text',
          vim.fn.fnamemodify(vim.uri_to_fname(uri), ':~:.'), first.line + 1, first.character + 1,
          last.line + 1, last.character + 1)
        local replacement = vim.split(change.newText, '\n', { plain = true })
        for i = 1, math.min(#replacement, 40) do lines[#lines + 1] = replacement[i] end
        if #replacement > 40 then lines[#lines + 1] = '…' end
        lines[#lines + 1] = ''
      end
    end
  end
  for uri, edits in pairs(edit.changes or {}) do if count < 32 then append(uri, edits) end end
  for _, change in ipairs(edit.documentChanges or {}) do
    if change.textDocument and count < 32 then append(change.textDocument.uri, change.edits or {}) end
  end
  if count == 0 then lines[#lines + 1] = 'No text edits supplied for preview; resolved or executed on selection.' end
  return lines
end

function M.select(items, opts, on_choice)
  if opts.kind == 'codeaction' then opts = vim.tbl_extend('force', opts, { preview_item = M.preview }) end
  return require('mini.pick').ui_select(items, opts, on_choice)
end

function M.code_action()
  require('mini.pick') -- Load the existing select adapter only on invocation.
  vim.lsp.buf.code_action()
end

return M
