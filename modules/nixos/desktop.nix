{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";

    displayManager.lightdm = {
      enable = true;
      greeters.gtk = {
        enable = true;
        theme = {
          name = "Matcha-dark-aliz";
          package = pkgs.matcha-gtk-theme;
        };
        cursorTheme = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 24;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };
    };

    windowManager.qtile.enable = true;
  };

  services.libinput.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    alacritty
    libsForQt5.qt5.qtgraphicaleffects 
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true; # Fix for Unity Hub login
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  security.polkit.enable = true;
}
