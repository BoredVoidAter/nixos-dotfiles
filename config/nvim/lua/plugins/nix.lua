return {
  -- We must let Mason load so LazyVim's LSP system doesn't crash,
  -- but we will bypass it for specific languages in their own files.

  -- Ensure Treesitter uses the system compiler
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "nix",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },
}
