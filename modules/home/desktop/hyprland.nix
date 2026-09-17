{ config, pkgs, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  home.packages = with pkgs; [
    swaybg
    wl-clipboard
    cbatticon # Battery tray indicator
  ];

  xdg.configFile.hypr = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
    recursive = true;
  };
}
