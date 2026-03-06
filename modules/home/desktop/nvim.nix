{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
in
{
  xdg.configFile.nvim = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
  };
}
