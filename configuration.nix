{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # -- Boot & System --
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 1. Add File Watcher Fixes for Unity/IDE performance
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  
  # -- Time & Locale --
  time.timeZone = "Europe/Berlin";
  
  # -- Graphics & Gaming Optimization --
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0"; 
      nvidiaBusId = "PCI:1:0:0"; 
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  # -- Desktop Environment --
  services.xserver = {
    enable = true;
    
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";

    displayManager.lightdm.enable = true;
    windowManager.qtile.enable = true;
  };

  # -- Audio & Input --
  services.libinput.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # -- BLUETOOTH FIX --
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;  # Enables better device support
      };
    };
  };
  
  # Enable blueman for better Bluetooth management
  services.blueman.enable = true;
  
  # Ensure your user is in the bluetooth group
  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "bluetooth" ];
    packages = with pkgs; [
      tree
    ];
  };
  
  security.polkit.enable = true;

  # -- Networking & Firewall --
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
  
  # -- Services --
  
  hardware.enableRedistributableFirmware = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  services.playit = {
    enable = true;
    secretPath = "/etc/nixos/playit.toml"; 
  };
  
  programs.dconf.enable = true;

  # -- Packages --
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    alacritty
    git
    libsForQt5.qt5.qtgraphicaleffects
    pciutils
    lshw
    
    # Bluetooth tools
    bluez
    bluez-tools
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # -- Nix Configuration --
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
