{ pkgs, pkgs-stable, lib, ... }:

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
    youtube-tui  # Beautiful TUI for YouTube (Audio fixed!)
    yewtube      # Robust CLI Youtube Player (mps-youtube fork)
    cava         # Audio Visualizer
  ];

  services.activitywatch.enable = true;

  # Hide the ugly tray icon by running in no-gui mode
  systemd.user.services.activitywatch.Service.ExecStart = lib.mkForce "${pkgs.activitywatch}/bin/aw-qt --no-gui";

  home.sessionVariables = {
    YTUI_MUSIC_DIR = "/home/boredvoidater/Music/ytui-music";
  };
}
