vim.api.nvim_create_autocmd("FileType", {
  pattern = "cs",
  callback = function()
    require("lspconfig").csharp_ls.setup({
      mason = false,
      cmd = { "csharp-ls" },
      filetypes = { "cs" },
      root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern("*.slnx", "*.sln", "Assembly-CSharp.csproj")(fname) or util.find_git_ancestor(fname)
      end,
    })

    require("lspconfig").csharp_ls.launch()
  end,
})
