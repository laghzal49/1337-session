-- A focused launch surface; the wordmark disappears as soon as editing starts.
local function action(icon, label, key, command, opts)
  opts = opts or {}
  return {
    text = {
      { icon .. "  ", hl = "SnacksDashboardIcon" },
      { label, hl = "SnacksDashboardDesc", width = opts.width or 29 },
      { " " .. key .. " ", hl = "BlackKey" },
    },
    key = key,
    action = command,
    padding = opts.padding or 1,
  }
end

local function branch()
  if vim.fn.isdirectory(".git") == 0 and vim.fn.filereadable(".git") == 0 then
    return nil
  end
  local name = vim.fn.systemlist({ "git", "branch", "--show-current" })[1]
  return name and name ~= "" and name or nil
end

local function rule(width)
  width = width or 36
  return {
    { "━━", hl = "BlackLabel" },
    { string.rep("━", math.max(8, width - 2)), hl = "BlackRule" },
  }
end

return {
  width = 46,
  pane_gap = 8,
  formats = {
    file = function(item, ctx)
      local name = vim.fn.fnamemodify(item.file, ":t")
      local parent = vim.fn.fnamemodify(item.file, ":h:t")
      local room = math.max(6, (ctx.width or 36) - vim.fn.strdisplaywidth(name) - 2)
      return {
        { name, hl = "SnacksDashboardFile" },
        { "  " .. vim.fn.strcharpart(parent, 0, room), hl = "BlackMuted" },
      }
    end,
  },
  sections = function()
    local wide = vim.o.columns >= 100 and vim.o.lines >= 30
    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    local git_branch = branch()
    local sections = {
      {
        text = {
          { "DEVIL", hl = "BlackBrand" },
          { "  /  TARIK'S WORKSPACE", hl = "BlackMuted" },
        },
        padding = 1,
      },
      {
        text = {
          { "Build something worth keeping.", hl = "BlackMuted" },
        },
        padding = 1,
      },
      { text = rule(), padding = 1 },
      { text = { { "  WORKSPACE", hl = "BlackLabel" } }, padding = 1 },
      action("", "Find a file", "f", ":lua require('config.pick').open('files')"),
      action("", "Search the project", "g", ":lua require('config.pick').open('grep')"),
      action("", "Recent files", "r", ":lua require('config.pick').open('oldfiles')"),
      action("", "Open buffers", "b", ":lua require('config.pick').open('buffers')"),
      action("", "New buffer", "n", ":ene | startinsert"),
      action("", "Project terminal", "t",
        ":lua Snacks.terminal(nil, { cwd = require('config.project').root() })"),
      {
        section = "session",
        key = "s",
        padding = 1,
        text = {
          { "  ", hl = "SnacksDashboardIcon" },
          { "Restore session", hl = "SnacksDashboardDesc", width = 29 },
          { " s ", hl = "BlackKey" },
        },
      },
    }

    local pane = wide and 2 or 1
    if wide then
      table.insert(sections, 1, {
        text = {
          {
            [[
    ____  _______ _    ______   __
   / __ \/ ____/ | |  / /  _/  / /
  / / / / __/  | | / // /     / /
 / /_/ / /___  | |/ // /     / /___
/_____/_____/  |___/___/    /_____/
]],
            hl = "BlackLabel",
          },
        },
        padding = 2,
      })
      sections[#sections + 1] = {
        text = { { "DEVIL  ·  BLACK STUDIO", hl = "BlackLabel" } },
        pane = pane,
        padding = 1,
      }
      sections[#sections + 1] = {
        text = { { cwd, hl = "BlackBrand" } },
        pane = pane,
        padding = 1,
      }
      if git_branch then
        sections[#sections + 1] = {
          text = {
            { "  ", hl = "SnacksDashboardIcon" },
            { git_branch, hl = "BlackMuted" },
          },
          pane = pane,
          padding = 0,
        }
      end
      sections[#sections + 1] = { text = rule(42), pane = pane, padding = 3 }
    end

    sections[#sections + 1] = {
      text = { { "  PICK UP WHERE YOU LEFT OFF", hl = "BlackLabel" } },
      pane = pane,
      padding = 1,
    }
    sections[#sections + 1] = {
      section = "recent_files",
      cwd = true,
      limit = wide and 6 or 3,
      pane = pane,
      gap = wide and 1 or 0,
      padding = 1,
    }
    sections[#sections + 1] = {
      text = {
        { cwd, hl = "BlackBrand" },
        { git_branch and ("  ·  " .. git_branch) or "", hl = "BlackMuted" },
      },
      pane = pane,
      padding = 1,
    }
    sections[#sections + 1] = {
      text = {
        { "f", hl = "BlackKey" },
        { " files   ", hl = "BlackMuted" },
        { "g", hl = "BlackKey" },
        { " grep   ", hl = "BlackMuted" },
        { "t", hl = "BlackKey" },
        { " terminal   ", hl = "BlackMuted" },
        { "q", hl = "BlackKey" },
        { " quit", hl = "BlackMuted" },
      },
      pane = pane,
      padding = 1,
    }
    return sections
  end,
}
