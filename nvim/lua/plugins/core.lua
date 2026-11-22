-- Explicit foundations: no distribution defaults or automatic tool installers.
local performance = require('config.performance')
performance.setup()
return {
  -- nvimz's visual foundation; loaded eagerly so the theme is ready on first draw.
  { 'folke/tokyonight.nvim', lazy = false, priority = 1100,
    enabled = vim.g.black_color_style == 'nvimz',
    opts = {
      style = 'moon',
      transparent = true,
      terminal_colors = true,
      on_colors = function(colors)
        colors.bg, colors.bg_dark = '#0b1210', '#080d0b'
        colors.bg_float, colors.bg_sidebar = '#0d1614', '#080d0b'
        colors.bg_statusline = '#0d1614'
        colors.bg_visual, colors.bg_highlight = '#253b34', '#101a17'
        colors.green, colors.teal = '#9ad179', '#73daca'
        colors.blue, colors.blue1 = '#61afef', '#b4f9f8'
        colors.blue2, colors.blue5 = '#2ac3de', '#89ddff'
        colors.blue6, colors.blue7 = '#b4f9f8', '#394b70'
        colors.orange, colors.yellow = '#e6b366', '#d9b36c'
        colors.magenta, colors.purple = '#a7c080', '#a7c080'
        colors.magenta2 = '#73daca'
      end,
      styles = {
        comments = { italic = true }, keywords = { italic = true },
        functions = { bold = true }, variables = {},
        sidebars = 'transparent', floats = 'transparent',
      },
      on_highlights = function(hl, colors)
        hl.Normal = { bg = 'NONE' }
        hl.NormalFloat = { bg = 'NONE' }
        hl.LineNr = { fg = '#2f3d37' }
        hl.CursorLineNr = { fg = '#d7e3dc', bold = true }
        hl.CursorLine = { bg = '#101a17' }
        hl.Visual = { bg = '#253b34' }
        hl.WinSeparator = { fg = '#1f312b' }
        hl['@keyword'] = { fg = colors.green, italic = true }
        hl['@keyword.function'] = { fg = colors.orange, bold = true }
        hl['@keyword.return'] = { fg = colors.green, italic = true }
        hl['@keyword.import'] = { fg = colors.green, italic = true }
        hl['@function'] = { fg = colors.blue, bold = true }
        hl['@function.call'] = { fg = colors.blue, bold = true }
        hl['@function.method'] = { fg = colors.blue2 }
        hl['@function.method.call'] = { fg = colors.blue2 }
        hl['@variable'] = { fg = colors.yellow }
        hl['@variable.parameter'] = { fg = colors.yellow }
        hl['@variable.member'] = { fg = '#9cd4d0' }
        hl['@type'] = { fg = colors.blue2 }
        hl['@type.definition'] = { fg = '#78c2d8', bold = true }
        hl['@string'] = { fg = '#8fbf8f' }
        hl['@constant'] = { fg = colors.magenta }
        hl['@operator'] = { fg = colors.teal }
        hl['@comment'] = { fg = '#688077', italic = true }
        hl['@punctuation.bracket'] = { fg = '#5a6e68' }
        hl['@punctuation.delimiter'] = { fg = '#89b482' }
      end,
    },
  },
  { 'stevearc/oil.nvim', cmd = 'Oil',
    dependencies = { 'refractalize/oil-git-status.nvim' },
    enabled = vim.g.black_color_style == 'nvimz',
    config = function() require('config.nvimz_files').setup() end,
  },
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = {}, keys = {
    { '<leader>qs', function() require('persistence').load() end, desc = 'Restore session' },
    { '<leader>qS', function() require('persistence').select() end, desc = 'Select session' },
    { '<leader>qd', function() require('persistence').stop() end, desc = "Don't save session" },
    { '<leader>ql', function() require('persistence').load({ last = true }) end, desc = 'Restore last session' },
  } },
  -- Last main snapshot before the installer adopted Neovim 0.12-only vim.list.
  { 'nvim-treesitter/nvim-treesitter', commit = '4d9916e477e5d4e3b245845dfd285edf429f3252',
    event = { 'BufReadPost', 'BufNewFile' }, build = ':TSUpdate', opts = {}, config = function(_, opts)
    require('nvim-treesitter').setup(opts)
    local warned = {}
    vim.api.nvim_create_autocmd('FileType', { callback = function(ev)
      if vim.bo[ev.buf].buftype == '' and not performance.large(ev.buf) and not require('config.markdown').large(ev.buf) then
        local filetype = vim.bo[ev.buf].filetype
        local language = vim.treesitter.language.get_lang(filetype) or filetype
        if language == '' then return end
        -- A newer highlights query with an older parser can start successfully
        -- and then fail later in the decoration provider on every redraw.
        local query_ok, query_err = pcall(vim.treesitter.query.get, language, 'highlights')
        if not query_ok then
          if not warned[language] and tostring(query_err):find('Query error', 1, true) then
            warned[language] = true
            vim.schedule(function()
              vim.notify(('Tree-sitter %s highlights are incompatible with its parser. Run :TSUpdate %s.'):format(language, language), vim.log.levels.WARN)
            end)
          end
          return
        end
        pcall(vim.treesitter.start, ev.buf)
      end
    end })
  end },
  { 'nvim-treesitter/nvim-treesitter-context',
    -- nvimz prioritizes a fast uncluttered code surface.
    enabled = vim.g.black_color_style ~= 'nvimz', event = { 'BufReadPost', 'BufNewFile' }, opts = {
    max_lines = 2, trim_scope = 'outer',
    on_attach = function(buf) return not performance.large(buf) and not require('config.markdown').large(buf) end,
  } },
  { 'neovim/nvim-lspconfig', event = { 'BufReadPre', 'BufNewFile' }, dependencies = { 'saghen/blink.cmp' },
    config = function(_, opts)
      vim.diagnostic.config(opts.diagnostics or {})
      local base_caps = require('blink.cmp').get_lsp_capabilities()
      for name, config in pairs(opts.servers or {}) do
        config = vim.deepcopy(config)
        config.enabled, config.mason = nil, nil
        config.capabilities = vim.tbl_deep_extend('force', base_caps, config.capabilities or {})
        vim.lsp.config(name, config)
        local resolved = vim.lsp.config[name]
        if resolved and type(resolved.cmd) == 'table' and vim.fn.executable(resolved.cmd[1]) == 1 then
          vim.lsp.enable(name)
        end
      end
    end },
  { 'stevearc/conform.nvim', event = 'BufWritePre', cmd = 'ConformInfo', opts = {
    format_on_save = function(buf)
      if vim.b[buf].autoformat == false or vim.g.autoformat == false then return end
      if performance.large(buf) then return end
      return { timeout_ms = vim.bo[buf].filetype == 'python' and 1500 or 500, lsp_format = 'fallback' }
    end,
  }, keys = { { '<leader>cf', function() require('conform').format({ async = true, lsp_format = 'fallback' }) end, desc = 'Format buffer' } } },
  { 'mason-org/mason.nvim', cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' }, opts = {
    ui = { border = require('config.ui').border, width = 0.8, height = 0.8 },
  } },
}
