{ config, lib, pkgs, ... }:

let
  dotfiles = import ../dotfiles-path.nix { inherit config; };
in
{
  xdg.configFile.qtile = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/qtile";
    recursive = true;
  };
}
