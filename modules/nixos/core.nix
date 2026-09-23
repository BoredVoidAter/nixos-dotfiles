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
    useOSProber = true;        # This automatically finds Windows and makes it the 2nd option
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
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.nftables.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
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
    bubblewrap
    (writeShellScriptBin "bubblewrap" ''exec ${pkgs.bubblewrap}/bin/bwrap "$@"'')
  ];

  networking.firewall.checkReversePath = false; 

  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };

  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "bluetooth" "dialout" "cdrom" "input" "render" ];
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
}
