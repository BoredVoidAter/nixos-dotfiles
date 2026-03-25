{ config, lib, ... }:
{
  options.boredvoidater.dotfilesPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/nixos-dotfiles/config";
    description = "Path to tracked dotfiles config directory.";
  };
}
