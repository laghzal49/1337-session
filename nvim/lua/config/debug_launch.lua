-- Project-scoped launches and a small, contextual debugger control menu.
local M = {}
local last, selected, pending = {}, {}, {}
local function notify(message) vim.notify(message, vim.log.levels.WARN, { title = 'Debugger' }) end

function M.context()
  return { root = require('config.project').root(), buf = vim.api.nvim_get_current_buf(),
    file = vim.api.nvim_buf_get_name(0), ft = vim.bo.filetype }
end

-- Capture source placeholders before opening any picker or asynchronous prompt.
local function resolve(value, ctx)
  if type(value) == 'table' then
    local result = {}
    for key, item in pairs(value) do result[key] = resolve(item, ctx) end
    return result
  end
  if type(value) ~= 'string' then return value end
  local basename = vim.fs.basename(ctx.file)
  local relative = vim.fs.relpath(ctx.root, ctx.file) or ctx.file
  local values = { file = ctx.file, fileBasename = basename,
    fileBasenameNoExtension = vim.fn.fnamemodify(basename, ':r'),
    fileDirname = vim.fs.dirname(ctx.file), fileExtname = vim.fn.fnamemodify(basename, ':e'),
    relativeFile = relative, relativeFileDirname = vim.fs.dirname(relative),
    fileDirnameBasename = vim.fs.basename(vim.fs.dirname(ctx.file)),
    workspaceFolder = ctx.root, workspaceFolderBasename = vim.fs.basename(ctx.root) }
  return (value:gsub('%${([^}]+)}', function(key) return values[key] end))
end

-- Bounded discovery: never walk dependency trees or execute a candidate.
function M.executables(root)
  local result, seen, visited = {}, {}, 0
  local function scan(directory, depth)
    local iter = vim.uv.fs_scandir(directory)
    if not iter then return end
    while visited < 800 do
      local name, kind = vim.uv.fs_scandir_next(iter)
      if not name then break end
      visited = visited + 1
      local path = directory .. '/' .. name
      if kind == 'file' and vim.fn.executable(path) == 1 then
        local fd = vim.uv.fs_open(path, 'r', 0)
        local magic = fd and vim.uv.fs_read(fd, 4, 0)
        if fd then vim.uv.fs_close(fd) end
        if magic and (magic == '\127ELF' or magic:sub(1, 2) == 'MZ'
          or magic == '\207\250\237\254' or magic == '\254\237\250\207') and not seen[path] then
          seen[path], result[#result + 1] = true, path
        end
      elseif kind == 'directory' and depth > 0 and not name:match('^%.')
        and not vim.tbl_contains({ 'CMakeFiles', '_deps', 'node_modules', 'venv', 'vendor' }, name) then
        scan(path, depth - 1)
      end
    end
  end
  scan(root, 0)
  for _, name in ipairs({ 'build', 'bin', 'debug', 'Debug', 'cmake-build-debug' }) do scan(root .. '/' .. name, 2) end
  table.sort(result)
  return result
end

function M.executable(ctx, callback)
  local choices = M.executables(ctx.root)
  choices[#choices + 1] = 'Browse for executable…'
  vim.ui.select(choices, { prompt = 'Debug executable · ' .. vim.fs.basename(ctx.root),
    format_item = function(path) return vim.fs.relpath(ctx.root, path) or path end }, function(choice)
    if not choice then return end
    local function accept(path)
      if not path or path == '' then return end
      path = vim.fn.expand(path)
      if not vim.startswith(path, '/') then path = ctx.root .. '/' .. path end
      if vim.fn.executable(path) ~= 1 or vim.fn.isdirectory(path) == 1 then
        notify('Executable not found. Build with debug symbols (-g), then choose the compiled program.')
        return
      end
      callback(vim.fs.normalize(path))
    end
    if choice == choices[#choices] then
      vim.ui.input({ prompt = 'Compiled program (-g): ', default = ctx.root .. '/', completion = 'file' }, accept)
    else accept(choice) end
  end)
end

local function save_project(ctx, callback)
  local changed = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' and vim.bo[buf].modified
      and (buf == ctx.buf or vim.fs.relpath(ctx.root, name)) then changed[#changed + 1] = buf end
  end
  if #changed == 0 then callback(); return end
  vim.ui.select({ 'Save and debug', 'Cancel' }, {
    prompt = ('Debug · save %d modified project file%s?'):format(#changed, #changed == 1 and '' or 's'),
  }, function(choice)
    if choice ~= 'Save and debug' then return end
    for _, buf in ipairs(changed) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
        local ok, err = pcall(vim.api.nvim_buf_call, buf, function() vim.cmd.update() end)
        if not ok then notify('Could not save: ' .. tostring(err)); return end
      end
    end
    callback()
  end)
end

function M.run(config, ctx)
  ctx = ctx or M.context()
  if require('dap').session() then notify('A session is active. Stop it or use Restart from :Debug.'); return end
  if config.type == 'python' and config.program == '${file}' and ctx.ft ~= 'python' then
    notify('Open a Python source file for this profile, or choose a different target with :DebugTarget.'); return
  end
  local original = vim.deepcopy(config)
  config = resolve(config, ctx)
  if type(config.cwd) ~= 'string' then config.cwd = ctx.root end
  if not config.cwd:find('%${') and vim.fn.isdirectory(config.cwd) ~= 1 then
    notify('Working directory does not exist: ' .. config.cwd); return
  end
  if config.request == 'launch' and config.type == 'python' then
    if type(config.pythonPath) ~= 'string' then config.pythonPath = require('config.debugging').python(ctx.root) end
    if config.pythonPath == '' or vim.fn.executable(config.pythonPath) ~= 1 then
      notify('Python interpreter not found. Create a project .venv or set pythonPath in :DebugProjectEdit.'); return
    end
    if config.program and (type(config.program) ~= 'string' or config.program == '') then
      notify('Open a saved Python file before starting the debugger.'); return
    end
  end
  if config.type == 'gdb' and config.request == 'launch'
    and (type(config.program) ~= 'string' or vim.fn.executable(config.program) ~= 1) then
    M.executable(ctx, function(path)
      original.program = path
      M.run(original, ctx)
    end)
    return
  end
  save_project(ctx, function()
    if config.request == 'launch' and type(config.program) == 'string' and not config.program:find('%${')
      and vim.fn.filereadable(config.program) ~= 1 then
      notify('Program not found: ' .. config.program .. '. Choose a target with :Debug or edit :DebugProjectEdit.'); return
    end
    local function launch()
      if require('dap').session() then notify('Another debug session started while choosing this launch.'); return end
      last[ctx.root] = vim.deepcopy(config)
      pending[config.name] = { root = ctx.root, cwd = config.cwd }
      require('dap').run(config)
    end
    if config.type == 'python' and config.request == 'launch' and type(config.module) == 'string'
      and not config.module:find('%${') and not config.envFile and not config.cwd:find('%${') then
      vim.system({ config.pythonPath, '-c', 'import importlib.util,sys; sys.exit(0 if importlib.util.find_spec(sys.argv[1]) else 1)',
        config.module }, { cwd = config.cwd, env = config.env, text = true, timeout = 5000 }, vim.schedule_wrap(function(result)
        if result.code ~= 0 then
          notify('Module "' .. config.module .. '" is unavailable in ' .. config.pythonPath .. '. Install it in that environment or edit the launch profile.')
        else launch() end
      end))
    else launch() end
  end)
end

function M.start(choose)
  local dap = require('dap')
  if dap.session() then dap.continue(); return end
  local ctx = M.context()
  if ctx.file == '' or vim.bo.buftype ~= '' then notify('Open a source file, then press F5.'); return end
  local projects = require('config.debug_projects')
  local _, _, err = projects.ensure(ctx.root)
  if err then notify(err); return end
  local configs, read_err = projects.read(ctx.root)
  if read_err then notify(read_err .. '\nUse :DebugProjectEdit to fix the profile.'); return end
  if #configs == 0 then M.pick(); return end
  if not choose then
    for _, config in ipairs(configs) do
      if #configs == 1 or selected[ctx.root] == config.name then M.run(config, ctx); return end
    end
  end
  vim.ui.select(configs, { prompt = 'Debug project · ' .. vim.fs.basename(ctx.root),
    format_item = function(config) return config.name end }, function(config)
    if config then selected[ctx.root] = config.name; M.run(config, ctx) end
  end)
end

function M.pick()
  local ctx, choices = M.context(), {}
  local configs, err = require('config.debug_projects').read(ctx.root)
  if err then notify(err); return end
  for _, config in ipairs(configs) do choices[#choices + 1] = { label = 'Project · ' .. config.name, config = config } end
  for _, config in ipairs(require('dap').configurations[ctx.ft] or {}) do
    choices[#choices + 1] = { label = config.name, config = config }
  end
  if ctx.ft == 'python' and (vim.fs.basename(ctx.file):match('^test_') or ctx.file:match('_test%.py$')) then
    choices[#choices + 1] = { label = 'Python: pytest current file', config = {
      name = 'Python: pytest current file', type = 'python', request = 'launch', module = 'pytest',
      args = { ctx.file, '-s' }, cwd = ctx.root, console = 'integratedTerminal', justMyCode = true } }
  end
  if #choices == 0 then notify('Open a Python, C or C++ source file, or add a profile with :DebugProjectEdit.'); return end
  vim.ui.select(choices, { prompt = 'Debug target · ' .. vim.fs.basename(ctx.root),
    format_item = function(item) return item.label end }, function(item)
    if item then M.run(item.config, ctx) end
  end)
end

function M.rerun()
  if require('dap').session() then require('dap').restart(); return end
  local ctx = M.context()
  if last[ctx.root] then M.run(last[ctx.root], ctx) else M.start() end
end

function M.step(action)
  local dap = require('dap')
  if not dap.session() or not dap.session().stopped_thread_id then
    notify('Pause at a breakpoint before stepping. F5 starts or continues debugging.'); return
  end
  dap[action]()
end

function M.watch()
  local word = vim.bo.buftype == '' and vim.fn.expand('<cexpr>') or ''
  vim.ui.input({ prompt = 'Watch expression: ', default = word }, function(value)
    if not value or vim.trim(value) == '' then return end
    require('dapui').elements.watches.add(value)
    require('config.debug_panels').inspect('watches')
  end)
end

function M.menu()
  local dap, items = require('dap'), {}
  local session = dap.session()
  local function add(label, action) items[#items + 1] = { label = label, action = action } end
  if session then
    if session.stopped_thread_id then
      add('Continue  ·  F5', dap.continue)
      add('Step over  ·  F10', dap.step_over)
      add('Step into  ·  F11', dap.step_into)
      add('Step out  ·  F12', dap.step_out)
      add('Run to cursor  ·  Space DC', dap.run_to_cursor)
    else add('Pause execution', dap.pause) end
    add('Restart session  ·  Space DR', M.rerun)
    add('Stop session  ·  Shift F5', dap.terminate)
    add('Add watch expression  ·  Space Dw', M.watch)
    add('Variables', function() require('config.debug_panels').inspect('scopes') end)
    add('Call stack', function() require('config.debug_panels').inspect('stacks') end)
    add('Debug console', dap.repl.toggle)
  else
    add('Start project  ·  F5', M.start)
    add('Choose target / arguments  ·  Space Df', M.pick)
    if last[require('config.project').root()] then add('Rerun last target in this project  ·  Space Dl', M.rerun) end
    add('Edit project launch.json', function() require('config.debug_projects').edit() end)
    add('Validate project profiles', function() vim.cmd.DebugProjectCheck() end)
  end
  add('Toggle debugger panels  ·  Space Du', function() require('config.debug_panels').toggle() end)
  local state = session and ((session.stopped_thread_id and 'Paused' or 'Running') .. ' · ' .. session.config.name)
    or ('Ready · ' .. vim.fs.basename(require('config.project').root()))
  if vim.o.columns < 80 then state = session and (session.stopped_thread_id and 'Paused' or 'Running') or 'Ready' end
  vim.ui.select(items, { kind = 'debug', prompt = 'Debug · ' .. state, format_item = function(item) return item.label end }, function(item)
    if item then item.action() end
  end)
end

function M.setup()
  require('mini.pick') -- Install the shared popup selector on debugger first use.
  require('dap').listeners.after.event_initialized.black_launch_history = function(session)
    local owner = pending[session.config.name]
    if owner and session.config.cwd == owner.cwd then
      last[owner.root] = vim.deepcopy(session.config)
      pending[session.config.name] = nil
    end
  end
  for name, action in pairs({ Debug = M.menu, DebugStart = M.start, DebugTarget = M.pick,
    DebugRestart = M.rerun, DebugWatch = M.watch }) do
    vim.api.nvim_create_user_command(name, function() action() end, { desc = 'Debugger · ' .. name })
  end
end
return M
