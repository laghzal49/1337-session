# Perfect Black — Edition 02

## Direction

A pure-black editor with readable syntax, cool blue interaction surfaces, and
clear emphasis. The previous all-italic, mostly gray design made controls hard
to distinguish. This edition changes typography, Python syntax, documentation,
commands, icons, and the statusline as one system.

## Palette

| Role | Color | Reason |
| --- | --- | --- |
| Editor canvas | `#000000` | Preserve the requested black background |
| Body text | `#E6E6E6` | Readable without using white everywhere |
| Secondary text | `#A0A0A0` | Paths and supporting details |
| Comments | `#7A7A7A` | Quiet, italic annotations |
| Interaction accent | `#82AAFF` | Selection, prompts, headings, matches |
| Documentation fill | `#10151C` | Separate reference material from code |
| Command fill | `#121923` | A recognizable command surface |
| Popup edge | `#354357` | Delimit text panels over dense code |
| Selected completion | `#243B59` | Obvious keyboard selection |
| Picker selection | `#162439` | Tie search to the interaction accent |
| Statusline | `#0A0F16` | A quiet continuous base |
| Statusline end blocks | `#172333` | Group mode and cursor position |

Python receives its own syntax overrides:

| Token | Color |
| --- | --- |
| Variables, parameters, members | `#B8D7F0` |
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
and source labels. Project files use recognizable filetype glyphs; Python and
Lua have restrained yellow/blue accents. Directory names remain neutral.
Dashboard actions use matching outline icons. The statusline avoids repeating
a language icon beside an already visible file name.

## Components

### Bottom status bar

Mode and file are on the left. Diagnostics follow the filename. Git branch,
change counts, and filetype appear on the right when space allows. The final
block explicitly labels line and column. The modified marker is `+` and a
recording indicator appears while recording a macro. Mode color stays in the
mode block; the cursor-position block remains neutral. Branch/change counts
hide before they crowd small terminals.

### Completion and documentation

The menu orders information as kind icon, completion text, then kind/source.
Labels longer than 38 cells are shortened for display; insertion text is
unmodified. Selected items have a stronger blue fill.

Documentation uses a distinct opaque panel with a thin cell border, a
DOCUMENTATION title, and keyboard hints when its width permits. Ctrl-D toggles
it. Ctrl-B/F open it from a visible completion menu or scroll it when already
open. Outside completion, these mappings fall back to their normal behavior.
The title helper uses public Neovim window APIs and leaves very narrow panels
unlabelled to avoid crowding. Documentation still opens only on request.

### Command palette and hover

Commands have explicit COMMAND, LUA, SEARCH, HELP, or SHELL labels, a restrained
outline, horizontal padding, and a 55% width capped at 78 columns. Noice's command
palette preset aligns command completion beneath the input. Hover shares the
documentation palette and wraps prose.

This intentionally revises the earlier border-free rule: a subtle outline helps
separate reference text over busy code. Terminal cell borders are not pixel
borders; radius and font rendering depend on the terminal.

### Search and navigation

Quick pickers are compact; grep and references have a preview. Height follows
result count within the viewport cap. Ctrl-P toggles preview. Narrow layouts
stack it below results; wide inspection uses a side-by-side preview. File names
come first, with muted directories. Search retains filled padding without an
outline. Neo-tree is 28 columns and closes after opening a file below 110 columns.

### Workspace

The 1337 wordmark and two panes appear at 100×30 or larger. Small terminals show
compact actions and recent files. Recents are scoped to the working directory.
The launch screen disappears when editing begins.

### Feedback

A diagnostic handler shows the worst diagnostic on each line across namespaces.
The sign column can expand for a simultaneous Git marker. Repeated active
notifications batch; errors share a persistent summary. Original notifications
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
