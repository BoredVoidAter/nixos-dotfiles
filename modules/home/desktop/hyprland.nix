{ config, pkgs, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  home.packages = with pkgs; [
    swaybg
    wl-clipboard
    cbatticon # Battery tray indicator
    waybar    # Minimal top bar (battery, time, workspace)
  ];

  xdg.configFile.hypr = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
    recursive = true;
  };

  xdg.configFile.waybar = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/waybar";
    recursive = true;
  };
}
