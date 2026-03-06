return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "bash", "html", "javascript", "json", "lua",
        "markdown", "markdown_inline", "nix", "python", "query",
        "regex", "tsx", "typescript", "vim", "yaml" },
    },
  },
  -- Force Mason to NOT install lua-ls since we have it via Nix
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
    },
  },
  -- Disable Mason entirely for LSPs we manage via Nix
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },
}
