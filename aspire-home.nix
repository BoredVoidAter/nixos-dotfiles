{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/home/dotfiles-path.nix
    ./modules/home/desktop/theme.nix
    ./modules/home/desktop/qtile.nix
    ./modules/home/desktop/rofi.nix
    ./modules/home/desktop/polkit.nix
    ./modules/home/desktop/nvim.nix
    ./modules/home/terminal/git.nix
    ./modules/home/terminal/bash.nix
    ./modules/home/terminal/fzf.nix
    ./modules/home/apps/neovim.nix
    ./modules/home/apps/firefox.nix
    ./modules/home/apps/media.nix
  ];

  home.packages = with pkgs; [
    brightnessctl
    wireplumber
    lxappearance
    mpv
    keepassxc
    gh
    pamixer
    repomix
    localsend
    vlc
    libdvdcss
    libdvdread
    libdvdnav
    asunder
    handbrake
    vcdimager
    yt-dlp
    ffmpeg
    xfburn
    
    # --- ADDED GSTREAMER PACKAGES ---
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  # --- ADDED SESSION VARIABLES ---
  home.sessionVariables = {
    # This dynamically points to wherever Home Manager installs your user packages
    GST_PLUGIN_PATH = "${config.home.profileDirectory}/lib/gstreamer-1.0";
  };

  home.username = "boredvoidater";
  home.stateVersion = "25.05";
}

