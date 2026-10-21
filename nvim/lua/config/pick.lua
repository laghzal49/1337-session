-- One adapter for dashboard actions and keymaps.
local M = {}
function M.open(command, opts)
  opts = opts or {}
  local config = { source = { cwd = opts.cwd or require("config.project").root() } }
  local aliases = { live_grep = 'grep', recent = 'oldfiles', git_log = 'git_commits',
    lsp_references = 'references', lsp_definitions = 'definition', lsp_implementations = 'implementation',
    lsp_type_definitions = 'type_definition', lsp_symbols = 'document_symbol', lsp_workspace_symbols = 'workspace_symbol_live' }
  command = aliases[command] or command
  if command == 'grep' and not require('config.tool_health').require_tool('rg') then return end
  if vim.tbl_contains({ 'references', 'definition', 'declaration', 'implementation', 'type_definition' }, command) then
    return require('config.lsp_actions').locations(command, command == 'references')
  end
  local sources = { files = 'files', grep = 'grep', buffers = 'buffers', oldfiles = 'recent',
    help = 'help', resume = 'resume', command_history = 'command_history', commands = 'commands',
    keymaps = 'keymaps', diagnostic = 'diagnostics', git_commits = 'git_log',
    document_symbol = 'lsp_symbols', workspace_symbol_live = 'lsp_workspace_symbols' }
  if sources[command] then
    local options = { cwd = config.source.cwd }
    if command == 'files' or command == 'grep' then
      options.hidden = true
      options.exclude = { '.git', '*.bak-*' }
    end
    return Snacks.picker[sources[command]](options)
  end
  vim.notify('Unknown picker: ' .. tostring(command), vim.log.levels.WARN)
end
-- Lightweight search reuses the documentation picker when preview is unnecessary.
function M.fast(command)
  if command == 'grep' and not require('config.tool_health').require_tool('rg') then return end
  local pick = require('mini.pick')
  local config = { source = { cwd = require('config.project').root() } }
  if command == 'files' then
    if vim.fn.executable('rg') == 1 then
      return pick.builtin.cli({ command = { 'rg', '--files', '--hidden', '-g', '!.git', '-g', '!*.bak-*' } }, config)
    end
    return pick.builtin.files(nil, config)
  end
  if command == 'grep' then
    return pick.builtin.grep_live({ tool = 'rg', globs = { '!.git', '!*.bak-*' } }, config)
  end
end
return M
