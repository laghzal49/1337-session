-- Async transport shared by the attached-UI documentation/actions review.
local state = { delay = 60, hover = true, signature = true, locations = {}, resolve = 0, requests = {} }
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')
local path = dir .. '/documentation.lua'
vim.fn.writefile({ 'analyze', 'middle', 'destination', 'other destination' }, path)
vim.cmd.edit(path)
vim.bo.filetype = 'documentation_review'
state.buf, state.dir, state.path = vim.api.nvim_get_current_buf(), dir, path
state.uri = vim.uri_from_fname(path)
state.target = dir .. '/target.lua'
vim.fn.writefile({ 'target header', 'target definition', 'target return' }, state.target)
state.target_uri = vim.uri_from_fname(state.target)
state.markdown = '```python\ndef analyze(values: list[int], limit: int) -> int\n```\n\n'
  .. '**Parameters**\n\n- `values`: Input values.\n- `limit`: Maximum number of values.\n\n'
  .. '**Returns**\n\nThe accumulated integer.\n\n'
  .. string.rep('A deliberately long documentation paragraph which wraps at smaller terminal widths and remains readable while scrolling.\n\n', 24)
local serial, closed = 0, false
state.client = vim.lsp.start({
  name = 'documentation-review', root_dir = dir,
  cmd = function(dispatchers)
    return {
      request = function(method, params, callback)
        serial = serial + 1
        state.requests[method] = (state.requests[method] or 0) + 1
        local result
        if method == 'initialize' then result = { capabilities = {
          textDocumentSync = 1, hoverProvider = true, definitionProvider = true,
          referencesProvider = true, implementationProvider = true, typeDefinitionProvider = true,
          signatureHelpProvider = { triggerCharacters = { '(' } }, codeActionProvider = { resolveProvider = true },
        } }
        elseif method == 'textDocument/hover' and state.hover then result = { contents = { kind = 'markdown', value = state.markdown } }
        elseif method == 'textDocument/signatureHelp' and state.signature then result = {
          activeSignature = 0, activeParameter = 1, signatures = {{
            label = 'analyze(values: list[int], limit: int) -> int', documentation = 'Signature-priority documentation.',
            parameters = {{ label = 'values', documentation = 'Input values.' }, { label = 'limit', documentation = 'Maximum number of values.' }},
          }},
        }
        elseif method == 'textDocument/definition' or method == 'textDocument/references'
          or method == 'textDocument/implementation' or method == 'textDocument/typeDefinition' then result = state.locations
        elseif method == 'textDocument/codeAction' then result = state.empty_actions and {} or {
          { title = 'Supplied edit', kind = 'quickfix', edit = { changes = { [state.uri] = {{
            range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 7 } },
            newText = 'review_replacement',
          }} } } },
          { title = 'Unresolved action', kind = 'quickfix', data = { review = true } },
        }
        elseif method == 'codeAction/resolve' then state.resolve = state.resolve + 1; result = params end
        vim.defer_fn(function() if not closed then callback(nil, result) end end, method == 'initialize' and 0 or state.delay)
        return true, serial
      end,
      notify = function() return true end,
      is_closing = function() return closed end,
      terminate = function() closed = true; dispatchers.on_exit(0, 0) end,
    }
  end,
}, { bufnr = state.buf })
assert(vim.wait(1500, function()
  local client = vim.lsp.get_client_by_id(state.client)
  return client and client.initialized
end), 'documentation LSP did not initialize')
_G.documentation_review = state
