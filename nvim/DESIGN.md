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

The menu orders information as kind icon, completion text, then a short kind label. Source names are omitted.
Labels longer than 38 cells are shortened for display; insertion text is
unmodified. Selected items have a stronger blue fill.

Documentation uses a distinct opaque panel with a thin cell border, a
DOCUMENTATION title, and keyboard hints when its width permits. Ctrl-D toggles
it. Ctrl-B/F open it from a visible completion menu or scroll it when already
open. Outside completion, these mappings fall back to their normal behavior.
The title helper decorates the window immediately after the pinned completion
plugin renders resolved documentation. It leaves very narrow panels unlabelled
to avoid crowding. This small adapter uses the plugin’s internal docs-open
method and must be checked when updating that pinned dependency. Documentation still opens only on request.

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
when hidden, rows retain matching code so narrow layouts stay informative. Neo-tree is 28 columns and closes after opening a file below 110 columns.

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

- Mini Files is on-demand. Neo-tree remains available through its existing mapping.
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
- **Panel restraint:** Mini Files shows one column below 100 columns and updates on
  resize. Namu removes ornamental border/footer and uses proportional dimensions.
  Glance leaves code context by capping the peek at 12 rows. Terminal-cell geometry
  is used; pixel-radius promises would be misleading in a terminal.
- **Navigation:** file/text search is the default route; Mini Files manages nearby
  files, Neo-tree shows hierarchy, Namu navigates symbols, Glance peeks references.
  Keeping all requested plugins still carries maintenance cost. They remain lazy
  loaded where appropriate; the README now explains when each earns its place.
- **Performance evidence:** five headless starts on this workspace, Neovim 0.12.5,
  existing plugin caches: 49.859, 45.365, 51.606, 52.647, 47.133 ms; median 49.859 ms.
  The synthetic 20,000-line/4,000-diagnostic/2,000-sign operation took 143.5 ms in
  the first review run. These are local measurements, not a cluster guarantee.
  A repeatable startup script is included for target-machine measurement.

Still imperfect: Namu is beta, Colorful Menu uses generic ty formatting, terminal
font rendering varies, and actual cluster cold-start/interactive latency needs
measurement there. Adding more plugins would not resolve those limits.

## Standalone revision — supersedes the integration above

Removed the LazyVim distribution and its inherited defaults. Kept lazy.nvim as a
plugin manager: explicit specifications and a pinned lockfile provide reproducible
installation without an additional package-manager migration. The tradeoff is that
we now own the LSP setup, completion sources, keymaps and formatting policy.

Mini Files replaces Neo-tree. Mini Pick + Mini Extra replace Snacks picker and
reuse one compact results/preview window. This gives up simultaneous side-by-side
preview and content-dependent window shrinking; it reduces custom layout code
and remains bounded at 80×24. Aerial replaces Namu for structural navigation and
can derive Python symbols from Tree-sitter before the LSP is ready. Glance retains
its separate role for reference inspection. Native hints replace Endhints; plain
completion labels replace Colorful Menu's generic ty formatting.

The dashboard and all project/search mappings now call a small owned picker
adapter. Distribution-specific integrations and their lockfile entries are gone.
Snacks remains for useful independent modules, not its picker/explorer. No new
claim of faster searching is made without comparative measurements.

Core setup is explicit in `lua/plugins/core.lua`. The installer now installs Ruff
through uv and installs syntax parsers explicitly. Missing LSP executables are not
spawned repeatedly; `:ConfigTools` reports availability. Tools remain opt-in through
Mason rather than installing silently on every workstation's first launch.

Validation: real configured ty attached and reported errors without LazyVim;
Mini Pick files/grep/preview passed at 80×24, 100×30 and 140×42; documentation
open/scroll/close, quickfix writes, native hints toggle, Mini Files, Aerial, Glance
and incremental rename passed. Cluster cold-cache and desk migration remain
unverified. Prior benchmark numbers above describe the earlier revision.

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
