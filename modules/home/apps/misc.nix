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

  # Deletes leftover PWA and Android shortcut files cluttering launchers
  home.activation.removeUnwantedDesktopFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Using 'find -iname' handles capitalization differences like WhatsAppWeb and firefoxPWA reliably
    find ~/.local/share/applications -maxdepth 1 -type f -iname '*whatsapp*' -delete || true
    find ~/.local/share/applications -maxdepth 1 -type f -iname '*firefoxpwa*' -delete || true
    find ~/.local/share/applications -maxdepth 1 -type f -iname '*fdroid*' -delete || true
    find ~/.local/share/applications -maxdepth 1 -type f -iname '*musify*' -delete || true
    find ~/.local/share/applications -maxdepth 1 -type f -iname '*waydroid*' -delete || true
  '';
}
