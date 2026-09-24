-- One adapter for dashboard actions and keymaps.
local M = {}
function M.open(command, opts)
  opts = opts or {}
  local pick, extra = require('mini.pick'), require('mini.extra').pickers
  local config = { source = { cwd = opts.cwd or require("config.project").root() } }
  local aliases = { live_grep = 'grep', recent = 'oldfiles', git_log = 'git_commits',
    lsp_references = 'references', lsp_definitions = 'definition', lsp_implementations = 'implementation',
    lsp_type_definitions = 'type_definition', lsp_symbols = 'document_symbol', lsp_workspace_symbols = 'workspace_symbol_live' }
  command = aliases[command] or command
  if command == 'files' then
    -- Include project dotfiles; keep gitignore and backup exclusions.
    if vim.fn.executable('rg') == 1 then
      return pick.builtin.cli({ command = { 'rg', '--files', '--hidden', '-g', '!.git', '-g', '!*.bak-*' } }, config)
    end
    return pick.builtin.files(nil, config)
  elseif command == 'grep' then return pick.builtin.grep_live({ tool = 'rg', globs = { '!.git', '!*.bak-*' } }, config)
  elseif command == 'buffers' or command == 'help' or command == 'resume' then return pick.builtin[command](nil, config)
  elseif command == 'command_history' then return extra.history({ scope = ':' }, config)
  elseif vim.tbl_contains({ 'references', 'definition', 'declaration', 'implementation', 'type_definition', 'document_symbol', 'workspace_symbol_live' }, command) then
    return extra.lsp({ scope = command }, config)
  elseif extra[command] then return extra[command](nil, config)
  end
  vim.notify('No Mini picker for: ' .. tostring(command), vim.log.levels.WARN)
end
return M
