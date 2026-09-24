# Perfect Black Neovim

## Intent

Keep code in the foreground on a true `#000000` canvas. Give search a clear
focus, put secondary tools behind a keypress, and use solid surface fills to
show depth. The result should feel quiet during editing and informative when
an action needs attention.

This is a terminal UI. Cell borders, line height, font size, ligatures, and
pixel corner radius depend on the terminal; Neovim cannot promise 1 px borders
or 10 px corners. Use JetBrainsMono Nerd Font in the terminal for the intended
icons. Nothing in this config changes the terminal's font settings.

## Tokens

| Role | Hex | Use |
| --- | --- | --- |
| Canvas | `#000000` | Editor background |
| Float | `#0A0A0A` | Raised dark surface |
| Surface 1 | `#141414` | Sidebar, menus, picker preview |
| Surface 2 | `#1E1E1E` | Picker input/list, active sidebar row |
| Surface 3 | `#2A2A2A` | Selected picker row |
| Border | `#1F1F1F` | Float edge where needed |
| Body | `#E6E6E6` | Reading and editing |
| Secondary | `#A0A0A0` | Supporting text |
| Dim | `#7A7A7A` | Inactive line numbers |
| Decorative | `#3D3D3D` | Indent guides only, never body text |
| Selection | `#B49CE8` | Picker matches and chosen items |
| Normal / info | `#7FB4F5` | Mode and information |
| Insert / git add | `#93D68F` | Mode and added lines |
| Replace / error / git delete | `#E88B8B` | Problems and deletions |
| Command / git change | `#E8D48B` | Mode and changed lines |
| Terminal / hint | `#7FD4C4` | Terminal and hints |

The statusline confines mode color to its mode segment. Diagnostics and Git
retain semantic colors. Search uses purple to mark the current interaction;
other secondary surfaces stay neutral.

## Components and behavior

- **Editor:** Black background, body text off-white, dim line numbers, one
  reserved sign slot that expands to two on collisions, a barely raised cursor line, and no end-of-buffer
  tildes. Errors can show inline; warnings stay in signs and the statusline.
- **Chrome:** One global statusline; a buffer tab row appears when useful.
  The command line is hidden until needed. Code-area percentages apply only
  to a stated editing layout. The earlier 90.5% estimate assumed too small a
  gutter: native sign slots consume two terminal cells each, plus line numbers.
  Multiple buffers, longer line numbers, sign collisions, and open panels
  change the result. The 90% target is a focus-view goal, not a universal
  invariant or a measured guarantee.
- **File tree:** Neo-tree opens on demand as a 28-column charcoal panel.
  Project name is short, source selector is hidden, and an already visible
  file gets a filled active row. Redundant unstaged exclamation marks are
  hidden; change type and staged/conflict indicators remain. Closing the tree
  returns its width to code.
- **Search:** Quick file, buffer, recent, and command pickers use a compact
  list. Project grep and references use a larger list with a preview. At
  narrow widths they switch to stacked layouts. Main navigation pickers have
  no borders: the list uses `#1E1E1E`, preview uses `#141414`, and selection
  uses `#2A2A2A`. The input prompt names its operation. Layouts cap at 110 x 36;
  backup files are excluded from file search. Generic selection dialogs retain
  their existing compact borders.
- **Completion and hover:** Completion shows at most eight items; docs open
  on request. Floats use opaque backgrounds. Borders are cell characters
  where separation is necessary, not simulated glow or shadows.
- **Notifications:** Compact opaque toasts: info 3 seconds, warning 6 seconds,
  and errors without a timeout. At most three are tracked. Overflow removes
  the lowest-severity toast first, oldest first on ties. A new info toast
  cannot evict an error; a fourth error replaces the oldest error in the live
  stack. All ordinary notifications remain in Snacks' session history.
  `<leader>n` opens a scrollable bottom history drawer; `q` closes it and
  `<leader>un` dismisses live toasts. Explicit caller timeouts are respected
  except the default 3000 ms value, which gets severity defaults. Callers may
  explicitly opt out of history. History is not saved across restarts.
  Identical notifications are not yet batched into counters.
- **Motion:** Panel motion and scrolling animation are off. Indent scope has
  an at-most-110 ms animation; set `vim.g.reduce_motion = true` before plugin
  setup to disable it.
- **Python:** `ty` provides language intelligence and Ruff handles linting
  and formatting. Python tooling is separate from the visual design.

## Critical review

The editing view is cleanest with the tree closed. In the screenshot with a
140-column viewport, opening a 28-column tree leaves roughly four fifths of
the width to code, so that state does **not** meet the 90% content target.
This is a deliberate tradeoff for navigation; close the tree when editing.

The previous picker was too close in brightness to the sidebar and used a
border to compensate. The revised input/list surface is brighter and the
preview uses a separate fill. An explicit end-of-buffer background also
caused short previews to have a black region below their contents; it now
inherits the window fill. The new design separates those surfaces cleanly in
the captured terminal grid, but needs inspection on the actual cluster display.

The earlier toast cap evicted by age alone, so an info message could remove a
persistent error. Severity-aware overflow fixes that. Snacks already kept
history before this change; dismissing a toast did not delete its record.
The new drawer makes this recovery path explicit. There is still no duplicate
counter, and a three-toast cap necessarily displaces an error if four errors
arrive. The history drawer contains all four unless a caller disables history.

Native `signcolumn=auto:1-2` now handles collisions, with the custom status
column disabled so that rendering follows the option. The original LazyVim
status column had separate Git and diagnostic components, so the old option
alone was not proof that those signs always overwrote one another. More than
two simultaneous signs can still exceed the new limit; priority decides
which two remain visible.

The pure-black canvas is a preference, not a promise of reduced eye strain.
OLED transition behavior depends on the display. `#14` is decimal 20, and
sRGB code values are not linear luminance steps; the claimed universal
"14-step luminance" failure is not a valid measurement of this interface.
The terminal controls font rendering, pixel geometry, and final display output.

`ty` and Ruff are native tools with documented editor integrations. Their
deployment still needs working executables and project environments; describing
them as fringe wrappers does not establish a dependency defect.

### Verification of this revision

- Actual embedded Neovim UI: one sign used 2 cells, two signs on one line used
  4, and removing the second sign returned the gutter to 2 cells.
- Three errors followed by an info message: all four remained in history,
  with all three errors retained in the live stack.
- Notification history opened as a scrollable bottom split (10 rows at
  100 x 30), rather than an automatically appearing overlay.
- File search and project grep inspected through captured Neovim UI grids.

### Remaining limits and rating

**8.5/10, subjective.** The layout is cohesive and the tested failure states
behave predictably. It falls short of a complete 10 because duplicate batching
is absent, content-area goals depend on the active layout, and no latency or
long-session comfort measurements have been made on the 1337 workstation.

### Technical references

- [Neovim sign column options](https://neovim.io/doc/user/options/#'signcolumn')
- [Neovim sign priorities](https://neovim.io/doc/user/sign/)
- [Snacks notification history](https://github.com/folke/snacks.nvim/blob/main/docs/notifier.md)
- [ty editor integration](https://docs.astral.sh/ty/editors/)
- [Ruff editor integration](https://docs.astral.sh/ruff/editors/)

The original brief supplied only section 1, including its tokens and baseline
options. Its table of contents referenced sections 2–5, but their component,
module, and acceptance details were not present. This document describes the
implemented design and its known gaps rather than assuming those details.

## Review commands

Open Neovim with this config, toggle the file tree with the existing explorer
binding, then try file search and project grep. Check a narrow 80 x 24 terminal
as well as a wide one. To verify the Lua files load without startup errors,
run `nvim --headless '+qa!'` in an environment where this config and its
plugins are installed.
