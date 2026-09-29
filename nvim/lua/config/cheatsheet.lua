local M = {}

M.win_id = nil
M.buf_nr = nil

-- Define highlights matching theme palette
local function setup_highlights()
  local ok, surfaces = pcall(require, "config.surfaces")
  local accent = ok and surfaces.accent or "#82AAFF"
  local lilac = ok and surfaces.lilac or "#C7A6FF"
  local teal = ok and surfaces.teal or "#4FD1C5"
  local muted = ok and surfaces.muted or "#61708A"
  local edge = ok and surfaces.edge or "#38557A"
  local panel = ok and surfaces.panel or "#0E141D"
  local text = ok and surfaces.text or "#D7E3FF"

  vim.api.nvim_set_hl(0, "CheatsheetNormal", { fg = text, bg = panel, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetBorder", { fg = teal, bg = panel, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetTitle", { fg = accent, bg = panel, bold = true, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetHeader", { fg = accent, bold = true, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetKey", { fg = lilac, bold = true, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetSep", { fg = edge, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetMuted", { fg = muted, italic = true, default = true })
  vim.api.nvim_set_hl(0, "CheatsheetAction", { fg = teal, default = true })
end

local content_lines = {
  "## 📁 File Explorer (`Snacks.explorer`)",
  "  `<leader>e`   Toggle file tree             │ `<leader>fe`  Focus file tree",
  "  Inside: `<CR>` open · `a` create · `d` trash · `r` rename · `c` copy · `m` move · `.` hidden · `q` close",
  "",
  "## Makefile & Completion",
  "  `<leader>cm` Pick Make target  │ `<leader>cM` Run default target  │ `:Make test` Run a target",
  "  `<C-n>` / `<C-p>` Next / previous completion (opens Blink when hidden)",
  "  `<C-space>` Completion  │ `<C-d>` Toggle docs  │ `<C-b>` / `<C-f>` Open / scroll docs",
  "  `<C-e>` Dismiss completion  │ `<C-k>` Toggle signature help",
  "",
  "## 󰞌 Floating Terminal",
  "  `<C-t>` / `<C-/>`  Toggle centered float terminal (Normal, Insert, Terminal mode)",
  "  `<Esc><Esc>`       Exit terminal mode back to Normal mode",
  "",
  "## 󰛢 Harpoon 2 (Buffer Hopping)",
  "  `<leader>a`        Pin file to Harpoon     │ `<C-e>`       Open Harpoon quick menu",
  "  `<leader>1`..`<4>` Jump to pinned file 1–4 │ `<C-S-N>` / `<C-S-P>` Next / prev pin",
  "",
  "## 󰅩 Treesitter Text Objects",
  "  `daf` / `dif`  Delete func (outer/inner)   │ `caf` / `cif` Change func (outer/inner)",
  "  `dac` / `cic`  Class (outer/inner)         │ `daa` / `cia` Param (outer/inner)",
  "  `]m`  / `[m`   Jump next / prev func start",
  "",
  "## 󰍉 Fuzzy Finding & Search",
  "  `<leader><space>` or `<leader>ff` Find files│ `<leader>/`   Grep project",
  "  `<leader>fb`   Buffers                     │ `<leader>fr`  Recent files  │ `<leader>sk` Keymaps",
  "",
  "## 󰒋 Code Navigation & LSP",
  "  `gd`  Definition   │ `gr`  References      │ `K`           Hover docs",
  "  `<leader>ca`  Code action (quick fixes)    │ `<leader>cr`  Rename symbol (IncRename)",
  "  `[d`  / `]d`  Previous / next diagnostic error",
  "",
  "## 󰏫 Git Integration",
  "  `<leader>gg`  Lazygit floating UI          │ `<leader>gL`  Commit history",
  "",
  "  ────────────────────────────────────────────────────────────────────────────",
  "  Press `q` or `<Esc>` to close  ·  Use `j`/`k` or `<C-d>`/`<C-u>` to scroll",
}

local function apply_highlights(buf)
  local ns = vim.api.nvim_create_namespace("cheatsheet_highlights")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for l_idx, line in ipairs(content_lines) do
    local row = l_idx - 1
    if line:match("^## ") then
      vim.api.nvim_buf_add_highlight(buf, ns, "CheatsheetHeader", row, 0, -1)
    elseif line:match("^%s*─") then
      vim.api.nvim_buf_add_highlight(buf, ns, "CheatsheetSep", row, 0, -1)
    elseif line:match("^%s*Press") then
      vim.api.nvim_buf_add_highlight(buf, ns, "CheatsheetMuted", row, 0, -1)
    end

    -- Highlight keys inside backticks `...`
    local start_col = 1
    while true do
      local s, e = line:find("`[^`]+`", start_col)
      if not s then break end
      vim.api.nvim_buf_add_highlight(buf, ns, "CheatsheetKey", row, s - 1, e)
      start_col = e + 1
    end

    -- Highlight delimiters │ and ·
    for _, sym in ipairs({ "│", "·" }) do
      local cur = 1
      while true do
        local s, e = line:find(sym, cur, true)
        if not s then break end
        vim.api.nvim_buf_add_highlight(buf, ns, "CheatsheetSep", row, s - 1, e)
        cur = e + 1
      end
    end
  end
end

function M.close()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_win_close(M.win_id, true)
  end
  if M.buf_nr and vim.api.nvim_buf_is_valid(M.buf_nr) then
    vim.api.nvim_buf_delete(M.buf_nr, { force = true })
  end
  M.win_id = nil
  M.buf_nr = nil
end

function M.show()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    vim.api.nvim_set_current_win(M.win_id)
    return M.win_id
  end

  setup_highlights()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content_lines)
  vim.bo[buf].modifiable = false

  -- Target dimensions
  local target_w = 86
  local target_h = 32

  -- Clamp dimensions to fit current terminal size gracefully
  local width = math.min(target_w, math.max(20, vim.o.columns - 4))
  local height = math.min(target_h, math.max(10, vim.o.lines - 4))
  local row = math.max(0, math.floor((vim.o.lines - height) / 2))
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    title = " 󰋖 Neovim Feature & Keymap Guide ",
    title_pos = "center",
    style = "minimal",
  })

  vim.wo[win].winblend = 0
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].spell = false
  vim.wo[win].conceallevel = 0
  vim.wo[win].winhighlight = "Normal:CheatsheetNormal,FloatBorder:CheatsheetBorder,FloatTitle:CheatsheetTitle"

  apply_highlights(buf)

  M.win_id = win
  M.buf_nr = buf

  -- Key mappings to close
  local close_fn = function()
    M.close()
  end

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close_fn, { buffer = buf, nowait = true, silent = true, desc = "Close cheatsheet" })
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      M.win_id = nil
      M.buf_nr = nil
    end,
  })

  return win
end

function M.toggle()
  if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
    M.close()
  else
    M.show()
  end
end

return M
