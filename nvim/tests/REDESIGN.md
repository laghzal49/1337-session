# Verification for Perfect Black II

The matched startup/idle measurements and picker tradeoff are recorded in
`redesign_results.json`. They use Neovim 0.11.5, installed plugin data and isolated
cache/state directories; headless startup does not measure LSP readiness.

From the repository root, set `XDG_CONFIG_HOME=$PWD` and use your installed
Neovim. The Lua reviews create temporary fixtures, not repository edits:

```sh
export XDG_CONFIG_HOME="$PWD"
nvim --headless '+luafile nvim/tests/responsiveness_review.lua' +qa!
nvim --headless '+luafile nvim/tests/performance_review.lua' +qa!
nvim --headless '+luafile nvim/tests/redesign_review.lua' +qa!
nvim --headless '+luafile nvim/tests/tasks_workspace_review.lua' +qa!
nvim --headless '+luafile nvim/tests/debugging_review.lua' +qa!
```

The debugger test needs debugpy in `stdpath('data')/debugpy` (see the main guide).
The responsiveness review expects a non-cluster host without a Station override.
The performance review's context completion timeout is not a latency measurement.
It verifies bounded size checks and shutdown of already-attached decorations.

For attached UI checks and grid screenshots:

```sh
NVIM_BIN=/path/to/nvim python3 nvim/tests/redesign_ui.py
NVIM_BIN=/path/to/nvim python3 nvim/tests/ui_review.py
```

`redesign_ui.py` requires Python msgpack/Pillow and fontconfig; set
`NVIM_PREVIEW_FONT=/path/to/monospaced.ttf` to select the capture font. It renders
real RGB Neovim grid events into the dashboard/editor/picker PNGs and checks
responsive bounds and Escape. The live debugger screenshot was captured while
real debugpy stopped on a breakpoint, rather than drawn as a mockup.

`ui_review.py` needs installed Python/Markdown parsers and exercises navigation,
completion, documents, snippets, explorer, TreeSJ, text objects, quickfix and
LSP mock interactions. `picker_bench.py` retains a direct MiniPick baseline and
compares the actual Snacks picker; the richer preview has a measured overhead.

Manual C/C++ debugging requires GDB 14+ with Python/DAP support. Live GDB and
Python attach sessions were not exercised here. Background project tasks are
noninteractive; interactive jobs can use the existing Make/project terminal.
