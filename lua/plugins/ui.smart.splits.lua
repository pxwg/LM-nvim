return {
  'mrjones2014/smart-splits.nvim',
  event = "UIEnter",
  opts = {
    extensions = {
      smart_splits = {
        directions = { 'h', 'j', 'k', 'l' },
        mods = {
          -- for moving cursor between windows
          move = '<C>',
          swap = false, -- false disables creating a binding
        },
      },
    }
  }
}
