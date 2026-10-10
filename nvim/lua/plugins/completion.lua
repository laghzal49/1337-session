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
          min_width = 28,
          max_height = 6,
          -- One input row, then the command border, then completion.
          cmdline_position = function()
            local pos = vim.g.ui_cmdline_pos
            if pos then return {pos[1], pos[2]} end
            return {vim.o.lines-math.max(1,vim.o.cmdheight),0}
          end,
          border = 'rounded',
          winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
          scrollbar = true,
          scrolloff = 2,
          draw = {
            cursorline_priority = 100,
            columns = function()
              local label = vim.o.columns >= 100 and { 'label', 'label_description', gap = 1 } or { 'label' }
              local columns = { { 'kind_icon' }, label }
              if vim.o.columns >= 100 or vim.g.have_nerd_font == false then columns[#columns+1] = { 'kind' } end
              if vim.o.columns >= 80 then columns[#columns+1] = { 'source_name' } end
              return columns
            end,
            components = {
              kind_icon = {
                text = function(ctx)
                  local ui = require('config.ui')
                  return (ctx.source_id=='cmdline' and ui.icon('command') or ui.symbol(ctx.kind)) .. ' '
                end,
                highlight = function(ctx)
                  return {{group=ctx.source_id=='cmdline' and 'BlackPopupCommand' or ctx.kind_hl,priority=20000}}
                end,
              },
              label = { text = function(ctx) return ctx.label end, width = { max = function()
                local width = vim.o.columns
                if vim.api.nvim_get_mode().mode == 'c' then
                  return math.max(4, math.min(48, width - (vim.g.have_nerd_font == false and 20 or 8)))
                end
                local kind = (width >= 100 or vim.g.have_nerd_font == false) and 16 or 0
                local source = width >= 80 and 10 or 0
                local description = width >= 100 and 21 or 0
                return math.max(4, math.min(48, width - 8 - kind - source - description))
              end } },
              label_description = { width = { max = 20 }, text=function(ctx)
                return ctx.label_description~='' and ctx.label_description or ctx.label_detail
              end },
              kind = { width = { max = 12 },
                text=function(ctx) return ctx.source_id=='cmdline' and 'Command' or ctx.kind end,
                highlight=function(ctx) return ctx.source_id=='cmdline' and 'BlackPopupCommand' or ctx.kind_hl end,
              },
              source_name = {
                width = { max = 7 },
                text = function(ctx)
                  return ({lsp='LSP',buffer='BUF',path='PATH',snippets='SNIP',cmdline='CMD'})[ctx.source_id] or ctx.source_name
                end,
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 180,
          draw = function(opts) require('config.documentation').completion_draw(opts) end,
          window = {
            desired_min_width = 44,
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
          menu = { auto_show = true, draw = { columns = function()
            return vim.g.have_nerd_font == false and { { 'kind_icon' }, { 'label' }, { 'kind' } }
              or { { 'kind_icon' }, { 'label' } }
          end } },
          ghost_text = { enabled = false },
        },
      },
    },
    config = function(_, opts)
      -- Perfect Black owns these groups centrally in config.surfaces.
      vim.treesitter.language.register('markdown', 'blink-cmp-documentation')
      local cmp = require('blink.cmp')
      cmp.setup(opts)
      local function reflow()
        if not cmp.is_menu_visible() then return end
        local selected = cmp.get_selected_item_idx()
        cmp.hide({ callback = function() cmp.show({ initial_selected_item_idx = selected }) end })
      end
      local group = vim.api.nvim_create_augroup('BlackCompletionLayout', { clear = true })
      vim.api.nvim_create_autocmd('VimResized', { group = group, callback = reflow })
      vim.api.nvim_create_autocmd('User', { group = group, pattern = 'BlackUIPresetChanged', callback = reflow })
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
