-- A useful launch surface; the wordmark disappears as soon as editing starts.
local function action(icon, label, key, command)
  return {
    text = { { icon .. "  ", hl = "SnacksDashboardIcon" },
      { label, hl = "SnacksDashboardDesc", width = 29 },
      { " " .. key .. " ", hl = "BlackKey" } },
    key = key, action = command, padding = 1,
  }
end
return {
  width = 42,
  pane_gap = 8,
  formats = {
    file = function(item, ctx)
      local name = vim.fn.fnamemodify(item.file, ":t")
      local parent = vim.fn.fnamemodify(item.file, ":h:t")
      local room = math.max(6, (ctx.width or 36) - vim.fn.strdisplaywidth(name) - 2)
      return { { name, hl = "SnacksDashboardFile" },
        { "  " .. vim.fn.strcharpart(parent, 0, room), hl = "BlackMuted" } }
    end,
  },
  sections = function()
    local wide = vim.o.columns >= 100 and vim.o.lines >= 30
    local sections = {
      { text = { { "1337", hl = "BlackBrand" }, { "  /  TARIK'S WORKSPACE", hl = "BlackMuted" } }, padding = 1 },
      { text = { { "Build something worth keeping.", hl = "BlackMuted" } }, padding = 1 },
      { text = { { "━━", hl = "BlackLabel" }, { "────────────────────────────────", hl = "BlackRule" } }, padding = 1 },
      { text = { { "  WORKSPACE", hl = "BlackLabel" } }, padding = 1 },
      action("", "Find a file", "f", ":lua require('config.pick').open('files')"),
      action("", "Search the project", "g", ":lua require('config.pick').open('grep')"),
      action("", "Recent files", "r", ":lua require('config.pick').open('oldfiles')"),
      action("", "New buffer", "n", ":ene | startinsert"),
      { section = "session", key = "s", padding = 1,
        text = { { "  ", hl = "SnacksDashboardIcon" },
          { "Restore session", hl = "SnacksDashboardDesc", width = 29 },
          { " s ", hl = "BlackKey" } } },
    }
    local pane = wide and 2 or 1
    if wide then
      table.insert(sections, 1, { text = { { " ▄█  ▀▀▀█  ▀▀▀█  █▀▀▀█\n  █   ▄▄█   ▄▄█     █ \n  █     █     █    █  \n ▄█▄ █▄▄█  █▄▄█   █   ", hl = "BlackLabel" } }, padding = 1 })
      sections[#sections + 1] = { text = { { "BLACK  /  STUDIO", hl = "BlackLabel" } }, pane = pane, padding = 1 }
      sections[#sections + 1] = { text = { { vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), hl = "BlackBrand" } }, pane = pane, padding = 1 }
      sections[#sections + 1] = { text = { { "━━", hl = "BlackLabel" }, { "────────────────────────────────", hl = "BlackRule" } }, pane = pane, padding = 5 }
    end
    sections[#sections + 1] = { text = { { "  PICK UP WHERE YOU LEFT OFF", hl = "BlackLabel" } }, pane = pane, padding = 1 }
    sections[#sections + 1] = { section = "recent_files", cwd = true, limit = wide and 5 or 2, pane = pane, gap = wide and 1 or 0, padding = 1 }
    sections[#sections + 1] = { text = { { "SPACE  commands     :q  quit", hl = "BlackMuted" } }, pane = pane }
    return sections
  end,
}
