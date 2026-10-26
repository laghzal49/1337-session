// Included in nvim-gfx's kitty module by build_media.py.
// Keep PDF pages in the terminal's graphics cache. Pan/zoom only change a
// placement rectangle; they never resize/re-upload the page on each keypress.
use image::ImageEncoder as _;

impl KittyRenderer {
    pub fn clear_pdf_cache(&mut self) -> Result<(), String> {
        for id in self.pdf_cached.drain(..) {
            write_terminal_line(&mut *self.writer,
                format!("\x1b_Ga=d,d=I,i={id},q=2\x1b\\").as_bytes())?;
        }
        self.pdf_current = None;
        Ok(())
    }

    pub fn display_pdf(
        &mut self,
        page: &image::RgbaImage,
        view: &crate::pdf::PdfView,
        page_number: u32,
        col: u32, row: u32, cols: u32, rows: u32,
        vw: u32, vh: u32,
    ) -> Result<(), String> {
        let id = KITTY_IMAGE_ID + page_number;
        let (pw, ph) = page.dimensions();
        if !self.pdf_cached.contains(&id) {
            let mut png = Vec::new();
            image::codecs::png::PngEncoder::new_with_quality(
                &mut png,
                image::codecs::png::CompressionType::Fast,
                image::codecs::png::FilterType::Adaptive,
            ).write_image(page.as_raw(), pw, ph, image::ColorType::Rgba8)
                .map_err(|e| format!("encode PDF page: {e}"))?;
            let encoded = STANDARD.encode(png);
            let chunks = encoded.as_bytes().chunks(4096);
            let total = chunks.len();
            for (index, data) in chunks.enumerate() {
                let m = if index + 1 < total { 1 } else { 0 };
                let data = std::str::from_utf8(data).unwrap();
                let header = if index == 0 {
                    format!("a=t,f=100,i={id},q=2,m={m}")
                } else { format!("m={m},q=2") };
                write_terminal_line(&mut *self.writer,
                    format!("\x1b_G{header};{data}\x1b\\").as_bytes())?;
            }
            if self.pdf_cached.len() >= 5 {
                let old = self.pdf_cached.remove(0);
                write_terminal_line(&mut *self.writer,
                    format!("\x1b_Ga=d,d=I,i={old},q=2\x1b\\").as_bytes())?;
            }
            self.pdf_cached.push(id);
        }
        // Delete only the previous placement (lowercase i keeps cached pixels).
        // Clearing the bitmap here would defeat caching and reintroduce lag.
        let mut commands = String::new();
        if let Some(old) = self.pdf_current.filter(|old| *old != id) {
            commands.push_str(&format!("\x1b_Ga=d,d=i,i={old},q=2\x1b\\"));
        }
        let scaled_w = vw as f32 * view.zoom;
        let scaled_h = ph as f32 * scaled_w / pw.max(1) as f32;
        let scale = scaled_w / pw.max(1) as f32;
        let visible_w = scaled_w.min(vw as f32);
        let visible_h = scaled_h.min(vh as f32);
        let x = ((view.x * (scaled_w - vw as f32).max(0.0) / scale) as u32).min(pw - 1);
        let y = ((view.y * (scaled_h - vh as f32).max(0.0) / scale) as u32).min(ph - 1);
        let width = ((visible_w / scale).round() as u32).clamp(1, pw - x);
        let height = ((visible_h / scale).round() as u32).clamp(1, ph - y);
        let dest_cols = ((visible_w / vw as f32 * cols as f32).round() as u32).clamp(1, cols.max(1));
        let dest_rows = ((visible_h / vh as f32 * rows as f32).round() as u32).clamp(1, rows.max(1));
        let left = col + cols.saturating_sub(dest_cols) / 2;
        let top = row + rows.saturating_sub(dest_rows) / 2;
        commands.push_str(&format!(
            "\x1b7\x1b[{};{}H\x1b_Ga=p,i={id},p=1,x={x},y={y},w={width},h={height},c={dest_cols},r={dest_rows},q=2,C=1\x1b\\\x1b8",
            top + 1, left + 1));
        write_terminal_line(&mut *self.writer, commands.as_bytes())?;
        self.pdf_current = Some(id);
        Ok(())
    }
}
