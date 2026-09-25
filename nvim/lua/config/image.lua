local M = {}

local image_extensions = { png = true, jpg = true, jpeg = true, gif = true, webp = true, avif = true, tiff = true }
local configured = false
local commands_defined = false

local function path_from_arg(arg)
  local path = (arg and arg ~= '') and vim.fn.fnamemodify(arg, ':p') or vim.api.nvim_buf_get_name(0)
  return path ~= '' and path or nil
end

local function is_image(path)
  return path and image_extensions[vim.fn.fnamemodify(path, ':e'):lower()] == true
end

local function kitty_available()
  return vim.env.KITTY_WINDOW_ID ~= nil
    or vim.env.TERM == 'xterm-kitty'
    or (vim.env.TERM_PROGRAM or ''):lower() == 'kitty'
end

local function external_view(path)
  for _, command in ipairs({ 'xdg-open', 'open' }) do
    if vim.fn.executable(command) == 1 then
      vim.fn.jobstart({ command, path }, { detach = true })
      vim.notify('Opened image externally: ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
      return true
    end
  end
  vim.notify('No image viewer found. Install kitty or xdg-open.', vim.log.levels.WARN)
  return false
end

function M.setup()
  if configured then return true end
  local ok, image = pcall(require, 'image')
  if not ok then
    vim.notify('Image.nvim is unavailable; use :ImageOpenExternal instead', vim.log.levels.WARN)
    return false
  end
  image.setup({
    backend = 'kitty',
    processor = 'magick_cli',
    integrations = { markdown = { enabled = false } },
    max_width = 100,
    max_height = 30,
    max_width_window_percentage = 80,
    max_height_window_percentage = 60,
    window_overlap_clear_enabled = true,
    editor_only_render_when_focused = true,
    tmux_show_only_in_active_window = true,
  })
  configured = true
  return true
end

function M.view(arg)
  local path = path_from_arg(arg)
  if not is_image(path) then
    vim.notify('ImageView expects an image file (png, jpg, gif, webp, avif, or tiff)', vim.log.levels.WARN)
    return
  end
  if not kitty_available() then
    external_view(path)
    return
  end
  if not M.setup() then return end
  local ok, image = pcall(require, 'image')
  if not ok then return external_view(path) end
  local object = image.from_file(path, { window = 0 })
  if object then
    object:render()
    vim.notify('Rendered image: ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
  else
    vim.notify('Image.nvim could not render this file; opening externally', vim.log.levels.WARN)
    external_view(path)
  end
end

function M.clear()
  local ok, image = pcall(require, 'image')
  if ok and image.clear then image.clear() end
end

function M.info()
  vim.notify(table.concat({
    'Image workflow',
    'Terminal image protocol: ' .. (kitty_available() and 'available' or 'unavailable'),
    'ImageMagick: ' .. (vim.fn.executable('magick') == 1 and 'available' or 'missing'),
    'Fallback viewer: ' .. ((vim.fn.executable('xdg-open') == 1 or vim.fn.executable('open') == 1) and 'available' or 'missing'),
  }, '\n'), vim.log.levels.INFO, { title = 'Neovim images' })
end

function M.setup_commands()
  if commands_defined then return end
  commands_defined = true
  vim.api.nvim_create_user_command('ImageView', function(opts) M.view(opts.args) end, {
    nargs = '?', complete = 'file', desc = 'Render an image or open it externally',
  })
  vim.api.nvim_create_user_command('ImageOpenExternal', function(opts)
    local path = path_from_arg(opts.args)
    if path and is_image(path) then external_view(path) else vim.notify('Not an image file', vim.log.levels.WARN) end
  end, { nargs = '?', complete = 'file', desc = 'Open an image in the system viewer' })
  vim.api.nvim_create_user_command('ImageClear', M.clear, { desc = 'Clear rendered images' })
  vim.api.nvim_create_user_command('ImageInfo', M.info, { desc = 'Show image workflow support' })
  vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif', '*.tiff', '*.PNG', '*.JPG', '*.JPEG', '*.GIF', '*.WEBP', '*.AVIF', '*.TIFF' },
    callback = function() vim.schedule(function() M.view() end) end,
    desc = 'Render supported images when opened',
  })
end

return M
