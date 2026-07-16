{ config, pkgs, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  home.packages = with pkgs; [
    swaybg # Wallpaper utility
    wl-clipboard
  ];

  xdg.configFile.hypr = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
    recursive = true;
  };
}
