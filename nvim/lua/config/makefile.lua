-- Makefile target picker and terminal runner.
local M = {}

-- Locate Makefile in project root or current working directory
function M.find_makefile(start_dir)
  local project_root = require("config.project").root()
  local candidates = {
    (start_dir or project_root) .. "/GNUmakefile",
    (start_dir or project_root) .. "/makefile",
    (start_dir or project_root) .. "/Makefile",
    vim.fn.getcwd() .. "/GNUmakefile",
    vim.fn.getcwd() .. "/makefile",
    vim.fn.getcwd() .. "/Makefile",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

-- Parse Makefile and extract targets, descriptions, and recipes
function M.parse(makefile_path)
  makefile_path = makefile_path or M.find_makefile()
  if not makefile_path then return {} end

  local lines = vim.fn.readfile(makefile_path)
  local targets = {}
  local seen = {}
  local pending_comment = nil
  local current_target = nil

  local special = {
    [".PHONY"] = true,
    [".SUFFIXES"] = true,
    [".DEFAULT"] = true,
    [".PRECIOUS"] = true,
    [".INTERMEDIATE"] = true,
    [".SECONDARY"] = true,
    [".SECONDEXPANSION"] = true,
    [".DELETE_ON_ERROR"] = true,
    [".IGNORE"] = true,
    [".LOW_RESOLUTION_TIME"] = true,
    [".SILENT"] = true,
    [".EXPORT_ALL_VARIABLES"] = true,
    [".NOTPARALLEL"] = true,
    [".ONESHELL"] = true,
    [".POSIX"] = true,
  }

  for _, line in ipairs(lines) do
    -- Comment doc line: ## comment or # comment
    local doc = line:match("^##%s*(.*)$") or line:match("^#%s*(.*)$")
    if doc and not line:match("^#[#%s]*$") then
      pending_comment = doc
    elseif line:match("^[%s]*$") then
      pending_comment = nil
    else
      -- Check for target definition: name: or name: prereqs or name: ## desc
      local target_name, inline_desc = line:match("^([%w_%-%./]+)%s*:%s*.*##%s*(.*)$")
      if line:match("^[^:]+:%s*=") then target_name = nil
      elseif not target_name then
        target_name = line:match("^([%w_%-%./]+)%s*:%s*.*$")
      end

      if target_name and not special[target_name] and not target_name:match("^%%") then
        local desc = inline_desc or pending_comment or ""
        pending_comment = nil
        if not seen[target_name] then
          seen[target_name] = true
          current_target = {
            name = target_name,
            desc = desc,
            recipes = {},
          }
          table.insert(targets, current_target)
        else
          for _, target in ipairs(targets) do
            if target.name == target_name then current_target = target; break end
          end
        end
      elseif current_target and line:match("^\t") then
        local recipe_cmd = vim.trim(line:sub(2))
        table.insert(current_target.recipes, recipe_cmd)
      else
        pending_comment = nil
        current_target = nil
      end
    end
  end

  return targets
end

-- Run a Makefile target in an interactive terminal floating window
function M.run(target_name)
  local makefile = M.find_makefile()
  if not makefile then
    vim.notify("No Makefile found in project root or current directory", vim.log.levels.WARN, { title = "Makefile" })
    return
  end
  local root = vim.fn.fnamemodify(makefile, ":h")
  local cmd = { "make", "-C", root, "-f", makefile }
  if target_name and target_name ~= "" then
    cmd[#cmd + 1] = "--"
    cmd[#cmd + 1] = target_name
  end
  Snacks.terminal(cmd, { cwd = root, interactive = true })
end

-- Interactive Picker for Makefile targets
function M.pick()
  local makefile = M.find_makefile()
  if not makefile then
    vim.notify("No Makefile found in project root or working directory", vim.log.levels.WARN, { title = "Makefile" })
    return
  end

  local targets = M.parse(makefile)
  if #targets == 0 then
    vim.notify("No targets found in " .. vim.fn.fnamemodify(makefile, ":~:."), vim.log.levels.INFO, { title = "Makefile" })
    return
  end

  local items = {}
  local max_name_len = 16
  for _, t in ipairs(targets) do
    if #t.name > max_name_len then max_name_len = #t.name end
  end

  for _, t in ipairs(targets) do
    local icon = require("config.ui").icon("terminal") .. " "
    local padding = string.rep(" ", max_name_len - #t.name + 2)
    local desc = t.desc ~= "" and t.desc or (t.recipes[1] and ("→ " .. t.recipes[1]:sub(1, 40)) or "")
    table.insert(items, {
      text = icon .. t.name .. padding .. desc,
      target = t.name,
    })
  end

  local ok, pick = pcall(require, "mini.pick")
  if ok then
    pick.start({
      window = {
        config = function()
          local width = math.max(1, math.min(90, vim.o.columns - 4))
          local height = math.max(1, math.min(#items, 16, vim.o.lines - 6))
          return {
            relative = "editor", width = width, height = height,
            row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
            col = math.max(0, math.floor((vim.o.columns - width) / 2) - 1),
          }
        end,
      },
      source = {
        name = "Run Makefile Target",
        items = items,
        choose = function(selected)
          if not selected then return end
          M.run(selected.target)
        end,
        show = function(buf, matches, query)
          pick.default_show(buf, matches, query, { show_icons = false })
        end,
      },
    })
  else
    -- Fallback to vim.ui.select
    vim.ui.select(items, {
      prompt = "Run Makefile Target:",
      format_item = function(item) return item.text end,
    }, function(selected)
      if not selected then return end
      M.run(selected.target)
    end)
  end
end

-- User Commands
vim.api.nvim_create_user_command("Make", function(cmd_opts)
  if cmd_opts.args ~= "" then
    M.run(cmd_opts.args)
  else
    M.pick()
  end
end, {
  nargs = "?",
  complete = function(arglead)
    local targets = M.parse()
    local matches = {}
    for _, t in ipairs(targets) do
      if t.name:match("^" .. vim.pesc(arglead)) then
        table.insert(matches, t.name)
      end
    end
    return matches
  end,
  desc = "Run Makefile target or pick one interactively",
})

vim.api.nvim_create_user_command("MakePick", function() M.pick() end, { desc = "Interactive Makefile target picker" })

return M
