local M = {}

local viewers = { 'zathura', 'sioyek', 'okular', 'mupdf', 'xdg-open' }

local function pdf_path(arg)
  local path = arg ~= '' and arg or vim.b.pdf_source or vim.api.nvim_buf_get_name(0)
  if path == '' then
    vim.notify('Usage: PdfRead {file.pdf} or PdfOpen {file.pdf}', vim.log.levels.ERROR)
    return
  end
  path = vim.fn.fnamemodify(path, ':p')
  if not path:lower():match('%.pdf$') then
    vim.notify('Not a PDF file: ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify('PDF file is not readable: ' .. path, vim.log.levels.ERROR)
    return
  end
  return path
end

local function open_external(path)
  for _, viewer in ipairs(viewers) do
    if vim.fn.executable(viewer) == 1 then
      local job = vim.fn.jobstart({ viewer, path }, { detach = true })
      if job > 0 then
        vim.notify('Opened PDF with ' .. viewer, vim.log.levels.INFO)
        return true
      end
      vim.notify('Could not start PDF viewer: ' .. viewer, vim.log.levels.ERROR)
      return false
    end
  end
  vim.notify('No PDF viewer found; install zathura or use :PdfRead for text', vim.log.levels.ERROR)
  return false
end

local function read_pdf(path)
  if vim.fn.executable('pdftotext') == 0 then
    vim.notify('Install poppler (pdftotext) to read PDF files', vim.log.levels.ERROR)
    return
  end
  local lines = vim.fn.systemlist({ 'pdftotext', '-layout', '-nopgbrk', path, '-' })
  if vim.v.shell_error ~= 0 then
    vim.notify('Could not extract text from ' .. vim.fn.fnamemodify(path, ':t') .. ' (is it encrypted or damaged?)',
      vim.log.levels.ERROR)
    return
  end
  vim.bo.filetype = 'pdf'
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(0, 0, -1, false, #lines > 0 and lines or { '[PDF contains no extractable text]' })
  vim.bo.modifiable = false
  vim.bo.modified = false
  vim.b.pdf_source = path
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.signcolumn = 'no'
  vim.wo.cursorline = true
  vim.notify('Reading PDF as text: ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
end

function M.setup()
  vim.api.nvim_create_autocmd('BufReadCmd', {
    pattern = { '*.pdf', '*.PDF' },
    callback = function(ev) read_pdf(ev.file) end,
  })
  vim.api.nvim_create_user_command('PdfRead', function(opts)
    local path = pdf_path(opts.args)
    if not path then return end
    vim.cmd.edit(vim.fn.fnameescape(path))
  end, { nargs = '?', complete = 'file', desc = 'Read a PDF as a clean text buffer' })
  vim.api.nvim_create_user_command('PdfOpen', function(opts)
    local path = pdf_path(opts.args)
    if not path then return end
    open_external(path)
  end, { nargs = '?', complete = 'file', desc = 'Open PDF in an external viewer' })
end

return M
