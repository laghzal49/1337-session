-- Rust handles decoding, scaling and Kitty graphics; no video/FFmpeg dependency.
return {
  {
    'bobcowher/neovim-graphics-viewer',
    name = 'nvim-gfx',
    commit = '2ab524b8bf699a94f41c346e1fdd710e8988ed0d',
    cmd = { 'ViewImage', 'ViewPDF', 'PDFText', 'MediaHealth', 'NvimGfxBuild' },
    event = {
      'BufReadCmd *.png', 'BufReadCmd *.jpg', 'BufReadCmd *.jpeg',
      'BufReadCmd *.webp', 'BufReadCmd *.gif', 'BufReadCmd *.bmp', 'BufReadCmd *.pdf',
      'BufReadCmd *.PNG', 'BufReadCmd *.JPG', 'BufReadCmd *.JPEG', 'BufReadCmd *.PDF',
      'BufReadCmd *.WEBP', 'BufReadCmd *.GIF', 'BufReadCmd *.BMP',
    },
    keys = {
      { '<leader>fi', function() require('config.media').pick() end, desc = 'Read image or PDF' },
    },
    build = function(plugin)
      if vim.fn.executable('cargo') ~= 1 then
        vim.notify('Rust media build skipped: install Cargo, then run make media-build', vim.log.levels.WARN)
        return
      end
      local output = vim.fn.system({ 'python3', vim.fn.stdpath('config') .. '/scripts/build_media.py', plugin.dir })
      if vim.v.shell_error ~= 0 then error(output) end
    end,
    config = function() require('config.media').setup() end,
  },
}
