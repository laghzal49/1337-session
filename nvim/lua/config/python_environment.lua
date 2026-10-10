-- Resolve standalone-script user packages without blocking Neovim's UI.
local M = {}
local cache, waiting, roots = {}, {}, {}
local overrides = {}
local markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pytest.ini", "Pipfile", "poetry.lock", "uv.lock", ".git" }

function M.project_root(buf)
  local project = vim.fs.root(buf, markers)
  local root = project or vim.fn.getcwd()
  return vim.uv.fs_realpath(root) or root, project
end

local function named_buffer(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if vim.api.nvim_buf_get_name(buf) == '' then
    -- Python servers need stable file URIs, including across document renames.
    if not vim.b[buf].black_python_waiting_for_name then
      vim.b[buf].black_python_waiting_for_name = true
      vim.api.nvim_create_autocmd('BufFilePost', { buffer = buf, once = true, callback = function()
        vim.b[buf].black_python_waiting_for_name = nil
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == 'python'
            and (vim.lsp.is_enabled('ruff') or vim.lsp.is_enabled('ty')) then
            vim.api.nvim_exec_autocmds('FileType', { group = 'nvim.lsp.enable', buffer = buf, modeline = false })
          end
        end)
      end })
    end
    return false
  end
  return true
end

function M.ruff_root_dir(buf, on_dir)
  if named_buffer(buf) then on_dir(M.project_root(buf)) end
end

function M.interpreter(root)
  root = root or M.project_root(0)
  if overrides[root] then return overrides[root], 'project override' end
  if type(vim.g.python_lsp_python) == 'string' and vim.g.python_lsp_python ~= '' then
    return vim.g.python_lsp_python, 'configured override'
  end
  -- Match ty's native precedence; do not override a project's ty.toml settings.
  for _, entry in ipairs({ { vim.env.VIRTUAL_ENV, 'active virtualenv' }, { vim.env.CONDA_PREFIX, 'active Conda' },
    { root .. '/.venv', 'project .venv' } }) do
    if entry[1] and vim.fn.executable(entry[1] .. '/bin/python') == 1 then
      return entry[1] .. '/bin/python', entry[2]
    end
  end
  return vim.fn.exepath('python3'), 'PATH (ty may override this from project configuration)'
end

function M.set_interpreter(root, path)
  if path and vim.fn.executable(path) ~= 1 then return false, 'Python interpreter is not executable: ' .. path end
  overrides[root] = path
  return true
end

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
  if not named_buffer(buf) then return end
  local root, project = M.project_root(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local cwd = vim.fn.getcwd()
  if (project and project ~= vim.fn.expand("~")) or vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
    or vim.fn.isdirectory(root .. "/.venv") == 1 then
    roots[root] = false
    on_dir(root)
    return
  end
  M.user_site(function(path)
    if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_name(buf) ~= name
      or (not project and vim.fn.getcwd() ~= cwd) then return end
    roots[root] = path or false
    on_dir(root)
  end)
end

function M.before_init(_, config)
  config.settings = vim.deepcopy(config.settings or {})
  config._python_base_settings = vim.deepcopy(config.settings)
  local explicit = overrides[config.root_dir] or vim.g.python_lsp_python
  if type(explicit) == 'string' and explicit ~= '' then
    config.settings.ty = vim.tbl_deep_extend('force', config.settings.ty or {}, {
      configuration = { environment = { python = explicit } },
    })
    return
  end
  local path = roots[config.root_dir]
  if path then
    config.settings = config.settings or {}
    config.settings.ty = vim.tbl_deep_extend("force", config.settings.ty or {}, {
      configuration = { environment = { ["extra-paths"] = { path } } },
    })
  end
end
return M
