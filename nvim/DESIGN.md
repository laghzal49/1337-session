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
notifications batch; errors share a persistent summary with a short latest-error
message. Original notifications
remain in session history. At most three live toasts are tracked. History does
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
