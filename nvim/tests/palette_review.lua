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
for _,name in ipairs({'Normal','NormalNC'}) do
  assert(vim.api.nvim_get_hl(0,{name=name,link=false}).bg==0,name..' must remain pure black')
end
assert(vim.api.nvim_get_hl(0,{name='@constructor.lua',link=false}).fg==color(p.punctuation),
  'Lua table braces must stay neutral')
assert(ratio(color(p.gutter),color(p.canvas))>=4.5,'unreadable line numbers')
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
  for _,bg in ipairs({p.canvas,p.panel,p.selection,p.inset,p.popup_selection}) do
    local contrast=ratio(assert(hl.fg,name),color(bg))
    assert(contrast>=4.5,('%s contrast %.2f on %s'):format(name,contrast,bg))
    lowest=math.min(lowest,contrast)
  end
end
for _,lang in ipairs({'python','lua','c','cpp'}) do
  local syntax=vim.api.nvim_get_hl(0,{name='@variable.'..lang,link=false})
  local semantic=vim.api.nvim_get_hl(0,{name='@lsp.type.variable.'..lang,link=false})
  assert(syntax.fg==color(p.variable) and semantic.fg==syntax.fg and not syntax.bold and not semantic.bold,
    'variable role drift for '..lang)
end
assert(vim.api.nvim_get_hl(0,{name='DiagnosticUnderlineError',link=false}).undercurl,
  'errors need a non-color cue')
print(('PALETTE PASS: syntax/diagnostics on five backgrounds, minimum %.2f:1; LSP parity and error undercurl'):format(lowest))

-- Catch lazy plugin setup and theme reloads reverting the chosen colors/weight.
require('lazy').load({plugins={'mini.icons','flash.nvim','nvim-dap','neogen','todo-comments.nvim','render-markdown.nvim','blink.cmp','aerial.nvim','which-key.nvim','lualine.nvim','bufferline.nvim'}})
assert(vim.wait(1000,function() return require('todo-comments.config').loaded end))
local function check_runtime()
  for kind, expected in pairs(p.kinds) do
    for _,prefix in ipairs({'BlinkCmpKind','Aerial'}) do
      assert(vim.api.nvim_get_hl(0,{name=prefix..kind,link=false}).fg==color(expected), prefix..kind..' lost semantic color')
    end
  end
  for family, expected in pairs(p.icons) do
    assert(vim.api.nvim_get_hl(0,{name='MiniIcons'..family,link=false}).fg==color(expected), 'file icon palette overwritten')
  end
  for name,role in pairs({Directory='folder',SnacksPickerDirectory='folder',DapUIVariable='variable',DapUIStop='error',
    DapUIPlayPause='success',DiagnosticError='error',DiagnosticWarn='warning',DiagnosticInfo='info',DiagnosticHint='hint',DiagnosticOk='success'}) do
    assert(vim.api.nvim_get_hl(0,{name=name,link=false}).fg==color(p[role]), name..' role mismatch')
  end
  local _,directory_hl=require('mini.icons').get('directory','color-review')
  assert(vim.api.nvim_get_hl(0,{name=directory_hl,link=false}).fg==color(p.folder),'directory glyph disagrees with directory text')
  for _,name in ipairs(require('mini.icons').list('directory')) do
    local _,hl=require('mini.icons').get('directory',name)
    assert(vim.api.nvim_get_hl(0,{name=hl,link=false}).fg==color(p.folder),'special folder has another color: '..name)
  end
  for _,name in ipairs({'Search','CurSearch','FlashLabel','FlashCurrent','DiffAdd','DiffDelete','DiffChange',
    'LspSignatureActiveParameter','SnacksPickerMatch','BlinkCmpMenuSelection','TodoBgTODO','TodoBgFIX','TodoBgWARN'}) do
    local hl=vim.api.nvim_get_hl(0,{name=name,link=false})
    assert(hl.fg and hl.bg and ratio(hl.fg,hl.bg)>=4.5,'unreadable filled label: '..name)
  end
  assert(not vim.api.nvim_get_hl(0,{name='Visual',link=false}).fg,'selection must preserve syntax colors')
  for _,name in ipairs(names) do
    local hl=vim.api.nvim_get_hl(0,{name=name,link=false})
    assert(ratio(hl.fg,color(require('config.surfaces').selected))>=4.5,'accessible selection dims '..name)
  end
  local bold={}
  for name,hl in pairs(vim.api.nvim_get_hl(0,{link=true})) do
    if hl.bold or (hl.cterm and hl.cterm.bold) then bold[#bold+1]=name end
  end
  assert(#bold==0,'bold returned: '..table.concat(bold,', '))
end
vim.wait(50,function() return false end)
check_runtime()
vim.cmd.colorscheme('perfect-black')
vim.wait(50,function() return false end)
check_runtime()
require('config.accessibility').set(true)
vim.wait(50,function() return false end)
check_runtime()
require('config.accessibility').set(false)
print('PALETTE LIFECYCLE PASS: lazy loading, theme reload, accessible selection, icon roles, filled labels and regular font weight')
