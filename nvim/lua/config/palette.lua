-- Shared semantic palette: cool neutral surfaces and balanced Oklch accents.
-- Source, adaptations and contrast measurements: nvim/DESIGN.md.
local classic = {
  canvas = '#000000', inset = '#090B0F', panel = '#111419', selection = '#1B222D',
  text = '#D0D4DB', muted = '#999FA8', punctuation = '#9299A4', path = '#B3B8BF',
  gutter = '#89909A', guide = '#1F2227',
  border = '#4C5057', border_strong = '#686F7B', border_soft = '#2D3137', focus_border = '#667B9E',
  focus = '#8BB5FA', variable = '#FA4D56', parameter = '#E0B9B8', member = '#E89BAC',
  callable = '#6EC3EB', keyword = '#C6A0F2', type = '#71CBB9',
  string = '#84C485', literal = '#EFA464',
  error = '#FD8A8C', warning = '#EBBD57',
  on_accent = '#000000', strong = '#E8EBF1',
  error_bg = '#291414', warning_bg = '#201A0D', success_bg = '#131E13',
  focus_bg = '#1E2B42', search_bg = '#231B2D', search_text = '#D5B9F7',
}
-- Default: screenshot-inspired dark rose, balanced for long coding sessions.
-- Classic preserves the previous Perfect Black accents.
local rose = {
  canvas = '#000000', inset = '#0C0A0D', panel = '#151116', line = '#211923', selection = '#261D26',
  text = '#E9E4E9', muted = '#B2A6B0', punctuation = '#BDB2BC', path = '#D0C5CF',
  gutter = '#A89EAA', guide = '#2A242B',
  border = '#675463', border_strong = '#877584', border_soft = '#393039',
  focus_border = '#C58EAE', focus = '#F3B4D1',
  variable = '#F09ABC', parameter = '#DFBED0', member = '#DBA8BA',
  callable = '#A9D8EB', keyword = '#D7B8EE', type = '#B2DCCC',
  string = '#DAC4AE', literal = '#EFC390',
  success = '#9CD5B7', error = '#FF91A9', warning = '#E9C77F',
  on_accent = '#000000', strong = '#FFF5FA',
  error_bg = '#30131F', warning_bg = '#292112', success_bg = '#13251F',
  focus_bg = '#362439', search_bg = '#3B273B', search_text = '#F6D0F0',
}
-- Choose before Neovim starts: NVIM_COLOR_STYLE=classic nvim
local style = vim.g.black_color_style or vim.env.NVIM_COLOR_STYLE
if style ~= 'classic' then style = 'rose' end
vim.g.black_color_style = style
local c = style == 'classic' and classic or rose
c.folder, c.info, c.hint = c.focus, c.focus, c.type
c.success, c.comment, c.popup_selection = c.success or c.string, c.muted, c.selection
-- A heading hierarchy in one cool family, shared by native and rendered Markdown.
c.headings = { c.focus, c.callable, c.text, c.path, c.path, c.muted }
c.icons = {
  Red=c.error, Orange=c.literal, Yellow=c.warning, Green=c.success,
  Cyan=c.type, Azure=c.callable, Blue=c.folder, Purple=c.keyword, Grey=c.muted,
}
c.kinds = {
  Text=c.text, Method=c.callable, Function=c.callable, Constructor=c.type,
  Field=c.member, Variable=c.variable, Class=c.type, Interface=c.type,
  Module=c.type, Property=c.member, Unit=c.literal, Value=c.literal,
  Enum=c.type, Keyword=c.keyword, Snippet=c.keyword, Color=c.member,
  File=c.text, Reference=c.info, Folder=c.folder, EnumMember=c.literal,
  Constant=c.type, Struct=c.type, Event=c.literal, Operator=c.punctuation,
  TypeParameter=c.type, Namespace=c.type, Package=c.type, String=c.string,
  Number=c.literal, Boolean=c.literal, Array=c.type, Object=c.type, Key=c.member, Null=c.literal,
}
return c
