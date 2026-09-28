return {
  'chomosuke/typst-preview.nvim',
  ft = 'typst',
  priority = 1000,
  version = '1.*',
  opts = function()
    local focus = require('util.zettypst_focus')
    local selected = {}
    return {
      extra_args = { '--input=preview=true' },
      get_main_file = function(path)
        local root, id = focus.note(path)
        local config = require('typst-preview.config')
        if root then
          local main = root .. '/focus.typ'
          -- Preview is bound to the explicitly requested note, not every BufEnter.
          -- A later preview command on another note replaces the old preview.
          if selected[root] and selected[root] ~= id then
            require('typst-preview.servers').remove(main)
          end
          selected[root] = id
          config.opts.extra_args = { '--input=preview=true', '--input=focus=' .. id }
          return main
        end
        -- The preview factory resolves the returned main a second time.
        local project = vim.fs.root(path, '.zettypst')
        if project and path == project .. '/focus.typ' and selected[project] then return path end
        config.opts.extra_args = { '--input=preview=true' }
        return path
      end,
      get_root = function(path) return vim.fs.root(path, '.zettypst') or vim.fn.getcwd() end,
      dependencies_bin = { tinymist = 'tinymist', websocat = 'websocat' },
    }
  end,
}
