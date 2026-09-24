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
| Surface 1 | `#141414` | Sidebar, menus, picker |
| Surface 2 | `#1E1E1E` | Active row or selected item |
| Surface 3 | `#2A2A2A` | Rare emphasis |
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
  reserved sign column, a barely raised cursor line, and no end-of-buffer
  tildes. Errors can show inline; warnings stay in signs and the statusline.
- **Chrome:** One global statusline; a buffer tab row appears when useful.
  The command line is hidden until needed. A clean 100 x 30 viewport with two
  chrome rows and an approximately three-column number/sign gutter has about
  90.5% code cells; 80 x 24 has about 88.2%. These are estimates for the
  editor alone, not guarantees with panels, split windows, or long signs.
- **File tree:** Neo-tree opens on demand as a 28-column charcoal panel.
  Project name is short, source selector is hidden, and an already visible
  file gets a filled active row. Closing the tree returns its width to code.
- **Search:** Quick file, buffer, recent, and command pickers use a compact
  list. Project grep and references use a larger list with a preview. At
  narrow widths they switch to stacked layouts. Picker input is opaque.
- **Completion and hover:** Completion shows at most eight items; docs open
  on request. Floats use opaque backgrounds. Borders are cell characters
  where separation is necessary, not simulated glow or shadows.
- **Notifications:** Compact opaque toasts: info 3 seconds, warning 6 seconds,
  error until dismissed; new messages evict the oldest tracked toast when
  three are already tracked. Trace and debug messages are hidden from the
  live stack. Identical notifications are not yet batched into counters.
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

The picker still has a thin character border. Solid fill alone is hard to
separate against code at the same terminal brightness, but this does add more
visual structure than the pure fill ideal. The selected row is noticeably
stronger than its surrounding items, while the tree's many Git markers can
become noisy in a heavily modified repository. There is no duplicate-toast
counter and no dynamic two-column sign gutter for simultaneous Git and
diagnostic markers. The terminal controls actual OLED output, font rendering,
and pixel geometry; color values alone cannot guarantee them.

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
