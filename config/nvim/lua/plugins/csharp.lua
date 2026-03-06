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
          root_dir = function(fname)
            local root_files = {
              "*.sln",
              "*.slnx",
              "*.csproj",
            }
            for _, pattern in ipairs(root_files) do
              local root = require("lspconfig.util").root_pattern(pattern)(fname)
              if root then return root end
            end
          end,
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






