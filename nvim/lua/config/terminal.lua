local M = {}

function M.toggle()
  local ok, err = pcall(function()
    if vim.bo.buftype == 'terminal' then
      vim.cmd.stopinsert()
      for _, instance in ipairs(Snacks.terminal.list()) do
        if instance.buf == vim.api.nvim_get_current_buf() then instance:hide(); return end
      end
    end
    local terminal = vim.b[0].snacks_terminal
    local root = type(terminal) == 'table' and terminal.cwd or require('config.project').root()
    local cwd = root and vim.fn.isdirectory(root) == 1 and root or vim.fn.getcwd()
    Snacks.terminal.focus(nil, {
      cwd = cwd,
      count = type(terminal) == 'table' and terminal.id or 1,
      win = {
        -- Snacks' 200ms single-Esc timer competes with the existing 350ms
        -- double-Esc mapping. Own that mapping once, without a second timer.
        keys = { term_normal = false },
        on_buf = function(win)
          vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', {
            buffer = win.buf, desc = 'Exit terminal mode', silent = true,
          })
        end,
      },
    })
  end)
  if not ok then
    vim.notify('Terminal could not open: ' .. tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

return M
