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
  ];

  home.username = "boredvoidater";
  home.stateVersion = "25.05";
}
