return {
  -- VSCode like Extension Manager
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason (Extension Manager)" } },
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "nil",       -- Nix LSP
        "nixpkgs-fmt"
      },
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    },
  },

  -- Automatic LSP Hookup
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      automatic_installation = true, -- Automatically install LSPs when you open a file!
    },
  },

  -- Auto-install Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      auto_install = true, -- If you open a new file format, it downloads highlighting automatically
    },
  },
}
