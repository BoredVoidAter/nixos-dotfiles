{ pkgs, config, lib, ... }:

{
  # -- Boot & System --
  boot.loader.systemd-boot = {
  	enable = true;
	configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # File Watcher Fixes for Unity/IDE performance
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  
  # -- Time & Locale --
  time.timeZone = "Europe/Berlin";

  # -- Services --
  hardware.enableRedistributableFirmware = true;

  # -- Packages --
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    pciutils
    lshw
    tree
  ];

  # -- Users --
  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "bluetooth" ];
    home = "/home/boredvoidater";
  };

  # -- Nix Configuration --
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
