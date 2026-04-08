{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/nixos/core.nix
      ./modules/nixos/gaming.nix
      ./modules/nixos/desktop.nix
      ./modules/nixos/audio.nix
      ./modules/nixos/flatpak.nix
    ];

  networking.hostName = "nixos-btw"; # <--- Add this line

  system.stateVersion = "25.05";
}
