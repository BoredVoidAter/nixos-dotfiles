{ pkgs, config, lib, ... }:

{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
    "usbcore.autosuspend=-1"
  ];
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";          # Required for EFI
    useOSProber = false;       # Windows dualboot removed - no longer needed
    configurationLimit = 20;   # Keeps the last 20 generations in the "Advanced" submenu
    splashImage = null;
    extraConfig = ''
      set menu_color_normal=light-gray/black
      set menu_color_highlight=white/dark-gray
      set color_normal=light-gray/black
      set color_highlight=white/dark-gray
    '';
  };

  hardware.uinput.enable = true;
  boot.kernelModules = [ "uinput" ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  console = {
    useXkbConfig = true;
  };

  networking.networkmanager = {
    enable = true;
  };

  # Disable NetworkManager-wait-online to speed up boot (~5.5s saved)
  # Network will come up in background, apps can handle transient connectivity
  systemd.services.NetworkManager-wait-online.enable = false;
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.nftables.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = [ 53317 8080 9090 ];
    allowedUDPPorts = [ 53317 ];
    # Ports for KDE Connect (iOS Integration)
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };

  time.timeZone = "Europe/Berlin";

  hardware.enableRedistributableFirmware = true;
  hardware.rtl-sdr.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Enable usbmuxd to communicate with iOS devices over USB
  services.usbmuxd.enable = true;

  # Power management and thermal tuning
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  powerManagement.powertop.enable = true;

  services.udev.extraRules = ''
    # Prevent USB power-saving autosuspend on USB devices
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
  '';

  environment.systemPackages = with pkgs; [
    vim wget git pciutils lshw tree calibre wireguard-tools proton-vpn wl-clicker gtk3
    libimobiledevice ifuse # Required for mounting and interacting with iOS devices
    libsmbios
    mcp-nixos
    # Wrapper for passwordless nixos-rebuild (uses current system's nixos-rebuild)
    (writeShellScriptBin "nixos-rebuild-claude" ''
      #!/usr/bin/env sh
      exec /run/current-system/sw/bin/nixos-rebuild switch --flake /home/boredvoidater/nixos-dotfiles#nixos-btw "$@"
    '')
  ];

  networking.firewall.checkReversePath = "loose"; 

  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };

  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "bluetooth" "dialout" "cdrom" "input" "render" "uinput"];
    home = "/home/boredvoidater";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # MAGIC FIX FOR NEOVIM (MASON) & PRECOMPILED BINARIES
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc zlib fuse3 icu nss openssl curl expat
  ];

  security.sudo.extraRules = [
    {
      users = [ "boredvoidater" ];
      commands = [
        {
          command = "${pkgs.libsmbios}/bin/smbios-battery-ctl";
          options = [ "NOPASSWD" ];
        }
        {
          # Allow passwordless nixos-rebuild via wrapper script (stable path)
          command = "/run/current-system/sw/bin/nixos-rebuild-claude";
          options = [ "NOPASSWD" ];
        }
        {
          # Allow passwordless nix-env for profile switching
          command = "${pkgs.nix}/bin/nix-env";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
