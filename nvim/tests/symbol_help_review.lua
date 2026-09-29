local help = require('config.symbol_help')
assert(help.call_name('sum([1, 2], ') == 'sum')
assert(help.call_name('outer(inner(1), ') == 'outer')
assert(help.call_name('outer(inner(') == 'inner')
assert(help.call_name('sum("fake(", ') == 'sum')
assert(help.call_name('sum("unfinished(') == nil)
assert(help.call_name('# fake(') == nil)
assert(help.call_name('sum(\n# fake(\n[1], ') == 'sum')
assert(help.call_name('finished(1)') == nil)
assert(help.call_name('if (') == nil)

vim.cmd.enew()
vim.bo.filetype = 'python'
_G.symbol_help_review = { empty_signature = false, empty_hover = false }
local closed, serial = false, 0
local client = vim.lsp.start({
  name = 'symbol-help-review',
  cmd = function(dispatchers)
    return {
      request = function(method, _, callback)
        serial = serial + 1
        local result
        if method == 'initialize' then
          result = { capabilities = { textDocumentSync = 1, hoverProvider = true,
            signatureHelpProvider = { triggerCharacters = { '(', ',' } } } }
        elseif method == 'textDocument/signatureHelp' and not symbol_help_review.empty_signature then
          result = { activeSignature = 0, activeParameter = 1, signatures = {
            { label = 'analyze(values: list[int], limit: int) -> int',
              documentation = 'Analyze values with an upper limit.', parameters = {
                { label = 'values', documentation = 'Input integers.' },
                { label = 'limit', documentation = 'Maximum number of values to inspect.' },
              } },
          } }
        elseif method == 'textDocument/hover' and not symbol_help_review.empty_hover then
          result = { contents = { kind = 'markdown', value = 'Usage: analyze([1, 2], limit=10)' } }
        end
        vim.defer_fn(function() if not closed then callback(nil, result) end end,
          method == 'initialize' and 0 or 150)
        return true, serial
      end,
      notify = function() return true end,
      is_closing = function() return closed end,
      terminate = function() closed = true; dispatchers.on_exit(0, 0) end,
    }
  end,
})
assert(vim.wait(1500, function() return vim.lsp.get_client_by_id(client).initialized end))
symbol_help_review.client = client
