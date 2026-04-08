{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [

      gnumake
      gcc
      cmake
      unzip
      gzip
      curl
      wget


      ripgrep # Fast text search (Telescope)
      fd # Fast file search (Telescope)
      xclip # X11 Clipboard support
      wl-clipboard # Wayland Clipboard support
      tree-sitter # TreeSitter CLI



      lua-language-server
      stylua


      nil # Nix LSP
      nixpkgs-fmt # Nix formatter


      python3
      pyright
      black # Python formatter


      nodejs
      nodePackages.typescript-language-server
      nodePackages.prettier


      shfmt
      shellcheck


      (with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ])
      csharp-ls
      netcoredbg
    ];
  };
}
