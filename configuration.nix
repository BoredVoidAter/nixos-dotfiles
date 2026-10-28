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

  networking.hostName = "nixos-btw";

  # iCloud Drive integration via rclone (main password + 2FA)
  services.icloud-drive = {
    enable = true;
    appleId = "boredvoidater@icloud.com";
    mountPoint = "/mnt/icloud-drive";
    readOnly = true;
    mountUser = "boredvoidater";
  };

  system.stateVersion = "25.05";
}
