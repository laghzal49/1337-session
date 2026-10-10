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
  informed the original hue families and vivid red variable accent. [Carbon's semantic tokens](https://www.carbondesignsystem.com/building-blocks/foundations/color/tokens)
  informed warning and numeric roles. Supporting colors are now custom-balanced;
  syntax assignments are design choices, not IBM recommendations for code.
- [W3C CSS Color 4](https://www.w3.org/TR/css-color-4/#ok-lab) describes Oklab
  and its perceptual lightness/chroma model. Supporting syntax accents use Oklch
  lightness 0.76–0.78 and chroma 0.09–0.12, with deliberate exceptions for vivid
  red variables and warning/error signals. This balances their visual intensity;
  it does not establish an objectively best palette. Hex values are precomputed.
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
| Inset | `#090B0F` | Status bar, sidebar, code preview, stopped debug line |
| Panel | `#111419` | Current line, picker input and larger tool panels |
| Popup | `#090B0F` | Completion, documentation, commands, prompts and notifications |
| Popup selection | `#1B222D` | Subtle blue tint for the selected result |
| Selection | `#1B222D` | Visual selection, focused rows, active tabs |
| Text | `#D0D4DB` | Prose, filenames, normal labels |
| Strong text | `#E8EBF1` | Matched text and small emphasized labels; regular weight |
| Secondary / comments | `#999FA8` | Comments, hints, inactive information |
| Structure | `#9299A4` | Operators, punctuation and Lua table braces |
| Paths | `#B3B8BF` | Supporting paths |
| Gutter / guides | `#89909A` / `#1F2227` | Readable line numbers / quiet indent guides |
| Borders | `#4C5057` / `#686F7B` / `#2D3137` | Default, popup, decorative separators |
| Focused border | `#667B9E` | Active popup edges and editor separators, quieter than blue labels |
| Variables | `#FA4D56` | Local/global names, LSP, completion, outline, debugger |
| Parameters | `#E0B9B8` | Function inputs and documentation parameters |
| Members | `#E89BAC` | Fields, properties, object keys |
| Callables | `#6EC3EB` | Functions, methods, callable built-ins |
| Keywords | `#C6A0F2` | Control flow, modifiers, imports, directives |
| Types | `#71CBB9` | Classes, constructors, type names, modules, constants |
| Strings | `#84C485` | Literal text and inline documentation code |
| Values | `#EFA464` | Numbers, booleans, escapes, enum members |
| Focus / folders | `#8BB5FA` | Navigation, directory icons/text, current split, prompts |
| Error | `#FD8A8C` | Diagnostics, failed watches, stop control, deleted code |
| Warning | `#EBBD57` | Warnings, modified-file markers, changed debugger values, stopped-line arrow |
| Information | `#8BB5FA` | Informational messages, progress, untracked files |
| Hint | `#71CBB9` | Suggestions and note comments |
| Success | `#84C485` | Additions, successful checks, debugger play/restart |
| Search | `#D5B9F7` on `#231B2D` | Matches; current match gets an orange fill |
| Focus fill | `#1E2B42` | Active signature parameter, marked results, yank flash |
| Diff fills | `#131E13` / `#201A0D` / `#291414` | Added / changed / deleted lines |
| On accent | `#000000` | Text inside small colored badges |

The neutral ramp and blue focus/selection fills share a cool hue family.
Editor and popup selections share one token. Softer rose members and parameters
relate to the vivid red variables; warning amber relates to numeric orange.
Markdown headings step from blue/cyan to neutral instead of cycling through a rainbow.
Visual selection preserves syntax foregrounds instead of repainting the
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
| Command popup occupied 56 columns on a 40-column screen | Content-sized input with a 28-column minimum, one editable row, no vertical padding, and live resize |
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
selection, popup and popup selection: the minimum tested ratio is **4.77:1**
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
| Commands appeared as “Property” | Blue command icon and concise label; plain-icon mode also spells out “Command” |
| Docs could collapse to a nine-column strip | Vertical placement below 100 columns; useful reading width at 40 columns |
| Documentation touched its frame | A window gutter adds margin without changing parser or signature byte offsets |
| Long references hid their scroll state | Width-aware controls and visible line range; symbol-specific completion titles |
| Command suggestions covered the prompt border | Place suggestions below the one-row prompt and its border |
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

## Coordinated palette and compact command follow-up

All syntax, LSP, completion, debugger and icon roles consume the revised palette.
Selections use the same blue-gray fill, active borders use a quieter related blue,
and supporting accents have similar perceptual lightness/chroma. The black canvas,
vivid red variable color and regular font weight remain explicit requirements.

The command popup now grows with its text from 28 columns, with one input row
and no empty vertical padding. Command suggestions omit redundant source/kind
columns in glyph mode. Menus show at most six rows while retaining all results.
Long commands remain editable through horizontal scrolling.

The debugger now has project-aware F5, a contextual `:Debug` menu, bounded native
binary discovery, popup argument/module prompts, watch creation and clearer setup
errors. Python saves run safe Ruff fixes, import organization and formatting in
that order; see [README.md](README.md) for keys, limits and project settings.

Final verification for this follow-up: **30 fresh-process regressions passed**,
plus `make test`. Attached UI checks passed for completion, command/input live
resizing, long commands, plain icons, notifications and cancellation. A new UI
assertion initially assumed Noice used a native window title; after checking its
actual border buffer, the corrected popup section passed in a fresh process.
The debugger action menu was checked at 140 and 40 columns and its Step over
action exercised against real debugpy. This host has GDB 12.1; its unsupported
DAP capability is detected, but native C/C++ debugging still needs a newer GDB.

A separate legacy Markdown reader test passed its behavior assertions but reports
`E31: No such mapping` when run under the stricter smoke wrapper; it is not part
of the 30-case suite above. No Markdown reader behavior was changed in this pass.
