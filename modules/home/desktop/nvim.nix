{ config, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  xdg.configFile.nvim = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
  };
}
