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
    "elevator=bfq"
  ];
  services.xserver.videoDrivers = [ "modesetting" ];

  services.xserver.deviceSection = ''
    Option "AccelMethod" "none"
  '';

  environment.variables = {
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

  programs.k3b.enable = true;


  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # Make sure this matches your drive
  };
 

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
  };





  sops.secrets = lib.mkForce { };
  sops.templates = lib.mkForce { };


  users.users.boredvoidater.extraGroups = [ "cdrom" ];


  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };


  boot.kernel.sysctl = { "vm.swappiness" = 10; };


  nix.settings.auto-optimise-store = false;


  system.stateVersion = "25.05";
}
