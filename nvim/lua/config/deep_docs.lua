-- Offline reference surface: cached local indexes, native docs, one MiniPick.
local M = { max_display_lines = 200, max_history = 20 }
local store = require('config.docs_store')
local resolver = require('config.docs_resolver')
local picker_cache = setmetatable({}, { __mode = 'k' })

local function bounded(lines, message)
  if #lines <= M.max_display_lines then return lines end
  local selected, fence = {}, nil
  for row = 1, M.max_display_lines do
    local line = lines[row]
    selected[row] = line
    local marker = line:match('^%s*(```+)') or line:match('^%s*(~~~+)')
    if marker then
      if not fence then fence = marker
      elseif marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence then fence = nil end
    end
  end
  if fence then selected[#selected + 1] = fence end
  selected[#selected + 1], selected[#selected + 2] = '', message
  return selected
end

local function page(docset, entry)
  local lines, error_message, source = require('config.docs_store').page_lines(docset, entry.path)
  if not lines then return nil, error_message end
  local extracted, missing = false, false
  if entry.path:find('#', 1, true) then
    local stem = entry.name:gsub('%(%)$', '')
    local stems = { stem }
    local short = stem:match('([%w_]+%.[%w_]+)$')
    if short and short ~= stem then stems[#stems + 1] = short end
    local section, heading_level, declaration
    -- Prefer actual section/declaration starts over introductory mentions.
    local prefixes = docset == 'python' and { '^%*%*`', '^#+%s', '^`' } or { '^#+%s', '^%*%*`', '^`' }
    for _, prefix in ipairs(prefixes) do
      for _, candidate in ipairs(stems) do
        for row, line in ipairs(lines) do
          local first, last = line:find(candidate, 1, true)
          local before, after = first and line:sub(first - 1, first - 1), last and line:sub(last + 1, last + 1)
          if line:match(prefix) and first and not (before or ''):match('[%w_]') and not (after or ''):match('[%w_%.:]') then
            section, heading_level, declaration = row, #(line:match('^(#+)') or ''), line:match('^%*%*`') ~= nil
            break
          end
        end
        if section then break end
      end
      if section then break end
    end
    if section then
      local last = #lines
      for row = section + 1, #lines do
        local heading = lines[row]:match('^(#+)%s')
        if (heading and (heading_level == 0 or #heading <= heading_level))
          or (declaration and lines[row]:match('^%*%*`')) then last = row - 1; break end
      end
      local selected = {}
      for row = section, last do selected[#selected + 1] = lines[row] end
      lines, extracted = bounded(selected, '… This section continues in the full reference linked below.'), true
    else missing = true end
  end
  lines = bounded(lines, '… Showing the beginning of this manual; the full reference is linked below.')
  if missing then table.insert(lines, 1, 'Section heading unavailable in the offline conversion; showing the beginning of the manual.') end
  if source then
    lines[#lines + 1], lines[#lines + 2] = '', '[' .. (extracted and 'Reference section · full manual' or 'Source: DevDocs') .. '](' .. source .. ')'
  end
  return lines, nil, source, extracted
end

local function visible_metadata()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].black_docs then return vim.b[buf].black_docs, vim.b[buf].black_docs_history or {} end
  end
end

function M.show(docset, entry, saved, back)
  saved = saved or resolver.capture()
  if not resolver.current(saved) or type(entry) ~= 'table' or type(entry.path) ~= 'string' or type(entry.name) ~= 'string' then return false end
  local lines, error_message, source, extracted = page(docset, entry)
  if not lines then vim.notify(error_message, vim.log.levels.INFO); return false end
  local previous, history = visible_metadata()
  history = vim.deepcopy(history or {})
  if not back and previous and (previous.docset ~= docset or previous.path ~= entry.path or previous.name ~= entry.name) then
    history[#history + 1] = previous
    if #history > M.max_history then table.remove(history, 1) end
  end
  local docs = require('config.documentation')
  local was_focused = vim.b[saved.buf].black_docs ~= nil
  docs.close()
  local buf, win = docs.open(lines, 'REFERENCE · ' .. docset .. ' · ' .. entry.name)
  vim.b[buf].black_docs = { docset = docset, name = entry.name, path = entry.path, source = source, section = extracted }
  vim.b[buf].black_docs_history = history
  if was_focused then docs.focus() end
  if source then vim.keymap.set('n', 'gx', function() vim.ui.open(source) end, { buffer = buf, desc = 'Open full reference source' }) end
  vim.keymap.set('n', '<C-o>', function()
    local stack = vim.b[buf].black_docs_history or {}
    local prior = stack[#stack]
    if not prior then return vim.notify('No earlier reference page', vim.log.levels.INFO) end
    table.remove(stack)
    local origin = resolver.capture()
    if M.show(prior.docset, prior, origin, true) then
      local fresh
      -- Closing/reopening may allocate a new window handle.
      for _, candidate in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local b = vim.api.nvim_win_get_buf(candidate)
        if vim.b[b].black_docs then fresh = b; break end
      end
      if fresh then vim.b[fresh].black_docs_history = stack end
    end
  end, { buffer = buf, desc = 'Previous reference page' })
  vim.keymap.set('n', '<CR>', function()
    local origin = resolver.capture()
    local target = store.find_entry(docset, origin.word)
    if not target then return vim.notify('No exact offline reference for ' .. origin.word, vim.log.levels.INFO) end
    M.show(docset, target, origin)
  end, { buffer = buf, desc = 'Follow exact reference' })
  return true
end

function M.search(query, docset, saved)
  if not saved then resolver.cancel(); saved = resolver.capture() end
  if not resolver.current(saved) then return end
  local items, names = {}, docset and { docset } or store.installed()
  for _, name in ipairs(names) do
    local loaded = store.load_index(name)
    if loaded then
      local cached = picker_cache[loaded]
      if not cached then
        cached = {}
        for _, entry in ipairs(loaded.entries) do cached[#cached + 1] = { text = name:upper() .. "    " .. entry.name, docset = name, entry = entry } end
        picker_cache[loaded] = cached
      end
      for _, item in ipairs(cached) do items[#items + 1] = item end
    end
  end
  if #items == 0 then return vim.notify('Offline documentation not installed; run :DocsUpdate ' .. (docset or 'all'), vim.log.levels.INFO) end
  local pick = require('mini.pick')
  vim.schedule(function()
    if resolver.current(saved, true) and pick.get_picker_state() then pick.set_picker_query(vim.fn.split(query or '', '\\zs')) end
  end)
  pick.start({ source = { name = 'Offline references', items = items,
    preview = function(buf, item)
      if not item or not resolver.current(saved, true) then return end
      local lines, err = page(item.docset, item.entry)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { err })
      vim.bo[buf].filetype = 'markdown'
      local state = pick.get_picker_state()
      if state then require('config.documentation').render(buf, state.windows.main) end
    end,
    choose = function(item)
      if not item or not resolver.current(saved, true) then return end
      vim.schedule(function() if resolver.current(saved) then M.show(item.docset, item.entry, saved) end end)
    end,
  } })
end

function M.lookup(word, docset)
  return resolver.resolve(function(result)
    local name = result.docset
    if not name then return vim.notify('No offline docset for this filetype', vim.log.levels.INFO) end
    if result.allow_literal ~= false then
      for _, candidate in ipairs(result.candidates) do
        local entry = store.find_entry(name, candidate)
        if entry and M.show(name, entry, result) then return end
      end
      local entry = store.find_entry(name, result.word)
      if entry and M.show(name, entry, result) then return end
    end
    M.search(result.candidates[1] or result.word, name, result)
  end, { word = word, docset = docset })
end

function M.cleanup()
  resolver.cancel()
end

function M.setup(opts)
  opts = opts or {}
  store.setup(opts)
  if opts.timeout_ms then resolver.timeout_ms = opts.timeout_ms end
  if opts.max_display_lines then M.max_display_lines = opts.max_display_lines end
  picker_cache = setmetatable({}, { __mode = 'k' })
end

return M
