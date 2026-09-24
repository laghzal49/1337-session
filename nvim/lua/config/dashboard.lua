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
    file = function(item)
      return { { vim.fn.fnamemodify(item.file, ":t"), hl = "SnacksDashboardFile" } }
    end,
  },
  sections = function()
    local wide = vim.o.columns >= 100 and vim.o.lines >= 30
    local sections = {
      { text = { { "1337", hl = "BlackBrand" }, { "  /  TARIK'S WORKSPACE", hl = "BlackMuted" } }, padding = 1 },
      { text = { { "Build something worth keeping.", hl = "BlackMuted" } }, padding = 2 },
      { text = { { "01   WORKSPACE", hl = "BlackLabel" } }, padding = 1 },
      action("", "Find a file", "f", ":lua Snacks.picker.files()"),
      action("", "Search the project", "g", ":lua Snacks.picker.grep()"),
      action("", "Recent files", "r", ":lua Snacks.picker.recent()"),
      action("", "New buffer", "n", ":ene | startinsert"),
      { section = "session", icon = "", desc = "Restore session", key = "s", padding = 1 },
    }
    local pane = wide and 2 or 1
    if wide then
      table.insert(sections, 1, { text = { { " ▄█  ▀▀▀█  ▀▀▀█  █▀▀▀█\n  █   ▄▄█   ▄▄█     █ \n  █     █     █    █  \n ▄█▄ █▄▄█  █▄▄█   █   ", hl = "BlackLabel" } }, padding = 1 })
      sections[#sections + 1] = { text = { { "BLACK / EDITION 01", hl = "BlackLabel" } }, pane = pane, padding = 1 }
      sections[#sections + 1] = { text = { { vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), hl = "BlackBrand" } }, pane = pane, padding = 2 }
    end
    sections[#sections + 1] = { text = { { "02   PICK UP WHERE YOU LEFT OFF", hl = "BlackLabel" } }, pane = pane, padding = 1 }
    sections[#sections + 1] = { section = "recent_files", cwd = true, limit = wide and 5 or 2, pane = pane, padding = 1 }
    sections[#sections + 1] = { text = { { "SPACE  commands     :q  quit", hl = "BlackMuted" } }, pane = pane }
    return sections
  end,
}
