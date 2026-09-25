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
      { label, hl = "SnacksDashboardDesc", width = opts.width or 25 },
      { " " .. key .. " ", hl = "BlackKey" },
    },
    key = key,
    action = command,
    padding = opts.padding or 1,
  }
end

local function rule(width)
  return {
    { "━━", hl = "BlackLabel" },
    { string.rep("━", math.max(8, width - 2)), hl = "BlackRule" },
  }
end

return {
  width = 52,
  pane_gap = 6,
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
    local columns, lines = vim.o.columns, vim.o.lines
    local wide = columns >= 110 and lines >= 28
    local compact = columns < 72
    local cwd = root()
    local git = git_info(cwd)
    local name = project_name(cwd)
    local label_width = compact and 19 or (wide and 27 or 23)
    local pane = wide and 2 or 1
    local sections = {
      {
        text = {
          { "◆ ", hl = "BlackBrandIcon" },
          { "DEVIL", hl = "BlackBrand" },
          { compact and "  /  WORKSPACE" or "  /  TARIK'S WORKSPACE", hl = "BlackMuted" },
        },
        padding = compact and 0 or 1,
      },
      {
        text = { { compact and "Make something worth keeping." or "Build something worth keeping.", hl = "BlackMuted" } },
        padding = 1,
      },
      { text = rule(compact and 28 or 38), padding = 1 },
      {
        text = {
          { icon("workspace") .. "  ", hl = "SnacksDashboardIcon" },
          { name, hl = "BlackLabel" },
          { git and ("  " .. icon("branch") .. " " .. git.name .. (git.dirty and " •" or "")) or "", hl = "BlackMuted" },
        },
        padding = 1,
      },
      {
        text = { { "WORKSPACE", hl = "BlackLabel" } },
        pane = pane,
        padding = 1,
      },
      action(icon("file"), "Find a file", "f", ":lua require('config.pick').open('files')", { width = label_width }),
      action(icon("search"), "Search the project", "g", ":lua require('config.pick').open('grep')", { width = label_width }),
      action(icon("file"), "Recent files", "r", ":lua require('config.pick').open('oldfiles')", { width = label_width }),
      action(icon("buffer"), "Open buffers", "b", ":lua require('config.pick').open('buffers')", { width = label_width }),
      action(icon("file"), "New buffer", "n", ":ene | startinsert", { width = label_width }),
      action(icon("terminal"), "Project terminal", "t",
        ":lua Snacks.terminal(nil, { cwd = require('config.project').root() })", { width = label_width }),
      action(icon("read"), "Markdown files", "m", M.open_markdown, { width = label_width }),
      action(icon("command"), "Quit", "q", ":qa", { width = label_width }),
      {
        section = "session",
        key = "s",
        padding = 1,
        text = {
          { icon("read") .. "  ", hl = "SnacksDashboardIcon" },
          { "Restore session", hl = "SnacksDashboardDesc", width = label_width },
          { " s ", hl = "BlackKey" },
        },
      },
    }

    if wide then
      table.insert(sections, 1, {
        text = {
          { "  N E O V I M", hl = "BlackBrand" },
          { "\n  a calm place to build", hl = "BlackMuted" },
        },
        pane = 1,
        padding = 2,
      })
      sections[#sections + 1] = {
        text = { { icon("file") .. "  PICK UP WHERE YOU LEFT OFF", hl = "BlackLabel" } },
        pane = 2,
        padding = 1,
      }
      sections[#sections + 1] = {
        section = "recent_files",
        cwd = true,
        limit = 7,
        pane = 2,
        gap = 1,
        padding = 1,
      }
      sections[#sections + 1] = {
        text = { { "f", hl = "BlackKey" }, { " files   ", hl = "BlackMuted" },
          { "g", hl = "BlackKey" }, { " grep   ", hl = "BlackMuted" },
          { "m", hl = "BlackKey" }, { " markdown   ", hl = "BlackMuted" },
          { "q", hl = "BlackKey" }, { " quit", hl = "BlackMuted" } },
        pane = 2,
        padding = 1,
      }
    else
      sections[#sections + 1] = {
        text = { { icon("file") .. "  PICK UP WHERE YOU LEFT OFF", hl = "BlackLabel" } },
        padding = 1,
      }
      sections[#sections + 1] = { section = "recent_files", cwd = true, limit = compact and 2 or 4, padding = 1 }
      sections[#sections + 1] = {
        text = { { "?", hl = "BlackKey" }, { " help   ", hl = "BlackMuted" },
          { "q", hl = "BlackKey" }, { " quit", hl = "BlackMuted" } },
        padding = 1,
      }
    end
    sections[#sections + 1] = { section = "startup", padding = 0 }
    return sections
  end,
}
