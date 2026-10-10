-- IBM/Carbon swatches with role assignments for a code editor.
-- Source, adaptations and contrast measurements: nvim/DESIGN.md.
local c = {
  canvas = '#000000', inset = '#080A0C', panel = '#121619', selection = '#202327',
  text = '#DDE1E6', muted = '#A2A9B0', punctuation = '#A2A9B0', path = '#C1C7CD',
  gutter = '#7F8A96', guide = '#23292E',
  border = '#4D5358', border_strong = '#697077', border_soft = '#343A3F',
  focus = '#78A9FF', variable = '#FA4D56', parameter = '#FFD7D9', member = '#FF7EB6',
  callable = '#33B1FF', keyword = '#BE95FF', type = '#3DDBD9',
  string = '#42BE65', literal = '#FF832B', comment = '#A2A9B0',
  folder = '#78A9FF', error = '#FF8389', warning = '#F1C21B',
  info = '#78A9FF', hint = '#3DDBD9', success = '#42BE65',
  on_accent = '#000000', strong = '#F2F4F8',
  error_bg = '#2D0709', warning_bg = '#302400', success_bg = '#071908',
  focus_bg = '#001D6C', search_bg = '#1C0F30', search_text = '#D4BBFF',
}
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
