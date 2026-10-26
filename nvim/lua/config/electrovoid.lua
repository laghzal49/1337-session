-- ElectroVoid by SireOmega. The supplied Zed theme is the source of truth.
local M = {}
local path = assert(vim.api.nvim_get_runtime_file('themes/electrovoid.json', false)[1], 'Missing ElectroVoid theme')
M.source = vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
M.style = M.source.themes[1].style

-- Terminal highlights have opaque RGB colors; composite Zed's RGBA surfaces.
local function rgb(value, base)
  local alpha = #value == 9 and tonumber(value:sub(8, 9), 16) / 255 or 1
  base = base or M.style.background
  local channels = {}
  for index = 2, 6, 2 do
    local foreground = tonumber(value:sub(index, index + 1), 16)
    local background = tonumber(base:sub(index, index + 1), 16)
    channels[#channels + 1] = math.floor(foreground * alpha + background * (1 - alpha) + 0.5)
  end
  return string.format('#%02x%02x%02x', unpack(channels))
end
function M.color(name, base) return rgb(assert(M.style[name], 'Unknown ElectroVoid color: ' .. name), base) end
function M.syntax(name) return rgb(assert(M.style.syntax[name]).color) end

function M.palette()
  local c, s = M.color, M.syntax
  local p = {
    canvas = c('editor.background'), inset = c('surface.background'), panel = c('panel.background'),
    popup = c('elevated_surface.background'), tree_panel = c('panel.background'),
    line = c('editor.active_line.background'), selection = c('element.selected'),
    text = c('text'), strong = c('text'), muted = c('text.muted'), path = c('text.muted'),
    punctuation = s('punctuation'), gutter = c('editor.line_number'), guide = c('editor.wrap_guide'),
    border = c('border'), border_strong = c('border.focused'), border_soft = c('border.variant'),
    focus_border = c('border.focused'), focus = c('text.accent'), panel_accent = c('text.accent'),
    variable = s('variable'), parameter = s('variable.parameter'), member = s('property'),
    callable = s('function'), keyword = s('keyword'), type = s('type'),
    string = s('string'), literal = s('number'), boolean = s('boolean'), comment = s('comment'),
    success = c('success'), error = c('error'), warning = c('warning'), info = c('info'), hint = c('hint'),
    on_accent = c('vim.visual_line.foreground'), folder = c('icon.accent'), teal = c('hint'),
    error_bg = c('error.background'), warning_bg = c('warning.background'), success_bg = c('success.background'),
    focus_bg = c('element.selected'), search_bg = c('search.match_background'), search_text = c('text'),
    popup_selection = c('element.selected'),
  }
  p.headings = { s('title'), s('title'), s('title'), s('title'), s('title'), s('title') }
  return p
end

function M.apply()
  vim.cmd('highlight clear')
  vim.g.colors_name = 'electrovoid'
  vim.o.termguicolors = true
  vim.o.background = 'dark'
  local c, s = M.color, M.syntax
  local function hi(name, attrs) vim.api.nvim_set_hl(0, name, attrs) end
  local function groups(names, attrs)
    for name in names:gmatch('%S+') do hi(name, vim.deepcopy(attrs)) end
  end
  local function syntax(name)
    local spec = M.style.syntax[name]
    return { fg = rgb(spec.color), italic = spec.font_style == 'italic',
      bold = type(spec.font_weight) == 'number' and spec.font_weight >= 700 or false }
  end
  -- Convert all existing panel, completion, debugger and documentation tokens.
  for name, spec in pairs(require('config.surfaces').highlights()) do
    local attrs = vim.deepcopy(spec)
    for flag in (attrs.fmt or ''):gmatch('[^,]+') do attrs[flag] = true end
    attrs.fmt = nil
    hi(name, attrs)
  end
  groups('Normal NormalNC', { fg = c('editor.foreground'), bg = c('editor.background') })
  groups('SnacksTerminal', { fg = c('terminal.foreground'), bg = c('terminal.background') })
  groups('NormalFloat Pmenu', { fg = c('text'), bg = c('elevated_surface.background') })
  groups('SignColumn FoldColumn LineNr LineNrAbove LineNrBelow', { fg = c('editor.line_number'), bg = c('editor.gutter.background') })
  groups('CursorLine', { bg = c('editor.active_line.background') })
  groups('CursorLineNr', { fg = c('editor.active_line_number'), bg = c('editor.gutter.background') })
  groups('CursorColumn ColorColumn', { bg = c('editor.wrap_guide') })
  groups('EndOfBuffer', { fg = c('editor.background'), bg = c('editor.background') })
  groups('NonText Whitespace Conceal', { fg = c('editor.invisible') })
  groups('WinSeparator', { fg = c('border.variant'), bg = c('background') })
  groups('BlackActiveSeparator', { fg = c('pane.focused_border'), bg = c('background') })
  groups('StatusLine StatusLineNC', { fg = c('text'), bg = c('status_bar.background') })
  groups('WinBar WinBarNC', { fg = c('text.muted'), bg = c('toolbar.background') })
  groups('BlackPath', { fg = c('text.muted'), bg = c('toolbar.background') })
  groups('BlackFileTitle', { fg = c('text'), bg = c('toolbar.background') })
  groups('TabLine TabLineFill BufferLineFill BufferLineBackground', { fg = c('text.muted'), bg = c('tab_bar.background') })
  groups('TabLineSel BufferLineBufferSelected', { fg = c('text'), bg = c('tab.active_background') })
  groups('BufferLineIndicatorSelected', { fg = c('border.focused'), bg = c('tab.active_background') })
  groups('FloatBorder', { fg = c('border.focused'), bg = c('elevated_surface.background') })
  groups('FloatTitle', { fg = c('text.accent'), bg = c('elevated_surface.background') })
  groups('PmenuSel', { fg = c('text'), bg = c('element.selected') })
  groups('PmenuSbar', { bg = c('surface.background') })
  groups('PmenuThumb', { bg = c('scrollbar_thumb.background', M.style['surface.background']) })
  groups('Search', { fg = c('text'), bg = c('search.match_background') })
  groups('IncSearch CurSearch Substitute', { fg = c('text'), bg = c('search.active_match_background') })
  groups('Visual VisualNOS', { bg = rgb(M.style.players[1].selection) })
  groups('Cursor lCursor TermCursor BlackCursorNormal BlackCursorInsert BlackCursorVisual BlackCursorReplace BlackCursorCommand',
    { fg = c('editor.background'), bg = rgb(M.style.players[1].cursor) })
  groups('MatchParen', { bg = c('element.selected'), fg = c('text.accent'), bold = true })
  groups('Folded', { bg = c('editor.subheader.background'), fg = c('text.muted') })
  groups('Directory', { fg = c('icon.accent') })
  groups('MsgArea MoreMsg Question ModeMsg', { fg = c('text'), bg = c('background') })
  groups('Error ErrorMsg', { fg = c('error') })
  groups('WarningMsg', { fg = c('warning') })
  groups('Title', syntax('title'))
  groups('Todo', { fg = c('warning'), bg = c('warning.background'), bold = true })
  groups('Underlined', { fg = s('link_uri'), underline = true })
  groups('BlackSymbolReference', { bg = c('editor.document_highlight.read_background') })
  groups('BlackSymbolCurrent', { bg = c('editor.document_highlight.write_background') })
  groups('BlinkCmpGhostText', syntax('predictive'))
  groups('TreesitterContext', { fg = c('text'), bg = c('editor.subheader.background') })
  groups('TreesitterContextLineNumber', { fg = c('editor.line_number'), bg = c('editor.subheader.background') })
  groups('SnacksIndent', { fg = c('editor.wrap_guide') })
  groups('SnacksIndentScope', { fg = c('editor.active_wrap_guide') })

  -- Zed captures with Neovim equivalents; dotted captures inherit the closest parent.
  local captures = {
    comment='comment', ['comment.documentation']='comment.doc',
    punctuation='punctuation', ['punctuation.bracket']='punctuation.bracket',
    ['punctuation.delimiter']='punctuation.delimiter', ['punctuation.special']='punctuation.special',
    attribute='attribute', constant='constant', number='number', boolean='boolean',
    constructor='constructor', ['function']='function', type='type', label='label',
    module='namespace', namespace='namespace', variable='variable',
    ['variable.parameter']='variable.parameter', ['variable.member']='property',
    ['variable.builtin']='variable.special', property='property', keyword='keyword',
    ['keyword.directive']='preproc', tag='tag', ['tag.attribute']='attribute',
    string='string', ['string.escape']='string.escape', ['string.regexp']='string.regex',
    ['string.special']='string.special', ['string.special.symbol']='string.special.symbol',
    character='string', operator='operator', ['markup.heading']='title',
    ['markup.strong']='emphasis.strong', ['markup.italic']='emphasis',
    ['markup.link']='link_text', ['markup.link.url']='link_uri',
    ['markup.raw']='text.literal', ['markup.list']='punctuation.list_marker',
    ['markup.quote']='comment', ['diff.plus']='diff.plus', ['diff.minus']='diff.minus',
  }
  local function capture_target(name)
    while name ~= '' do
      if captures[name] then return name end
      name = name:match('^(.*)%.') or ''
    end
  end
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:sub(1, 1) == '@' then
      local target = capture_target(name:sub(2))
      hi(name, target and { link = '@' .. target } or {})
    end
  end
  for capture, token in pairs(captures) do hi('@' .. capture, syntax(token)) end
  local legacy = {
    Comment='comment', SpecialComment='comment.doc', Identifier='variable', Function='function',
    Type='type', Structure='type', Typedef='type', StorageClass='keyword', Constant='constant',
    Number='number', Float='number', Boolean='boolean', String='string', Character='string',
    Statement='keyword', Conditional='keyword', Repeat='keyword', Label='label', Keyword='keyword',
    Exception='keyword', PreProc='preproc', Include='preproc', Define='preproc', Macro='preproc',
    PreCondit='preproc', Special='punctuation.special', SpecialChar='string.escape',
    Delimiter='punctuation.delimiter', Operator='operator', Tag='tag', Debug='keyword',
  }
  for group, token in pairs(legacy) do hi(group, syntax(token)) end
  local semantic = {
    variable='variable', parameter='variable.parameter', property='property', function_='function',
    method='function', class='type', interface='type', struct='type', enum='constructor',
    enumMember='constant', type='type', typeParameter='type', namespace='module',
    decorator='attribute', macro='keyword.directive', keyword='keyword', comment='comment',
    string='string', number='number', operator='operator', boolean='boolean', event='function',
  }
  semantic['function'], semantic.function_ = semantic.function_, nil
  for kind, capture in pairs(semantic) do hi('@lsp.type.' .. kind, { link = '@' .. capture }) end
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local kind = name:match('^@lsp%.type%.([^%.]+)%.')
    if kind and semantic[kind] then hi(name, { link = '@lsp.type.' .. kind }) end
  end
  for name, key in pairs({ Error='error', Warn='warning', Info='info', Hint='hint', Ok='success' }) do
    groups('Diagnostic' .. name .. ' DiagnosticSign' .. name, { fg = c(key) })
    groups('DiagnosticVirtualText' .. name, { fg = c(key), bg = c(key .. '.background') })
    groups('DiagnosticUnderline' .. name, { sp = c(key), undercurl = true })
  end
  for name, key in pairs({ Add='added', Change='modified', Delete='deleted' }) do
    groups('GitSigns' .. name .. ' GitSigns' .. name .. 'Nr', { fg = c('version_control.' .. key) })
  end
  for name, key in pairs({ Add='created', Change='modified', Delete='deleted' }) do
    hi('Diff' .. name, { fg = c(key), bg = c(key .. '.background') })
  end
  hi('DiffText', { bg = c('version_control.word_added') })
  for name, key in pairs({ Bad='error', Cap='warning', Rare='info', Local='success' }) do
    hi('Spell' .. name, { sp = c(key), undercurl = true })
  end
  for level = 1, 6 do
    groups('RenderMarkdownH' .. level .. ' markdownH' .. level, syntax('title'))
  end
  groups('RenderMarkdownCodeInline', { fg = s('text.literal'), bg = c('editor.subheader.background') })
  groups('RenderMarkdownLink RenderMarkdownWikiLink', { fg = s('link_uri') })
  groups('RenderMarkdownBullet', syntax('punctuation.list_marker'))
  local ansi = { 'black','red','green','yellow','blue','magenta','cyan','white' }
  for index, name in ipairs(ansi) do
    vim.g['terminal_color_' .. (index - 1)] = c('terminal.ansi.' .. name)
    vim.g['terminal_color_' .. (index + 7)] = c('terminal.ansi.bright_' .. name)
  end
end
return M
