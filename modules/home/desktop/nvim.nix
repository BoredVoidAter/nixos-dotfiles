{ config, ... }:
let
  dotfiles = import ../dotfiles-path.nix { inherit config; };
in
{
  xdg.configFile.nvim = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
  };
}
