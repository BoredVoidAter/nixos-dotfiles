{ config, lib, pkgs, ... }:

let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  home.packages = [ pkgs.rofi ]; # Use Wayland fork!

  xdg.configFile.rofi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/rofi";
    recursive = true;
  };
}
