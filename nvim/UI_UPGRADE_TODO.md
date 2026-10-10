# UI upgrade checklist

This tracks the whole installed UI, including the current color pass. A checked
item means its change is implemented; the final validation items cover runtime
and screenshot review. Existing behavior is retained where it already works.

## Color and readability

- [x] Define named color roles in one shared palette.
- [x] Use vivid bold red for variables, including LSP tokens.
- [x] Give parameters, properties, functions, keywords, types and values distinct roles.
- [x] Make punctuation neutral and comments readable.
- [x] Match completion and outline symbol colors to syntax.
- [x] Use cyan folders and readable secondary paths.
- [x] Distinguish error, warning, information and success with labels/shapes too.
- [x] Give TODO/FIXME/NOTE comments visible labels and navigation.
- [x] Improve selected-row contrast and remove obsolete duplicate theme overrides.
- [x] Document the role map, critique, sources and contrast measurements.

## Editor and navigation

- [x] Compact numbered tabs and readable split titles.
- [x] Clear focused split, cursor line, modified and read-only state.
- [x] Quiet indent guides and visible current scope.
- [x] Clear search results, current match and selection colors.
- [x] Responsive file/search picker with preview and accurate key hints.
- [x] Consistent explorer, symbols, references and diagnostic panels.
- [x] Project dashboard with recent files and useful shortcuts.
- [x] Readable command menu and keymap guide with section navigation.

## Language and project tools

- [x] Completion selection, kind icons, matching text and deprecation styling.
- [x] Shared documentation/signature surfaces and readable inlay hints.
- [x] Diagnostic source/code information with severity cues.
- [x] LSP progress in the status bar and attached server names while idle.
- [x] Debugger types/scopes using the shared color roles.
- [x] Git add/change/delete/untracked colors with existing status markers.
- [x] Terminal ANSI palette consistent with the editor.
- [x] Shared panel/text roles for tasks, notifications, plugin and tool managers.

## Accessibility and release

- [x] Plain icon fallback and live accessibility toggle.
- [x] Remove comment italics in both Tree-sitter and LSP under that preset.
- [x] Automated foreground contrast and semantic-role consistency checks.
- [x] Run the complete regression suite after the final color changes — `make check`, including 25 fresh-process tests.
- [x] Inspect real editor, picker, explorer, dashboard and narrow guide captures.
- [x] Refresh preview assets and publish the verified configuration.
