return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "Hoffs/omnisharp-extended-lsp.nvim",
    },
    opts = {
      servers = {
        omnisharp = {
          mason = false,
          cmd = { "OmniSharp" },
          handlers = {
            ["textDocument/definition"] = function(...)
              return require("omnisharp_extended").handler(...)
            end,
          },
          enable_roslyn_analyzers = true,
          enable_import_completion = true,
          organize_imports_on_format = true,
          enable_editorconfig_support = true,
        },
      },
    },
  }
}
