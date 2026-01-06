{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;

  networking.firewall.allowedTCPPorts = [ 53317 ]; # LocalSend
  networking.firewall.allowedUDPPorts = [ 53317 ];

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Berlin";

  #services.displayManager.ly.enable = true;
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    displayManager.lightdm.enable = true;
    windowManager.qtile.enable = true;
    xkb.layout = "de"; # Fixed syntax for newer NixOS
  };

  services.libinput.enable = true;



  services.playit = {
    enable = true;
    secretPath = "/etc/nixos/playit.toml"; 
  };

  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    vim 
    wget
    alacritty
    git
    # Added for theme consistency helper
    libsForQt5.qt5.qtgraphicaleffects
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
  
  services.gvfs.enable = true; # Mount USBs/Trash in PCManFM
  services.udisks2.enable = true; # Required for PCManFM mounting

  programs.dconf.enable = true;

  # XDG Portal settings
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}
