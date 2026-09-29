"""Render actual Neovim UI-grid cells as a PNG, preserving RGB highlights."""
from html import escape
from pathlib import Path
import subprocess
import tempfile


def save_grid(grid, attrs, default_fg, default_bg, output):
 cell_w, cell_h = 10, 21
 svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(grid[0])*cell_w}" height="{len(grid)*cell_h}">']
 for y, row in enumerate(grid):
  for x, (char, hl) in enumerate(row):
   style = attrs.get(hl, {})
   fg, bg = style.get('foreground', default_fg), style.get('background', default_bg)
   if style.get('reverse'): fg, bg = bg, fg
   svg.append(f'<rect x="{x*cell_w}" y="{y*cell_h}" width="{cell_w}" height="{cell_h}" fill="#{bg:06x}"/>')
 for y, row in enumerate(grid):
  for x, (char, hl) in enumerate(row):
   if not char or char == ' ': continue
   style = attrs.get(hl, {})
   fg = style.get('background', default_bg) if style.get('reverse') else style.get('foreground', default_fg)
   weight = 'bold' if style.get('bold') else 'normal'
   italic = 'italic' if style.get('italic') else 'normal'
   svg.append(f'<text x="{x*cell_w}" y="{y*cell_h+16}" fill="#{fg:06x}" font-family="JetBrainsMono Nerd Font Mono" font-size="16" font-weight="{weight}" font-style="{italic}" xml:space="preserve">{escape(char)}</text>')
 svg.append('</svg>')
 with tempfile.TemporaryDirectory() as tmp:
  source = Path(tmp) / 'capture.svg'
  source.write_text(''.join(svg))
  subprocess.run(['magick', str(source), str(output)], check=True)
