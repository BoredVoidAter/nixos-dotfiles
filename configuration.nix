{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/nixos/core.nix
      ./modules/nixos/gpu.nix
      ./modules/nixos/desktop.nix
      ./modules/nixos/audio.nix
      ./modules/nixos/flatpak.nix
      ./modules/nixos/storage.nix
      ./modules/nixos/ios.nix
      ./modules/nixos/icloud.nix
    ];

  networking.hostName = "nixos-btw"; # <--- Add this line


  system.stateVersion = "25.05";
}
