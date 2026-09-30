# Perfect Black — Edition 03

## Direction

A pure-black editor with readable syntax, cool blue interaction surfaces, and
clear emphasis. The previous all-italic, mostly gray design made controls hard
to distinguish. Edition 03 unifies interactive panels through `lua/config/surfaces.lua` and
removes repeated information from completion, search, and the statusline.

## Palette

| Role | Color | Reason |
| --- | --- | --- |
| Editor canvas | `#000000` | Preserve the requested black background |
| Body text | `#E6E6E6` | Readable without using white everywhere |
| Secondary text | `#A0A0A0` | Paths and supporting details |
| Comments | `#8994A3` | Readable italic annotations on black and panels |
| Interaction accent | `#82AAFF` | Selection, prompts, headings, matches |
| Shared panel fill | `#10151C` | Commands, search, docs, and notifications |
| Inset fill | `#0A0F16` | Preview, sidebar, and statusline |
| Popup edge | `#354357` | Delimit text panels over dense code |
| Selected completion | `#243B59` | Obvious keyboard selection |
| Picker selection | `#243B59` | Match completion and tree selection |
| Statusline | `#0A0F16` | A quiet continuous base |
| Statusline end blocks | `#172333` | Group mode and cursor position |

Python receives its own syntax overrides:

| Token | Color |
| --- | --- |
| Variables and parameters | `#B8D7F0` |
| Members and properties | `#CCD6E0` |
| Keywords, decorators, built-in variable references | `#C4A7E7` |
| Functions and methods | `#E5C07B` |
| Types and constructors | `#78DCCA` |
| Strings | `#B5CEA8` |
| Numbers and booleans | `#D9A98F` |
| Operators and punctuation | `#A0A0A0` |

Primary LSP token groups match the corresponding Tree-sitter roles. Keyword
subgroups are explicit so generic theme defaults do not override Python's
palette. Diagnostics retain red/amber/blue/teal semantic colors. Git keeps
add/change/delete colors. These communicate state rather than decorate text.

## Typography and icons

JetBrains Mono Nerd Font Mono, Regular, 13 pt. Bold is used for emphasis;
comments and documentation strings use the actual Italic face. Kitty and
Alacritty select all four real faces. The installer verifies all four files.
Neovim cannot change a terminal emulator's font itself.

Completion uses one Codicon family for symbol kinds, alongside readable kind
labels. Code files, documents, shell scripts, folders, and dashboard actions
use related outline glyphs. Configured file icons share a muted foreground;
third-party file types can retain their plugin defaults.
Dashboard actions use matching outline icons. The statusline avoids repeating
a language icon beside an already visible file name.

## Components

### Bottom status bar

Mode and file are on the left. The mode block reads SEARCH or FILES while
those tools have focus, without losing the underlying editor filename. Diagnostics follow the filename. Git branch,
and change counts appear on the right when space allows. The redundant
filetype label is removed. The final
block explicitly labels line and column, shortening to `line:column` in
narrow terminals. The modified marker is `+` and a
recording indicator appears while recording a macro. Mode color stays in the
mode block; the cursor-position block remains neutral. Branch/change counts
hide before they crowd small terminals.

### Completion and documentation

Blink is the only completion engine. It supplies LSP capabilities, completion,
resolved documentation, snippets and automatic signature help. The obsolete cmp
shim and its window-decoration adapter are removed. Noice's automatic signature
help is disabled to avoid duplicate popups.

Documentation opens automatically after selecting an item. Insert Ctrl-K requests
compact signature help only; Ctrl-D toggles completion docs. Normal Ctrl-K retains
contextual symbol help; native Ctrl-W K still moves to the window above. Smart K
prefers exact offline references and falls back to LSP/project or builtin help.

Requests track the buffer, cursor, edit count and request generation to discard
stale responses. Builtin docs are cached; selected buffer words use their full label.
Ctrl-B/F open or scroll completion docs, and Ctrl-E dismisses completion. Enter inserts a
newline until an item is explicitly selected. The UI review uses a real Blink
provider with delayed resolution and tests the actual menu and documentation
windows at narrow and wide viewport sizes. Local buffer suggestions no longer
wait for LSP responses: the semantic source is asynchronous, with a ranking
boost when its results arrive. Buffer scanning uses only the active file and
limits size/result counts. The native matcher retains typo tolerance, usage
history and nearby-word ranking; exact matches sort first without custom Lua
comparators. A slow simulated LSP regression checks that local suggestions appear
before its response and semantic results rank first afterward.

### Command palette and hover

Commands have explicit COMMAND, LUA, SEARCH, HELP, or SHELL labels, a restrained
outline, horizontal padding, and a content-sized input between 42 and 72 columns. Noice's command
palette preset aligns command completion beneath the input. Hover shares the
documentation palette and wraps prose.

This intentionally revises the earlier border-free rule: a subtle outline helps
separate reference text over busy code. Terminal cell borders are not pixel
borders; radius and font rendering depend on the terminal.

### Search and navigation

Quick pickers are compact; grep and references have a preview. Height follows
result count within the viewport cap. Ctrl-P toggles preview. Narrow layouts
stack it below results; wide inspection uses a side-by-side preview. File names
come first, with muted directories. Search shares the documentation panel fill, outline, heading style, and
selection color. Its footer keeps preview/close shortcuts visible. When a
grep preview is open, rows show file locations and the preview shows code;
when hidden, rows retain matching code so narrow layouts stay informative. Snacks Explorer provides the file tree.

### Workspace

The 1337 wordmark and two panes appear at 100×30 or larger. Small terminals show
compact actions and recent files. Recents are scoped to the working directory.
The two section headings align, actions share key badges, and recent filenames
include their immediate parent directory. The launch screen disappears when
editing begins.

### Feedback

A diagnostic handler shows the worst diagnostic on each line across namespaces.
Source severity filters are honored, while the combined display uses one
explicit icon/priority policy instead of inheriting a random namespace’s options.
The sign column can expand for a simultaneous Git marker. Repeated active
notifications batch in the display without modifying history; errors share a persistent summary with a short latest-error
message. Original notifications
remain in session history. Mini Notify shows at most three grouped entries in one opaque window. History does
not survive restarting Neovim.

## Verification and limits

`tests/ui_review.py` exercises diagnostic namespace removal, notification batching
and overflow, picker resizing/preview toggling at 80×24, 100×30, and 140×42,
20,000-line editing with 4,000 synthetic diagnostics, and responsive tree closure.
It also opens, scrolls, and closes actual completion documentation through its
insert-mode mappings at 80×24 and 140×42 and checks command popup geometry.

README images are actual embedded Neovim grids rendered with JetBrains Mono's
Regular, Bold, Italic, and Bold Italic faces. Python is an illustrative unsaved
buffer. Documentation uses a deterministic demo completion source; it does not
claim to show a live ty response. No generated UI mockups are used.

These checks do not measure NFS startup, physical display response, sustained
real-project LSP performance, or comfort on the user's cluster terminal. No
numerical rating substitutes for those checks or the user's visual preference.


## Responsiveness follow-up

- Standalone Python user-site discovery is asynchronous, shares in-flight requests,
  caches results for the session, and times out after 1.5 seconds. Only the affected
  language-server startup waits for discovery; Neovim's UI does not. Lookup failure
  falls back to ty's normal discovery. Project roots and active environments remain
  isolated from the user-site override.
- Mapping timeout is 350 ms and idle update time is 250 ms. These are interaction
  settings, not claimed improvements to raw input latency.
- Completion shortcut overrides use canonical key names, preventing collisions
  with the inherited preset (such as `<C-b>` versus `<C-B>`).
- Documentation labels follow actual rendering rather than a fixed 60 ms
  timer. Regression tests deliberately delay completion resolution by 1.6 seconds.
- Completion truncation uses display-cell width, including non-ASCII labels.
- Search preview matches use an explicit readable accent on selection fill,
  avoiding the inherited dark foreground on a dark preview row.
- Shared panel highlights are defined once in `config/surfaces.lua`; superseded
  declarations were removed from the theme.
- Notification history remains session-only and unbounded. Real cluster/NFS and
  sustained project LSP performance still need measurements on that workstation.

`nvim --headless -u NONE -l nvim/tests/python_environment.lua` tests asynchronous
lookup, coalescing, caching, failure fallback, and virtual-environment/project
isolation with a controlled subprocess substitute.


## Eleven-plugin integration

The complete research shortlist is installed, with exact revisions in the lockfile.
Most additions load on a command or key. Mini Notify and Tiny Inline Diagnostic
load on VeryLazy; Endhints loads on LspAttach; Colorful Menu follows completion.

- Snacks Explorer is the only file browser; obsolete Mini Files hooks are removed.
- Namu owns the new symbol-navigation shortcuts; Glance owns explicit peek shortcuts.
  Neither replaces the project search picker or opens a permanent extra sidebar.
- Incremental rename uses LazyVim's supported extra and Noice integration.
- Tiny Inline Diagnostic replaces native virtual text, preserving gutter signs.
- Mini Notify replaces Snacks notifier and Noice's vim.notify interception. Original
  messages remain intact in history; grouping and the three-entry cap affect display
  copies only. Errors remain active until acknowledged; no error TTL is applied.
- Colorful Menu uses its generic fallback for ty; a parser failure leaves a plain
  completion label. The existing completion documentation mappings stay in place.
- TreeSJ extends editing; Ruff remains the formatting authority on save.
- Various Textobjs enables only indentation and subword mappings.
- Endhints preserves the existing inlay-hints toggle; it does not invent type data.

All new panels reuse the existing black/blue surface palette where their APIs permit.
Namu is a pinned beta dependency. Notification history is session-only and bounded
as described below. The synthetic test LSP verifies UI integration; a separate
real-ty fixture verifies language-server behavior.

## Reliability review — 2026-09-24

The previous integration added useful capabilities but overestimated its evidence:
mock LSP success did not establish real Python behavior, fixed panel sizes were
only partially tested, and retaining every notification was unbounded memory use.

Changes and tradeoffs:

- **Python correctness:** real ty 0.0.84 exposed a symlink-root diagnostic failure.
  Canonical project roots fixed the fixture. Empty settings now use an explicit
  JSON object rather than an array, avoiding ty's deserialization warning.
  Native `.venv`/activated-environment discovery remains authoritative. Tests cover
  a temporary installed package reached through a project symlink. Actual desk
  migration and the user's RAG repository remain outside this workspace's evidence.
- **Notification retention:** 500 original records, 16 KiB maximum per message,
  visible discard count. Mini Notify's internal history is compacted using its
  public setup API, retaining at most three active display groups and the pending
  error count. Timer generations prevent old callbacks removing recycled IDs;
  preserved deadlines prevent compaction extending transient toast lifetime.
  Older error details can age out; the error summary persists until acknowledged.
  This is an explicit bounded journal, not a permanent audit log.
- **Panel restraint:** Snacks Explorer provides the file tree; Mini Pick and Aerial
  adapt their dimensions to the viewport.
  Glance leaves code context by capping the peek at 12 rows. Terminal-cell geometry
  is used; pixel-radius promises would be misleading in a terminal.
- **Navigation:** Mini Pick handles file/text search, Snacks Explorer manages files,
  Aerial lists symbols and Glance peeks references. Removed browsers and symbol
  plugins have no remaining runtime hooks.
- **Performance evidence:** five headless starts on this workspace, Neovim 0.12.5,
  existing plugin caches: 49.859, 45.365, 51.606, 52.647, 47.133 ms; median 49.859 ms.
  The synthetic 20,000-line/4,000-diagnostic/2,000-sign operation took 143.5 ms in
  the first review run. These are local measurements, not a cluster guarantee.
  A repeatable startup script is included for target-machine measurement.

Terminal font rendering varies, and actual cluster cold-start/interactive latency
needs measurement there. Removed plugins no longer contribute maintenance cost.

## Standalone revision — supersedes the integration above

Removed the LazyVim distribution and its inherited defaults. Kept lazy.nvim as a
plugin manager: explicit specifications and a pinned lockfile provide reproducible
installation without an additional package-manager migration. The tradeoff is that
we now own the LSP setup, completion sources, keymaps and formatting policy.

Snacks.explorer serves as the modern, fast file explorer with tree navigation, git status indicators, LSP integration, floating/sidebar layouts, and built-in file operations (`<leader>e`).
Mini Pick + Mini Extra provide fast fuzzy picking and reuse one compact results/preview window.
This gives up simultaneous side-by-side preview and content-dependent window shrinking;
it reduces custom layout code and remains bounded at 80×24. Aerial replaces Namu for
structural navigation and can derive Python symbols from Tree-sitter before the LSP is ready.
Glance retains its separate role for reference inspection. Native hints replace Endhints;
plain completion labels replace Colorful Menu's generic ty formatting.

The dashboard and all project/search mappings now call a small owned picker
adapter. Distribution-specific integrations and their lockfile entries are gone.
Snacks provides its explorer, picker, dashboard, terminal, input, and git integrations. No new
claim of faster searching is made without comparative measurements.

Core setup is explicit in `lua/plugins/core.lua`. The installer now installs Ruff
through uv and installs syntax parsers explicitly. Missing LSP executables are not
spawned repeatedly; `:ConfigTools` reports availability. Tools remain opt-in through
Mason rather than installing silently on every workstation's first launch.

Validation: real configured ty attached and reported errors without LazyVim;
Mini Pick files/grep/preview passed at 80×24, 100×30 and 140×42; documentation
open/scroll/close, quickfix writes, native hints toggle, Snacks.explorer browser/navigation/geometry,
Aerial, Glance and incremental rename passed. Cluster cold-cache and desk migration
remain unverified. Prior benchmark numbers above describe the earlier revision.

Standalone headless startup, five runs with existing caches: 23.920, 25.236,
27.795, 24.544, 23.662 ms; median 24.544 ms. This excludes deferred plugins and
LSP readiness, so it is not a claim that interactive editing is twice as fast.

## Selective depth on the mode indicator

A light left edge and dark right edge suggest a raised mode indicator on its
existing blue-grey fill. The two single-cell edges replace its normal padding,
so the indicator keeps the same width and the status bar stays one row tall.
Mode text retains its semantic color. The position readout uses the flat bar
background, keeping the mode as the only raised control. Panels, selections and
the pure-black code canvas remain flat. This is a terminal bevel, not simulated
soft shadows or rounded pixel geometry. Edge contrast is decorative; the mode
label carries the information.

## Quiet decoration

The launch dashboard gains two-tone section rules and compact Nerd Font labels.
Its right pane uses a BLACK / STUDIO label instead of a numbered edition. Search
and file-browser floats gain a single top rule, making their native titles visible
without a complete frame. The active buffer uses a blue vertical marker and filled
selected surface; the label stays bold and readable. The existing raised mode
indicator remains the only beveled control. These are static highlights and glyphs:
no animations, new plugins, shadow windows or extra persistent chrome rows.

## Historical Python and browser spacing refinement

The former Mini Files implementation used its temporary column-browser model with short directory
names in titles, two-cell outer margins when space permits, and blank side/bottom
padding. Panels begin below the screen edge and stop at 18 content rows; long
folders scroll. Narrow screens keep one column. Layout coordinates are derived
from the current window widths, so repeated updates do not accumulate offsets.
Python's cursor line has a slightly clearer blue-grey fill. Indent guides stay
quiet, with a brighter muted-blue active scope and no animation. Syntax colors
remain unchanged: structure is easier to follow without adding color categories.

Indent guides also initialize for new unsaved code buffers; the upstream default
starts on file reads, which missed the dashboard-to-new-buffer workflow.

## Spatial awareness — 2026-09-30

This revision uses the current crimson Perfect Black surfaces; the blue palette
descriptions above document earlier revisions. The existing bufferline, statusline,
Edgy panels, outline, context rows and diagnostic/Git gutters remain the foundation.
No new plugin, permanent row, sidebar or animation framework is introduced.

### Destination feedback and physical cursor

`config.cursor_ui` owns one extmark namespace and one active, 180 ms one-shot
timer. A new landing clears the old mark and closes its timer. Generation checks
discard already-queued timer callbacks. Buffer disposal, entering Insert and
leaving a buffer/window clear feedback; cleanup removes the owned maps and group.

Hooks cover native asynchronous LSP destinations (`show_document`, preserving
preview behavior and return values), diagnostic mappings, jump history, search
acceptance/repeats, buffer entry, MiniPick selection, Flash, Aerial and quickfix
selection. Accepted command-line navigation uses a one-shot `SafeState` event
to wait for the committed cursor position. Canceled searches do not arm it.
There is no ordinary movement handler, idle animation or repeating timer.
Aerial's separate 300 ms jump highlight is disabled in favor of this shared cue;
its outline hover preview remains available. Native Snacks scrolling replaces
the previous animated scroll integration.

`guicursor` gives Normal a red block, Insert a green bar, Visual a lilac block,
Replace a pink underline, and Command a yellow bar. All new highlights reuse
`config.ui`/`config.surfaces` tokens. GUI/terminal capabilities determine color
and shape support; no terminal escape sequence or simulated cursor is injected.

### Focus and symbol context

`config.focus_ui` replaces the old handler that overwrote panel `winhighlight`.
It merges only owned entries, preserves Edgy/panel chrome, keeps inactive code
dim, and shows cursorline only in the focused window. Markdown reader mode keeps
its cursorline suppression. Updates are coalesced on focus and layout events.

One native separator owner is accented: prefer the right edge, otherwise its
left neighbor, then a horizontal boundary. Neovim assigns a vertical separator
to the window on its left and a horizontal separator to the upper window. This
does not draw a frame. At a junction, both separator segments owned by the same
window can inherit the accent; independent per-side coloring would require
additional rendering machinery. Floats retain their existing border treatment.

`config.symbol_context` starts on VeryLazy. On buffer/window entry, CursorHold
and InsertLeave, it walks the cursor's Tree-sitter ancestors for Python, C/C++
and Lua. It does not run a full-buffer symbol query. For other languages or
missing parsers, it can reuse already-populated Aerial data without loading
Aerial or asking an LSP for symbols. Real top-level locations show no capsule.
Text changes invalidate the old string until the next update.

Lualine reads only `vim.b.current_symbol`. The capsule hides below 120 terminal
columns and is capped to 48 display cells. Lookup stops above
10,000 lines or 1 MiB (`max_lines`/`max_bytes` in the module), including unsaved
buffers. Initial/incremental parser work can still vary by language; ordinary
cursor movement does not run it. Other existing statusline work is also moved
out of render functions: project roots and formatter names are cached, search
counts reuse native cached results, and Station detection is cached per session.

### Resolved conflicts and deferred rail

- MiniBracketed lowercases its configured suffix, so `diagnostic.suffix = 'D'`
  still overwrote native `[d`/`]d`. Duplicate diagnostic and quickfix mappings
  are disabled; native navigation retains counts and receives the beacon.
- Blink's empty command source list is replaced with command suggestions and
  bounded buffer-word suggestions for search. Noice owns the command input;
  Blink owns its completion menu. Tab selects and Enter accepts/executes once,
  with no automatic text insertion. The conflicting hardcoded blue Blink
  highlight callback is removed; surfaces now own the menu/docs/signature colors.
- Harpoon 2, its bindings and chrome are removed. Its `<leader>1` pin conflicted
  with the Station prefix, and the existing buffer picker covers file switching.
- The malformed lockfile containing only `{` is repaired using the installed
  configured plugin revisions, including Lazydev, without updating plugins.
- The overview rail is intentionally deferred, with no active renderer. A
  rightmost screen column needs window geometry, fold/wrap handling, clipping
  and overlay lifetime management alongside Edgy and Treesitter Context. Native
  extmarks address source rows, not whole-file screen fractions. Existing Git
  and diagnostic gutters remain available. The extra state and rendering cost
  do not justify enabling this experiment in this revision.

### Verification and measurements

`make check` includes the attached-UI spatial review. Real input tests cover
accepted/canceled search, quickfix Enter/`:cnext`, Flash labels, MiniPick
same-buffer selection, Aerial Enter, command suggestions and execution. Module
checks cover rapid beacon replacement/cleanup, ordinary movement exclusion,
cursor shapes, real Python nested methods/classes/top level, C functions, Lua
functions, missing parsers, cached Aerial containment, both size guards and
cached-only statusline rendering. Layout tests focus every window in two code
splits, code+Aerial, code+terminal, code+Trouble and code+Aerial+terminal.

The existing completion/docs, slow-LSP completion, Glance, rename, diagnostic,
notification, picker, quickfix-editing and actual configured ty tests pass.
The terminal review verifies focus/hide and shell exit. The UI stress check
uses 20,000 lines, 4,000 diagnostics and 2,000 displayed signs.

Raw startup samples and before/after batch measurements are saved in
`tests/spatial_results.json`. Measurements use Neovim 0.12.5 and installed
plugin caches. Startup excludes deferred work/LSP readiness. Interactive batches
use an embedded 140×42 UI and a normal unsaved 20,000-line buffer without a parser
or LSP. Focus callbacks drain after each focus change; other batches drain
queued callbacks before returning. Panel timings include synchronous opening
and explicit redraw, excluding later asynchronous readiness. These measurements
do not establish physical terminal response, cluster NFS behavior or real-project
definition/reference latency. Lower samples are not proof of a general speedup.

## Documentation and semantic navigation — 2026-09-30

The entire current configuration and test infrastructure were reread before this
phase. Existing ty, Ruff, clangd, Blink, Aerial, Glance, Edgy, Trouble, Quicker,
Lualine and Snacks remain. No plugin was added or upgraded.

### Reference ownership

`config.documentation` owns native reference geometry, focus, close behavior and
the existing Markdown renderer. Width is content-sized up to 75% of terminal
columns and 80 columns; height is capped to half the usable screen and 20 rows.
Headings, lists, inline code and fenced code use the existing Perfect Black
surface tokens. Original server text is preserved: no generated parameter,
return, source-location or API information is inserted.

The earlier contextual docs implementation used `config.symbol_help`; Smart K
now uses `config.smart_docs` (see the BLACK DECK section below). Normal Ctrl-K
still provides contextual help. Inside an unfinished call, asynchronous
signature help precedes hover; otherwise hover precedes isolated, cached Python
builtin help. Ctrl-K uses the same surface. All requests retain buffer,
cursor, changedtick and generation validation. Rejected requests release the
fallback path. A second documentation key focuses the existing native surface
for scrolling; q/Escape closes it. Insert-mode focus is scheduled because Blink
expression mappings run under Neovim textlock.

Blink retains its existing completion resolver and automatic signature engine.
Its documentation draw hook applies the same bounds and renderer only while the
window is open. Selecting completion documentation closes the manual reference
and signature surface; the window changes are scheduled outside expression
mapping textlock. Manual references hide Blink documentation/signatures when
they open. Delayed render callbacks validate the buffer's changedtick. Blink's
existing scrolling and dismissal mappings remain. The native renderer and
Blink's existing scrollbar behavior are retained; no extra overlay indicators
or second reference theme is introduced.

### Semantic illumination and locations

`config.symbol_illumination` requests `documentHighlight` asynchronously only on
CursorHold. It accepts server ranges, converts the client's position encoding,
and underlines visible occurrences with restrained central highlights. Identical
text in a separate semantic scope receives no mark unless the server includes it.
Movement, scrolling, insertion, buffer/window changes and detachment clear marks
and cancel pending requests. Late responses validate generation, buffer, window,
position and changedtick. Empty clearing short-circuits; movement does no lookup.

Work is bounded to 10,000 lines/1 MiB, 384 inspected results and 96 visible marks.
These limits are configurable. No blind identifier fallback is installed: an
unsupported LSP produces no underline. Mini Cursorword becomes obsolete and is
removed with its lock entry rather than leaving duplicate text-based highlights.

`config.lsp_actions` keeps native asynchronous LSP requests and empty-result
notifications. Single locations jump directly; multiple locations share the
existing MiniPick preview and selection controls. References use the picker.
Native quickfix `filename` entries are normalized to MiniPick's `path`; this
fixes gd printing a destination table instead of opening its file. Jump/tag
history and the destination beacon are preserved. Location rows include file,
line, column and supplied context. Glance keeps the explicit peek role.

Code actions use the same `vim.ui.select` adapter. Tab previews only supplied
WorkspaceEdit replacement text and ranges, capped to 32 edits and 40 lines per
replacement. Preview does not apply edits or issue resolve requests. Actions
without supplied edits explain that no text preview is available; native LSP
resolution/execution remains responsible for selection.

### Terminal and Markdown fixes

Snacks' 200 ms single-Escape handler conflicted with the configuration's 350 ms
double-Escape mapping. The existing double-Escape binding now owns exit behavior
without that competing timer. Single Escape still reaches the shell. Ctrl-T
hides a focused Snacks terminal, including command/Make terminals, without
starting another shell; the project shell remains reusable.

Large Markdown uses a configurable 5,000-line/512 KiB guard in
`config.markdown`. It disables rendering, Tree-sitter highlighting/context and
expression folds for that buffer, while ordinary Markdown keeps rendering.
The guard also handles a buffer growing across the threshold, reevaluating
context attachment once. Fold settings restore when returning to code. Reader
mode uses per-buffer rendering controls, avoids spellchecking and restores its
window options when leaving Markdown. It no longer disables documentation or
other Markdown buffers through a global renderer toggle.

### Picker decision and measured limits

**Picker decision: KEEP MINIPICK.** The current adapter is small; migration would
also require changing dashboard/document/Make pickers and select integration.
Both installed pickers passed root, preview, two-item selection and bounds checks
at 80×24 and 140×42. MiniPick remains the single compact results/preview surface;
Snacks retains Explorer. No new Search Board or permanent panel is introduced.

Five warm samples, 1,000 actual fixture files, matched cwd and installed plugins:

| Operation | MiniPick (ms) | Snacks (ms) |
| --- | ---: | ---: |
| Files | 30.73 | 76.41 |
| Grep results | 32.50 | 84.72 |
| Buffers | 16.09 | 40.89 |
| Recent files | 15.56 | 50.56 |
| Command history | 14.54 | 40.44 |
| Filter 1,000 results | 6.15 | 3.51 |
| Filter 20,000 results | 12.00 | 31.49 |
| 300 references, including 20 ms mock response | 61.93 | 109.96 |

Snacks wins the smaller filter case; the measured overall result does not justify
replacing MiniPick. References use mixed Location/LocationLink responses from a
controlled async transport, not a claim about live ty/clangd server latency.

| Documentation operation | Before (ms) | After (ms) |
| --- | ---: | ---: |
| Hover at 80 columns | 79.09 | 70.65 |
| Hover at 140 columns | 75.36 | 73.72 |
| Blink docs at 80 columns | 85.78 | 84.48 |
| Blink docs at 140 columns | 84.93 | 86.16 |

Documentation timings include an injected 60 ms response/resolution delay and
2 ms readiness polling. They establish similar local opening cost, not a general
speedup. First use includes lazy loading and is recorded separately. Native
hover bounds changed from 78×21 to 60×10 at 80×24, and 80×24 to 80×19 at 140×42.
Blink documents use the same maximum proportions and retain scrolling.

The 12,000-line fenced Markdown fixture measured 1,252.07 → 48.39 ms per 100
normal cursor moves with explicit redraw. Disabling only render-markdown measured
1,214.84 ms; the decisive change was guarding Tree-sitter/context work. This is
a synthetic large document, not a guarantee for every Markdown file.

Seven sequential headless starts with the same repository cwd and /tmp cache/
state measured medians 80.85 ms for the original config, 69.82 ms after the
spatial phase, and 89.08 ms after this phase. Samples varied widely (current
57.17–101.83 ms); other matched runs also reversed their apparent trend. No
startup speedup or stable regression conclusion is supported. Earlier cached
spatial-phase measurements remain historical rather than being mixed with these
different cache/host conditions. Startup excludes deferred work and LSP readiness.

Controlled 20k-line movement/layout batches and all raw samples are in
`tests/spatial_results.json`; old comparisons with different cwd were replaced.
The focused semantic test measured approximately 3–5 µs/event above an empty
CursorMoved callback baseline, ~0.05 ms idle request dispatch, and ~0.003–0.004 ms
two-mark cleanup. These are local synthetic costs, excluding server response.
No idle animation, repeated timer, synchronous Git or LSP request was introduced.

Raw data and reproduction scripts: `tests/picker_results.json`,
`tests/picker_references_results.json`, `tests/docs_results.json`,
`tests/markdown_results.json`, `tests/picker_bench.py`, `tests/docs_bench.py`,
`tests/markdown_bench.py`, and `tests/startup_bench.py --config <snapshot>`.
Cluster NFS, real RAG-project LSP latency, terminal font/color support and physical
display latency remain outside these measurements.

`make check` includes `make reference`: native/Blink docs at all three requested
sizes, actual Markdown rendering marks, focus/scroll/close, active signature
parameters, repeated Insert Ctrl-K and completion ownership under textlock,
builtin fallback, stale replies, real cross-file gd LocationLink selection and
tagstack/beacon, empty results, marked location previews, read-only code-action
previews, semantic scope/encoding/staleness/guards, terminal escape and Markdown
window restoration. The original UI/workflow/spatial suites also pass.

Rejected/simplified: no picker migration, blind text fallback, speculative
code-action simulation, fabricated source metadata, new plugin or overview rail.
The large Markdown guard remains sticky until the buffer is reopened; reducing
its size does not automatically restart heavy rendering. Native separator
junction ownership and terminal cursor capabilities retain the limits described
in the spatial section.

### Files changed during this task

The list compares against the initial workspace snapshot, preserving pre-existing
user changes. The root `Makefile` also changed to include the reference suite.

```text
DESIGN.md
README.md
lazy-lock.json
lua/config/cheatsheet.lua
lua/config/cursor_ui.lua
lua/config/documentation.lua
lua/config/focus_ui.lua
lua/config/keymaps.lua
lua/config/lazy.lua
lua/config/lsp_actions.lua
lua/config/markdown.lua
lua/config/options.lua
lua/config/pick.lua
lua/config/python_help.lua
lua/config/station.lua
lua/config/surfaces.lua
lua/config/symbol_context.lua
lua/config/symbol_help.lua
lua/config/symbol_illumination.lua
lua/config/terminal.lua
lua/config/ui.lua
lua/plugins/completion.lua
lua/plugins/core.lua
lua/plugins/harpoon.lua (removed)
lua/plugins/navigation.lua
lua/plugins/statusline.lua
lua/plugins/tools.lua
lua/plugins/ui.lua
tests/capture_makefile.py
tests/docs_bench.py
tests/docs_results.json
tests/documentation_fixture.lua
tests/documentation_review.py
tests/markdown_bench.py
tests/markdown_results.json
tests/markdown_review.lua
tests/picker_bench.py
tests/picker_references_results.json
tests/picker_results.json
tests/plugins_review.lua
tests/semantic_review.lua
tests/spatial_bench.py
tests/spatial_results.json
tests/spatial_review.lua
tests/spatial_review.py
tests/startup_bench.py
tests/terminal_escape_review.py
tests/terminal_review.lua
```

### BLACK DECK and Smart Docs — 2026-09-30

BLACK DECK uses Which-Key's supported title, sorter, group descriptions, native
column layout and help controls. No renderer patch or replacement modal framework
is used. Immediate commands precede Code/Docs, project and system groups. Arbitrary
section rows would require a custom renderer, so the hierarchy uses ordered groups
and a restrained `›` group marker. `:BlackDeck` explicitly opts into native loop
mode; the ordinary leader popup retains its usual behavior.

Documentation separates semantic identity from content. `config.docs_resolver`
uses asynchronous hover (and clangd symbolInfo) plus bounded Python import/receiver
context. It cancels stale requests with generation/window/buffer/cursor/changedtick
checks and a one-shot timeout. Python local definitions/bindings suppress external
builtin matches. Qualified suffixes resolve only when unique in the update-built
index; uncertain names go to MiniPick rather than a guessed reference page.

`K` prefers exact offline content, reuses the asynchronous hover response for a
project fallback, then tries existing builtin help or useful offline search.
Insert `Ctrl-K` requests signature help only, capped at eight rows. `gK` uses the
same identity resolver but never displays LSP content. The shared documentation
module owns rendering, responsiveness, focus and close behavior. Offline history
is buffer-local and bounded to 20 pages; Enter follows exact indexed names.

The former upstream DevDocs adapter was removed: its Telescope-oriented fallback,
extra commands and unlicensed converter added unnecessary complexity. The new
stdlib Python updater downloads only the six configured DevDocs sets, converts
actual HTML content and builds exact/unique-suffix/fuzzy indexes. Immutable
generations, path validation, a file lock and atomic manifest publication keep old
manuals usable after failure. The installer download is optional; the runtime
checks only a small manifest and six index paths after startup, and then starts
an asynchronous update when missing/stale. No lookup accesses the network.

Full-manual rendering was rejected: the real Python pathlib manual took a warm
median 687.05 ms in the earlier experiment (`tests/deep_docs_results.json`).
Anchored reference sections are bounded to 200 displayed lines, with a real source
link and an explicit continuation notice. Pages above 1 MiB are refused. Reference
versions can differ from a project's runtime; dependency docsets are not inferred
or downloaded automatically.

The current tests cover native deck layout/navigation, existing mappings, semantic
lookup and local shadowing, stale replies, missing/corrupt data, documentation
history, responsive rendering, offline update failure/atomic publication and
missing/stale/fresh/disabled auto-update behavior. The automatic updater is disabled
in tests/benchmarks with `NVIM_BLACK_DOCS_AUTO_UPDATE=0`.

Matched final measurements (five samples, installed caches, repo cwd, automatic
updates disabled; medians in milliseconds):

| Operation | Before | After |
| --- | ---: | ---: |
| Existing startup benchmark | 39.61 | 37.86 |
| BLACK DECK root, 80 columns | 4.62 | 5.14 |
| BLACK DECK root, 100 columns | 4.00 | 3.61 |
| BLACK DECK root, 140 columns | 4.53 | 7.13 |
| Nested Files group, 80 columns | 1.14 | 1.75 |
| K with exact offline entry + 20 ms mock LSP | 27.17 | 27.48 |
| K offline miss → 20 ms mock hover | 26.46 | 25.55 |
| gK, no LSP | 6.62 | 7.89 |
| DocsBrowse + fuzzy filter, 20,000 entries | 41.03 | 43.96 |
| Actual Python reference section | 12.38 | 12.92 |
| Actual Lua reference section | 13.98 | 14.90 |
| Actual C reference section | 12.71 | 14.82 |

The baseline K displayed hover content; the new K displays offline content for an
exact match. New no-LSP Smart K opened in 7.22 ms; the baseline had no equivalent
operation. Startup samples overlap: these runs do not establish a speedup.
First-use costs are larger, including lazy parser/renderer initialization and
index decoding. Neither transport benchmarks nor headless startup measure physical
display latency or real server/network delays. Updates were disabled throughout.

Idle RSS was 25,064 → 25,016 KiB. Under the same 20k fixture, all six loaded indexes
and three real-page stress sequence, RSS was 108,844 → 126,888 KiB and live Lua
memory after GC was 40,244 → 53,236 KiB. The custom exact/suffix indexes add a
measured memory cost when used; they remain unloaded at idle/startup. Current docs
use 39,087,577 logical bytes / 62,439,424 allocated bytes (about 59.5 MiB), outside
Git. The updater retains one previous generation, so later updates can use more
storage; DocsHealth reports actual disk usage asynchronously.

Raw results: `tests/black_existing_startup_before_results.json`,
`tests/black_existing_startup_after_results.json`,
`tests/black_deck_before_results.json`, `tests/black_deck_results.json`,
`tests/black_system_before_results.json`,
`tests/black_system_before_runtime_results.json`, `tests/black_system_results.json`.
Reproduce with `tests/startup_bench.py --runs 5`, `tests/black_deck_review.py
--expect-black-deck`, and `tests/black_system_bench.py --data <docs-store>`.

Primary files for this phase: `lua/config/black_deck.lua`, `smart_docs.lua`,
`docs_resolver.lua`, `docs_store.lua`, `docs_lifecycle.lua`, `deep_docs.lua`,
`documentation.lua`, `symbol_help.lua`, `keymaps.lua`, `surfaces.lua`,
`lua/plugins/ui.lua`, `completion.lua`, `scripts/update_docs.py`, the root
`scripts/update-docs`, `install.sh`, `Makefile`, documentation and focused tests.

The final command-registration fix adds `:Docs` with `browse`, `update` and
`health` subcommands, while preserving `:DocsBrowse`, `:DocsUpdate`, `:DocsHealth`
and the earlier `:Devdocs` / `:DevdocsUpdate` aliases. Registration/dispatch and
reload cleanup are covered by `tests/docs_lifecycle_review.lua`. Existing sessions
can load the commands with `require('config.docs_lifecycle').setup()`; restarting
once loads the complete new mappings and documentation architecture.
