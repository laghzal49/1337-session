-- Resolve standalone-script user packages without blocking Neovim's UI.
local M = {}
local cache, waiting, roots = {}, {}, {}
local markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }

function M.user_site(done)
  local executable = vim.fn.exepath("python3")
  if executable == "" then done(nil); return end
  local key = executable .. "\0" .. (vim.env.PYTHONUSERBASE or "") .. "\0" .. (vim.env.PYTHONPATH or "")
  if cache[key] ~= nil then done(cache[key] or nil); return end
  if waiting[key] then table.insert(waiting[key], done); return end
  waiting[key] = { done }
  local function finish(path)
    cache[key] = path or false
    local callbacks = waiting[key] or {}
    waiting[key] = nil
    for _, callback in ipairs(callbacks) do callback(path) end
  end
  local ok = pcall(vim.system, { executable, "-m", "site", "--user-site" },
    { text = true, timeout = 1500 }, vim.schedule_wrap(function(result)
      local path = vim.trim(result.stdout or "")
      finish(result.code == 0 and vim.fn.isdirectory(path) == 1 and path or nil)
    end))
  if not ok then finish(nil) end
end

function M.root_dir(buf, on_dir)
  local project = vim.fs.root(buf, markers)
  local root = project or vim.fn.getcwd()
  root = vim.uv.fs_realpath(root) or root
  if (project and project ~= vim.fn.expand("~")) or vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
    or vim.fn.isdirectory(root .. "/.venv") == 1 then
    roots[root] = false
    on_dir(root)
    return
  end
  M.user_site(function(path)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    roots[root] = path or false
    on_dir(root)
  end)
end

function M.before_init(_, config)
  local path = roots[config.root_dir]
  if path then
    config.settings = config.settings or {}
    config.settings.ty = vim.tbl_deep_extend("force", config.settings.ty or {}, {
      configuration = { environment = { ["extra-paths"] = { path } } },
    })
  end
end
return M
