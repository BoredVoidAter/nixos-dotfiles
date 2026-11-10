{ config, pkgs, lib, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  xdg.configFile."mako/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/mako/config";
  };

  # mako is already in hyprland.nix packages
}