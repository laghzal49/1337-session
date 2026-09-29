-- A focused launch surface; the wordmark disappears as soon as editing starts.
-- Keep this module limited to dashboard composition: workflows live in config.pick.
local ui = require("config.ui")
local M = {}

local function icon(name)
  return ui.icon(name)
end

local function root()
  local cwd = vim.uv.cwd() or vim.fn.getcwd()
  return vim.fs.root(0, { ".git", "Makefile", "pyproject.toml", "ty.toml", "Cargo.toml", "go.mod" }) or cwd
end

local function project_name(path)
  return vim.fn.fnamemodify(path, ":t") ~= "" and vim.fn.fnamemodify(path, ":t") or path
end

local function git_info(path)
  if vim.fn.executable("git") == 0 then return nil end
  local top = vim.fn.systemlist({ "git", "-C", path, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 or not top or top == "" then return nil end
  local name = vim.fn.systemlist({ "git", "-C", path, "branch", "--show-current" })[1]
  if not name or name == "" then
    name = vim.fn.systemlist({ "git", "-C", path, "rev-parse", "--short", "HEAD" })[1]
  end
  local dirty = vim.fn.systemlist({ "git", "-C", path, "status", "--porcelain", "--untracked-files=no" })
  return { name = name and name ~= "" and name or "detached", dirty = #dirty > 0 }
end

local function files_with_extensions(extensions)
  local matches = vim.fs.find(function(name)
    return extensions[vim.fn.fnamemodify(name, ":e"):lower()] == true
  end, { path = root(), type = "file", limit = 200 })
  table.sort(matches, function(a, b) return a:lower() < b:lower() end)
  return matches
end

local function pick_documents(extensions, title, chooser)
  local items = files_with_extensions(extensions)
  if #items == 0 then
    vim.notify("No " .. title:lower() .. " found in this project", vim.log.levels.INFO)
    return
  end
  local ok, pick = pcall(require, "mini.pick")
  if not ok then
    vim.notify("Mini Pick is unavailable; use Find a file instead", vim.log.levels.WARN)
    return
  end
  pick.start({
    source = {
      name = title,
      items = items,
      choose = function(item)
        if item then chooser(item) end
      end,
      show = function(item) return vim.fn.fnamemodify(item, ":~:.") end,
    },
  })
end

function M.open_markdown()
  pick_documents({ md = true, markdown = true, mkd = true }, "Markdown files", function(path)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
end

local function action(glyph, label, key, command, opts)
  opts = opts or {}
  return {
    text = {
      { glyph .. "  ", hl = "SnacksDashboardIcon" },
      { label, hl = "SnacksDashboardDesc", width = opts.width or 22 },
      { " " .. key .. " ", hl = "BlackKey" },
    },
    key = key,
    action = command,
    padding = opts.padding or 0,
    pane = opts.pane or 1,
  }
end

local function rule(width)
  return {
    { "━━", hl = "BlackBrandIcon" },
    { string.rep("━", math.max(8, width - 2)), hl = "BlackRule" },
  }
end

local devil_logo = table.concat({
  [[██████╗  ███████╗██╗   ██╗██╗██╗     ]],
  [[██╔══██╗ ██╔════╝██║   ██║██║██║     ]],
  [[██║  ██║ █████╗  ██║   ██║██║██║     ]],
  [[██║  ██║ ██╔══╝  ╚██╗ ██╔╝██║██║     ]],
  [[██████╔╝ ███████╗ ╚████╔╝ ██║███████╗]],
  [[╚═════╝  ╚══════╝  ╚═══╝  ╚═╝╚══════╝]],
}, "\n")

return {
  width = 38,
  pane_gap = 4,
  formats = {
    file = function(item, ctx)
      local name = vim.fn.fnamemodify(item.file, ":t")
      local parent = vim.fn.fnamemodify(item.file, ":h:t")
      local max_name = 18
      if vim.fn.strdisplaywidth(name) > max_name then
        name = vim.fn.strcharpart(name, 0, max_name - 1) .. "…"
      end
      local room = math.max(4, (ctx.width or 38) - vim.fn.strdisplaywidth(name) - 4)
      local parent_str = vim.fn.strcharpart(parent, 0, room)
      return {
        { name, hl = "SnacksDashboardFile" },
        { "  " .. parent_str, hl = "BlackMuted" },
      }
    end,
  },
  sections = function()
    local columns = vim.o.columns
    local lines = vim.o.lines
    local two_col = columns >= 84
    local cwd = root()
    local git = git_info(cwd)
    local name = project_name(cwd)
    local label_width = 22

    local sections = {}

    if two_col then
      -- ── LEFT PANE (pane = 1): DEVIL LOGO & ACTIONS ─────────────────
      sections[#sections + 1] = {
        text = devil_logo,
        hl = "SnacksDashboardHeader",
        padding = 1,
        pane = 1,
      }
      sections[#sections + 1] = {
        text = {
          { "◆ ", hl = "BlackBrandIcon" },
          { "DEVIL", hl = "BlackBrand" },
          { "  ·  TARIK'S WORKSPACE", hl = "BlackMuted" },
        },
        padding = 1,
        pane = 1,
      }
      sections[#sections + 1] = {
        text = rule(38),
        padding = 1,
        pane = 1,
      }

      -- Command Palette (tight 0-gap rows)
      sections[#sections + 1] = action(icon("file"), "Find a file", "f", ":lua require('config.pick').open('files')", { width = label_width, pane = 1 })
      sections[#sections + 1] = action(icon("search"), "Search project", "g", ":lua require('config.pick').open('grep')", { width = label_width, pane = 1 })
      sections[#sections + 1] = action(icon("clock"), "Recent files", "r", ":lua require('config.pick').open('oldfiles')", { width = label_width, pane = 1 })
      sections[#sections + 1] = action(icon("buffer"), "Open buffers", "b", ":lua require('config.pick').open('buffers')", { width = label_width, pane = 1 })
      sections[#sections + 1] = action(icon("file_new"), "New buffer", "n", ":ene | startinsert", { width = label_width, pane = 1 })
      sections[#sections + 1] = action(icon("terminal"), "Project terminal", "t",
        ":lua Snacks.terminal(nil, { cwd = require('config.project').root() })", { width = label_width, pane = 1 })
      sections[#sections + 1] = action(icon("markdown"), "Markdown files", "m", M.open_markdown, { width = label_width, pane = 1 })
      sections[#sections + 1] = {
        section = "session",
        key = "s",
        pane = 1,
        padding = 0,
        text = {
          { icon("session") .. "  ", hl = "SnacksDashboardIcon" },
          { "Restore session", hl = "SnacksDashboardDesc", width = label_width },
          { " s ", hl = "BlackKey" },
        },
      }
      sections[#sections + 1] = action(icon("quit"), "Quit Neovim", "q", ":qa", { width = label_width, pane = 1 })

      -- ── RIGHT PANE (pane = 2): WORKSPACE & RECENT FILES ────────────
      sections[#sections + 1] = {
        pane = 2,
        text = {
          { icon("workspace") .. "  ", hl = "SnacksDashboardIcon" },
          { "ACTIVE WORKSPACE", hl = "BlackLabel" },
        },
        padding = 1,
      }
      sections[#sections + 1] = {
        pane = 2,
        text = {
          { name, hl = "BlackBrand" },
          { git and ("   " .. icon("branch") .. " " .. git.name .. (git.dirty and " •" or "")) or "", hl = "BlackMuted" },
        },
        padding = 1,
      }
      sections[#sections + 1] = {
        pane = 2,
        text = rule(38),
        padding = 1,
      }
      sections[#sections + 1] = {
        pane = 2,
        text = {
          { icon("clock") .. "  ", hl = "SnacksDashboardIcon" },
          { "RECENT FILES", hl = "BlackLabel" },
        },
        padding = 1,
      }
      sections[#sections + 1] = {
        section = "recent_files",
        pane = 2,
        cwd = true,
        limit = 7,
        padding = 1,
      }
      sections[#sections + 1] = {
        section = "startup",
        pane = 2,
        padding = 1,
      }

    else
      -- ── SINGLE COMPACT PANE (when window width is under 84 cols) ────
      sections[#sections + 1] = {
        text = {
          { "◆ ", hl = "BlackBrandIcon" },
          { "DEVIL", hl = "BlackBrand" },
          { "  ·  TARIK'S WORKSPACE", hl = "BlackMuted" },
        },
        padding = 1,
      }
      sections[#sections + 1] = { text = rule(36), padding = 1 }
      sections[#sections + 1] = {
        text = {
          { icon("workspace") .. "  ", hl = "SnacksDashboardIcon" },
          { name, hl = "BlackLabel" },
          { git and ("   " .. icon("branch") .. " " .. git.name .. (git.dirty and " •" or "")) or "", hl = "BlackMuted" },
        },
        padding = 1,
      }
      sections[#sections + 1] = action(icon("file"), "Find a file", "f", ":lua require('config.pick').open('files')", { width = label_width })
      sections[#sections + 1] = action(icon("search"), "Search project", "g", ":lua require('config.pick').open('grep')", { width = label_width })
      sections[#sections + 1] = action(icon("clock"), "Recent files", "r", ":lua require('config.pick').open('oldfiles')", { width = label_width })
      sections[#sections + 1] = action(icon("buffer"), "Open buffers", "b", ":lua require('config.pick').open('buffers')", { width = label_width })
      sections[#sections + 1] = action(icon("file_new"), "New buffer", "n", ":ene | startinsert", { width = label_width })
      sections[#sections + 1] = action(icon("terminal"), "Project terminal", "t",
        ":lua Snacks.terminal(nil, { cwd = require('config.project').root() })", { width = label_width })
      sections[#sections + 1] = action(icon("markdown"), "Markdown files", "m", M.open_markdown, { width = label_width })
      sections[#sections + 1] = {
        section = "session",
        key = "s",
        padding = 0,
        text = {
          { icon("session") .. "  ", hl = "SnacksDashboardIcon" },
          { "Restore session", hl = "SnacksDashboardDesc", width = label_width },
          { " s ", hl = "BlackKey" },
        },
      }
      sections[#sections + 1] = action(icon("quit"), "Quit Neovim", "q", ":qa", { width = label_width, padding = 1 })
      sections[#sections + 1] = { section = "startup", padding = 1 }
    end

    return sections
  end,
}
