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
    "radeon.dpm=0"
  ];
  services.xserver.videoDrivers = [ "modesetting" ];

  services.xserver.deviceSection = ''
    Option "AccelMethod" "none"
  '';

  environment.variables = {
    LIBGL_ALWAYS_SOFTWARE = "1";
  };
 

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

  security.wrappers.wodim = {
    source = "${pkgs.cdrkit}/bin/wodim";
    owner = "root";
    group = "cdrom";
    setuid = true;
  };

  security.wrappers.cdrecord = {
    source = "${pkgs.cdrtools}/bin/cdrecord";
    owner = "root";
    group = "cdrom";
    setuid = true;
  };

  users.users.boredvoidater.extraGroups = [ "cdrom" ];

  system.stateVersion = "25.05";
}
