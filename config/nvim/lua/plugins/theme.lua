return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "storm",
      on_colors = function(colors)
        colors.bg = "#0D0D0D"
        colors.bg_dark = "#0D0D0D"
        colors.bg_float = "#0D0D0D"
        colors.fg = "#D9BC9A"
        colors.fg_dark = "#D9BC9A"
        colors.fg_gutter = "#BF8845"
        colors.red = "#590202"
        colors.blue = "#23A5D9"
        colors.yellow = "#BF8845"
        colors.border = "#590202"
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight" },
  },
}
