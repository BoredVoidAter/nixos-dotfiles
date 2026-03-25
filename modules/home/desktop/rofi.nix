{ config, lib, pkgs, ... }:

let
  dotfiles = import ../dotfiles-path.nix { inherit config; };
in
{
  home.packages = [ pkgs.rofi ];

  xdg.configFile.rofi = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/rofi";
    recursive = true;
  };
}
