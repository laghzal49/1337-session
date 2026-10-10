-- Buffer size checks use Neovim's byte offsets, never copy the entire buffer.
local M = { max_bytes = 1024 * 1024, max_lines = 20000 }

function M.large(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' then return false end
  if vim.b[buf].bigfile or vim.bo[buf].filetype == 'bigfile' then return true end
  local lines = vim.api.nvim_buf_line_count(buf)
  return lines > M.max_lines or vim.api.nvim_buf_get_offset(buf, lines) > M.max_bytes
end

function M.guard(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not M.large(buf) then return end
  -- Window-local options need applying again when a guarded buffer enters a
  -- different split; one-time buffer classification alone does not cover it.
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.wo[win].foldmethod ~= 'manual' then vim.wo[win].foldmethod = 'manual' end
    if vim.wo[win].spell then vim.wo[win].spell = false end
    if vim.wo[win].cursorcolumn then vim.wo[win].cursorcolumn = false end
  end
  if vim.b[buf].performance_guard then return end
  vim.b[buf].performance_guard = true
  vim.b[buf].bigfile = true
  vim.b[buf].minihipatterns_disable = true
  vim.b[buf].snacks_indent = false
  vim.b[buf].snacks_scope = false
  local hipatterns = package.loaded['mini.hipatterns']
  if hipatterns then hipatterns.disable(buf) end
  local context = package.loaded['treesitter-context']
  if context and context.enabled() then
    -- Its attach decisions are cached until enable() reevaluates all buffers.
    vim.schedule(function()
      if context.enabled() then context.enable() end
    end)
  end
  pcall(vim.treesitter.stop, buf)
  vim.bo[buf].syntax = ''
  vim.diagnostic.enable(false, { bufnr = buf })
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('BlackBufferPerformance', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWinEnter', 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(ev) M.guard(ev.buf) end,
  })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(ev)
      if M.large(ev.buf) then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then vim.lsp.buf_detach_client(ev.buf, ev.data.client_id) end
        end)
      end
    end,
  })
end

return M
