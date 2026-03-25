{ config, lib, pkgs, ... }:

let
  dotfiles = (import ../dotfiles-path.nix { inherit config; }).dotfiles;
in
{
  xdg.configFile.qtile = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/qtile";
    recursive = true;
  };
}
