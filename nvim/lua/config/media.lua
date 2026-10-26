-- On-demand image/PDF reader; ordinary editing never starts a renderer.
local M = {}
local formats = { png=true, jpg=true, jpeg=true, webp=true, gif=true, bmp=true, pdf=true }
local saved_window, saved_options
local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = 'Media reader' })
end
local function restore()
  if saved_window and vim.api.nvim_win_is_valid(saved_window) then
    for name, value in pairs(saved_options) do vim.wo[saved_window][name] = value end
  end
  saved_window, saved_options = nil, nil
end
local function path_or_current(path)
  return vim.fn.fnamemodify(path and path ~= '' and vim.fn.expand(path) or vim.b.media_source or vim.api.nvim_buf_get_name(0), ':p')
end
function M.supported_terminal()
  return vim.env.TMUX == nil and (vim.env.TERM == 'xterm-kitty'
    or vim.env.KITTY_WINDOW_ID ~= nil or vim.env.TERM_PROGRAM == 'ghostty')
end
function M.open(path)
  path = path_or_current(path)
  local extension = vim.fn.fnamemodify(path, ':e'):lower()
  if not formats[extension] then notify('Supported: PNG, JPEG, WebP, GIF (first frame), BMP and PDF'); return false end
  if vim.fn.filereadable(path) ~= 1 then notify('File is not readable: ' .. path); return false end
  if vim.bo.modified then notify('Save the current buffer before opening a media viewer'); return false end
  if not M.supported_terminal() then
    notify('Use Kitty or Ghostty outside tmux for graphics. :PDFText reads PDF text in any terminal.')
    return false
  end
  if extension == 'pdf' then
    for _, tool in ipairs({ 'pdfinfo', 'pdftoppm' }) do
      if not require('config.tool_health').require_tool(tool) then return false end
    end
  end
  local plugin = require('lazy.core.config').plugins['nvim-gfx']
  if not plugin or vim.fn.executable(plugin.dir .. '/bin/nvim-gfx') ~= 1 then
    notify('Build the Rust reader with :NvimGfxBuild'); return false
  end
  local stat = vim.uv.fs_stat(path)
  if stat and stat.size > 100 * 1024 * 1024 then notify('Media exceeds the 100 MiB preview limit'); return false end
  local viewer = require('nvim-gfx.viewer')
  if viewer.is_active() then viewer.close('replace') end
  saved_window, saved_options = vim.api.nvim_get_current_win(), {}
  for _, name in ipairs({ 'number', 'relativenumber', 'signcolumn' }) do saved_options[name] = vim.wo[name] end
  local ok, err = pcall(viewer.open, path)
  if not ok or not viewer.is_active() then
    restore()
    notify('Viewer could not open: ' .. tostring(err or path))
    return false
  end
  vim.b.media_source = path
  vim.b.snacks_scroll = false
  if extension == 'pdf' then
    for key, target in pairs({ ['<ScrollWheelDown>']='j', ['<ScrollWheelUp>']='k',
      ['<C-d>']='J', ['<C-u>']='K', ['<Space>']='J', ['<BS>']='K' }) do
      local map = vim.fn.maparg(target, 'n', false, true)
      if map.callback then vim.keymap.set('n', key, map.callback, { buffer=true, silent=true }) end
    end
  end
  return true
end
function M.text(path)
  path = path_or_current(path)
  if vim.fn.fnamemodify(path, ':e'):lower() ~= 'pdf' or vim.fn.filereadable(path) ~= 1 then
    notify('Choose a readable PDF file'); return false
  end
  if not require('config.tool_health').require_tool('pdftotext') then return false end
  vim.system({ 'pdftotext', '-layout', path, '-' }, { text = true, timeout = 15000 }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then notify('PDF text extraction failed: ' .. (result.stderr or '')); return end
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout or '', '\n', { plain = true }))
    vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'hide', false
    vim.bo[buf].modifiable, vim.bo[buf].filetype = false, 'text'
    vim.b[buf].media_source = path
    vim.api.nvim_set_current_buf(buf)
  end))
  return true
end
function M.pick()
  Snacks.picker.files({ title = 'Images and PDFs', layout = { preview = false },
    filter = { filter = function(item)
      return formats[vim.fn.fnamemodify(item.file or '', ':e'):lower()] == true
    end },
    confirm = function(picker, item)
      picker:close()
      if item then M.open(Snacks.picker.util.path(item)) end
    end,
  })
end
function M.setup()
  -- Do not enable upstream's eager BufReadPost handlers: intercept binary files
  -- before Neovim reads their raw bytes, and keep unsupported terminals usable.
  local viewer = require('nvim-gfx.viewer')
  local close = viewer.close
  viewer.close = function(...)
    local result = close(...)
    restore()
    return result
  end
  local group = vim.api.nvim_create_augroup('MediaReader', { clear = true })
  local patterns = {}
  for extension in pairs(formats) do
    patterns[#patterns + 1] = '*.' .. extension
    patterns[#patterns + 1] = '*.' .. extension:upper()
  end
  vim.api.nvim_create_autocmd('BufReadCmd', { group = group, pattern = patterns, callback = function(ev)
    if not M.open(ev.file) and vim.api.nvim_buf_is_valid(ev.buf) then
      -- An intercepted binary must never become an editable empty file.
      vim.bo[ev.buf].buftype, vim.bo[ev.buf].swapfile = 'nofile', false
      vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, {
        'Media reader', '', ev.file, '',
        'Use Kitty or Ghostty outside tmux for graphics.',
        'Run :MediaHealth for dependencies, or :PDFText for searchable PDF text.',
      })
      vim.bo[ev.buf].modified, vim.bo[ev.buf].modifiable = false, false
      vim.b[ev.buf].media_source = ev.file
      if ev.file:lower():match('%.pdf$') then M.text(ev.file) end
    end
  end })
  vim.api.nvim_create_autocmd('BufWinEnter', { group = group, callback = function(ev) viewer.on_other_buf(ev.buf) end })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, callback = function(ev)
    if vim.bo[ev.buf].filetype == 'nvim-gfx' then
      vim.schedule(function() if not viewer.is_active() then restore() end end)
    end
  end })
  local function command(name, callback, description)
    vim.api.nvim_create_user_command(name, function(args) callback(args.args) end,
      { nargs = '?', complete = 'file', desc = description, force = true })
  end
  command('ViewImage', M.open, 'View an image or PDF with the Rust reader')
  command('ViewPDF', M.open, 'Read a PDF with the Rust reader')
  command('PDFText', M.text, 'Read searchable PDF text in any terminal')
  vim.api.nvim_create_user_command('MediaHealth', function()
    local plugin = require('lazy.core.config').plugins['nvim-gfx']
    vim.notify(table.concat({ 'Graphics terminal: ' .. tostring(M.supported_terminal()),
      'Rust backend: ' .. tostring(plugin and vim.fn.executable(plugin.dir .. '/bin/nvim-gfx') == 1),
      'pdfinfo: ' .. vim.fn.exepath('pdfinfo'), 'pdftoppm: ' .. vim.fn.exepath('pdftoppm'),
      'pdftotext: ' .. vim.fn.exepath('pdftotext') }, '\n'), vim.log.levels.INFO, { title = 'Media reader' })
  end, { force = true })
  vim.api.nvim_create_user_command('NvimGfxBuild', function()
    local plugin = require('lazy.core.config').plugins['nvim-gfx']
    vim.notify('Building the image/PDF backend; progress appears in this terminal.', vim.log.levels.INFO)
    Snacks.terminal.open({ 'python3', vim.fn.stdpath('config') .. '/scripts/build_media.py', plugin.dir },
      { auto_close = false })
  end, { force = true, desc = 'Build image/PDF-only Rust backend without FFmpeg' })
end
return M
