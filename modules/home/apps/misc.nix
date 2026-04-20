{ pkgs, pkgs-stable, lib, config, sops, neohabit-src, ... }:

{
  home.packages = with pkgs;[
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

    pkgs-stable.aseprite

    tenacity

    gimp

    gsettings-desktop-schemas
    pamixer
    xfconf
    repomix
    bluetuith
    pavucontrol

    xsel
    xclip
    copyq

    gqrx
    sdrpp

  ];

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";



  home.sessionVariables = {
    YTUI_MUSIC_DIR = "/home/boredvoidater/Music/ytui-music";
  };


}
