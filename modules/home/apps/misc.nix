{ pkgs, pkgs-stable, lib, config, ... }:

{
  home.packages = with pkgs; [
    tumbler
    obsidian
    brightnessctl
    wireplumber
    lxappearance
    prismlauncher
    jdk17
    localsend
    mpv
    keepassxc
    gh

    digital

    peek
    gifski

    gtk-engine-murrine
    gnome-themes-extra
    
    gsettings-desktop-schemas
    pamixer
    xfconf
    repomix
    bluetuith
    pavucontrol

    xsel
];

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";

  # REMOVED SOPS BLOCKS HERE (Now in hackatime.nix)
  
  home.sessionVariables = {
    YTUI_MUSIC_DIR = "/home/boredvoidater/Music/ytui-music";
  };

  # temporary
  services.neohabit = {
    enable = true;
    domain = "localhost"; # Or your actual domain
    environmentFile = config.sops.templates."neohabit.env".path;
  };
  # Open port 80 for Nginx if it's not open
  networking.firewall.allowedTCPPorts = [ 80 ];
}
