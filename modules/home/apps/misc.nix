{ pkgs, pkgs-stable, lib, config, ... }:

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
    rawtherapee

    gsettings-desktop-schemas
    pamixer
    xfconf
    repomix
    bluetuith
    pavucontrol

    xsel
    xclip
    wl-clipboard

    grim          
    slurp         
    qt5.qtwayland   

    gqrx
    sdrpp
    rtl_433

    xdg-utils

    blender

    wl-clicker

    ghidra

    davinci-resolve
    obs-studio
    ferdium

    jq
    steamcmd
    python3
    
    zbar # Provides zbarimg for reading QR codes
    tesseract # Optical Character Recognition (OCR) for screen scraping
    hyprpicker # Global color picker
  ];

  # Enables KDE Connect Indicator (Pairs great with the KDE Connect iOS App for notifications & clipboard)
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/boredvoidater/.config/sops/age/keys.txt";

  # Wipes Downloads directory on shutdown/logout
  systemd.user.services.clean-downloads = {
    Unit = {
      Description = "Clean Downloads folder on logout/shutdown";
      DefaultDependencies = "no";
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = "${pkgs.bash}/bin/bash -c 'rm -rf %h/Downloads/*'";
    };
    Install.WantedBy = [ "default.target" ];
  };

  xdg.desktopEntries."com.blackmagicdesign.resolve" = {
    name = "DaVinci Resolve";
    genericName = "Video Editor";
    exec = "nvidia-offload davinci-resolve %u";
    icon = "davinci-resolve";
    terminal = false;
    categories = [ "AudioVideo" "Video" "AudioVideoEditing" ];
  };
}
