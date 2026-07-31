{ config, pkgs, ags, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  home.packages = with pkgs; [
    swaybg
    wl-clipboard
    ags.packages.${pkgs.system}.default # Aylur's Gtk Shell (v1 from flake input)
  ];

  xdg.configFile.hypr = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
    recursive = true;
  };

  xdg.configFile.ags = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ags";
    recursive = true;
  };
}
