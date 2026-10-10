-- LSP signature formatting with protocol-correct UTF-16 parameter offsets.
local M = {}
local function doc(lines, value)
  if type(value) ~= 'string' and type(value) ~= 'table' then return end
  local ok, content = pcall(vim.lsp.util.convert_input_to_markdown_lines,value)
  if ok and type(content) == 'table' and #content > 0 then vim.list_extend(lines,content) end
end
local function index(value, size)
  value = tonumber(value) or 0
  return value >= 0 and value < size and value % 1 == 0 and value or 0
end
local function parameter_range(signature, selected)
  local parameters, label = type(signature.parameters) == 'table' and signature.parameters or {}, signature.label
  local parameter = parameters[selected+1]
  if not parameter then return end
  if type(parameter.label) == 'table' then
    local first,last = parameter.label[1],parameter.label[2]
    if type(first) ~= 'number' or type(last) ~= 'number' or first < 0 or last < first then return end
    local ok,a,b = pcall(function()
      return vim.str_byteindex(label,'utf-16',first),vim.str_byteindex(label,'utf-16',last)
    end)
    if ok and a < b and b <= #label then return a,b end
  elseif type(parameter.label) == 'string' and parameter.label ~= '' then
    local offset = label:find('(',1,true) or 1
    for pos,item in ipairs(parameters) do
      if type(item.label) ~= 'string' then return end
      local first,last = label:find(item.label,offset,true)
      if not first then return end
      if pos == selected+1 then return first-1,last end
      offset = last+1
    end
  end
end
local function location(label, offset)
  local prefix = label:sub(1,offset)
  local _,newlines = prefix:gsub('\n','')
  local final = prefix:match('([^\n]*)$') or ''
  return newlines+1,#final -- first row follows the opening code fence
end
function M.format(result, filetype, selected)
  if type(result) ~= 'table' or type(result.signatures) ~= 'table' or #result.signatures == 0 then return end
  local signatures = result.signatures
  selected = index(selected == nil and result.activeSignature or selected,#signatures)
  local signature
  for _ = 1,#signatures do
    local candidate = signatures[selected+1]
    if type(candidate) == 'table' and type(candidate.label) == 'string' and candidate.label ~= '' then signature=candidate;break end
    selected=(selected+1)%#signatures
  end
  if not signature then return end
  local lines = {'```'..(filetype or '')}
  vim.list_extend(lines,vim.split(signature.label,'\n',{plain=true}))
  lines[#lines+1] = '```'
  local parameters = type(signature.parameters) == 'table' and signature.parameters or {}
  local parameter = index(signature.activeParameter or result.activeParameter,#parameters)
  local active = parameters[parameter+1]
  local first,last = parameter_range(signature,parameter)
  local highlight
  if first then
    local sr,sc = location(signature.label,first)
    local er,ec = location(signature.label,last)
    highlight = {sr,sc,er,ec}
  end
  if active then
    local label = type(active.label) == 'string' and active.label or (first and signature.label:sub(first+1,last))
    lines[#lines+1] = ''
    lines[#lines+1] = ('Parameter %d/%d%s'):format(parameter+1,#parameters,label and (' · '..label) or '')
    doc(lines,active.documentation)
  end
  if signature.documentation then
    lines[#lines+1] = ''
    doc(lines,signature.documentation)
  end
  if #signatures > 1 then
    lines[#lines+1] = ''
    lines[#lines+1] = ('Overload %d/%d · [s / ]s to switch'):format(selected+1,#signatures)
  end
  return lines,highlight,{selected=selected,total=#signatures,parameter=parameter}
end
return M
