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

  networking.networkmanager.enable = true;

  # -- Time & Locale --
  time.timeZone = "Europe/Berlin";

  # -- Services --
  hardware.enableRedistributableFirmware = true;

  # -- Packages --
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs;[
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
    extraGroups =[ "wheel" "networkmanager" "video" "audio" "bluetooth" "dialout" "cdrom" ];
    home = "/home/boredvoidater";
  };

  # -- Nix Configuration --
  nix.settings.experimental-features =[ "nix-command" "flakes" ];

  # --- SYSTEM SECRETS (SOPS) ---
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";
  
  # Tell sops to decrypt this specific secret at the system level
  sops.secrets.neohabit_env = {};

  sops.templates."neohabit.env".content = ''
    JWT_SECRET=${config.sops.placeholder.neohabit_env}
  '';

  # --- NEOHABIT DEPLOYMENT ---
  services.neohabit = {
    enable = true;
    domain = "localhost"; # Or your actual domain
    environmentFile = config.sops.templates."neohabit.env".path;
  };
  
  # Open port 80 for Nginx
  networking.firewall.allowedTCPPorts = [ 80 ];
}
