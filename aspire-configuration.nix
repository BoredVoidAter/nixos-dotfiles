{ config, pkgs, lib, ... }:

{
  imports = [ 
    ./hardware-aspire.nix # You will generate this on the laptop
    ./modules/nixos/core.nix
    ./modules/nixos/desktop.nix
    ./modules/nixos/audio.nix
    # Notice we omitted gaming.nix and flatpak.nix entirely
  ];

  # Override Bootloader for old laptops (If your Aspire uses Legacy BIOS)
  # If it actually supports UEFI, you can remove these 3 lines.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # Change to your actual drive during install
  };

  # Disable heavy services hardcoded in core.nix
  services.neohabit.enable = lib.mkForce false;
  services.postgresql.enable = lib.mkForce false;
  services.nginx.enable = lib.mkForce false;

  # Optionally disable SOPS if you don't want to copy your private keys to the old laptop
  sops.defaultSopsFile = lib.mkForce null;

  system.stateVersion = "25.05";
}
