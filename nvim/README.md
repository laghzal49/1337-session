# ElectroVoid — Neovim

A standalone Neovim configuration: **no LazyVim distribution**. lazy.nvim manages
47 explicitly configured plugins and dependencies, pinned in `lazy-lock.json`.
Pure-black code surfaces, regular font weight, readable comments, opaque panels, and **ty + Ruff** for Python.
On Python save, Ruff applies **safe fixes → organizes imports → formats**.
The editor shares its Flake8-style defaults from `ruff.toml` between linting and
formatting when a project has no Ruff config. Project rules take precedence;
unsafe fixes remain disabled.
Ruff also provides diagnostics through its LSP; `<leader>cf` runs formatting manually and `<leader>uf`
toggles format-on-save.

## Check your cluster or laptop

Run `:checkhealth session` after installation. This local report shows resolved
storage paths, missing tools, station detection, clipboard availability and
display settings. It does not install plugins or repair files.

From the repository, run `make bench` to measure startup on the actual machine.
This measures headless startup with existing caches, not first-use LSP latency;
use `:Lazy profile` to inspect plugin timing in an interactive session.
Then open a real C or Python file and check completion, `K`, copy/paste and save.

If your terminal shows boxes instead of icons, try `NVIM_ASCII_ICONS=1 nvim`.
To disable cluster auto-detection, use `STATION_1337=0 nvim` (or set the variable
in your shell). A deliberate `vim.g.station_1337` setting takes precedence.
Windows now uses its native PATH separator so Mason tools can be discovered.
Offline runtime regressions run with `make runtime`; no plugins are required.

## Recovery, plain fonts and live profiling

Normal editing buffers now keep swap files under Neovim's state directory in
`swap/`, with full-path filenames so projects with the same filenames do not
collide. Swap files are removed on a clean exit. After a crash, run `nvim -r` to
list recovery files, then `nvim -r path/to/file` to recover and inspect your work.
Persistent undo remains enabled for edits that have already been saved.
Recovery is periodic, not a guarantee that every last keystroke survives.

`NVIM_ASCII_ICONS=1 nvim` now also replaces native and Glance fold glyphs.
`:UIAccessibility on` switches native fold markers immediately; the stronger
contrast preset still has its existing behavior. No new plugins are added.

To investigate slowness on your actual cluster or laptop:

1. Run `:SessionProfile start`.
2. Use completion, `K`, project search and save in a real project.
3. Run `:SessionProfile stop` and inspect `:messages` for the report.

The report shows count, mean and maximum completed LSP request time, plus
event-loop delays while working. These are observations of server round trips
and editor stalls, **not** end-to-end timings for each key or popup. Cancellation
and unfinished requests are excluded. The loop probe also reflects OS scheduling
and sleep. Profiling does not collect source text or paths, and adds no timer or
LSP observer until started. Starting again clears earlier samples.

`:ConfigTools` and `:checkhealth session` now share one tool inventory with
feature-specific installation guidance. Project grep and the Git UI report
missing dependencies before attempting to open. Existing documentation modules
remain separate: `smart_docs` chooses a source, `docs_resolver` resolves symbol
identity, `docs_store` reads cached content, and `documentation` owns the popup.
They have distinct responsibilities; removing them would remove behavior.

## Current colors and compact popups

![Coordinated colors and compact command popup](assets/popup-command-140.png)

ElectroVoid by SireOmega is the default, ported from the supplied Zed theme in
[`themes/electrovoid.json`](themes/electrovoid.json): pure black, white text,
purple focus and cursor accents, cyan information and the source syntax colors.
The embedded terminal uses the same 16 ANSI colors as the
[Kitty and Alacritty themes](../dotfiles/README.md#electrovoid-terminal).

Start with `NVIM_COLOR_STYLE=crimson nvim`, `NVIM_COLOR_STYLE=rose nvim`, or
`NVIM_COLOR_STYLE=classic nvim` for an earlier palette. The popup gallery and
screenshots below document earlier Perfect Black revisions.

## Rose UI polish and verified previews

Rose now gives variables a clear pink accent, keeps parameters and members
slightly softer, and uses warm-neutral strings so every identifier is not the
same color. Success indicators stay green, while the original classic palette
is unchanged. The active line has a dedicated low-glare violet surface and the
statusline now shows a compact, readable mode capsule with more spacing.

To capture the **actual Neovim UI** (not a composited mockup), install Neovim,
the config's plugins, and `pip install Pillow msgpack`, then run:

```sh
python3 scripts/capture-nvim.py --full --view editor --output editor.png
python3 scripts/capture-nvim.py --full --view explorer --output explorer.png
python3 scripts/capture-nvim.py --full --view completion --output completion.png
python3 scripts/capture-nvim.py --full --view documentation --output documentation.png
```

The editor uses a real C buffer, explorer opens Snacks, completion requests
Blink.cmp, and documentation uses the existing `config.documentation` floating
panel with example help text. Panels fail explicitly if their plugin does not
open. GitHub Actions publishes all four views as the
`neovim-rose-preview` artifact after checking readability and that each panel
differs from the editor capture.

## A complete workspace refresh

See the [full UI upgrade checklist](UI_UPGRADE_TODO.md) and
[color role map, critique and research](DESIGN.md). Syntax, LSP, completion and
outline colors now share one palette; measured foreground contrast is at least
4.77:1 across the tested canvas, panel and default selection backgrounds.

![New project dashboard](assets/redesign-dashboard.png)
![Black Deck command guide](assets/redesign-deck.png)
![New editor hierarchy](assets/redesign-editor.png)
![Red variables and TODO comment labels without bold](assets/redesign-annotations.png)
![Responsive keymap guide](assets/redesign-guide-100.png)
![Explorer with readable folder colors](assets/redesign-explorer.png)
![Project files with live preview](assets/redesign-picker.png)
![Responsive Station Health report (example data)](assets/redesign-station-40.png)
![Real Python debugger on a narrow screen](assets/redesign-debugger-40.png)

The original design (still available in `classic` mode) uses a pure-black canvas,
off-white text, blue focus accents and regular font weight in both active and inactive
editor splits. Its folders are blue, functions cyan, types teal, strings green,
keywords violet and values orange. Surrounding controls stay quiet, with
a dark status bar and restrained borders. Built-in functions share the function palette. The project home shows
project state, one-key actions, recent project files and workflow shortcuts. The branch is fetched
asynchronously; `tracked clean` deliberately excludes untracked files.

Native titles show the path and modified state above each editor split. The
statusline gives mode, cached project/branch, diagnostics, search count,
debug/recording state and position in a clear hierarchy. Narrow terminals keep
only the essential state. Buffer tabs use numbered basenames and short directory prefixes for duplicate
filenames, with one selection marker and no repeated diagnostic badges. Borders and guides are quiet; active split focus is visible.
The file path lives in the window title instead of appearing a third time below
the editor. Station startup alerts ignore small home caches and report quota
pressure only when a monitored cache reaches 100 MiB. Station Health now wraps
full details and resizes to small terminals; repair and recheck keys remain visible.

Everyday files, grep, buffers, diagnostics and symbols now use **Snacks Picker**:
side-by-side live preview on wide screens with more room for results, stacked
preview on smaller ones, Ctrl-P/Ctrl-N navigation, Tab to select, Alt-P to toggle
preview, Escape to close and `?` for actions. Mini Pick remains
for specialized offline documentation, Make targets and code-action previews;
the now-unused Mini Extra plugin and unreachable navigation fallback are removed.
For a minimal search popup, `<leader>fF` opens fast files and `<leader>sG` fast
grep using the existing lightweight picker. The preview-rich picker measured
~25 ms to first files results versus ~13 ms for the compact picker on this machine;
the richer UI trades a little latency for a visible preview.

The explorer keeps Git status in separate markers so changed folders stay blue.
Below 80 columns, the tree moves beneath the editor; wider sidebars use at most
30% of the screen. Command popups resize with the terminal, input prompts fit
including their borders, and Escape cancels the prompt in one press. Completion
shows compact source labels and kind names when space permits. Notifications use
colored severity headings with neutral body text; `<leader>n` opens newest-first
history, with `q` or Escape to close.

### Popup redesign

Popups use nearly black surfaces, blue edges for input/selection and quiet gray
edges for reference text. Text stays at regular weight. Completion has a live
selection count and key hints; documentation has a symbol title, reading margin,
scroll position and controls. Below 100 columns, completion docs stack vertically.
Command suggestions sit below the padded prompt without covering its border.
Rename/input prompts label Enter and Escape; code-action menus fit their contents.
Notifications sit at the lower right; `<leader>n` opens a searchable history float.
Watch/stack inspectors open centrally with action hints. Diagnostic floats show
severity, source and one copy of the diagnostic code.

See the [popup previews and controls](POPUPS.md).

The old disabled theme spec and duplicate text-object ownership are also removed.

`:UIAccessibility on` (or `<leader>ua`) switches to plain icons, stronger borders
and non-italic comments/docstrings. Loaded icon providers and command guides
refresh when toggled; `off` restores the previous font and highlight preferences.

Variables remain vivid red without bold, with pale rose parameters and rose
members. Tree-sitter and LSP semantic tokens share these colors. The statusline
shows attached language servers when idle and keeps loading progress out of floating
popups. Long progress messages are capped; diagnostic popups include diagnostic
codes so a warning can be identified precisely. Ty and Ruff wait for a filename before
attaching to a new Python buffer, then attach automatically when it is named.

TODO, FIXME, NOTE, HACK, WARN, PERF and TEST comments receive colored labels.
Both `TODO: message` and `TODO message` work, including `TODO(name): message`.
Use `]t` / `[t` to jump and `<leader>st` to search. Highlighting stays inside
comments, so strings containing these words are left alone.

The keymap guide (`<leader>?`) starts with everyday actions, wraps long rows,
and adapts when the terminal resizes. `/` searches the guide and `]]` / `[[`
jump between sections; `q` closes it.

Workspace mode (`<leader>uw`) opens only panels that fit and have useful content,
returns focus to your editor, and preserves windows you repurpose while working.
It no longer automatically opens a terminal. Project tasks run in the background:

| Key | Action |
| --- | --- |
| `<leader>rt` | Discover and run a project build/test/script |
| `<leader>rr` | Rerun the last task |
| `<leader>rs` | Stop the current task |
| `<leader>ro` | Open live or completed task output |

Tasks recognize Make, package.json scripts, Cargo, Go and Python projects. Tool
output stays available; failures with parseable file locations populate quickfix.
Live logs update in batches without taking editor focus. They follow new lines
while you are at the bottom and preserve your position when you scroll upward.
Quickfix parsing covers Cargo, TypeScript/ESLint, Go/compiler and Python outputs,
with the current buffer's compiler settings as a fallback.
Output retention is capped at 1 MiB or 5,000 lines per stream, with a visible
truncation notice. Stopping a task sends SIGTERM, then SIGKILL after one second
if needed. POSIX cancellation stops the task's process group, including ordinary
child processes. Windows stops the direct child; descendants that create their
own session can escape group cleanup.
Tools/packages are installed explicitly, never by opening a project.

The follow-up audit also fixes small-window and Unicode title sizing, keeps Git
change status visible beside long branch names, and makes the dashboard build
action discover tasks across supported projects. Root discovery respects local
working directories and recognizes standalone Node and Python projects. TODO
navigation and selected-line Git history retain their intended keybindings.

The additional project controls are available without adding plugins:

| Control | Feature |
| --- | --- |
| `<leader>ua` / `:UIAccessibility` | Toggle plain core icons, stronger borders and simpler decoration |
| `<leader>uB` / `:BufferPerformanceRestore` | Restore features after shrinking a large buffer, preserving unsaved edits |
| `<leader>Df` / `:DebugTarget` | Choose a debug target, arguments, module or test file |
| `:DebugProjectLaunch` | Explicitly choose a project profile |
| `<leader>Dg` / `:DebugProjectGenerate` | Generate a profile for the current Python or C/C++ project |
| `<leader>Dj` / `:DebugProjectEdit` | Create or edit `.vscode/launch.json` |
| `<leader>Dh` / `:DebugProjectCheck` | Validate project debugger profiles |
| `gsa` / `gsd` / `gsr` | Add, delete or replace surrounding characters |
| `gsf` / `gsF` / `gsh` / `gsn` | Find, highlight or change surround search width |
| `:StationVenvMigrate` | Move a real project environment to local storage while retaining its original backup |

Flash uses `s` immediately; surround shortcuts now start with `gs`. Start with
`NVIM_UI_PRESET=accessible` to make the accessible preset your default. Explicit
`vim.g.black_ui_preset` takes precedence. Live preset changes preserve custom
highlights and the current theme; some third-party hardcoded glyphs may remain.

Performance changes extend beyond startup: cached root lookups, one asynchronous
Git probe per project, no dashboard filesystem walk, no duplicate bufferline
LSP diagnostic pass, bounded large-buffer guards even after edits, and a bounded
format-on-save timeout (1.5 seconds for the three Ruff stages; 500 ms elsewhere). Files over 1 MiB or 20,000 lines switch to a conservative
plain editing mode. After reducing them, use `<leader>uB` to restore the prior
features without wiping the buffer or changing unsaved edits. Recovery refuses
buffers still above the size or Markdown/minified-file budgets. Existing disabled
diagnostic/decorative preferences are retained.

Matched five-run benchmarks on this machine: cached headless startup median
**20.78 → 19.08 ms** (~8% lower); attached idle RSS **21.4 → 20.0 MiB**.
These are local measurements, not promises of LSP or interactive latency.
The final upgrade run supersedes the earlier 15.38 ms audit measurement.
Raw results are in `tests/redesign_results.json`; screenshots are rendered from
Neovim's actual attached UI grid, not mockups.

The bounded typing benchmark (`tests/typing_results.json`) measured median
input/buffer/redraw RPC roundtrips of 4.41 ms for 2,000-line Lua, 4.75 ms for C,
and 51.81 ms for Markdown. Guarded 22,001-line Lua improved from 17.38 ms to
0.54 ms after preventing filetype plugins from restarting its parser. These
measurements exclude LSP and physical display latency; Markdown remains slower.

## Responsiveness and everyday controls

Completion loads on first Insert/Command mode entry (or when an LSP needs its
capabilities); the parser manager loads on the first file. The debugger and its two UI dependencies are loaded only on demand.
Files above 1 MiB, or averaging more than 1,000 bytes per line, use Snacks' plain
big-file view: manual folds, no Tree-sitter highlighting/context, no completion,
and no format-on-save. Explicit `<leader>cf` still formats on request. The existing
stricter Markdown line/size limits continue to apply.

Comments, inactive buffer labels and panel hints have brighter contrast while
using a pure-black canvas and blue navigation accents. The statusline removes secondary details in narrow terminals. Flash labels use dark text on violet.

| Key | Action |
| --- | --- |
| `<leader>ud` | Toggle diagnostics for the current buffer |
| `<leader>uv` | Toggle wrapping in the current window |
| `<leader>ul` / `<leader>ur` | Toggle absolute / relative line numbers |
| `<leader>bo` | Close other buffers, prompting for unsaved changes |
| `j` / `k` | Move by displayed lines; counts use logical lines |

Reopened files restore their last cursor position unless a position was already
selected. Writes keep a temporary backup until they succeed. Station Mode detects
cluster filesystem and hostname signals; a repository name or login alone does not
activate cluster scans. Use `STATION_1337=1` or `:StationMode on` to opt in elsewhere.
The inode quota parser also handles `df` output without a Lua multiple-return error.

Validation on Neovim 0.11.5: five cached headless launches per config had median
startup **20.78 ms before → 19.08 ms after**. These numbers describe this test
machine, exclude first-install costs, and do not measure LSP readiness or UI latency.
Run `NVIM_BIN=/path/to/nvim python3 nvim/tests/startup_bench.py --runs 5`
and `nvim --headless '+lua dofile("nvim/tests/responsiveness_review.lua")' +qa!`
from the repository root with `XDG_CONFIG_HOME` pointing to the repository.
The responsiveness review expects a non-cluster host with no Station Mode override.

## Debugger and yank feedback

Yanking briefly highlights exactly the copied text for 180 ms, including Visual
selections. There is no popup for each copy.

Debugging uses nvim-dap with scope, watch, stack, breakpoint and console panels
in the shared black UI. It loads only when a debug key is pressed.
Panels adapt to the terminal: full sidebar and console from 120 columns × 32
rows, sidebar from 80 × 24, and bottom scopes on smaller screens. Resize keeps
the source editor focused; replacing a debugger panel with your own buffer stops
automatic rearrangement. A yellow arrow and subtle line tint identify the stopped
line without repainting its syntax.
Panels open when a session starts and close when it ends.

![Debugger action menu during a real Python breakpoint](assets/popup-debug-menu-140.png)

`Space DD` or `:Debug` opens actions appropriate to the running/paused state.
Type to filter, Enter to select, Escape to close. The menu stays compact on
narrow terminals and scrolls to additional actions.

New to debugging? Press `Space D?` or run `:DebugHelp` for an in-editor tutorial.
It explains breakpoints, stepping, variables, watches, targets and troubleshooting.
Press `t` in the guide (or run `:DebugExample`) to open a temporary Python practice
project in a new tab, with a breakpoint already set. Press F5 to start, then F10
to see a value change. The guide opens without loading a debugger, and the
example preserves your editing buffers. See the [full debugger guide](DEBUGGING.md).

| Key | Action |
| --- | --- |
| `F5` / `<leader>Dc` | Start the project / continue the active session |
| `<leader>DD` / `:Debug` | Contextual debugger action menu |
| `<leader>D?` / `:DebugHelp` | Tutorial and keyboard guide; `t` opens the practice project |
| `<leader>Df` / `:DebugTarget` | Choose target, arguments, module, attach, or detected pytest file |
| `<leader>DR` / `:DebugRestart` | Restart active session / rerun this project |
| `<leader>DC` | Run to cursor while paused |
| `<leader>Dw` / `:DebugWatch` | Add a watch expression |
| `Shift-F5` | Stop session |
| `F10` / `<leader>Do` | Step over |
| `F11` / `<leader>Di` | Step into |
| `F12` / `<leader>DO` | Step out |
| `<leader>Db` / `<leader>DB` | Breakpoint / conditional breakpoint |
| `<leader>Du` / `<leader>De` | Toggle panels / evaluate expression or selection |
| `<leader>Dv` / `<leader>DS` | Floating watch expressions / call stack |
| `<leader>Dr` / `<leader>Dt` | Console / terminate |

The installer sets up debugpy in an isolated environment for Python debugging.
If you skipped that step, install it manually:

```sh
# Linux; default Neovim data directory. Adjust if XDG_DATA_HOME is customized.
uv venv ~/.local/share/nvim/debugpy
uv pip install --python ~/.local/share/nvim/debugpy/bin/python debugpy
```

Alternatively install debugpy in the project environment, or set
`vim.g.debugpy_python` to an interpreter that contains it. The debuggee uses the
selected Python interpreter override, then project `.venv/bin/python` or
`venv/bin/python`, the active `VIRTUAL_ENV`, and finally `python3` on PATH.
Open a Python file, set a breakpoint, and press F5. A single project profile
starts directly; multiple profiles prompt once and remember the choice for that
project during this Neovim session. `Space Df` offers file launches with arguments,
modules, local attach and a pytest-file launch for `test_*.py` / `*_test.py`.
Argument/module prompts use the shared popup UI; Escape cancels the launch. Attach requires an existing
`python -m debugpy --listen 127.0.0.1:5678 --wait-for-client script.py` process.
`<leader>DL` adds a logpoint; `<leader>Dp` pauses; `<leader>Dl` reruns; `<leader>Dx`
clears breakpoints. Live local attach was verified with a disposable debugpy server.

Project profiles use `.vscode/launch.json`; F5 reads the current project each time.
Target selections capture the source path before opening a popup, so switching
buffers cannot silently change the launch. Reruns stay scoped to their project.
Modified project buffers prompt to save before launch; cancelling leaves them
untouched. Once a session initializes, rerun remembers its resolved arguments.
Missing working directories, programs, interpreters and static Python modules
report actionable errors before launch.
On first use, the editor creates a language-specific profile for the current
Python or C/C++ file when none exists. `:DebugProjectGenerate` creates it
explicitly; `:DebugProjectCheck` creates a missing profile and validates it.
Existing launch files are never overwritten. For C/C++, the generated profile
uses an existing project-named or `a.out` executable when found; build first.
The provider reads the current buffer's project, resolves `${workspaceFolder}`,
and accepts JSON/JSON comments with static arguments. VSCode prompted inputs and
`preLaunchTask`/`postDebugTask` are rejected with guidance; run project tasks
explicitly. Project profiles do not modify the global built-in configurations.

For C/C++, install **GDB 14+ with Python/DAP support**, build with debug symbols
(e.g. `cc -g -O0 main.c -o main`), open the source, and press F5. If the profile
target is missing, choose a discovered binary from the project root, `build`,
`bin`, `debug`, `Debug` or `cmake-build-debug`, or browse for it. Discovery is
bounded and skips dependency trees. Builds remain explicit. GDB is checked for
Python/DAP support before starting; `vim.g.debug_gdb` can point to a newer
user-local installation. Debugger packages are not installed automatically.
Missing adapters show setup guidance. Python breakpoints, variable evaluation,
step-over and clean session/panel exit were tested against real debugpy 1.8.22;
C/C++ launch/attach configuration is provided but an actual GDB session was not tested
in this environment.

Cleanup removed the disabled onedark spec and stale Mini Files status labels.
Function/class text objects are now owned only by nvim-treesitter-textobjects;
Mini AI retains its other useful objects. Most existing pins are retained. Aerial uses its `nvim-0.11` branch
(`c5e56945d9703f7079ccff484b35d0e4c231dd6c`) so the outline works on the
advertised Neovim version. Tree-sitter is pinned for the same reason: its old pin requires Neovim 0.12,
so it is explicitly pinned to the last pre-vim.list main snapshot compatible with
0.11 (`4d9916e477e5d4e3b245845dfd285edf429f3252`). The compatible parser
installer and real Python text-object queries were checked on 0.11.5. The three
debugger dependencies are added and unused Mini Extra is removed from the lockfile.

## Workspace

![Decorated workspace dashboard](assets/workspace.png)

![Perfect Black live dashboard](assets/perfect-black-ui.png)

The current theme uses black surfaces, blue navigation and red variables.
The dashboard and older editing screenshots below document earlier revisions.

Navigation now gives a subtle 180 ms destination beacon for definitions,
references, diagnostic jumps, jump history, search selection, buffer switching,
Flash, Aerial and quickfix selection. Ordinary `hjkl` movement stays quiet.
The physical cursor uses a block in Normal/Visual, a bar in Insert/Command,
and an underline in Replace; terminal support determines cursor colors.

Split focus keeps inactive windows dim and uses one native blue separator anchor.
Panel highlights are preserved, including Edgy. At 130 columns or wider, the
existing statusline shows the enclosing function/class from an idle-updated
cache. Python, C/C++ and Lua use Tree-sitter; other languages can reuse
already-populated Aerial data. It hides at top level and above 10,000 lines or
1 MiB. No extra status row or sidebar is added. The overview rail is deferred.

Harpoon has been removed; use the existing buffer picker and `Shift-H`/`Shift-L`.
Command suggestions use Blink in Noice's command input: Tab selects a suggestion,
Enter accepts and executes it. Suggestions never replace your input automatically.

## Editing surfaces

![Python palette and status bar](assets/python.png)

![Blink completion and documentation](assets/completion.png)

![Command bar](assets/command.png)

These editing images and the Makefile image below document earlier palette
revisions. Current editor, picker, explorer and guide captures appear at the top.

## File browser

Snacks Explorer is the only file browser. Open it with `<leader>e` (toggle)
or `<leader>fe`. Use `<CR>` to open, `a` to create, `r` to rename, `d` to delete,
and `?` for its keymap help. Mini Files and its obsolete decoration code are
removed.

Markdown reader mode is available with `<leader>mr` (or
`:MarkdownReaderEnable`/`:MarkdownReaderDisable`); it enables rendered Markdown,
comfortable wrapping, concealed syntax, and a distraction-free view,
then restores the previous window settings when toggled off. Rendering is bounded
for very large files and keeps links, code languages, checkboxes, tables, quotes,
and YAML front matter readable.

Markdown above 5,000 lines or 512 KiB uses a plain view with manual folds,
without Tree-sitter highlighting/context or rendering. These thresholds are
configurable in `config.markdown`. Reader mode avoids spellchecking and restores
window options when returning to code. Small files keep normal rendering.

The leader popup is **BLACK DECK**, rendered by the existing Which-Key. Immediate
commands come first, followed by Files, Buffers, Tasks and Debug; each group has
a distinct icon with a live ASCII fallback. Escape closes; Backspace returns from
a nested group. `:BlackDeck` enables
Which-Key's supported repeating mode. Existing keypaths remain available.

Documentation keys:

- `K`: Smart Docs. Qualified offline reference first, then asynchronous LSP/project
  hover, then the existing Python builtin fallback or useful local docs search.
- Insert `Ctrl-K`: compact signature help only; it never opens a reference manual.
- `gK`: Deep Docs. Exact offline reference or MiniPick search, without LSP content.

Press `K` again to focus the reference surface. Normal Vim scrolling and `/` work
there; `q` or Escape closes it. Offline pages support `Ctrl-O` history and Enter on
an exact indexed reference. Blink retains automatic completion docs and `Ctrl-b`,
`Ctrl-f`, `Ctrl-d` scrolling/toggling. All reference surfaces share Perfect Black
colors, bounded dimensions and the existing Markdown renderer.

Python 3.14, C, C++, Lua 5.1, Bash and CMake are the default external references.
They describe those versions, not every dependency or project API. Local manuals
and prebuilt exact/fuzzy indexes live in `stdpath("data")/perfect-black/docs`,
outside Git. Lookup never downloads documentation or scans page files.

```vim
:Docs
:Docs python Path
:Docs update python
:Docs health
:DocsBrowse
:DocsBrowse Path
:DocsBrowse python Path
:DocsUpdate
:DocsUpdate python
:DocsHealth
```

An already-open session can register these commands without restarting:
`:lua require('config.docs_lifecycle').setup()`. `:Devdocs` and `:DevdocsUpdate`
remain aliases for the earlier command names.

The installer attempts the initial download without failing the installation when
offline. Neovim checks the small manifest and index-file presence five seconds
after startup and asynchronously updates missing or stale sets. It performs no
startup network work. Configure before setup:

```lua
vim.g.black_docs_auto_update = true -- false disables automatic downloads
vim.g.black_docs_max_age_days = 7
```

Shell equivalent: `scripts/update-docs all` or `scripts/update-docs python`.
The launcher uses uv; the stdlib-only Python 3.11+ backend can also run directly:
`python3 nvim/scripts/update_docs.py all`. Updates publish immutable generations
through an atomic manifest, with a lock against concurrent updates. Failed updates
preserve existing manuals. `--catalog FILE` supports additional docsets.

Anchored pages show the actual reference section, with a 200-line display cap and
an explicit source link; `gx` opens that link only when requested. Pages above
1 MiB are refused. Ambiguous symbol names go to search, not a guessed namespace.

On idle, supported LSPs underline semantic uses of the cursor symbol within the
viewport. Moving or entering Insert clears them immediately; unsupported servers
show no potentially misleading text matches. This replaces Mini Cursorword.
Multiple LSP locations and code actions use the existing picker; Tab previews
locations or replacement text already supplied by the server. Glance remains
the explicit peek tool.

## Makefile targets

![Makefile target picker in Neovim](assets/makefile.png)

Actual Neovim UI-grid capture of the current configuration. Use `<leader>cm`
or `:Make` to pick a target, `:Make test` to run one directly, and `<leader>cM`
to run the Makefile's default target in a terminal. `:MakePick` also opens the
picker. The picker lists literal targets in the root Makefile; included files,
variable-generated targets, and pattern rules are not expanded. GNU Make runs
the recipe with its normal dependencies and variable expansion.

The debugger is optional and loads on its first keypress. Run `:Lazy clean` to
remove unused local plugin checkouts after updating, then restart Neovim.

## Everyday workflow

- **Snacks Picker:** files, live grep, buffers, commands, diagnostics and
  symbols. Up/Down or Ctrl-P/Ctrl-N moves through results; Alt-P toggles preview,
  Tab selects a result, Ctrl-Q sends results to quickfix, and Enter opens it.
- **Snacks.explorer:** modern, fast file explorer with tree navigation, git status indicators, LSP integration, floating/sidebar layouts, and built-in file operations.
- **Aerial:** on-demand code outline, with Tree-sitter and LSP backends.
- **Glance:** peek at definitions/references without leaving the source.
- **Quicker:** editable quickfix with expandable context.
- **Tiny Inline Diagnostic:** wrapped cursor-line errors, quiet during insertion.
- **Blink completion:** LSP, paths, snippets and buffer words, with documentation
  and signature help. Enter accepts an explicitly selected item; otherwise it
  inserts a newline. Ctrl-E dismisses completion. Insert Ctrl-K opens only the
  function signature and active parameter documentation, bounded to eight rows.
  Missing signature responses do not fall back to a large hover or reference page.
  Smart K provides contextual/reference documentation in Normal mode. Delayed
  replies are ignored after moving or editing. Use Ctrl-D to toggle completion
  docs and Ctrl-B/Ctrl-F to scroll them; Ctrl-W K moves up a split.
  Local words from the active buffer appear while the LSP responds; semantic
  suggestions get a ranking boost. Exact matches come first, with the native
  matcher's usage/proximity ranking and typo tolerance retained. Documentation
  appears 80 ms after selection. Buffer scanning is bounded to 128 KB, with at
  most 30 buffer results and 100 total results. Tab/Shift-Tab follow snippet
  placeholders before navigating the completion menu.
- **TreeSJ, incremental rename, selected text objects:** editing tools with no
  permanent panels. Native inlay hints are off until you toggle them.

Snacks provides its explorer, picker, dashboard, terminal, input, indentation and Git UI. Neo-tree, Namu, Colorful Menu and Endhints are
removed. There are no inherited distribution keymaps or background tool installs.

## Lines and terminal

Editing windows show the current line number and relative numbers for nearby
lines, so `5j` moves down five lines. The floating terminal hides line numbers.

Use `<leader>ft` or `Ctrl-T` to focus the project terminal. Press the same key
while it has focus to hide it; its shell stays running. `Ctrl-/` is an alternate
binding when the terminal emulator sends that key combination to Neovim.
Press `Esc` twice to leave terminal input mode, then `i` to return to it. To
end the shell, run `exit` inside the terminal. Terminal startup errors are
shown as a notification instead of interrupting the editor.

## Keys

`<leader>` is Space.

| Action | Keys |
|---|---|
| Find files / search text | `<leader><space>` / `<leader>/` |
| Buffers / recent files | `<leader>,` / `<leader>fr` |
| Commands / keymaps / help | `<leader>sC` / `<leader>sk` / `<leader>sh` |
| Move / preview / mark / send marked to quickfix | `Up/Down` or `Ctrl-P/Ctrl-N` / `Alt-P` / `Tab` / `Ctrl-Q` in Snacks picker |
| Toggle file explorer (Snacks explorer) | `<leader>e` |
| Open file explorer | `<leader>fe` |
| Code outline / find file symbol | `<leader>cs` / `<leader>ss` |
| Find workspace symbol | `<leader>cS` |
| Peek definition / references | `<leader>cgd` / `<leader>cgr` |
| Definition / references / hover | `gd` / `gr` / `K` |
| Rename / code action / format | `<leader>cr` / `<leader>ca` / `<leader>cf` |
| Split/join structure | `<leader>cj` |
| Editable quickfix / expand / collapse | `<leader>xQ` / `>` / `<` |
| Indentation / subword text objects | `ii`, `ai` / `iS`, `aS` |
| Next / previous completion | `Ctrl-N` / `Ctrl-P` (also `Tab` / `Shift-Tab`) |
| Completion docs toggle / open and scroll | `Ctrl-D` / `Ctrl-B`, `Ctrl-F` in insertion |
| Native hints / format-on-save toggle | `<leader>uh` / `<leader>uf` |
| Notification history / dismiss | `<leader>n` / `<leader>un` |
| Makefile target picker / default target | `<leader>cm` / `<leader>cM` |
| Focus or hide project terminal / Git UI | `<leader>ft` or `Ctrl-T` / `<leader>gg` |
| Restore session | `<leader>qs` |
| Save / previous buffer / next buffer | `Ctrl-S` / `Shift-H` / `Shift-L` |

Quicker `:w` updates source buffers. Previously unmodified buffers are autosaved;
already modified buffers remain unsaved. Ruff can reformat TreeSJ layouts on save.

Notification history retains the latest 500 messages, capped at 16 KiB each, and
reports discarded records. Errors stay visible until acknowledged; their aggregate
count survives rollover, but older details can age out. History is session-only.

## Python language tools and richer signatures

Python uses **ty for types, completion, hover, signatures and navigation**, with
**Ruff for lint diagnostics and source fixes**. Both use the same physical project
root. Completion offers auto-imports and function-call snippets; Tab advances
through snippet placeholders. Diagnostics stay out of Insert mode and ty checks
open files rather than scanning the entire workspace for errors.

| Control | Action |
| --- | --- |
| Insert `Ctrl-K` | Show active signature with parameter documentation first |
| `K` with documentation visible | Focus the documentation window |
| `[s` / `]s` in focused signature help | Previous / next overload |
| `<leader>cI` / `:PythonOrganizeImports` | Organize imports using Ruff |
| `<leader>cF` / `:PythonFixAll` | Apply Ruff's configured fixes to the buffer |
| `<leader>cD` / `:PythonDocstring` | Generate an editable docstring for the enclosing definition |
| `<leader>cp` / `:PythonLspInfo` | Show project, interpreter candidate and attached servers |
| `:PythonInterpreter /path/to/python` | Set a session-local interpreter override for this project |
| `:PythonInterpreter auto` | Clear that project override and resume environment discovery |

### Generate Python docstrings

Inside a Python function or class, type **`"""`** on its first indented line.
The third quote automatically expands into a Google-style docstring with editable
descriptions. This also works immediately after writing a definition, before
adding its body. You can fill in the summary, arguments and other detected fields.
See [Google's docstring conventions](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings).

For an existing definition, **Space cD** (capital D) also generates its docstring.
Neogen reads the syntax tree and uses
[PEP 257's structure](https://peps.python.org/pep-0257/): triple double quotes,
a summary ending in a period, and a blank line before additional sections.
Google-style `Args`, `Returns`, `Yields`, `Raises` and `Attributes` sections are
included when detected. PEP 257 defines structure, not a particular section style.

Type over the selected summary, then use **Tab / Shift-Tab** to move between
editable descriptions; Escape returns to Normal mode. Fill in the actual behavior
and check the detected fields before saving. The generator supplies a scaffold,
not an explanation of what your code does. Ruff's existing save pipeline still applies.

`:PythonDocstring func`, `:PythonDocstring class` and `:PythonDocstring file`
explicitly choose a function, class or module. Existing docstrings are preserved;
the cursor moves to them. Inline bodies are expanded, shebangs and encoding
comments are kept, and invalid definitions are left untouched. Nothing is saved
or executed by docstring generation. Neogen loads only on first use; the Python
Tree-sitter parser comes from the installer (`:TSInstall python` to repair it).
Automatic expansion only applies to the empty first statement of a function or
class; quotes in assignments, later statements and existing documentation keep
their normal behavior.

### Signature help and environment selection

Overload counts appear in the signature title; active parameter documentation
precedes general documentation so it is visible in compact help. UTF-16 label
ranges highlight Unicode parameters correctly. Manual documentation requests
have a 1.5-second deadline and cancel superseded work; replies from a different
window or changed buffer cannot replace your current documentation. Builtin
fallbacks use isolated Python without importing project code, and coalesce
identical requests. Async Python definitions retain their project documentation
identity instead of accidentally opening builtin references.

The explicit Ruff actions edit the current buffer. Saving runs Conform's
`ruff_fix`, `ruff_organize_imports`, then `ruff_format` sequentially. All safe
fixes enabled by project rules are eligible; this does not enable every Ruff
lint rule. Project excludes/ignores and unfixable rules are respected. Automatic
unsafe fixes are disabled even if a project enables them. `<leader>uf` toggles
the entire save pipeline; `vim.b.autoformat = false` disables it for one buffer.
Large-file guards still skip automatic formatting. Ruff LSP formatting remains
disabled to avoid duplicate edits. ty's project configuration and normal environment
discovery remain authoritative unless you explicitly set an interpreter override.
Changing an interpreter restarts only this project's ty clients asynchronously,
keeping their eligible buffers attached; Ruff and other projects continue running.
The information panel reports a candidate, not an assertion about the server's
resolved interpreter. Python tools must be on PATH before opening Neovim.

## Setup / update

Requires **Neovim 0.11+**, Git and ripgrep. Select **JetBrainsMono Nerd Font Mono,
13 pt** in the terminal, with its real Italic face. Terminal fonts are not set by Lua.
Use the [repository installer](../Readme.md) for the no-sudo workstation setup.
Run `:IconInfo` to check the configured icon mode. If your terminal cannot use
Nerd Font glyphs, launch with `NVIM_ASCII_ICONS=1 nvim` for clean text icons
instead of boxes or corrupted symbols.

For an existing installation, update the repository, then run `:Lazy restore`.
After checking that the new config works, `:Lazy clean` removes unused plugin
checkouts. This does not remove project data.

Install Python tools with `uv tool install ty` and `uv tool install ruff`, ensuring
uv's executable directory is on PATH before opening Neovim. The bootstrap script
does this automatically and verifies both versions. Ruff uses each project's
Ruff configuration (or Ruff's defaults). `ruff check` remains available for
CI/scripts. `:ConfigTools`
reports missing executables. `:Mason` is available for manual tool management.

Install syntax parsers once (the installer also does this):

```vim
:TSInstall python c cpp lua vim vimdoc query markdown markdown_inline
```

If highlighting reports an invalid Tree-sitter node (for example `except*`
in Python), update the installed parser to match the current queries:

```vim
:TSUpdate python
```

The installer now checks parser/query compatibility when it runs again.

Project roots use canonical paths. Activate your environment before opening
Neovim; restart it after switching environments. Project `.venv` discovery stays
with ty. No environment paths tied to a particular desk are hardcoded.

## 1337 Station Mode

A dedicated environment manager built specifically for 1337 / 42 cluster machines where `$HOME` is network-mounted (NFS) with limited quotas and `/goinfre` is a fast local NVMe drive unique to each physical workstation.

- **Station health:** Open `<leader>13` / `:StationHealth` for the full health and repair view.
- **Workstation change detection:** Warns when you sit at a new machine so you can re-link local caches before compiling.
- **Broken symlink detection:** Identifies dangling `.venv` or cache links pointing to `/goinfre` folders on a previous workstation.
- **Quota & NFS monitoring:** Tracks HOME quota / inode limits and alerts if heavy caches (`~/.cache/uv`, `~/.cache/pip`, `~/.npm`) or project caches live on NFS.
- **uv cache manager:** Ensures `UV_CACHE_DIR` points to local SSD (`/goinfre/$USER/.uv_cache`) instead of consuming NFS quota.
- **Safe repairs (`[f]` / `:StationFix`):** Never deletes files. Automatically creates `/goinfre/$USER`, repairs `~/goinfre` symlinks, points `UV_CACHE_DIR`, and ensures `~/.local/bin` is in PATH.
- **Python venv builder (`[v]` / `:StationVenv`):** Rebuilds project virtual environments on fast local `/goinfre` storage using `uv venv` and `uv sync`, symlinking `.venv` back into the project.
  Project storage names include a canonical-path hash to keep same-named projects
  separate. A replacement link is published after environment creation succeeds;
  existing real `.venv` directories are preserved and require explicit relocation.
- **Tool manager (`[t]` / `:StationTools`):** Verifies and installs core tools (`ty`, `ruff`, `clangd`, `rg`, `lazygit`, `uv`).
- **Commands:**
  - `:StationHealth` — Open interactive floating status and repair modal
  - `:StationFix` — Execute safe automated repairs
  - `:StationVenv` — Rebuild project `.venv` on `/goinfre` with `uv`
  - `:StationVenvMigrate` — Copy an existing real `.venv` to its project-specific local target, retaining the original backup
  - `:StationTools` — Reinstall or update cluster tools
  - `:StationMode [on|off|toggle]` — Toggle station mode override

Migration previews its paths and runs only after you select it. It needs Python3
and available local storage, refuses existing destinations or symlink sources,
and restores the original directory if link publication fails. The original is
retained as `.venv.backup-<id>` after success; restart Python language/debug sessions.

Installer tool archives are checked against official SHA256 release metadata or
published checksum files before extraction. Missing, malformed or mismatched
checksums block installation. UV also uses a verified archive. Python3 is required
for verification; existing installed tools are skipped unless `--force` is used.

## Verification

Run `make check` from the repository root with installed plugins, ty on PATH,
debugpy installed as above, ty and Ruff on PATH, and Python `msgpack`. Use `make upgrade` for the
strict upgrade regression suite (or `make upgrade NVIM=/path/to/nvim`).
It checks the real Blink completion UI, workflow
regressions and the configured Python language server. Individual commands:

```sh
NVIM_BIN=/path/to/nvim python3 nvim/tests/ui_review.py
python3 nvim/tests/ui_review.py --screenshot  # refresh completion screenshot; requires ImageMagick + the configured font
nvim --headless -u NONE -l nvim/tests/python_environment.lua
NVIM_TY=/path/to/ty nvim --headless -u NONE -l nvim/tests/real_ty.lua
nvim --headless '+lua dofile("nvim/tests/standalone.lua")' +qa!
nvim --headless '+lua dofile("nvim/tests/terminal_review.lua")' +qa!
python3 nvim/tests/startup_bench.py --runs 5
python3 nvim/tests/spatial_review.py
make reference
python3 nvim/tests/markdown_bench.py
python3 nvim/tests/spatial_bench.py --config nvim --runs 7
python3 nvim/tests/capture_makefile.py  # also requires ImageMagick + JetBrainsMono Nerd Font Mono
```

Use your installation's `XDG_DATA_HOME`. New UI checks cover Snacks files/preview and responsive chrome; older checks cover Mini Pick docs/
preview, diagnostics, notifications, documentation controls, quickfix edits,
Snacks Explorer, Aerial, Glance and rename. The standalone test requires ty on PATH
and verifies actual attachment and diagnostics through the full config.

Tests use temporary files. Headless startup timings do not measure cluster NFS
or interactive language-server latency. See [design decisions](DESIGN.md).

## Rust image and PDF reader

[`nvim-gfx`](https://github.com/bobcowher/neovim-graphics-viewer) is loaded only
when opening media or running a reader command. This configuration builds its
Rust image/PDF backend locally, with FFmpeg/video disabled, and uses the existing
Poppler executables for PDF pages. Supported images: PNG, JPEG, WebP, BMP and GIF
(first frame). The build needs Cargo and Python 3; PDF pages need `pdfinfo` and
`pdftoppm`, and text mode needs `pdftotext` (all in Poppler).

Use **Kitty or Ghostty outside tmux** for full image rendering. Alacritty and
Neovim's nested terminal emulator cannot render this graphics protocol. PDF text
mode works in any terminal. No performance comparison with other viewers has
been measured.

- Open an image or PDF normally (`:edit file.pdf`), or use `<leader>fi` to select one.
- `:ViewImage path.png` / `:ViewPDF path.pdf`: view a file; omit the path for the current file.
- `J` / `K`, Ctrl-D / Ctrl-U or PageDown / PageUp: next/previous PDF page; `gg` / `G`: first/last.
- Mouse wheel: scroll within the PDF page.
- `+` / `-`: zoom; `h` / `j` / `k` / `l`: pan or scroll; `r`: reset; `q`: close.
- `:PDFText path.pdf`: searchable, selectable PDF text (`/` searches normally).
- `:MediaHealth`: check graphics terminal, backend and Poppler.
- `:NvimGfxBuild`: rebuild the local image/PDF binary after restoring on another machine.

The plugin revision is pinned. `scripts/build_media.py` compiles in a private
temporary directory and installs only the resulting backend in the plugin's
`bin/` directory. It does not install system packages or use sudo. Media larger
than 100 MiB is refused by the graphics reader. Encrypted/unsupported files report
an error; scanned PDFs need OCR before their text can be searched.

Run `make media` from the repository root to test the installed native reader and
PDF text fallback. The headless test captures the graphics protocol; it does not
visually inspect terminal rendering.

PDF pages are uploaded once as compressed PNGs and cached in the terminal (up to
five pages). Scroll and zoom update a crop/placement rectangle, avoiding a full
bitmap resize and upload for every keypress. On the two-page fixture at 160×60
cells, 20 alternating scroll steps plus a redraw sent 1,480 bytes after the first
page upload, versus 137,929,155 bytes with the original renderer. Backend time
fell from 1,217 ms to 0.2 ms on this machine. This captures protocol output to a
file; it does not measure GPU display latency or complex PDF first-page rendering.
