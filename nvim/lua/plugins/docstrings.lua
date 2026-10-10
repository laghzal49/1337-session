return {
  {
    'danymat/neogen',
    cmd = { 'Neogen', 'PythonDocstring' },
    keys = {
      { '<leader>cD', function() require('config.docstrings').generate() end, desc = 'Generate Python docstring' },
    },
    opts = {
      snippet_engine = 'nvim',
      placeholders_text = {
        description = 'Describe the behavior.', parameter = 'Describe this argument.',
        tparam = 'Describe this argument.', ['return'] = 'Describe the result.',
        yield = 'Describe each yielded value.', throw = 'Describe when this is raised.',
        attribute = 'Describe this attribute.', args = 'Describe these arguments.',
        kwargs = 'Describe these keyword arguments.',
      },
      languages = { python = { template = { annotation_convention = 'google_docstrings' } } },
    },
    config = function(_, opts)
      local items = require('neogen.types.template').item
      local extract = require('neogen.configurations.python').data.func.function_definition['0'].extract
      -- Keep signature order and use argument descriptions for typed parameters too.
      -- Upstream separates typed/untyped arguments and misses the varargs-only heading.
      opts.languages.python.data = { func = { function_definition = { ['0'] = {
        extract = function(node)
          local fields = extract(node)
          local names, parent, static = {}, node:parent(), false
          if parent:type() == 'decorated_definition' then
            for child in parent:iter_children() do
              if child:type() == 'decorator' and vim.treesitter.get_node_text(child, 0) == '@staticmethod' then static = true end
            end
            parent = parent:parent()
          end
          for child in node:field('parameters')[1]:iter_children() do
            local kind, name = child:type(), nil
            if kind == 'identifier' or kind == 'list_splat_pattern' or kind == 'dictionary_splat_pattern' then name = child
            elseif kind == 'default_parameter' or kind == 'typed_default_parameter' or kind == 'typed_parameter' then
              name = child:field('name')[1] or child:named_child(0)
            end
            if name then names[#names + 1] = vim.treesitter.get_node_text(name, 0) end
          end
          if not static and parent:type() == 'block' and parent:parent():type() == 'class_definition'
            and names[1] and not names[1]:match('^%*') then table.remove(names, 1) end
          fields[items.Parameter] = #names > 0 and names or nil
          fields[items.HasParameter] = #names > 0 and { true } or nil
          fields[items.Tparam], fields[items.ArbitraryArgs], fields[items.Kwargs] = nil, nil, nil
          return fields
        end,
      } } } }
      local template = vim.deepcopy(require('neogen.templates.google_docstrings'))
      for _, line in ipairs(template) do
        if line[1] == items.Parameter then line[2] = '    %s: $1' end
      end
      opts.languages.python.template.google_docstrings = template
      require('neogen').setup(opts)
      vim.api.nvim_create_user_command('PythonDocstring', function(args)
        require('config.docstrings').generate(args.args)
      end, { nargs = '?', complete = function() return { 'func', 'class', 'file' } end,
        desc = 'Generate an editable PEP 257 Python docstring' })
    end,
  },
}
