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
    wakatime-cli

    gtk-engine-murrine
    gnome-themes-extra
    
    gsettings-desktop-schemas
    pamixer
    xfconf
    repomix
    bluetuith
    google-chrome
    pavucontrol

    xsel   # Required by Repomix's clipboard library
    xclip  # General clipboard tool for X11
    gimp
    inkscape
    butler
    gemini-cli
    
    pkgs-stable.aseprite

    # Media / Rice
    yewtube      # Robust CLI Youtube Player (mps-youtube fork)
    cava         # Audio Visualizer
  ];

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";

  sops.secrets.wakatime_api_key = { };

  sops.templates.".wakatime.cfg" = {
    path = ".wakatime.cfg";
    content = ''
      [settings]
      api_url = https://waka.hackclub.com/api/v1
      api_key = ${config.sops.placeholder.wakatime_api_key}
      debug = false
    '';
  };

    home.sessionVariables = {
    YTUI_MUSIC_DIR = "/home/boredvoidater/Music/ytui-music";
  };
}
