-- Idle-only ancestry lookup. Lualine reads the resulting string, never a parser/LSP.
local M = { max_lines = 10000, max_bytes = 1024 * 1024 }
local group, pending
local supported = { python = true, c = true, cpp = true, lua = true }
local kinds = { function_definition = 'Function', function_declaration = 'Function',
  method_definition = 'Method', class_definition = 'Class', class_declaration = 'Class', struct_specifier = 'Struct' }

local function name_node(node)
  local name = node:field('name')[1]
  if name then return name end
  local declarator = node:field('declarator')[1]
  -- C's name is inside one or more declarators (including pointer returns).
  for _ = 1, 12 do
    if not declarator then return end
    if declarator:type() == 'identifier' or declarator:type() == 'field_identifier' then return declarator end
    declarator = declarator:field('declarator')[1]
  end
end

local function treesitter(buf, row, col)
  if not supported[vim.bo[buf].filetype] then return nil end
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then return nil end
  -- Parse only on idle/entry and within the cursor region; no full-buffer query.
  local parsed, trees = pcall(parser.parse, parser, { row, row + 1 })
  if not parsed or not trees or not trees[1] then return nil end
  local node = trees[1]:root():named_descendant_for_range(row, col, row, col)
  local names, inner_kind = {}, nil
  for _ = 1, 64 do
    if not node then break end
    local kind = kinds[node:type()]
    if kind then
      local named = name_node(node)
      if named then
        local sr, _, er = named:range()
        if er == sr then
          local name = vim.treesitter.get_node_text(named, buf)
          if name and #name <= 120 then
            table.insert(names, 1, name)
            inner_kind = inner_kind or kind
          end
        end
      end
    end
    node = node:parent()
  end
  return #names > 0 and { name = table.concat(names, '.'), kind = inner_kind } or false
end

function M.update()
  local buf = vim.api.nvim_get_current_buf()
  local count = vim.api.nvim_buf_line_count(buf)
  if vim.bo[buf].buftype ~= '' or vim.b[buf].bigfile or count > M.max_lines
    or vim.api.nvim_buf_get_offset(buf, count) > M.max_bytes then
    vim.b[buf].current_symbol = ''; return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  local symbol = treesitter(buf, pos[1] - 1, pos[2])
  -- Only reuse Aerial if already loaded; never load/request an LSP for this capsule.
  local aerial_data = package.loaded['aerial.data']
  if symbol == nil and package.loaded.aerial and aerial_data and aerial_data.has_symbols(buf) then
    local ok, location = pcall(package.loaded.aerial.get_location, true)
    if ok then
      local names, kind = {}, nil
      for _, item in ipairs(location) do
        if item.kind == 'Function' or item.kind == 'Method' or item.kind == 'Class' or item.kind == 'Struct' then
          names[#names + 1], kind = item.name, item.kind
        end
      end
      if #names > 0 then symbol = { name = table.concat(names, '.'), kind = kind } end
    end
  end
  local value = symbol and (require('config.ui').symbol(symbol.kind) .. ' ' .. symbol.name) or ''
  if vim.fn.strdisplaywidth(value) > 48 then
    value = vim.fn.strcharpart(value, 0, 47)
    while vim.fn.strdisplaywidth(value) > 47 do
      value = vim.fn.strcharpart(value, 0, vim.fn.strchars(value) - 1)
    end
    value = value .. '…'
  end
  if vim.b[buf].current_symbol ~= value then
    vim.b[buf].current_symbol = value
    vim.cmd.redrawstatus()
  end
end

function M.component()
  if vim.o.columns < 120 then return '' end
  local value = vim.b.current_symbol or ''
  -- Statusline markup must not interpret a percent sign inside a symbol name.
  return value:gsub('%%', '%%%%')
end

function M.cleanup()
  if group then vim.api.nvim_del_augroup_by_id(group); group = nil end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then vim.b[buf].current_symbol = nil end
  end
end

function M.setup()
  M.cleanup()
  group = vim.api.nvim_create_augroup('BlackSymbolContext', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'CursorHold', 'InsertLeave' }, {
    group = group, callback = function()
      -- Entry may restore the cursor after this event. Run once on the next turn.
      if pending then return end
      pending = true
      vim.schedule(function()
        pending = false
        if group then M.update() end
      end)
    end,
  })
  vim.api.nvim_create_autocmd('TextChanged', { group = group, callback = function(ev)
    vim.b[ev.buf].current_symbol = '' -- avoid displaying an old name until next idle
  end })
end

return M
