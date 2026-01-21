{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
in
{
  home.packages = [ pkgs.rofi ];

  xdg.configFile.rofi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/rofi";
    recursive = true;
  };
}
