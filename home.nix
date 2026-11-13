{ config, pkgs, sops-nix, vicinae, spicetify-nix, ... }:

{
  imports = [
    vicinae.homeManagerModules.default
    spicetify-nix.homeManagerModules.default
    ./modules/home/dotfiles-path.nix
    sops-nix.homeManagerModules.sops

    ./modules/home/desktop/theme.nix
    ./modules/home/desktop/hyprland.nix
    ./modules/home/desktop/notifications.nix
    ./modules/home/desktop/vicinae.nix
    ./modules/home/desktop/nvim.nix
    ./modules/home/desktop/gtk.nix
    ./modules/home/desktop/mako.nix
    ./modules/home/desktop/environment.nix

    ./modules/home/terminal/git.nix
    ./modules/home/terminal/bash.nix
    ./modules/home/terminal/fzf.nix

    ./modules/home/apps/neovim.nix
    ./modules/home/apps/librewolf.nix
    ./modules/home/apps/anki.nix
    ./modules/home/apps/unity.nix
    ./modules/home/apps/misc.nix
    ./modules/home/apps/cad.nix
    ./modules/home/apps/media.nix
    ./modules/home/apps/alacritty.nix
    ./modules/home/apps/free-claude-code.nix
    ./modules/home/apps/notion.nix
    ./modules/home/apps/todo.nix
    ./modules/home/apps/pkgripper/pkgripper.nix
    ./modules/home/apps/flatpak-auto-update.nix
    ./modules/home/apps/karaoke.nix
  ];


  home.username = "boredvoidater";
  home.stateVersion = "25.05";

  xdg.configFile."Thunar/uca.xml" = {
    force = true;
    text = ''
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
  };
}
