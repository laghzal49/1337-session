# Perfect Black — researched color system

The editor canvas is pure black, with regular font weight throughout. The design
is intended for long coding sessions: less glaring prose, quiet surrounding controls, distinct code
families, and readable comments. Vivid red variables remain a user preference.

## Research and decisions

- [Google's dark-theme design guide](https://codelabs.developers.google.com/codelabs/design-material-darktheme)
  describes dark gray surfaces, softened text, restrained saturation, and lighter
  elevated panels. These informed off-white text, restrained panel contrast and a
  dark status bar. The canvas stays pure black at the user’s explicit request.
  Large bright mode blocks were removed.
- [IBM's color specifications](https://www.ibm.com/design/language/color/)
  supply the cool neutrals and red, blue, cyan, purple, teal, green and magenta
  swatches. [Carbon's semantic tokens](https://www.carbondesignsystem.com/building-blocks/foundations/color/tokens)
  supply the warning yellow and orange. These are source swatches; the editor's
  syntax assignments are our design choices, not IBM recommendations for code.
- [Atlassian's color roles](https://atlassian.design/foundations/color/)
  separate neutral, informational, success, warning and danger states. Here,
  navigation is blue, warnings yellow, additions green, and errors red with
  explicit labels and undercurls.
- [Nord's syntax guidelines](https://www.nordtheme.com/docs/colors-and-palettes/)
  provide a reference for separating functions, strings, comments and structural
  elements. Its muted pastel palette was considered; the selected swatches keep
  the user's preference for stronger code colors.
- [W3C contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
  provides the 4.5:1 normal-text benchmark used in tests.
  [W3C use-of-color guidance](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)
  informs severity labels, selection markers, underlines and Git signs.

There is no universally best hue for a variable or folder. This is a deliberate
adaptation of those sources, tested against the actual editor backgrounds.
A theme also cannot guarantee ten hours without discomfort; display brightness,
font size, ambient lighting and breaks still affect comfort.

## Complete role map

All literal theme values live in `lua/config/palette.lua`. Surface, syntax,
semantic token, icon, debugger and completion definitions consume these roles.

| Role | Value | Applied to |
| --- | --- | --- |
| Canvas | `#000000` | Editing background, normal message area |
| Inset | `#080A0C` | Status bar, sidebar, inactive split, code preview |
| Panel | `#121619` | Popups, documentation, current line, guides |
| Selection | `#202327` | Visual selection, focused rows, active tabs |
| Text | `#DDE1E6` | Prose, filenames, normal labels |
| Strong text | `#F2F4F8` | Matched text and small emphasized labels; regular weight |
| Secondary / comments | `#A2A9B0` | Comments, hints, inactive information |
| Structure / paths | `#C1C7CD` | Operators, punctuation, supporting paths |
| Borders | `#4D5358` / `#697077` / `#343A3F` | Default, popup, decorative separators |
| Variables | `#FA4D56` | Local/global names, LSP, completion, outline, debugger |
| Parameters | `#FFD7D9` | Function inputs and documentation parameters |
| Members | `#FF7EB6` | Fields, properties, object keys |
| Callables | `#33B1FF` | Functions, methods, callable built-ins |
| Keywords | `#BE95FF` | Control flow, modifiers, imports, directives |
| Types | `#3DDBD9` | Classes, constructors, type names, modules, constants |
| Strings | `#42BE65` | Literal text and inline documentation code |
| Values | `#FF832B` | Numbers, booleans, escapes, enum members |
| Focus / folders | `#78A9FF` | Navigation, directory icons/text, current split, prompts |
| Error | `#FF8389` | Diagnostics, failed watches, debugger stop, deleted code |
| Warning | `#F1C21B` | Warnings, modified files, changed debugger values |
| Information | `#78A9FF` | Informational messages, progress, untracked files |
| Hint | `#3DDBD9` | Suggestions and note comments |
| Success | `#42BE65` | Additions, successful checks, debugger play/restart |
| Search | `#D4BBFF` on `#1C0F30` | Matches; current match gets an orange fill |
| Focus fill | `#001D6C` | Active signature parameter, marked results, yank flash |
| Diff fills | `#071908` / `#302400` / `#2D0709` | Added / changed / deleted lines |
| On accent | `#000000` | Text inside small colored badges |

Inset, panel, selection and warning fill are adaptations for these foregrounds.
Selection is slightly darker than IBM Cool Gray 90 to give red more contrast
margin. Visual selection preserves syntax foregrounds instead of repainting the
whole selection white. The accessible preset strengthens borders and removes
comment italics; it retains the same readable selection fill.

## Small details covered

- Mini Icons and Which-Key share one color-family table; default folders use blue.
  Python uses yellow, Lua/TypeScript blue, shell green, Rust/HTML orange.
- Every completion kind and outline kind uses the same role table. Debugger
  variables, scopes, values, changed values, controls and watch errors are mapped.
- TODO/FIXME/WARN/NOTE/TEST labels use semantic colors and regular font weight.
- Markdown headings, links, checkboxes, tables and code blocks are mapped.
- Search, jump labels, matching brackets, ghost text, inlay hints, deprecations,
  notifications, plugin/tool managers and the 16 ANSI terminal colors are mapped.
- Bold is disabled in theme definitions, statusline, tabs, TODO labels and guides.
  The typography hook also clears inherited bold after theme/plugin loading.
  Underlines, undercurls, strike-throughs and status symbols remain meaningful.
- Duplicate filenames get short directory prefixes in tabs. Long LSP progress is
  capped. Station Health wraps details, resizes, reuses its window and follows
  the live accessibility preset.

## Verification

`palette_review.lua` checks actual syntax/diagnostic highlights on canvas, panel
and selection: the minimum tested ratio is **4.70:1** (red variables on selection).
Variables measure **6.26:1** on the canvas. It also checks filled search/TODO/diff
labels, completion/outline/icon consistency, preserved syntax selection, and
absence of bold after lazy loading, theme reload and accessibility changes.

These checks measure foreground/background pairs, not complete WCAG conformance
or medical comfort. Terminal settings can change the final appearance. Attached
Neovim captures provide the visual review; report layout tests include 24-column
terminals and exercise real action callbacks without changing the workstation.
