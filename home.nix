{ config, pkgs, lib, ... }:
let
    dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
    create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
    configs = {
        qtile = "qtile";
        # rofi is handled via symlink
        rofi = "rofi";
        nvim = "nvim";
    };
in
{
  imports = [
    ./modules/theme.nix
    ./modules/neovim.nix
    ./modules/firefox.nix
    ./modules/anki.nix
  ];

  home.username = "boredvoidater";
  home.homeDirectory = "/home/boredvoidater";
  home.stateVersion = "25.05";

  programs.git = {
    enable = true;
    userName = "Boredvoidater";             # e.g. "John Doe"
    userEmail = "boredvoidater@proton.me";    # e.g. "john@example.com"
    
    # This setup allows 'git push' to use the login details you just saved with 'gh'
    extraConfig = {
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw";
      n = "nvim";
    };
  };

  # Symlink dotfiles (Qtile, Rofi)
  xdg.configFile = builtins.mapAttrs (name: subpath: {
        source = create_symlink "${dotfiles}/${subpath}";
        recursive = true;
    }) configs;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };
 
  

  # Activation script to remove leftover Waydroid desktop entries
  home.activation.removeWaydroidEntries = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Cleaning up Waydroid desktop entries..."
    rm -f $HOME/.local/share/applications/waydroid.*.desktop
    rm -f $HOME/.local/share/applications/lineage.*.desktop
  '';

  home.packages = with pkgs; [
    rofi
    # Thunar removed here; it is enabled in configuration.nix
    xfce.tumbler
    obsidian
    brightnessctl
    wireplumber
    lxappearance
    prismlauncher
    jdk17
    localsend
    mpv
    keepassxc
    gh

    gtk-engine-murrine
    gnome-themes-extra
    
    # REQUIRED for apps to load settings
    gsettings-desktop-schemas
    pamixer
    xfce.xfconf
    repomix
  ];
}
