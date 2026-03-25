{ config, lib, pkgs, ... }:

let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  xdg.configFile.qtile = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/qtile";
    recursive = true;
  };
}
