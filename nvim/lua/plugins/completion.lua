-- Blink.cmp completion configuration matching the Perfect Black palette
return {
  {
    'saghen/blink.cmp',
    version = 'v1.10.2',
    event = { 'InsertEnter', 'CmdlineEnter' },
    opts = {
      enabled = function()
        return vim.bo.buftype ~= 'prompt' and not require('config.performance').large(0)
      end,
      keymap = {
        preset = 'none',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-n>'] = { 'select_next', 'show' },
        ['<C-p>'] = { 'select_prev', 'show' },
        ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'show_documentation', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'show_documentation', 'fallback' },
        ['<C-d>'] = { 'hide_documentation', 'show_documentation', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<C-k>'] = { function() return require('config.symbol_help').signature() end },
      },

      completion = {
        trigger = { show_on_backspace_in_keyword = true, show_in_snippet = false },
        list = { max_items = 100, selection = { preselect = false, auto_insert = false } },
        menu = {
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
          scrollbar = true,
          scrolloff = 2,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 180,
          draw = function(opts) require('config.documentation').completion_draw(opts) end,
          window = {
            desired_min_width = 40,
            desired_min_height = 3,
            border = 'rounded',
            winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
          },
        },
      },

      signature = {
        enabled = true,
        window = {
          max_width = require('config.ui').max_width,
          max_height = 8,
          show_documentation = true,
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
        },
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          -- Display local matches immediately; semantic results rank higher
          -- as the server responds, without blocking the completion menu.
          lsp = { async = true, fallbacks = {}, score_offset = 10 },
          path = { fallbacks = {} },
          buffer = {
            min_keyword_length = 3,
            score_offset = -5,
            max_items = 30,
            opts = {
              get_bufnrs = function()
                return vim.bo.buftype == '' and not require('config.performance').large(0)
                  and { vim.api.nvim_get_current_buf() } or {}
              end,
              max_sync_buffer_size = 16000,
              max_async_buffer_size = 128000,
              max_total_buffer_size = 256000,
            },
          },
        },
      },

      -- Keep ranking in the native matcher: exact matches, fuzzy score
      -- (including usage/proximity), then the language server's sortText.
      fuzzy = { sorts = { 'exact', 'score', 'sort_text' } },

      cmdline = {
        sources = function()
          local kind = vim.fn.getcmdtype()
          if kind == '/' or kind == '?' then
            -- Blink's global enabled callback is bypassed in command mode.
            return require('config.performance').large(0) and {} or { 'buffer' }
          end
          -- Colon suggestions are independent of the file's size.
          return { 'cmdline' }
        end,
        completion = {
          list = { selection = { preselect = false, auto_insert = false } },
          menu = { auto_show = true },
          ghost_text = { enabled = false },
        },
      },
    },
    config = function(_, opts)
      -- Perfect Black owns these groups centrally in config.surfaces.
      vim.treesitter.language.register('markdown', 'blink-cmp-documentation')
      local cmp = require('blink.cmp')
      cmp.setup(opts)
      -- Blink initializes its input listeners after checking the native binary.
      -- A first batched ':command' can arrive before those listeners exist.
      -- Catch up once ready, without blocking input or loading private modules.
      local attempts = 0
      local function resume_first_command()
        if vim.api.nvim_get_mode().mode ~= 'c' then return end
        local trigger = package.loaded['blink.cmp.completion.trigger']
        if trigger and trigger.cmdline_events and #trigger.show_emitter.listeners > 0 then
          if vim.fn.getcmdline() ~= '' and #opts.cmdline.sources() > 0 and not cmp.is_menu_visible() then cmp.show() end
        elseif attempts < 100 then
          attempts = attempts + 1
          vim.defer_fn(resume_first_command, 50)
        end
      end
      vim.schedule(resume_first_command)
    end,
  },
}
