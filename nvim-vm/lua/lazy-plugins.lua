require('lazy').setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.

  require 'kickstart.plugins.gitsigns',

  require 'kickstart.plugins.telescope',

  require 'kickstart.plugins.neo-tree',

  require 'kickstart.plugins.file-operation',

  require 'kickstart.plugins.diffview',

  require 'kickstart.plugins.colorscheme',

  require 'kickstart.plugins.cmp',

  require 'kickstart.plugins.barbar',

  require 'kickstart.plugins.persistence',

  require 'kickstart.plugins.hbac',

  require 'kickstart.plugins.incline',

  require 'kickstart.plugins.todo-comments',

  require 'kickstart.plugins.flash',

  require 'kickstart.plugins.lsp',

  require 'kickstart.plugins.lsp-preview',

  require 'kickstart.plugins.snipe',

  require 'kickstart.plugins.comment',

  require 'kickstart.plugins.illuminate',

  require 'kickstart.plugins.mini',

  require 'kickstart.plugins.mini-diff',

  require 'kickstart.plugins.suda',

  require 'kickstart.plugins.cool',

  require 'kickstart.plugins.treesitter',

  require 'kickstart.plugins.autopairs',

  require 'kickstart.plugins.indent_line',

  require 'kickstart.plugins.formatting',

  require 'kickstart.plugins.neogit',

}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
