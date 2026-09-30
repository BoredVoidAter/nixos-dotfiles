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
    copyq
    wl-clipboard

    grim          
    slurp         
    qt5.qtwayland   

    gqrx
    sdrpp

    xdg-utils

    blender

    wl-clicker

    ghidra

    davinci-resolve
    ferdium

    jq
    steamcmd
    python3
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
}
