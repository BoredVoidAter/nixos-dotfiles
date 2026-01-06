return {
  -- Add Tokyonight
  { 
    "folke/tokyonight.nvim", 
    lazy = false, 
    priority = 1000, 
    opts = { style = "storm" } 
  },

  -- Configure LazyVim to load it
  { 
    "LazyVim/LazyVim", 
    opts = { 
      colorscheme = "tokyonight" 
    } 
  },
}
