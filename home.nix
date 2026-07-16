{ config, pkgs, sops-nix, ... }:

{
  imports = [
    ./modules/home/dotfiles-path.nix
    sops-nix.homeManagerModules.sops

    ./modules/home/desktop/theme.nix
    ./modules/home/desktop/hyprland.nix
    ./modules/home/desktop/rofi.nix
    ./modules/home/desktop/nvim.nix

    ./modules/home/terminal/git.nix
    ./modules/home/terminal/bash.nix
    ./modules/home/terminal/fzf.nix

    ./modules/home/apps/neovim.nix
    ./modules/home/apps/firefox.nix
    ./modules/home/apps/anki.nix
    ./modules/home/apps/unity.nix
    ./modules/home/apps/misc.nix
    ./modules/home/apps/cad.nix
    ./modules/home/apps/media.nix
    ./modules/home/apps/alacritty.nix
  ];


  home.username = "boredvoidater";
  home.stateVersion = "25.05";

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>localsend</icon>
        <name>Send via LocalSend</name>
        <command>localsend_app %F</command>
        <patterns>*</patterns>
        <directories/>
      </action>
    </actions>
  '';
}
