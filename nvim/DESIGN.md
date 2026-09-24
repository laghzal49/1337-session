# Perfect Black Neovim

## Intent

Keep code in the foreground on a true `#000000` canvas. Give search a clear
focus, put secondary tools behind a keypress, and use solid surface fills to
show depth. The result should feel quiet during editing and informative when
an action needs attention.

This is a terminal UI. Cell borders, line height, font size, ligatures, and
pixel corner radius depend on the terminal; Neovim cannot promise 1 px borders
or 10 px corners. Use JetBrainsMono Nerd Font in the terminal for the intended
icons. The terminal dotfiles select JetBrainsMono Nerd Font Mono Italic at
13 pt, with a real Bold Italic face. The installer checks both italic font
files. Applying only Neovim's configuration does not change terminal fonts.

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
  reserved sign slot that expands to two on collisions, a barely raised cursor
  line, and no end-of-buffer
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
  returns its width to code. Below 110 columns the tree closes automatically
  after opening a file. At wider sizes it remains open for repeated navigation.
- **Search:** Quick file, buffer, recent, and command pickers use a compact
  list. Project grep and references use a larger list with a preview. At
  narrow widths the preview starts hidden and can open below the results.
  `Ctrl-P` toggles the preview from the input or result list, including file
  search. Wide searches give 58% of the split to results and expand to 90% of
  terminal width. Main navigation pickers have
  no borders: the list uses `#1E1E1E`, preview uses `#141414`, and selection
  uses a subdued purple `#24202E`. The input prompt names its operation. Quick and narrow layouts
  cap at 110 x 36; wide inspection caps at 130 x 36 to reduce path truncation;
  backup files are excluded from file search. Generic selection dialogs retain
  their existing compact borders.
- **Adaptive proportions:** After matching finishes, the picker height follows
  result count within its existing viewport cap. A preview keeps a useful
  minimum height; closing it lets a short list shrink further. The input is
  anchored near the top so shrinking does not recenter it vertically. Resize
  hooks are removed when the picker closes.
- **Spacing and path hierarchy:** A one-cell solid fill border supplies padding
  without visible outline glyphs. Preview padding uses its own surface color.
  Filenames come first in bold, with muted directories and middle truncation.
  File icons remain distinct by shape but share one neutral color. Folder
  names no longer inherit Git colors; state markers retain semantic colors.
- **Typography:** The requested terminal style is JetBrains Mono Nerd Font Mono
  Italic, 13 pt. Comments explicitly request italic in the theme. Actual
  italic and bold-italic font files are used to render the README capture.
- **Completion and hover:** Completion shows at most eight items; docs open
  on request. Floats use opaque backgrounds. Borders are cell characters
  where separation is necessary, not simulated glow or shadows.
- **Notifications:** Compact opaque toasts: info 3 seconds, warning 6 seconds.
  Identical active messages batch by severity, title, and text, displaying a
  `×N` counter. Individual original records remain in Snacks' session history;
  explicit caller IDs still have Snacks' normal replacement semantics.
  Errors produce one sticky summary showing the number of error notifications
  since the last review or dismissal. Detailed error messages stay in history.
  At most three live toasts remain, with lower-severity overflow removed first.
  `<leader>n` opens a scrollable bottom history drawer; `q` closes it and
  `<leader>un` dismisses live toasts. Either action acknowledges the error
  summary without deleting history. Info/warning caller timeouts are respected
  except the default 3000 ms value, which gets severity defaults. Errors always
  use the summary. Callers may explicitly opt out of history. History is not
  saved across restarts.
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
The drawer makes this recovery path explicit. Repeated toasts now batch, and
an error burst produces one persistent summary instead of three competing
messages. Reviewing the drawer acknowledges the summary. The tradeoff is that
reading an error's full text takes one explicit navigation action.

Native `signcolumn=auto:1-2` now handles collisions, with the custom status
column disabled so that rendering follows the option. The original LazyVim
status column had separate Git and diagnostic components, so the old option
alone was not proof that those signs always overwrote one another. The signs
handler now shows only the most severe diagnostic on each line across all
active diagnostic sources. Hiding/resetting a source restores the next
available diagnostic. The complete diagnostics remain available to floats,
navigation, and Trouble. The separate staged Git sign is disabled, leaving
room for one Git sign and one diagnostic; staging information remains in Git
tools and the tree. Extra breakpoint/bookmark signs can still compete for the
two available slots.

The pure-black canvas is a preference, not a promise of reduced eye strain.
OLED transition behavior depends on the display. `#14` is decimal 20, and
sRGB code values are not linear luminance steps; the claimed universal
"14-step luminance" failure is not a valid measurement of this interface.
The terminal controls font rendering, pixel geometry, and final display output.

`ty` and Ruff are native tools with documented editor integrations. Their
deployment still needs working executables and project environments; describing
them as fringe wrappers does not establish a dependency defect.

### Verification of this revision

Tests used Neovim 0.12.5 in the local container, with the repository's pinned
LazyVim, Snacks, Neo-tree, and Gitsigns versions.

- Actual embedded Neovim UI: one sign used 2 cells, two signs on one line used
  4, and removing the second sign returned the gutter to 2 cells.
- Five identical warnings: one live toast with `×5`, all five history records.
- Four errors: one summary, all four original error records in history.
- A subsequent info burst keeps the live stack at three and preserves the
  error summary.
- Two diagnostic namespaces on one line: one error sign; resetting the error
  namespace restores the warning, and resetting both removes the sign.
- Notification history opened as a scrollable bottom split (10 rows at
  100 x 30), rather than an automatically appearing overlay.
- File search and project grep preview toggling/geometry passed at 80 x 24,
  100 x 30, and 140 x 42; wide grep inspected through a captured Neovim UI grid.
- Tree file-open event closes the panel at 80 columns and preserves it at 140.
- Three warm local headless start-and-exit runs: 43.1, 49.0, and 42.9 ms.
  These exclude interactive UI startup, external language servers, and NFS.
- Synthetic 20,000-line buffer: 4,000 diagnostics collapsed to 2,000 signs;
  buffer creation, diagnostic publication, one edit, and redraw took 167.2 ms
  in this container. This is not a real-project LSP or typing-latency benchmark.
- Regression checks are saved in `nvim/tests/ui_review.py`.
- Adaptive search is tested by filtering the same file picker to one result,
  clearing its query, and checking that preview visibility survives resizing.

### Remaining limits and rating

The tested failure states behave predictably. A numerical score is not a
substitute for evaluating the rendered UI. The remaining gap is validation on the actual 1337
workstation: NFS startup, real ty/Ruff workloads, font rendering, and comfort
over a long coding session. Content-area goals still depend on the active
layout. Session-only notification history and one extra action to read error
details are deliberate tradeoffs, not guarantees of perfection.

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

Run the UI regression suite from the repository root with Neovim and its
plugins installed: `uv run --with msgpack python nvim/tests/ui_review.py`.
Set `NVIM_BIN` if the Neovim executable is not on PATH. The suite uses unsaved
test buffers and inherited cache/data directories; it does not edit projects.

| Action | Shortcut |
| --- | --- |
| Toggle picker preview | `Ctrl-P` in picker input/list |
| Review and acknowledge notifications | `<leader>n` |
| Dismiss live notifications | `<leader>un` |
| Close notification drawer | `q` |


## Edition 01 refinement

The previous layout gave nearly every surface equal weight. This revision adds
identity at launch and clearer emphasis during interaction:

- **Workspace:** a lavender 1337 wordmark, two numbered sections, direct action
  keys, and recent files from the current project. The wordmark and second pane
  require at least 100 columns and 30 rows; smaller windows keep the actions.
- **Python:** off-white variables and parameters reduce distracting red text.
  Blue-gray members, blue functions, lavender keywords, sand types, sage strings,
  and peach numbers separate roles. Documentation strings are muted to reduce
  competition with executable code. Tree-sitter and primary LSP token groups
  are explicitly paired. This changes presentation, not ty or Ruff behavior.
- **Command bar:** a 60% width charcoal surface capped at 90 columns, with solid
  padding instead of a rounded outline. The active prompt supplies the accent.
- **Documentation:** completion and hover use padded opaque panels. Ctrl-D toggles
  completion docs; Ctrl-B/F scroll them. Normal-mode Ctrl-B remains page-up.
- **Statusline:** a filled mode block and bold filename provide a reliable visual
  anchor; location remains neutral. Mode labels shorten on narrow terminals.
- **Selection:** a purple-tinted fill ties picker selection to the primary accent.

Screenshots are actual embedded Neovim grids rendered with the configured italic
font. The Python screenshot uses an illustrative unsaved buffer. They do not prove
physical OLED behavior or replace testing on the user's terminal. The regression
suite passed after these changes; dashboard and command popup geometry were also
checked at 80×24 and 140×42. No claim of universal perfection is made.
