local function luminance(rgb)
  local total = 0
  for index, weight in ipairs({0.2126, 0.7152, 0.0722}) do
    local channel = math.floor(rgb / 256 ^ (3-index)) % 256 / 255
    total = total + weight * (channel <= 0.04045 and channel / 12.92 or ((channel+0.055)/1.055)^2.4)
  end
  return total
end
local function color(hex) return tonumber(hex:sub(2),16) end
local function ratio(fg,bg)
  local a,b=luminance(fg),luminance(bg)
  return (math.max(a,b)+0.05)/(math.min(a,b)+0.05)
end
local p=require('config.palette')
for _,family in ipairs({{'Variable','variable'}, {'Function','callable'}, {'Class','type'}, {'Field','member'}}) do
  local completion=vim.api.nvim_get_hl(0,{name='BlinkCmpKind'..family[1],link=false})
  local outline=vim.api.nvim_get_hl(0,{name='Aerial'..family[1],link=false})
  assert(completion.fg==color(p[family[2]]) and outline.fg==completion.fg,
    'completion/outline role drift for '..family[1])
end
local names={'@variable','@variable.parameter','@variable.member','@function','@keyword',
  '@type','@string','@number','@comment','@punctuation.delimiter','DiagnosticError','DiagnosticWarn'}
local lowest=100
for _,name in ipairs(names) do
  local hl=vim.api.nvim_get_hl(0,{name=name,link=false})
  for _,bg in ipairs({p.canvas,p.panel,p.selection}) do
    local contrast=ratio(assert(hl.fg,name),color(bg))
    assert(contrast>=4.5,('%s contrast %.2f on %s'):format(name,contrast,bg))
    lowest=math.min(lowest,contrast)
  end
end
for _,lang in ipairs({'python','lua','c','cpp'}) do
  local syntax=vim.api.nvim_get_hl(0,{name='@variable.'..lang,link=false})
  local semantic=vim.api.nvim_get_hl(0,{name='@lsp.type.variable.'..lang,link=false})
  assert(syntax.fg==color(p.variable) and semantic.fg==syntax.fg and syntax.bold,
    'variable role drift for '..lang)
end
assert(vim.api.nvim_get_hl(0,{name='DiagnosticUnderlineError',link=false}).undercurl,
  'errors need a non-color cue')
print(('PALETTE PASS: syntax/diagnostics on three backgrounds, minimum %.2f:1; LSP parity and error undercurl'):format(lowest))
