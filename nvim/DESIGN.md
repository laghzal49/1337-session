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
| Canvas | `#000000` | Active and inactive editor splits, normal message area |
| Inset | `#080A0C` | Status bar, sidebar, code preview, stopped debug line |
| Panel | `#121619` | Current line, picker input and larger tool panels |
| Popup | `#080A0C` | Completion, documentation, commands, prompts and notifications |
| Popup selection | `#111F2D` | Subtle blue tint for the selected result |
| Selection | `#202327` | Visual selection, focused rows, active tabs |
| Text | `#DDE1E6` | Prose, filenames, normal labels |
| Strong text | `#F2F4F8` | Matched text and small emphasized labels; regular weight |
| Secondary / comments | `#A2A9B0` | Comments, hints, inactive information |
| Structure | `#A2A9B0` | Operators, punctuation and Lua table braces |
| Paths | `#C1C7CD` | Supporting paths |
| Gutter / guides | `#7F8A96` / `#23292E` | Readable line numbers / quiet indent guides |
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
| Error | `#FF8389` | Diagnostics, failed watches, stop control, deleted code |
| Warning | `#F1C21B` | Warnings, modified-file markers, changed debugger values, stopped-line arrow |
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

- Mini Icons and Which-Key share one color-family table; all folder icons use blue,
  including built-in special directories such as `nvim`, `.git` and Downloads.
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

## Critical review of the actual UI

The follow-up review used attached Neovim screens at 40, 80 and 140 columns.
These changes address observed problems:

| Finding | Applied change |
| --- | --- |
| Inactive code changed from black to gray | Both editor backgrounds now use pure black |
| Braces, guides and filenames competed with identifiers | Neutral Lua table braces, softer punctuation/guides, off-white filenames; line numbers keep at least 4.5:1 contrast |
| Git status repainted whole explorer filenames | Status stays in its separate marker; blue folders and file colors remain stable |
| The sidebar crowded a narrow editor | Explorer becomes a bottom tree below 80 columns; sidebar width is capped at 30% elsewhere |
| Command popup occupied 56 columns on a 40-column screen | Percentage sizing follows live terminal resizing; input prompts include a border allowance |
| First Escape left an input prompt open in Normal mode | Escape cancels the prompt and restores the editor |
| Completion results lacked source context | LSP/BUF/PATH/SNIP labels, bounded labels and kind names where space permits; plain-icon mode includes kind text |
| A notification painted its entire message in a severity color | Colored severity headings with neutral body text, wrapped sizing, live plain icons |
| History opened at the oldest message | Newest first, wrapped lines, colored headings, Escape or q to close |
| Debugger left only four columns for code at 40 columns | Three layouts: full panels on large screens, a sidebar on medium screens, bottom scopes on small screens |
| Long branch and task names crowded status information | Explicit project, branch and task label limits |
| Ruff emitted repeated errors for unnamed Python buffers | Delay Python server attachment until the buffer receives a filename, then retry automatically |

Debugger resizing uses existing buffers, preserves editor focus, and stops
rearranging windows if the user replaces a panel's buffer. Watches and call stack
also have dedicated floating views (`<leader>Dv` and `<leader>DS`). Diagnostic
codes and source names are visible; overflow wraps outside insert mode.

The gutter and indent-guide colors are custom neutral adaptations. Their purpose
is hierarchy: code and meaningful states draw more attention than scaffolding.
No extra plugins are needed for this pass. The resize hook uses the pinned
Noice/Nui layout methods; run the attached UI regressions when updating those
plugins. Completion reopens through Blink’s public API, retaining the selected
item and typed command while rebuilding columns for the new width.

## Verification

`palette_review.lua` checks actual syntax/diagnostic highlights on canvas, panel,
selection, popup and popup selection: the minimum tested ratio is **4.70:1**
(red variables on the editor selection).
Variables measure **6.26:1** on the canvas. It also checks filled search/TODO/diff
labels, completion/outline/icon consistency, preserved syntax selection, and
absence of bold after lazy loading, theme reload and accessibility changes.

These checks measure foreground/background pairs, not complete WCAG conformance
or medical comfort. Terminal settings can change the final appearance. Attached
Neovim captures provide the visual review; report layout tests include 24-column
terminals and exercise real action callbacks without changing the workstation.

The UI regression checks also cover real completion source labels, floating-window
borders at 40 columns, live command/explorer resizing, prompt cancellation,
notification history order and ASCII severity icons. Debugger layout tests check
three sizes, focus, tab cleanup and preservation of unsaved text; the integration
suite still exercises actual debugpy launch, attach, evaluation and stepping.

Previous release verification: all `make check` targets passed; after resolving the
resize and unnamed-Python failures, the final `make review upgrade` run passed,
including 27 fresh-process regressions. Screenshots include a real debugpy stop,
40-column command/explorer layouts and the final folder-color overrides.

## Popup review

This pass changes layout and interaction as well as color. Attached Neovim
captures, including 40-column screens, exposed these problems:

| Problem | Change |
| --- | --- |
| Completion had little context or visible guidance | Live selection/result count, compact labels, kind/source columns, visible accept/close keys and a blue selection tint |
| Commands appeared as “Property” | Command icon, blue color and explicit “Command” label |
| Docs could collapse to a nine-column strip | Vertical placement below 100 columns; useful reading width at 40 columns |
| Documentation touched its frame | A window gutter adds margin without changing parser or signature byte offsets |
| Long references hid their scroll state | Width-aware controls and visible line range; symbol-specific completion titles |
| Command suggestions covered the prompt border | Account for the command prompt's vertical padding in completion placement |
| A short code-action list occupied most of the screen | Content-sized width and height while retaining the existing preview/cancel behavior |
| Notifications competed with the top of the file | Lower-right notices, content-sized width, severity heading and history shortcut |
| History rearranged editing splits | A searchable, resizable float; newest first; q/Escape restores the editor |
| Diagnostic codes appeared twice | Explicit suffix owns the code once; source and severity remain visible |
| Watch inspectors lacked context | Central placement, title, edit/expand/close hints and safe first-use loading |

`config.popups` changes window presentation only. It discards ownership when a
buffer is replaced, cleans up closed windows and preserves regular typography.
Blink still owns completion selection and documentation requests; Mini Pick owns
code-action previews and cancellation. No plugins were added.

Popup verification: full attached UI review, documentation/action review at
40/80/100/140 columns, the 1,102-notification rollover test and 28 strict regression
cases. The asynchronous Git-probe test needed a fresh-process rerun; it passed.
Final focused checks cover command resizing/selection, plain icons, prompt
cancellation, notification history, diagnostic code uniqueness and debugger first use.
Real captures and reproduction instructions are in [POPUPS.md](POPUPS.md).
