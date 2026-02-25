{ config, pkgs, sops-nix, ... }:

{
  imports = [
    sops-nix.homeManagerModules.sops
    # Desktop
    ./modules/home/desktop/theme.nix
    ./modules/home/desktop/qtile.nix
    ./modules/home/desktop/rofi.nix
    ./modules/home/desktop/polkit.nix
    ./modules/home/desktop/redshift.nix
    
    # Terminal
    ./modules/home/terminal/git.nix
    ./modules/home/terminal/bash.nix
    ./modules/home/terminal/fzf.nix
    
    # Apps
    ./modules/home/apps/neovim.nix
    ./modules/home/apps/firefox.nix
    ./modules/home/apps/anki.nix
    ./modules/home/apps/unity.nix
    ./modules/home/apps/misc.nix
    ./modules/home/apps/cad.nix
    ./modules/home/apps/hackatime.nix
  ];

  home.username = "boredvoidater";
  home.stateVersion = "25.05";
}
