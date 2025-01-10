return {
  'mrjones2014/smart-splits.nvim',
  opts = {
    extensions = {
      smart_splits = {
        directions = { 'h', 'j', 'k', 'l' },
        mods = {
          -- for moving cursor between windows
          move = '<C>',
          -- for resizing windows
          resize = '<A>',
          -- for swapping window buffers
          swap = false, -- false disables creating a binding
        },
      },
    }
  }
}
