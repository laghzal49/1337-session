-- Immutable offline generations; only the small manifest is checked per lookup.
local M = { max_manifest_bytes = 65536, max_index_bytes = 16 * 1024 * 1024, max_page_bytes = 1024 * 1024 }
local cache, manifest_cache, manifest_stamp = {}, nil, nil
local data_dir
local filetypes = { python = 'python', c = 'c', cpp = 'cpp', lua = 'lua',
  sh = 'bash', bash = 'bash', zsh = 'bash', cmake = 'cmake' }

function M.normalize(name)
  return type(name) == 'string' and name:match('^%s*(.-)%s*$'):gsub('%(%)$', '') or ''
end

function M.root()
  return data_dir or vim.g.black_docs_path or (vim.fn.stdpath('data') .. '/perfect-black/docs')
end

local function relative(path)
  if type(path) ~= 'string' or #path == 0 or #path > 4096 or path:sub(1, 1) == '/'
    or path:find('[%z\1-\31]') or path:find('\\', 1, true) or path:find(':', 1, true) then return false end
  for part in path:gmatch('[^/]+') do if part == '.' or part == '..' then return false end end
  return not path:find('//', 1, true)
end

local function within(path)
  local root, actual = vim.uv.fs_realpath(M.root()), vim.uv.fs_realpath(path)
  return root and actual and actual:sub(1, #root + 1) == root .. '/'
end

local function read_json(path, max_bytes)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'file' or stat.size > max_bytes or not within(path) then return end
  local file = io.open(path, 'rb')
  if not file then return end
  local text = file:read(max_bytes + 1)
  file:close()
  if not text or #text > max_bytes then return end
  local ok, result = pcall(vim.json.decode, text)
  if ok and type(result) == 'table' then return result end
end

function M.invalidate()
  cache, manifest_cache, manifest_stamp = {}, nil, nil
end

function M.setup(opts)
  opts = opts or {}
  data_dir = opts.data_dir
  if opts.max_page_bytes then M.max_page_bytes = opts.max_page_bytes end
  M.invalidate()
end

function M.manifest()
  local path = M.root() .. '/manifest.json'
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.size > M.max_manifest_bytes then manifest_cache, manifest_stamp = nil, nil; return end
  local stamp = table.concat({ M.root(), stat.ino or 0, stat.size, stat.mtime.sec, stat.mtime.nsec }, ':')
  if stamp == manifest_stamp then return manifest_cache end
  local result = read_json(path, M.max_manifest_bytes)
  if not result or result.schema ~= 1 or type(result.docsets) ~= 'table' then return end
  for name, set in pairs(result.docsets) do
    if type(name) ~= 'string' or not name:match('^[%w_-]+$') or type(set) ~= 'table'
      or not relative(set.root) or not set.root:match('^sets/' .. name .. '/[^/]+$')
      or type(set.slug) ~= 'string' or not set.slug:match('^[%w_~%.%-]+$')
      or type(set.lang) ~= 'string' or not set.lang:match('^[%w_-]+$') then return end
    for _, field in ipairs({ 'entries', 'pages', 'bytes', 'updated_at' }) do
      if type(set[field]) ~= 'number' or set[field] < 0 or set[field] % 1 ~= 0 then return end
    end
  end
  -- Shell updates publish a new generation too; release superseded indices.
  cache = {}
  manifest_cache, manifest_stamp = result, stamp
  return result
end

function M.docset_for(ft)
  return filetypes[ft]
end

function M.installed()
  local result = M.manifest()
  local names = result and vim.tbl_keys(result.docsets) or {}
  table.sort(names)
  return names
end

function M.load_index(docset)
  local manifest = M.manifest()
  local set = manifest and manifest.docsets[docset]
  if not set then return end
  local root = M.root() .. '/' .. set.root
  if cache[root] ~= nil then return cache[root] or nil end
  local result = read_json(root .. '/index.json', M.max_index_bytes)
  if not result or type(result.entries) ~= 'table' or not vim.islist(result.entries)
    or type(result.exact) ~= 'table' or type(result.suffix) ~= 'table' then cache[root] = false; return end
  for _, entry in ipairs(result.entries) do
    local path = type(entry) == 'table' and entry.path
    if type(entry) ~= 'table' or type(entry.name) ~= 'string' or #entry.name == 0 or #entry.name > 1024
      or not relative(type(path) == 'string' and path:gsub('#.*$', '') or nil) then cache[root] = false; return end
  end
  for _, map in ipairs({ result.exact, result.suffix }) do
    for key, position in pairs(map) do
      if type(key) ~= 'string' or #key > 1024 or (position ~= false and
        (type(position) ~= 'number' or position % 1 ~= 0 or not result.entries[position])) then cache[root] = false; return end
    end
  end
  cache[root] = result
  return result
end

function M.find_entry(docset, word)
  local index = M.load_index(docset)
  if not index then return end
  local key = M.normalize(word)
  if key == '' then return end
  local exact = index.exact[key]
  if not exact and docset == 'cpp' and not key:find('::', 1, true) then exact = index.exact['std::' .. key] end
  if exact then return index.entries[exact] end
  -- A qualified suffix may resolve only when publication proved it unique.
  -- Bare Python member words intentionally remain ambiguous.
  if key:find('.', 1, true) or docset == 'cpp' then
    local unique = index.suffix[key]
    if unique then return index.entries[unique] end
  end
end

function M.page_lines(docset, path)
  local manifest = M.manifest()
  local set = manifest and manifest.docsets[docset]
  local bare = type(path) == 'string' and path:gsub('#.*$', '')
  if not set or not relative(bare) then return nil, 'Offline documentation page path is invalid' end
  local file = M.root() .. '/' .. set.root .. '/pages/' .. bare .. '.md'
  local stat = vim.uv.fs_stat(file)
  if not stat or stat.type ~= 'file' or not within(file) then return nil, 'Offline page missing; run :DocsUpdate ' .. docset end
  if stat.size > M.max_page_bytes then return nil, 'Documentation page exceeds the configured size limit' end
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then return nil, 'Offline documentation page could not be read' end
  return lines, nil, 'https://devdocs.io/' .. set.slug .. '/' .. path
end

return M
