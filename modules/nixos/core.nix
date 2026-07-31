{ pkgs, config, lib, ... }:

{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";          # Required for EFI
    useOSProber = true;        # This automatically finds Windows and makes it the 2nd option
    configurationLimit = 20;   # Keeps the last 20 generations in the "Advanced" submenu
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
  };

  time.timeZone = "Europe/Berlin";

  hardware.enableRedistributableFirmware = true;
  hardware.rtl-sdr.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs;[
    vim wget git pciutils lshw tree calibre wireguard-tools protonvpn-gui wl-clicker gtk3
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
