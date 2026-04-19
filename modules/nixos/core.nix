{ pkgs, config, lib, ... }:

{

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;


  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];


  time.timeZone = "Europe/Berlin";


  hardware.enableRedistributableFirmware = true;


  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs;[
    vim
    wget
    git
    pciutils
    lshw
    tree
  ];


  users.users.boredvoidater = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "bluetooth" "dialout" "cdrom" ];
    home = "/home/boredvoidater";
  };


  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";


}
