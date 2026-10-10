# Debugger · start here

Press `t` in this guide to open a small Python practice project.
Press `q` or `Esc` to return to your editor. Use `j`/`k` to scroll.
Your leader key is Space: `Space Db` means Space, then D, then b.

## Your first debug session

1. Open a Python file and put the cursor on a line that runs.
2. Press `Space Db` to set a breakpoint. A red marker appears.
3. Press `F5`. Save changes if asked. A missing project profile is generated.
4. When the yellow arrow appears, execution is paused BEFORE that line runs.
5. Look at Locals for the variables in the current function.
6. Press `F10` to execute the next line, then watch the values change.
7. Press `F5` to continue to the next breakpoint or the end.
8. Press `Shift-F5` or `Space Dt` to stop early.

## Practice with a real example

`t` or `:DebugExample` opens a temporary project in a new tab.
Your existing files and breakpoints are preserved. No session starts until F5.

The example adds 4, 8 and 12. A breakpoint is set on `total += value`.
Press F5: the first stop shows total = 0 and value = 4.
Press F10: total becomes 4. Press F5 twice to reach the other iterations.
Press F5 again to finish; the Debug console prints 24. Use `Space Dr` to reopen it.
Close the practice tab when finished. The files are temporary, not in your project.

## Which step key should I use?

`F10` / `Space Do` · Step over
Execute the current line. A called function runs without stepping inside it.

`F11` / `Space Di` · Step into
Enter a function called on the current line, when the debugger can step into it.

`F12` / `Space DO` · Step out
Run the rest of the current function and pause back in its caller.

`Space DC` · Run to cursor
While paused, move the cursor to a later executable line and run to that line.

`Space Dp` · Pause
Interrupt a program that is still running, such as a long loop.

## Inspect values

`Space De` · Evaluate the expression under the cursor or a Visual selection.
`Space Dw` · Add a watch. Try `total` or `total + value` in the practice project.
`Space Dv` · Open watches. Enter expands a value; `d` removes a watch.
`Space DS` · Open the call stack. `o` selects a frame and its local variables.
`Space Dr` · Open the Debug console for output or evaluating expressions.
`Space Du` · Show/hide the debug panels. Narrow screens use bottom scopes.

Use `Ctrl-w w` to move between windows. Floating inspectors close with q/Esc.
Expressions can call functions and change program state; use simple names first.

## Breakpoints and repeats

`Space Db` toggles a breakpoint on the cursor line.
`Space DB` adds a condition, for example `value == 8`.
`Space DL` adds a logpoint, for example `total={total}`. It prints without pausing.
`Space Dx` clears ALL breakpoints, including those outside the practice file.
`Space DR` restarts the active session; when idle, it reruns this project's target.
`Space Dl` also reruns this project's last target.

## Choose a different target

`Space DD` / `:Debug` opens actions for the current running/paused state.
`Space Df` / `:DebugTarget` chooses a file, arguments, module, test file or attach.
Quote argument values with spaces, for example `--name "two words"`.
Test files named test_*.py or *_test.py offer a pytest launch; install pytest
in the selected project environment first.

`Space Dj` / `:DebugProjectEdit` opens .vscode/launch.json.
`Space Dg` generates it; `Space Dh` validates it.
Existing profiles are preserved. With multiple profiles, F5 remembers your choice.
`:DebugProjectLaunch` explicitly picks another project profile.

## When it does not stop

- Set breakpoints on executable lines, not comments or empty lines.
- The function must actually be called; defining it alone does not run its body.
- A script can finish immediately if there are no reached breakpoints.
- Check that the profile points to the file/module you intended to run.
- Use Space Dr for program output and :DapShowLog for adapter details.
- Missing Python packages must be installed in the debuggee's environment.

Python uses your selected interpreter override, then .venv/venv, the active
virtual environment, and Python on PATH. The installer provides isolated debugpy.
`:PythonInterpreter /path/to/python` selects a project interpreter.

C/C++ requires GDB 14+ with Python/DAP support and a program built with -g.
Build first, then choose the compiled executable with Space Df.
Set vim.g.debug_gdb to a newer user-local binary if the system GDB is too old.

## Reopen this guide

`:DebugHelp` or `Space D?` works before, during and after a session.
The :Debug action menu also includes this guide.
