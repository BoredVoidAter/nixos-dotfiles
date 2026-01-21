{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
in
{
  xdg.configFile.qtile = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/qtile";
    recursive = true;
  };
}
