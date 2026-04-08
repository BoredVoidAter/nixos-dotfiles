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

    # Added for Neohabit standalone wrapper
    chromium
  ];

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";

  # REMOVED SOPS BLOCKS HERE (Now in hackatime.nix)
  
  home.sessionVariables = {
    YTUI_MUSIC_DIR = "/home/boredvoidater/Music/ytui-music";
  };

  # --- Neohabit Standalone App Wrapper ---
  xdg.desktopEntries.neohabit = {
    name = "Neohabit";
    genericName = "Habit Tracker";
    # The --app flag strips all browser UI (tabs, URL bar) to make it feel native
    exec = "${pkgs.chromium}/bin/chromium --app=http://localhost --class=NeohabitApp";
    terminal = false;
    categories = [ "Utility" ];
    icon = "${neohabit-src}/frontend/src/logos/neohabit-logo-dark.svg";

  };
}
