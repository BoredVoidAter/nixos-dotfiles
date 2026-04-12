{ config, pkgs, sops-nix, ... }:

{
  imports = [
    ./modules/home/dotfiles-path.nix
    sops-nix.homeManagerModules.sops

    ./modules/home/desktop/theme.nix
    ./modules/home/desktop/qtile.nix
    ./modules/home/desktop/rofi.nix
    ./modules/home/desktop/polkit.nix
    ./modules/home/desktop/redshift.nix
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
    ./modules/home/apps/hackatime.nix
    ./modules/home/apps/media.nix
    ./modules/home/apps/alacritty.nix
  ];

  services.flameshot = {
    enable = true;
    settings.General.showStartupLaunchMessage = false;
  };

  home.username = "boredvoidater";
  home.stateVersion = "25.05";

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>localsend</icon>
        <name>Send via LocalSend</name>
        <submenu></submenu>
        <unique-id>localsend-action</unique-id>
        <command>localsend_app %F</command>
        <description>Send file(s) to another device on the network</description>
        <patterns>*</patterns>
        <directories/>
        <audio-files/>
        <image-files/>
        <other-files/>
        <text-files/>
        <video-files/>
      </action>
    </actions>
  '';
}
