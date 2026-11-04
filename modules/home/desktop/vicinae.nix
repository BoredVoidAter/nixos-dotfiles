{ config, pkgs, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  programs.vicinae = {
    enable = true;
  };

  home.packages = [
    pkgs.wtype
  ];

  xdg.configFile.vicinae = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/vicinae";
    recursive = true;
  };
}
