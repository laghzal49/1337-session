#!/usr/bin/env python3
"""Build the pinned nvim-gfx image/PDF backend without FFmpeg or system changes."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('plugin', type=Path, help='nvim-gfx checkout directory')
parser.add_argument('--test', action='store_true', help='run upstream image/PDF/protocol tests before installation')
args = parser.parse_args()
plugin = args.plugin.resolve()
expected = '2ab524b8bf699a94f41c346e1fdd710e8988ed0d'
head = subprocess.check_output(['git', '-C', str(plugin), 'rev-parse', 'HEAD'], text=True).strip()
if head != expected:
    parser.error('unsupported nvim-gfx revision; review the media build before updating its pin')
if not shutil.which('cargo'):
    parser.error('Cargo is required: install Rust from https://rustup.rs/')

# Build in a private copy. Preserve the managed checkout, its lockfile and video
# implementation. The frontend below only registers images/PDFs; the inert video
# adapter keeps the upstream command protocol compatible without linking FFmpeg.
video_stub = '''use std::time::Instant;
pub struct VideoDecoder { pub duration_secs: f64 }
impl VideoDecoder {
    pub fn open(_: &str) -> Result<Self, String> { Err("This build supports images and PDFs only".into()) }
    pub fn position_secs(&self) -> f64 { 0.0 }
    pub fn is_playing(&self) -> bool { false }
    pub fn is_finished(&self) -> bool { true }
    pub fn current_display_time(&self) -> Instant { Instant::now() }
    pub fn width(&self) -> u32 { 0 }
    pub fn height(&self) -> u32 { 0 }
    pub fn toggle_play(&mut self) {}
    pub fn seek(&mut self, _: i32) -> Result<(), String> { Ok(()) }
    pub fn rewind(&mut self) -> Result<(), String> { Ok(()) }
    pub fn next_frame(&mut self) -> Result<Option<Vec<u8>>, String> { Ok(None) }
}
'''
with tempfile.TemporaryDirectory(prefix='nvim-media-build-') as name:
    build = Path(name)
    shutil.copytree(plugin / 'src', build / 'src')
    shutil.copytree(plugin / 'tests', build / 'tests')
    manifest = (plugin / 'Cargo.toml').read_text()
    assert 'ffmpeg-next = "6"' in manifest, 'upstream FFmpeg dependency changed'
    assert 'version = "0.25"' in manifest, 'upstream image dependency changed'
    # 0.24.9 supports the older Rust compiler available on 1337 Linux machines.
    # These formats need no platform libraries and provide a small native build.
    manifest = manifest.replace('ffmpeg-next = "6"\n', '')
    manifest = manifest.replace('image = { version = "0.25", default-features = false, features = ["png", "jpeg", "webp"] }',
                                'image = { version = "=0.24.9", default-features = false, features = ["png", "jpeg", "webp", "gif", "bmp"] }')
    manifest += '\n[profile.release]\nstrip = true\n'
    (build / 'Cargo.toml').write_text(manifest)
    (build / 'src/video.rs').write_text(video_stub)
    # Native terminal caching makes scroll/zoom placement-only operations.
    renderer = build / 'src/kitty.rs'
    code = renderer.read_text()
    code = code.replace('    writer: Box<dyn Write>,',
                        '    writer: Box<dyn Write>,\n    pdf_cached: Vec<u32>,\n    pdf_current: Option<u32>,')
    code = code.replace('pan_y: 0.0, writer }',
                        'pan_y: 0.0, writer, pdf_cached: Vec::new(), pdf_current: None }')
    code = code.replace('writer: Box::new(Vec::new()) }',
                        'writer: Box::new(Vec::new()), pdf_cached: Vec::new(), pdf_current: None }')
    code = code.replace('    pub fn clear(&mut self) -> Result<(), String> {',
                        '    pub fn clear(&mut self) -> Result<(), String> {\n        self.clear_pdf_cache()?;')
    code += '\n' + Path(__file__).with_name('media_pdf_display.rs').read_text()
    renderer.write_text(code)
    main = build / 'src/main.rs'
    code = main.read_text()
    code = code.replace('let doc = PdfDoc::open(&path)?;',
                        'self.kitty.clear_pdf_cache()?;\n                        let doc = PdfDoc::open(&path)?;')
    before = """        let frame = pdf::compose(ps.doc.current_image()?, &ps.view, vw, vh);
        self.kitty.display_raw(frame.as_raw(), vw, vh, self.col, self.row, self.width, self.height)"""
    after = """        let page = ps.doc.page;
        self.kitty.display_pdf(ps.doc.current_image()?, &ps.view, page,
            self.col, self.row, self.width, self.height, vw, vh)"""
    assert before in code, 'upstream PDF render path changed'
    main.write_text(code.replace(before, after))
    # Match the editor's black canvas around PDF pages.
    pdf = build / 'src/pdf.rs'
    pdf.write_text(pdf.read_text().replace('const BG: [u8; 4] = [40, 40, 40, 255];',
                                          'const BG: [u8; 4] = [0, 0, 0, 255];'))
    shutil.copy2(Path(__file__).with_name('media-Cargo.lock'), build / 'Cargo.lock')
    if args.test:
        subprocess.run(['cargo', 'test', '--locked', '--manifest-path', str(build / 'Cargo.toml')], check=True)
    subprocess.run(['cargo', 'build', '--release', '--locked', '--manifest-path', str(build / 'Cargo.toml')], check=True)
    dest = plugin / 'bin/nvim-gfx'
    dest.parent.mkdir(parents=True, exist_ok=True)
    staged = dest.with_suffix('.new')
    target = Path(os.environ.get('CARGO_TARGET_DIR', build / 'target'))
    shutil.copy2(target / 'release/nvim-gfx', staged)
    staged.chmod(0o755)
    staged.replace(dest)
    # Keep the exact resolved build inputs for reproducibility on this machine.
    shutil.copy2(build / 'Cargo.lock', plugin / 'bin/media-Cargo.lock')
    print(f'Installed image/PDF backend: {dest}', flush=True)
