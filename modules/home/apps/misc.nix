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
    flameshot

    gtk-engine-murrine
    gnome-themes-extra
    
    gsettings-desktop-schemas
    pamixer
    xfconf
    repomix
    bluetuith
    google-chrome
    pavucontrol

    xsel
    xclip
    gimp
    inkscape
    butler
    gemini-cli
    
    pkgs-stable.aseprite

    yewtube
    cava

    tiled
  ];

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";

  # REMOVED SOPS BLOCKS HERE (Now in hackatime.nix)
  
  home.sessionVariables = {
    YTUI_MUSIC_DIR = "/home/boredvoidater/Music/ytui-music";
  };
}
