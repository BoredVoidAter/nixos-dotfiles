{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    extraPackages = with pkgs; [
      # -- Build Tools (Required for plugins that compile code) --
      gnumake
      gcc
      cmake
      unzip
      gzip
      curl
      wget
      
      # -- System Tools --
      ripgrep      # Fast text search (Telescope)
      fd           # Fast file search (Telescope)
      xclip        # X11 Clipboard support
      wl-clipboard # Wayland Clipboard support
      tree-sitter  # TreeSitter CLI

      # -- Language Servers & Formatters (Instead of Mason) --
      # Lua
      lua-language-server
      stylua

      # Nix
      nil          # Nix LSP
      nixpkgs-fmt  # Nix formatter

      # Python
      python3
      pyright
      black        # Python formatter

      # Web / JS
      nodejs
      nodePackages.typescript-language-server
      nodePackages.prettier

      # Shell
      shfmt
      shellcheck

      # -- C# / Unity Support --
      (with pkgs.dotnetCorePackages; combinePackages[ sdk_8_0 sdk_9_0 ])
      csharp-ls
      netcoredbg
    ];
  };
}
