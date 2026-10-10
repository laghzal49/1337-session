-- Shared semantic palette: cool neutral surfaces and balanced Oklch accents.
-- Source, adaptations and contrast measurements: nvim/DESIGN.md.
local c = {
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
c.folder, c.info, c.hint = c.focus, c.focus, c.type
c.success, c.comment, c.popup_selection = c.string, c.muted, c.selection
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
