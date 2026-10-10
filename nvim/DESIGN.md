# Perfect Black — color roles

A black editor with vivid bold red variables, clear token families and quieter
surrounding controls. The palette is defined in `lua/config/palette.lua`.
Syntax, LSP semantic tokens, completion kinds and outline symbols use the same
roles. UI surfaces are defined in `lua/config/surfaces.lua`.

## Critique and decisions

The previous theme mixed several generations of hardcoded colors. Built-ins,
control flow, selection, folders and Git state sometimes received unrelated
reds. Completion kinds disagreed with syntax colors. Some secondary labels used
dim brown, and the written design described a palette no longer installed.

This revision gives each role a consistent color. Punctuation and supporting
text are neutral so variable names and function calls are easier to find.
Dashboard icons use action families. Errors retain severity labels, signs and
undercurls; deleted code retains its minus/strike cues. Color is additional
information, not the only indication of state.

## Role map

| Role | Color | Where it appears |
| --- | --- | --- |
| Canvas | `#000000` | Editing area |
| Panel | `#101116` | Menus, docs, guides, notifications |
| Inset | `#08090D` | Preview, sidebar and status areas |
| Selection | `#24212C` | Focused result or menu row |
| Primary text | `#D7E3FF` | Labels, prose, filenames |
| Secondary text / comments | `#98A2B8` | Hints, comments, inactive information |
| Punctuation / paths | `#A9B9D6` | Structural separators and supporting paths |
| Variables | `#FF4057`, bold | Locals/globals, LSP variables, completion and outline |
| Focus | `#FF4057` | Active UI markers and command prompt |
| Parameters | `#FFD4A8` | Function inputs |
| Members | `#E0C6FF` | Properties and fields |
| Callables | `#70D7FF` | Functions, methods, callable built-ins |
| Keywords | `#C7A6FF` | Control flow, imports, directives and modifiers |
| Types | `#FFD166` | Classes, structs, constructors, type names and named constants |
| Strings | `#7FE3C2` | Literal text |
| Values | `#FFB47D` | Numbers, booleans, escapes and enum members |
| Folders / navigation | `#70D7FF` | Explorer directories and navigation actions |
| Errors | `#FF8FA3` | Diagnostics, FIXME labels, deletion state |
| Warnings / changes | `#FFD166` | Warnings, modified Git state |
| Information / untracked | `#70D7FF` | Informational diagnostics and untracked files |
| Success / additions | `#7FE3C2` | Added/staged files, successful actions |

Red variables are a user preference, not a universal recommendation. Error
messages use lighter rose plus explicit severity cues. Types and warnings share
amber in different contexts, with labels identifying their meaning.

## Readability checks

The previous variable red measured 4.37:1 against the default selected-row fill.
The new crimson measures 4.61:1 there and 6.12:1 against black. The palette test
checks syntax and diagnostic foregrounds on the canvas, panel and default
selection fill; the lowest tested contrast is 4.61:1. It also verifies agreement
between LSP, Tree-sitter, completion and outline colors.

These are pairwise checks, not a claim of complete WCAG conformance for Neovim.
Terminal fonts, transparency and user overrides can change the final appearance.
The accessible preset provides plain icons, stronger borders and non-italic
comments. Status messages keep text, icons and underlines alongside their colors.

## Typography and behavior

Variables are bold as requested. Headings, active state and selected items use
bold for emphasis. Comments are readable gray; the accessible preset removes
italics from syntax and LSP comments. File icons retain recognizable type colors.
The terminal's 16 ANSI colors use the same status and syntax families.

The dashboard shows project context and recent project files. Pickers allocate
more width to results and stack their preview on small screens. Split titles
show paths, while numbered tabs use compact basenames. LSP progress stays in the
status bar. The keymap guide wraps and provides section navigation.

## Research used

- [Material color roles](https://developer.android.com/codelabs/m3-design-theming):
  separate semantic roles from literal color values and apply them consistently.
- [W3C contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html):
  use 4.5:1 as a normal-text contrast benchmark.
- [W3C use of color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html):
  communicate meaningful state through text or shape as well as color.

The aesthetic choices follow your strong-red preference; readability decisions
use the checks above.
