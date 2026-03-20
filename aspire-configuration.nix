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
    "radeon.dpm=1"
  ];
  services.xserver.videoDrivers = [ "radeon" ];
  
  # This is the magic trick: it tells the Radeon driver to handle the 
  # resolution, but strictly forbids it from using the broken 3D engine.
  services.xserver.deviceSection = ''
    Option "NoAccel" "True"
    Option "DRI" "False"
  ''; 
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

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  networking.firewall = {
    allowedTCPPorts = [ 22 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  # FIX FOR SOPS: 
  # Instead of breaking the file path, we forcefully empty the list of secrets 
  # and templates that core.nix asked for. This prevents the laptop from 
  # attempting (and failing) to decrypt the Neohabit secrets on boot.
  sops.secrets = lib.mkForce {};
  sops.templates = lib.mkForce {};

  system.stateVersion = "25.05";
}
