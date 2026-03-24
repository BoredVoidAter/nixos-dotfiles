{ config, pkgs, lib, ... }:

{
  imports = [
    # Desktop
    ./modules/home/desktop/theme.nix
    ./modules/home/desktop/qtile.nix
    ./modules/home/desktop/rofi.nix
    ./modules/home/desktop/polkit.nix
    ./modules/home/desktop/nvim.nix
    
    # Terminal
    ./modules/home/terminal/git.nix
    ./modules/home/terminal/bash.nix
    ./modules/home/terminal/fzf.nix
    
    # Apps (Stripped down)
    ./modules/home/apps/neovim.nix
    ./modules/home/apps/firefox.nix
    ./modules/home/apps/media.nix
  ];

  # Basic lightweight apps instead of your heavy misc.nix
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
    
    # Optical Media Playback & Extraction
    vlc
    libdvdcss
    libdvdread
    libdvdnav
    asunder      # Graphical Audio CD Ripper
    handbrake    # Video DVD Ripper
    vcdimager    # Special tool for extracting SVCD/VCD .mpg files
    
    # CD Burning & YouTube Downloading
    yt-dlp
    ffmpeg
    brasero
    cdrtools
  ];

  home.username = "boredvoidater";
  home.stateVersion = "25.05";
}
