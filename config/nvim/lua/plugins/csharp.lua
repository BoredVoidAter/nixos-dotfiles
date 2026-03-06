return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
        csharp_ls = {
          mason = false,
          cmd = { "csharp-ls" },
          -- We guarantee the correct directory via the Unity wrapper or the terminal you open it in
          root_dir = function() return vim.fn.getcwd() end,
        },
      },
    },
  }
}
