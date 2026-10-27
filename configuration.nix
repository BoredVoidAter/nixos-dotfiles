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

  # iCloud Drive integration via rclone + SOPS
  services.icloud-drive = {
    enable = true;
    appleId = "boredvoidater@icloud.com";
    mountPoint = "/mnt/icloud-drive";
    readOnly = true;
    # appPasswordFile will be set via SOPS secret at runtime
    # Run: icloud-config to set up rclone remote, then icloud-mount
  };

  system.stateVersion = "25.05";
}
