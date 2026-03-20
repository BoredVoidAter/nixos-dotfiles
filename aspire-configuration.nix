{ config, pkgs, lib, ... }:

{
  imports = [ 
    ./hardware-aspire.nix 
    ./modules/nixos/core.nix
    ./modules/nixos/desktop.nix
    ./modules/nixos/audio.nix
  ];
  networking.hostName = "nixos-aspire";
  boot.kernelParams = [
    "radeon.dpm=0",
    "radeon.uvd=0"
  ];
  # Override Bootloader for old laptops (Legacy BIOS)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # Make sure this matches your drive
  };

  # Disable heavy services hardcoded in core.nix
  services.neohabit.enable = lib.mkForce false;
  services.postgresql.enable = lib.mkForce false;
  services.nginx.enable = lib.mkForce false;

  # FIX FOR SOPS: 
  # Instead of breaking the file path, we forcefully empty the list of secrets 
  # and templates that core.nix asked for. This prevents the laptop from 
  # attempting (and failing) to decrypt the Neohabit secrets on boot.
  sops.secrets = lib.mkForce {};
  sops.templates = lib.mkForce {};

  system.stateVersion = "25.05";
}
