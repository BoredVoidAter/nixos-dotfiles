return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          enabled = false,
        },
        csharp_ls = {
          mason = false,
          cmd = { "csharp-ls" },
          root_dir = function(fname)
            -- Use standard resolution, but fallback to our guaranteed CWD from the Unity wrapper
            return require("lspconfig.util").root_pattern("*.slnx", "*.sln", "*.csproj")(fname) or vim.fn.getcwd()
          end,
        },
      },
    },
  }
}
