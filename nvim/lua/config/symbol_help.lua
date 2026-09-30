local M = {}
local request = 0
local docs = require('config.documentation')
local signature_ns = vim.api.nvim_create_namespace('symbol_help_parameter')

function M.cancel()
  request = request + 1
end

-- Track the innermost unfinished call, ignoring quoted strings and comments.
-- This fallback also works before a parser has been installed.
function M.call_name(prefix)
  local stack, quote, escaped = {}, nil, false
  local i = 1
  while i <= #prefix do
    local c = prefix:sub(i, i)
    if quote then
      if escaped then escaped = false
      elseif c == '\\' then escaped = true
      elseif c == quote then quote = nil end
    elseif c == '"' or c == "'" or c == '`' then
      quote = c
    elseif c == '#' or prefix:sub(i, i + 1) == '//' or prefix:sub(i, i + 1) == '--' then
      i = prefix:find('\n', i, true) or #prefix
    elseif c == '(' or c == '[' or c == '{' then
      local name = c == '(' and prefix:sub(1, i - 1):match('([%a_][%w_%.:]*)%s*$') or nil
      if name == 'if' or name == 'while' or name == 'for' or name == 'switch' then name = nil end
      stack[#stack + 1] = { char = c, name = name }
    elseif c == ')' or c == ']' or c == '}' then
      local expected = ({ [')'] = '(', [']'] = '[', ['}'] = '{' })[c]
      if stack[#stack] and stack[#stack].char == expected then table.remove(stack) end
    end
    i = i + 1
  end
  if quote then return nil end
  for j = #stack, 1, -1 do
    if stack[j].name then return stack[j].name end
  end
end

function M.show(word, prefer_signature, signature_only)
  if not signature_only and not word and docs.focus() then return end
  local resolver = package.loaded['config.docs_resolver']
  if resolver then resolver.cancel() end
  request = request + 1
  local id, buf = request, vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local function current()
    return id == request and vim.api.nvim_get_current_buf() == buf
      and vim.api.nvim_buf_get_changedtick(buf) == tick
      and vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor)
  end
  local call
  if not word then
    local lines = vim.api.nvim_buf_get_lines(buf, math.max(0, cursor[1] - 40), cursor[1], false)
    local insert = vim.api.nvim_get_mode().mode:sub(1, 1) == 'i'
    lines[#lines] = lines[#lines]:sub(1, cursor[2] + (insert and 0 or 1))
    call = M.call_name(table.concat(lines, '\n'))
  end
  local function missing()
    if current() then vim.notify('No documentation available for this symbol', vim.log.levels.INFO) end
  end
  local function builtin()
    if not current() then return end
    if signature_only then return missing() end
    if vim.bo[buf].filetype == 'python' then
      require('config.python_help').show(word or call or vim.fn.expand('<cword>'), missing, current)
    else missing() end
  end
  -- Buffer suggestions have no resolver. Use the full label, not the typed prefix.
  if word then return builtin() end
  local function params(client)
    return vim.lsp.util.make_position_params(0, client.offset_encoding)
  end
  local function hover()
    if not current() then return end
    if signature_only then return missing() end
    local clients = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/hover' })
    if #clients == 0 then return builtin() end
    local remaining, lines = #clients, {}
    for _, client in ipairs(clients) do
      local function response(err, result)
        remaining = remaining - 1
        if not err and result and result.contents then
          local content = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
          if #content > 0 and table.concat(content):match('%S') then
            if #lines > 0 then lines[#lines + 1] = '---' end
            vim.list_extend(lines, content)
          end
        end
        if remaining == 0 then
          if not current() then return end
          if #lines == 0 then return builtin() end
          docs.open(lines, 'Documentation · ' .. vim.fn.expand('<cword>'))
        end
      end
      local accepted = client:request('textDocument/hover', params(client), response, buf)
      if not accepted then response(true) end
    end
  end
  if (call or prefer_signature) and #vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/signatureHelp' }) > 0 then
    local sig_clients = vim.lsp.get_clients({ bufnr = buf, method = 'textDocument/signatureHelp' })
    local sig_remaining, sig_found = #sig_clients, false
    for _, client in ipairs(sig_clients) do
      local function response(err, result)
        sig_remaining = sig_remaining - 1
        if sig_found then return end
        if not current() then return end
        if not err and result and result.signatures and #result.signatures > 0 then
          local lines, hl = vim.lsp.util.convert_signature_help_to_markdown_lines(result, vim.bo[buf].filetype)
          if lines and #lines > 0 then
            sig_found = true
            local float = docs.open(lines, 'Signature · ' .. (call or vim.fn.expand('<cword>')),
              signature_only and { max_height = math.min(8, docs.options().max_height) } or nil)
            if hl then
              vim.api.nvim_buf_clear_namespace(float, signature_ns, 0, -1)
              vim.hl.range(float, signature_ns, 'LspSignatureActiveParameter', { hl[1], hl[2] }, { hl[3], hl[4] })
            end
            return
          end
        end
        if sig_remaining == 0 and not sig_found then hover() end
      end
      local accepted = client:request('textDocument/signatureHelp', params(client), response, buf)
      if not accepted then response(true) end
    end
  else
    hover()
  end
end

function M.signature()
  -- Expression mappings run under textlock; opening/closing windows must wait.
  vim.schedule(function()
    local cmp = package.loaded['blink.cmp']
    if cmp then cmp.hide(); cmp.hide_documentation(); cmp.hide_signature() end
    docs.close()
    M.show(nil, true, true)
  end)
  return true
end

return M
