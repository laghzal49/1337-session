-- Neogen supplies the fields; this wrapper owns safe Python insertion.
local M = {}
local types = { function_definition = 'func', class_definition = 'class', module = 'file' }
local function message(text) vim.notify(text, vim.log.levels.INFO, { title = 'Python docstring' }) end

local function first_statement(body)
  for child in body:iter_children() do
    if child:named() and child:type() ~= 'comment' then return child end
  end
end

local function is_string(node)
  if node:type() == 'string' then
    -- Byte literals and interpolated strings are expressions, not docstrings.
    return vim.treesitter.get_node_text(node, 0):match('^[rRuU]*[\'"]') ~= nil
  end
  if node:type() == 'concatenated_string' or node:type() == 'parenthesized_expression'
    or node:type() == 'expression_statement' then
    local found = false
    for child in node:iter_children() do
      if child:named() and child:type() ~= 'comment' then
        if not is_string(child) then return false end
        found = true
      end
    end
    return found
  end
  return false
end

local function target(parser, kind)
  parser:parse()
  local node = vim.treesitter.get_node({ ignore_injections = true })
  -- A decorator belongs to the definition beneath it.
  local ancestor = node
  while ancestor and not types[ancestor:type()] do
    if ancestor:type() == 'decorated_definition' then
      node = ancestor:field('definition')[1] or node
      break
    end
    ancestor = ancestor:parent()
  end
  while node do
    if types[node:type()] and (not kind or types[node:type()] == kind) then return node, types[node:type()] end
    node = node:parent()
  end
  if not kind or kind == 'file' then return parser:parse()[1]:root(), 'file' end
end

function M.generate(kind)
  if kind == '' then kind = nil end
  if kind and not vim.tbl_contains({ 'func', 'class', 'file' }, kind) then
    message('Use :PythonDocstring [func|class|file].'); return false
  end
  if vim.bo.filetype ~= 'python' or vim.bo.buftype ~= '' or not vim.bo.modifiable then
    message('Open an editable Python buffer first.'); return false
  end
  if require('config.performance').large(0) then message('Docstring generation is disabled for large files.'); return false end
  local ok, parser = pcall(vim.treesitter.get_parser, 0, 'python')
  if not ok or not parser then message('Install the Python parser with :TSInstall python, then try again.'); return false end
  local node, selected = target(parser, kind)
  if not node then message('Place the cursor inside the function or class to document.'); return false end
  if node:has_error() then message('Fix the syntax in this definition before generating its docstring.'); return false end
  local body = selected == 'file' and node or node:field('body')[1]
  if not body then message('Add a function or class body first (pass is enough).'); return false end
  local first = first_statement(body)
  if first and is_string(first) then
    local row, col = first:start()
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
    message('This definition already has a docstring; moved to it.'); return false
  end

  local original_cursor = vim.api.nvim_win_get_cursor(0)
  local start, start_col = node:start()
  vim.api.nvim_win_set_cursor(0, selected == 'file' and { 1, 0 } or { start + 1, start_col })
  local generated, snippet = pcall(require('neogen').generate, { type = selected, return_snippet = true })
  vim.api.nvim_win_set_cursor(0, original_cursor)
  if not generated or type(snippet) ~= 'table' or #snippet == 0 then
    message('Could not generate this docstring: ' .. tostring(snippet)); return false
  end
  local row, col = body:start()
  local indent = ''
  if selected == 'file' then
    -- Keep shebangs, encoding cookies and initial comments above the docstring.
    row = first and select(1, first:start()) or vim.api.nvim_buf_line_count(0)
    if row == 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '' then row = 0 end
  else
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
    if line:sub(1, col):match(':%s*$') then
      -- Expand an inline suite without losing semicolons, comments or code.
      local declaration = vim.api.nvim_buf_get_lines(0, start, start + 1, false)[1]
      indent = declaration:match('^%s*') .. (vim.bo.expandtab and string.rep(' ', vim.fn.shiftwidth()) or '\t')
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, { line:sub(1, col):gsub('%s+$', ''), indent .. line:sub(col + 1) })
      row = row + 1
      vim.cmd.undojoin()
    else indent = line:match('^%s*') end
  end
  -- Normalize plugin indentation to the actual suite, including tab-indented code.
  local prefix = snippet[1]:match('^%s*')
  for index, line in ipairs(snippet) do
    snippet[index] = indent .. (vim.startswith(line, prefix) and line:sub(#prefix + 1) or line)
  end
  if selected == 'class' and snippet[#snippet] ~= '' then snippet[#snippet + 1] = '' end
  if vim.snippet.active() then vim.snippet.stop() end
  vim.api.nvim_buf_set_lines(0, row, row, false, { '' })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
  vim.cmd.undojoin()
  vim.snippet.expand(table.concat(snippet, '\n'))
  return true
end

return M
