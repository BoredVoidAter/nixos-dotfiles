-- config/nvim/lua/plugins/unity.lua
return {
  -- Import the C# extra from LazyVim
  { import = "lazyvim.plugins.extras.lang.omnisharp" },

  -- Configure Omnisharp to find the Nix-installed binary
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          cmd = { "OmniSharp" },
          -- Settings to help with Unity
          settings = {
            RoslynExtensionsOptions = {
              EnableDecompilationSupport = true,
              EnableImportCompletion = true,
            },
          },
        },
      },
    },
  },
}
