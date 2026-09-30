-- Identity can come from LSP; reference content prefers the local exact index.
local M = {}

function M.show()
  local docs = require('config.documentation')
  if docs.focus() then return end
  if vim.bo.filetype == 'help' or vim.bo.filetype == 'vim' then
    if not pcall(vim.cmd.help, vim.fn.expand('<cword>')) then vim.notify('No help for this symbol') end
    return
  end
  local resolver = require('config.docs_resolver')
  local symbol_help = package.loaded['config.symbol_help']
  if symbol_help then symbol_help.cancel() end
  resolver.resolve(function(saved)
    if not resolver.current(saved) then return end
    local store = require('config.docs_store')
    local deep = require('config.deep_docs')
    local candidates = vim.list_extend({}, saved.candidates)
    if saved.allow_literal ~= false then candidates[#candidates + 1] = saved.word end
    if saved.docset then
      for _, name in ipairs(candidates) do
        local entry = store.find_entry(saved.docset, name)
        if entry and deep.show(saved.docset, entry, saved) then return end
      end
    end
    if #saved.hover_lines > 0 then
      local lines = vim.list_extend({}, saved.hover_lines)
      vim.list_extend(lines, { '', '---', 'LSP' })
      local source = saved.project_local and 'PROJECT' or 'LSP'
      docs.close(); docs.open(lines, source .. ' · ' .. (saved.identity or saved.word))
      return
    end
    local function missing()
      if not resolver.current(saved) then return end
      if saved.word ~= '' and not saved.project_local and saved.docset and store.load_index(saved.docset) then
        deep.search(saved.word, saved.docset, saved)
      else vim.notify('No documentation available for this symbol', vim.log.levels.INFO) end
    end
    if vim.bo[saved.buf].filetype == 'python' and not saved.project_local then
      require('config.python_help').show(saved.word, missing, function() return resolver.current(saved) end)
    else missing() end
  end)
end

return M
