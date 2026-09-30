-- 1337 Station Mode — Automated environment management for 1337 / 42 cluster machines.
-- Handles NFS home quota limits, local /goinfre workstation storage, broken symlinks
-- across workstation changes, uv caches, tool availability, and safe local repairs.

local M = {}
local detected_station

M.state = {
  active = false,
  running = false,
  last_check = 0,
  problems_count = 0,
  items = {},
  current_station = '',
  prev_station = '',
  station_changed = false,
  goinfre_base = nil,
  goinfre_user = nil,
}

-- ── 1337 Environment Detection ───────────────────────────────────────────────
function M.is_1337()
  if vim.g.station_1337 ~= nil then return vim.g.station_1337 end
  if vim.env.STATION_1337 == '1' then return true end
  if detected_station ~= nil then return detected_station end

  -- Cluster local scratch filesystems
  if vim.fn.isdirectory('/goinfre') == 1 or vim.fn.isdirectory('/sgoinfre') == 1 then detected_station = true; return true end
  if vim.uv.fs_lstat(vim.fn.expand('~/goinfre')) ~= nil then detected_station = true; return true end

  -- Cluster hostname naming conventions (e.g. c1r2p3, f2r4p1, 1337-*, 42-*)
  local host = (vim.uv.os_gethostname() or ''):lower()
  if host:match('^[cbfzer]%d+r%d+p%d+') or host:match('1337') or host:match('42') then detected_station = true; return true end

  -- User login matching 1337 cluster usernames
  local user = vim.env.USER or ''
  if user == 'tlaghzal' then detected_station = true; return true end

  -- Check if config repo or active workspace is 1337-session
  local config_dir = vim.fn.stdpath('config')
  if config_dir:find('1337') then detected_station = true; return true end

  local ok, remote = pcall(vim.fn.system, { 'git', '-C', config_dir, 'remote', '-v' })
  detected_station = ok and type(remote) == 'string' and remote:find('1337%-session') ~= nil or false
  return detected_station
end

-- ── Workstation Tracking ─────────────────────────────────────────────────────
local function get_state_file()
  local state_dir = vim.fn.stdpath('state')
  if vim.fn.isdirectory(state_dir) == 0 then vim.fn.mkdir(state_dir, 'p') end
  return state_dir .. '/1337_station'
end

local function track_workstation()
  local current = vim.uv.os_gethostname() or 'unknown'
  M.state.current_station = current

  local state_file = get_state_file()
  local prev = ''
  local f = io.open(state_file, 'r')
  if f then
    prev = vim.trim(f:read('*a') or '')
    f:close()
  end

  M.state.prev_station = prev
  if prev ~= '' and prev ~= current then
    M.state.station_changed = true
  else
    M.state.station_changed = false
  end

  -- Record current workstation
  local fw = io.open(state_file, 'w')
  if fw then
    fw:write(current)
    fw:close()
  end
end

-- ── Local /goinfre Paths ─────────────────────────────────────────────────────
function M.get_goinfre_paths()
  local user = vim.env.USER or 'user'
  local base = nil
  if vim.fn.isdirectory('/goinfre') == 1 then
    base = '/goinfre'
  elseif vim.fn.isdirectory('/sgoinfre') == 1 then
    base = '/sgoinfre'
  elseif vim.fn.isdirectory(vim.fn.expand('~/goinfre')) == 1 then
    base = vim.fn.expand('~/goinfre')
  end

  local user_dir = nil
  if base then
    if base == vim.fn.expand('~/goinfre') then
      user_dir = base
    else
      user_dir = base .. '/' .. user
    end
  end

  M.state.goinfre_base = base
  M.state.goinfre_user = user_dir
  return base, user_dir
end

-- ── Async Check Implementation ───────────────────────────────────────────────
function M.check(callback)
  if M.state.running then return end
  M.state.running = true
  track_workstation()

  local items = {}
  local home = vim.fn.expand('~')
  local cwd = require('config.project').root() or vim.uv.cwd() or vim.fn.getcwd()

  -- 1. HOME Quota and Inodes
  local function check_quota(done)
    vim.system({ 'df', '-Pk', home }, { text = true }, function(df_res)
      vim.system({ 'df', '-iPk', home }, { text = true }, function(dfi_res)
        vim.schedule(function()
          local quota_status = 'ok'
          local quota_details = ''
          local pct = 0

          if df_res.code == 0 and df_res.stdout then
            local lines = vim.split(df_res.stdout, '\n')
            if #lines >= 2 then
              local parts = vim.split(lines[2], '%s+')
              if #parts >= 6 then
                local total_k = tonumber(parts[2]) or 0
                local used_k = tonumber(parts[3]) or 0
                local avail_k = tonumber(parts[4]) or 0
                local pct_str = parts[5]:gsub('%%', '')
                pct = tonumber(pct_str) or 0

                local function human(kb)
                  if kb >= 1048576 then return string.format('%.1fG', kb / 1048576) end
                  if kb >= 1024 then return string.format('%.0fM', kb / 1024) end
                  return kb .. 'K'
                end

                quota_details = human(used_k) .. ' / ' .. human(total_k) .. ' (' .. pct .. '% used)'
                if pct >= 95 then
                  quota_status = 'error'
                  quota_details = 'CRITICAL ' .. pct .. '% (' .. human(avail_k) .. ' left)'
                elseif pct >= 85 then
                  quota_status = 'warn'
                  quota_details = 'WARNING ' .. pct .. '% (' .. human(avail_k) .. ' left)'
                end
              end
            end
          end

          -- Inode check
          if dfi_res.code == 0 and dfi_res.stdout then
            local ilines = vim.split(dfi_res.stdout, '\n')
            if #ilines >= 2 then
              local iparts = vim.split(ilines[2], '%s+')
              if #iparts >= 6 and iparts[5] ~= '-' then
                local ipct = tonumber(iparts[5]:gsub('%%', '')) or 0
                if ipct >= 90 then
                  quota_status = 'error'
                  quota_details = quota_details .. ' · Inodes ' .. ipct .. '%!'
                end
              end
            end
          end

          items[#items + 1] = {
            id = 'home_quota',
            label = 'HOME quota',
            status = quota_status,
            details = quota_details ~= '' and quota_details or 'available',
          }
          done()
        end)
      end)
    end)
  end

  -- 2. Local /goinfre directory
  local function check_goinfre(done)
    local base, user_dir = M.get_goinfre_paths()
    if not base then
      items[#items + 1] = {
        id = 'goinfre',
        label = '/goinfre',
        status = 'info',
        details = 'no /goinfre partition (non-cluster workstation)',
      }
      done()
      return
    end

    local stat = user_dir and vim.uv.fs_stat(user_dir) or nil
    if not stat then
      items[#items + 1] = {
        id = 'goinfre',
        label = '/goinfre',
        status = 'error',
        details = 'missing ' .. (user_dir or base) .. ' (press [f] to create)',
        fixable = true,
      }
      done()
      return
    end

    -- Check free space on /goinfre
    vim.system({ 'df', '-Pk', user_dir }, { text = true }, function(res)
      vim.schedule(function()
        local free_str = ''
        if res.code == 0 and res.stdout then
          local lines = vim.split(res.stdout, '\n')
          if #lines >= 2 then
            local parts = vim.split(lines[2], '%s+')
            if #parts >= 6 then
              local avail_k = tonumber(parts[4]) or 0
              if avail_k >= 1048576 then
                free_str = string.format('%.0fG free', avail_k / 1048576)
              else
                free_str = string.format('%.0fM free', avail_k / 1024)
              end
            end
          end
        end
        items[#items + 1] = {
          id = 'goinfre',
          label = '/goinfre',
          status = 'ok',
          details = (user_dir:gsub('^/goinfre/', '') .. ' ready') .. (free_str ~= '' and (' (' .. free_str .. ')') or ''),
        }
        done()
      end)
    end)
  end

  -- 3. Project .venv symlink / state
  local function check_venv(done)
    local venv_path = cwd .. '/.venv'
    local lstat = vim.uv.fs_lstat(venv_path)

    local is_python = vim.fn.glob(cwd .. '/*.py') ~= ''
      or vim.uv.fs_stat(cwd .. '/pyproject.toml') ~= nil
      or vim.uv.fs_stat(cwd .. '/requirements.txt') ~= nil
      or vim.uv.fs_stat(cwd .. '/ty.toml') ~= nil

    if not lstat then
      if is_python then
        items[#items + 1] = {
          id = 'venv',
          label = '.venv symlink',
          status = 'error',
          details = 'missing (press [v] to build with uv)',
          fixable = true,
        }
      else
        items[#items + 1] = {
          id = 'venv',
          label = '.venv symlink',
          status = 'info',
          details = 'none (non-Python project)',
        }
      end
      done()
      return
    end

    if lstat.type == 'link' then
      local target = vim.uv.fs_readlink(venv_path) or 'unknown'
      local real = vim.uv.fs_realpath(venv_path)
      if not real then
        items[#items + 1] = {
          id = 'venv',
          label = '.venv symlink',
          status = 'error',
          details = 'broken -> ' .. target,
          fixable = true,
        }
      else
        if real:find('^/goinfre') or real:find('^/sgoinfre') then
          items[#items + 1] = {
            id = 'venv',
            label = '.venv symlink',
            status = 'ok',
            details = 'local (/goinfre)',
          }
        else
          items[#items + 1] = {
            id = 'venv',
            label = '.venv symlink',
            status = 'warn',
            details = 'points inside NFS: ' .. vim.fn.fnamemodify(real, ':~'),
            fixable = true,
          }
        end
      end
    elseif lstat.type == 'directory' then
      if venv_path:find('^' .. vim.pesc(home)) then
        items[#items + 1] = {
          id = 'venv',
          label = '.venv symlink',
          status = 'warn',
          details = 'stored on NFS ($HOME) — eats quota! [v] moves to /goinfre',
          fixable = true,
        }
      else
        items[#items + 1] = {
          id = 'venv',
          label = '.venv symlink',
          status = 'ok',
          details = 'local directory',
        }
      end
    end
    done()
  end

  -- 4. uv Cache Location
  local function check_uv_cache(done)
    local uv_cache = vim.env.UV_CACHE_DIR
    local base, _ = M.get_goinfre_paths()

    if not uv_cache or uv_cache == '' then
      items[#items + 1] = {
        id = 'uv_cache',
        label = 'uv cache',
        status = base and 'warn' or 'ok',
        details = base and 'unset (defaults to NFS ~/.cache/uv) [f] fixes' or 'default (~/.cache/uv)',
        fixable = base ~= nil,
      }
      done()
      return
    end

    if uv_cache:find('^/goinfre') or uv_cache:find('^/sgoinfre') then
      local exists = vim.fn.isdirectory(uv_cache) == 1
      if exists then
        items[#items + 1] = {
          id = 'uv_cache',
          label = 'uv cache',
          status = 'ok',
          details = uv_cache,
        }
      else
        items[#items + 1] = {
          id = 'uv_cache',
          label = 'uv cache',
          status = 'warn',
          details = 'dir missing on this station: ' .. uv_cache,
          fixable = true,
        }
      end
    else
      items[#items + 1] = {
        id = 'uv_cache',
        label = 'uv cache',
        status = 'warn',
        details = 'on NFS: ' .. vim.fn.fnamemodify(uv_cache, ':~'),
        fixable = base ~= nil,
      }
    end
    done()
  end

  -- 5. Core Tools (ty, ruff, clangd, rg, lazygit)
  local function check_tools(done)
    local tool_names = { 'ty', 'ruff', 'clangd', 'rg', 'lazygit' }
    for _, name in ipairs(tool_names) do
      local path = vim.fn.exepath(name)
      if path ~= '' then
        items[#items + 1] = {
          id = 'tool_' .. name,
          label = name,
          status = 'ok',
          details = path,
        }
      else
        items[#items + 1] = {
          id = 'tool_' .. name,
          label = name,
          status = 'error',
          details = 'missing from PATH',
          fixable = true,
        }
      end
    end
    done()
  end

  -- 6. Other Broken Symlinks in Project Root
  local function check_broken_symlinks(done)
    local broken = {}
    local handle = vim.uv.fs_scandir(cwd)
    if handle then
      while true do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if ftype == 'link' and name ~= '.venv' then
          local full = cwd .. '/' .. name
          if not vim.uv.fs_realpath(full) then
            local target = vim.uv.fs_readlink(full) or 'unknown'
            broken[#broken + 1] = name .. ' -> ' .. target
          end
        end
      end
    end
    if #broken > 0 then
      items[#items + 1] = {
        id = 'broken_links',
        label = 'Broken links',
        status = 'error',
        details = table.concat(broken, ', '),
      }
    end
    done()
  end

  -- 7. Heavy NFS Caches in $HOME
  local function check_nfs_caches(done)
    local culprits = {
      { path = home .. '/.cache/uv', name = '~/.cache/uv' },
      { path = home .. '/.cache/pip', name = '~/.cache/pip' },
      { path = home .. '/.cargo/registry', name = '~/.cargo' },
      { path = home .. '/.npm', name = '~/.npm' },
    }
    local nfs_found = {}
    for _, c in ipairs(culprits) do
      local lstat = vim.uv.fs_lstat(c.path)
      if lstat and lstat.type == 'directory' then
        nfs_found[#nfs_found + 1] = c.name
      end
    end
    if #nfs_found > 0 and cwd:find('^' .. vim.pesc(home)) then
      items[#items + 1] = {
        id = 'nfs_caches',
        label = 'NFS Caches',
        status = 'warn',
        details = table.concat(nfs_found, ', ') .. ' on NFS quota',
      }
    end
    done()
  end

  -- 8. Project Location (NFS vs Local SSD)
  local function check_project(done)
    local is_nfs = cwd:find('^' .. vim.pesc(home))
    local is_goinfre = cwd:find('^/goinfre') or cwd:find('^/sgoinfre')

    if is_goinfre then
      items[#items + 1] = {
        id = 'project_loc',
        label = 'Project Location',
        status = 'ok',
        details = 'local SSD (' .. vim.fn.fnamemodify(cwd, ':t') .. ')',
      }
    elseif is_nfs then
      items[#items + 1] = {
        id = 'project_loc',
        label = 'Project Location',
        status = 'info',
        details = 'NFS (~/' .. vim.fn.fnamemodify(cwd, ':~:.') .. ')',
      }
    else
      items[#items + 1] = {
        id = 'project_loc',
        label = 'Project Location',
        status = 'info',
        details = cwd,
      }
    end
    done()
  end

  -- Sequence runner
  local tasks = {
    check_quota,
    check_goinfre,
    check_venv,
    check_uv_cache,
    check_tools,
    check_broken_symlinks,
    check_nfs_caches,
    check_project,
  }
  local idx = 1
  local function run_next()
    if idx > #tasks then
      M.state.items = items
      M.state.last_check = vim.uv.now()
      M.state.running = false

      -- Count problems (status == 'error' or status == 'warn')
      local count = 0
      for _, it in ipairs(items) do
        if it.status == 'error' or it.status == 'warn' then
          count = count + 1
        end
      end
      M.state.problems_count = count

      if callback then callback(items, count) end
      return
    end
    local current_task = tasks[idx]
    idx = idx + 1
    current_task(run_next)
  end

  run_next()
end

-- ── Status Indicators ────────────────────────────────────────────────────────
function M.problem_count()
  return M.state.problems_count or 0
end

function M.status_text()
  if not M.is_1337() then return '' end
  local count = M.state.problems_count or 0
  if count == 0 then
    return '1337 ✓'
  elseif count == 1 then
    return '1337 ⚠ 1 problem'
  else
    return '1337 ⚠ ' .. count .. ' problems'
  end
end

-- ── Safe Repairs ([f] / :StationFix) ──────────────────────────────────────────
function M.fix_safe()
  local fixes_done = {}
  local user = vim.env.USER or 'user'
  local home = vim.fn.expand('~')
  local base, user_dir = M.get_goinfre_paths()

  -- 1. Create /goinfre/$USER if partition exists
  if base and user_dir and vim.fn.isdirectory(user_dir) == 0 then
    local ok = pcall(vim.fn.mkdir, user_dir, 'p', 448) -- 0700
    if ok then
      fixes_done[#fixes_done + 1] = 'Created local directory ' .. user_dir
    end
  end

  -- 2. Link ~/goinfre -> /goinfre/$USER if appropriate
  if user_dir and vim.fn.isdirectory(user_dir) == 1 then
    local home_link = home .. '/goinfre'
    local lstat = vim.uv.fs_lstat(home_link)
    if not lstat then
      local ok = pcall(vim.uv.fs_symlink, user_dir, home_link)
      if ok then fixes_done[#fixes_done + 1] = 'Linked ~/goinfre -> ' .. user_dir end
    elseif lstat.type == 'link' and not vim.uv.fs_realpath(home_link) then
      vim.uv.fs_unlink(home_link)
      vim.uv.fs_symlink(user_dir, home_link)
      fixes_done[#fixes_done + 1] = 'Repaired ~/goinfre symlink'
    end
  end

  -- 3. Set UV_CACHE_DIR to /goinfre/$USER/.uv_cache
  if user_dir and vim.fn.isdirectory(user_dir) == 1 then
    local target_cache = user_dir .. '/.uv_cache'
    if vim.fn.isdirectory(target_cache) == 0 then
      vim.fn.mkdir(target_cache, 'p')
    end
    vim.env.UV_CACHE_DIR = target_cache
    fixes_done[#fixes_done + 1] = 'Set UV_CACHE_DIR=' .. target_cache
  end

  -- 4. Ensure ~/.local/bin in PATH
  local local_bin = home .. '/.local/bin'
  if vim.fn.isdirectory(local_bin) == 1 and not (vim.env.PATH or ''):find(vim.pesc(local_bin)) then
    vim.env.PATH = local_bin .. ':' .. (vim.env.PATH or '')
    fixes_done[#fixes_done + 1] = 'Added ~/.local/bin to PATH'
  end

  if #fixes_done > 0 then
    vim.notify(table.concat(fixes_done, '\n'), vim.log.levels.INFO, { title = '1337 Station Repairs' })
  else
    vim.notify('No automatic safe repairs needed.', vim.log.levels.INFO, { title = '1337 Station' })
  end

  -- Re-run check
  M.check(function()
    pcall(function()
      local win = vim.g.station_health_win
      if win and vim.api.nvim_win_is_valid(win) then
        M.health()
      end
    end)
  end)
end

-- ── Rebuild Virtualenv ([v] / :StationVenv) ──────────────────────────────────
function M.rebuild_venv()
  local cwd = require('config.project').root() or vim.uv.cwd() or vim.fn.getcwd()
  local user = vim.env.USER or 'user'
  local proj_name = vim.fn.fnamemodify(cwd, ':t')
  local venv_path = cwd .. '/.venv'

  local _, user_dir = M.get_goinfre_paths()
  local target_venv = nil

  if user_dir and vim.fn.isdirectory(user_dir) == 1 then
    local venvs_root = user_dir .. '/venvs'
    if vim.fn.isdirectory(venvs_root) == 0 then vim.fn.mkdir(venvs_root, 'p') end
    target_venv = venvs_root .. '/' .. proj_name
  else
    target_venv = venv_path
  end

  -- Handle existing .venv link or folder
  local lstat = vim.uv.fs_lstat(venv_path)
  if lstat and lstat.type == 'link' then
    vim.uv.fs_unlink(venv_path)
  end

  -- If using local goinfre, establish symlink first
  if target_venv ~= venv_path then
    if vim.fn.isdirectory(target_venv) == 0 then vim.fn.mkdir(target_venv, 'p') end
    pcall(vim.uv.fs_symlink, target_venv, venv_path)
  end

  -- Build uv command
  local cmd = 'uv venv ' .. vim.fn.shellescape(target_venv)
  if vim.uv.fs_stat(cwd .. '/pyproject.toml') ~= nil then
    cmd = cmd .. ' && uv sync'
  elseif vim.uv.fs_stat(cwd .. '/requirements.txt') ~= nil then
    cmd = cmd .. ' && uv pip install -r requirements.txt'
  end

  vim.notify('Building venv with uv in terminal...', vim.log.levels.INFO, { title = '1337 Station' })

  if pcall(require, 'snacks') and Snacks.terminal then
    Snacks.terminal(cmd, {
      cwd = cwd,
      win = {
        title = ' 󰌠 1337 Station · uv venv build ',
        title_pos = 'center',
      },
    })
  else
    vim.cmd('botright split | terminal cd ' .. vim.fn.shellescape(cwd) .. ' && ' .. cmd)
  end
end

-- ── Tool Installer ([t] / :StationTools) ─────────────────────────────────────
function M.install_tools()
  local installer = vim.fn.expand('~/Projects/1337-session/install.sh')
  if vim.uv.fs_stat(installer) == nil then
    installer = vim.fn.stdpath('config') .. '/../install.sh'
  end

  if vim.uv.fs_stat(installer) ~= nil then
    if pcall(require, 'snacks') and Snacks.terminal then
      Snacks.terminal('bash ' .. vim.fn.shellescape(installer), {
        win = { title = ' 󰒓 1337 Station Installer ', title_pos = 'center' },
      })
    else
      vim.cmd('botright split | terminal bash ' .. vim.fn.shellescape(installer))
    end
  else
    vim.notify('Installer not found at ~/Projects/1337-session/install.sh', vim.log.levels.WARN)
  end
end

-- ── Interactive Health Modal UI ──────────────────────────────────────────────
function M.health()
  M.check(function(items, _)
    local width = 68
    local host = M.state.current_station ~= '' and M.state.current_station or vim.uv.os_gethostname() or 'unknown'

    local lines = {}
    local hl_map = {} -- { line_idx = { { col_start, col_end, group } } }

    lines[#lines + 1] = ''

    if M.state.station_changed then
      lines[#lines + 1] = string.format('  ⚠ WORKSTATION CHANGED: %s → %s', M.state.prev_station, host)
      hl_map[#lines] = { { 2, #lines[#lines], 'DiagnosticWarn' } }
      lines[#lines + 1] = '  Local /goinfre and venvs may need re-linking.'
      hl_map[#lines] = { { 2, #lines[#lines], 'BlackMuted' } }
      lines[#lines + 1] = ''
    end

    -- Render each status item
    for _, it in ipairs(items) do
      local icon_char = '✓'
      local icon_hl = 'MiniIconsGreen'
      if it.status == 'error' then
        icon_char = '✗'
        icon_hl = 'MiniIconsRed'
      elseif it.status == 'warn' then
        icon_char = '⚠'
        icon_hl = 'MiniIconsYellow'
      elseif it.status == 'info' then
        icon_char = 'ℹ'
        icon_hl = 'MiniIconsAzure'
      end

      local label = it.label
      local line = string.format('  %-18s %s  %s', label, icon_char, it.details)
      lines[#lines + 1] = line

      -- Highlight positions
      local icon_start = 21
      local icon_end = icon_start + #icon_char
      hl_map[#lines] = {
        { 2, 20, 'BlackLabel' },
        { icon_start, icon_end, icon_hl },
        { icon_end + 2, #line, it.status == 'error' and 'DiagnosticError' or (it.status == 'warn' and 'DiagnosticWarn' or 'BlackDocs') },
      }
    end

    lines[#lines + 1] = ''
    lines[#lines + 1] = '  ' .. string.rep('─', width - 6)
    hl_map[#lines] = { { 2, #lines[#lines], 'BlackDocsBorder' } }
    lines[#lines + 1] = '  Actions:'
    hl_map[#lines] = { { 2, 10, 'BlackBrand' } }

    local actions = {
      { key = 'f', desc = 'Fix safe issues (create /goinfre/$USER, link, cache)' },
      { key = 'v', desc = 'Rebuild project .venv on local /goinfre with uv' },
      { key = 't', desc = 'Install / restore missing tools (install.sh)' },
      { key = 'r', desc = 'Recheck station health' },
      { key = 'q', desc = 'Close' },
    }

    for _, act in ipairs(actions) do
      local line = string.format('   [%s] %s', act.key, act.desc)
      lines[#lines + 1] = line
      hl_map[#lines] = {
        { 3, 6, 'BlackKey' },
        { 7, #line, 'BlackDocs' },
      }
    end

    lines[#lines + 1] = ''

    -- Create floating buffer & window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].modifiable = false

    local row = math.max(2, math.floor((vim.o.lines - #lines) / 2))
    local col = math.max(4, math.floor((vim.o.columns - width) / 2))

    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = width,
      height = #lines,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      title = ' 󰒓 1337 STATION HEALTH (' .. host .. ') ',
      title_pos = 'center',
    })

    vim.wo[win].winhighlight = 'Normal:BlackDocs,FloatBorder:BlackDocsBorder,FloatTitle:BlackDocsTitle'
    vim.g.station_health_win = win

    -- Apply highlight ranges
    local ns = vim.api.nvim_create_namespace('station_health_modal')
    for line_idx, ranges in pairs(hl_map) do
      for _, r in ipairs(ranges) do
        pcall(vim.api.nvim_buf_add_highlight, buf, ns, r[3], line_idx - 1, r[1], r[2])
      end
    end

    -- Keymaps inside the modal
    local function close()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end

    local bmap = function(key, fn)
      vim.keymap.set('n', key, fn, { buffer = buf, silent = true, nowait = true })
    end

    bmap('q', close)
    bmap('<Esc>', close)
    bmap('r', function()
      close()
      M.health()
    end)
    bmap('f', function()
      close()
      M.fix_safe()
    end)
    bmap('v', function()
      close()
      M.rebuild_venv()
    end)
    bmap('t', function()
      close()
      M.install_tools()
    end)
  end)
end

-- ── Startup Initialization (Deferred & Non-Blocking) ─────────────────────────
function M.init()
  if not M.is_1337() then return end
  M.state.active = true
  M.get_goinfre_paths()

  -- Perform background health scan after UI is up
  M.check(function(_, problems_count)
    if problems_count > 0 then
      vim.schedule(function()
        local msg = string.format('1337 Station: %d environment problem%s detected.\nPress <leader>13 or :StationHealth to inspect and fix.',
          problems_count, problems_count == 1 and '' or 's')
        vim.notify(msg, vim.log.levels.WARN, { title = '1337 Station Mode' })
      end)
    end
  end)
end

return M
