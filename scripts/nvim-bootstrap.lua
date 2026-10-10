-- Installer phases fail explicitly: Neovim otherwise exits 0 after Lua errors.
local function run()
  assert(vim.v.errmsg == '', 'startup failed: ' .. vim.v.errmsg)
  assert(vim.fn.has('nvim-0.11') == 1, 'Neovim 0.11 or newer is required')
  local mode = assert(vim.env.NVIM_BOOTSTRAP_MODE, 'missing installer phase')
  if mode == 'plugins' then
    require('lazy').restore({ wait = true, show = false })
    for name, plugin in pairs(require('lazy.core.config').plugins) do
      assert(vim.fn.isdirectory(plugin.dir) == 1, name .. ' was not installed')
      for _, task in ipairs(plugin._.tasks or {}) do
        assert(not task:has_errors(), name .. ': ' .. (task:output() or 'plugin task failed'))
      end
    end
  elseif mode == 'parsers' then
    local languages = { 'python', 'c', 'cpp', 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline' }
    -- Install missing parsers, then refresh older ones to match current queries.
    -- update() alone skips languages that have never been installed.
    local treesitter = require('nvim-treesitter')
    treesitter.install(languages):wait(300000)
    treesitter.update(languages):wait(300000)
    for _, language in ipairs(languages) do
      assert(vim.treesitter.language.add(language), 'parser unavailable: ' .. language)
      local ok, err = pcall(vim.treesitter.query.get, language, 'highlights')
      assert(ok, 'highlight query is incompatible with ' .. language .. ' parser: ' .. tostring(err))
    end
  else error('unknown installer phase: ' .. mode) end
  assert(vim.v.errmsg == '', 'phase reported an error: ' .. vim.v.errmsg)
  print('BOOTSTRAP PASS: ' .. mode)
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd('cquit 1')
else vim.cmd('qa!') end
