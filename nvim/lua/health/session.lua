local M = {}

-- Explicit, local inspection only: no downloads, repairs or plugin loading.
function M.check()
  local health = vim.health
  health.start('1337-session runtime')
  if vim.fn.has('nvim-0.11') == 1 then
    health.ok('Neovim ' .. tostring(vim.version()))
  else
    health.error('Neovim 0.11 or newer is required')
  end
  health.info('OS: ' .. vim.uv.os_uname().sysname)
  health.info('Station mode: ' .. (require('config.station').is_1337() and 'on' or 'off')
    .. ' (STATION_1337=0 disables automatic detection)')

  health.start('Configuration and storage')
  for _, kind in ipairs({ 'config', 'data', 'state', 'cache' }) do
    local path = vim.fn.stdpath(kind)
    local real = vim.uv.fs_realpath(path)
    if not real then
      health.warn(kind .. ': missing directory or broken link: ' .. path)
    else
      health.info(kind .. ': ' .. real)
      if kind ~= 'config' and vim.fn.filewritable(path) ~= 2 then
        health.warn(kind .. ' directory is not writable')
      end
    end
  end

  health.start('Tools available to this Neovim process')
  for _, name in ipairs({ 'git', 'rg', 'uv', 'ty', 'ruff', 'clangd' }) do
    local path = vim.fn.exepath(name)
    if path ~= '' then
      health.ok(name .. ': ' .. path)
    else
      health.warn(name .. ' is missing from PATH; needed only for its corresponding workflow')
    end
  end

  health.start('Display and clipboard')
  health.info('Palette: ' .. (vim.env.NVIM_COLOR_STYLE or 'rose'))
  if vim.o.termguicolors then
    health.ok('True color enabled; verify colors in your actual terminal')
  else
    health.warn('True color is disabled')
  end
  health.info('Terminal fonts cannot be detected reliably. If icons show boxes, try NVIM_ASCII_ICONS=1 nvim')
  local clipboard = vim.fn['provider#clipboard#Executable']()
  if clipboard ~= '' then
    health.ok('Clipboard provider: ' .. clipboard)
  else
    health.warn('No clipboard provider detected; run :checkhealth vim.provider for details')
  end
  health.info('Measure startup on this machine with make bench from the repository; use :Lazy profile for plugin timing')
end

return M
