{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # -- Boot & System --
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  
  # -- Time & Locale --
  time.timeZone = "Europe/Berlin";
  
  # -- Graphics & Gaming Optimization (NEW) --
  
  # 1. Enable OpenGL/Graphics
  # 'hardware.graphics' is the modern option for NixOS Unstable (25.05)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Critical for Steam and Wine
  };

  # 2. Load Nvidia Drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for most Wayland compositors and modern X setups
    modesetting.enable = true;

    # Power management settings
    # 'enable = false' is generally more stable. 'finegrained = false' keeps GPU on 
    # when needed, preventing crashes on some laptops.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use proprietary drivers (generally better performance for gaming than open modules)
    open = false;

    # Accessible via 'nvidia-settings'
    nvidiaSettings = true;

    # Stable driver branch
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # 3. PRIME Offloading (Hybrid Graphics)
    # Configured for your Dell G3 15 (Intel + RTX 2060)
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # Bus IDs derived from your lspci output
      intelBusId = "PCI:0:2:0"; 
      nvidiaBusId = "PCI:1:0:0"; 
    };
  };

  # 4. Gaming Software
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;     # Open ports for Stream Remote Play
    dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server
    gamescopeSession.enable = true;      # Micro-compositor for better scaling/perf
  };

  programs.gamemode.enable = true;       # Optimizes CPU/IO when games are running

  # -- Desktop Environment --
  services.xserver = {
    enable = true;
    
    # Keyboard settings
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";

    # Display Manager
    displayManager.lightdm.enable = true;
    
    # Window Manager
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
  
  hardware.bluetooth = {
    enable = true; # Enable support
    powerOnBoot = true; # Power up the controller on boot
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket"; # Modern support
      };
    };
  };
  security.polkit.enable = true;

  # -- Networking & Firewall --
  networking.firewall.allowedTCPPorts = [ 53317 ]; # LocalSend
  networking.firewall.allowedUDPPorts = [ 53317 ];
  
  # -- Services --
  
  # Firmware
  hardware.enableRedistributableFirmware = true;

  # File Manager Support
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.tumbler.enable = true; # Thumbnails
  services.gvfs.enable = true;    # Mounts/Trash
  services.udisks2.enable = true; # Auto-mounting

  # Playit.gg
  services.playit = {
    enable = true;
    secretPath = "/etc/nixos/playit.toml"; 
  };
  
  programs.dconf.enable = true;

  # -- Users --
  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    packages = with pkgs; [
      tree
    ];
  };

  # -- Packages --
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim 
    wget
    alacritty
    git
    # Theme consistency
    libsForQt5.qt5.qtgraphicaleffects
    
    # Useful for checking GPU status
    pciutils
    lshw
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # XDG Portals
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # -- Nix Configuration --
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
