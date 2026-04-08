{ pkgs, lib, ... }:

{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Matcha-dark-aliz";
      package = pkgs.matcha-gtk-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Matcha-dark-aliz";
      cursor-theme = "Bibata-Modern-Ice";
      icon-theme = "Papirus-Dark";
    };
  };

  xresources.properties = {
    "Xcursor.theme" = "Bibata-Modern-Ice";
    "Xcursor.size" = 24;
  };

  home.sessionVariables = {
    GTK_THEME = "Matcha-dark-aliz";
    GTK2_RC_FILES = lib.mkForce "${pkgs.matcha-gtk-theme}/share/themes/Matcha-dark-aliz/gtk-2.0/gtkrc";
    GTK_USE_PORTAL = "1";
  };

  home.packages = with pkgs; [ xsettingsd ];

  xdg.configFile."xsettingsd/xsettingsd.conf".text = ''
    Net/ThemeName "Matcha-dark-aliz"
    Net/IconThemeName "Papirus-Dark"
    Gtk/CursorThemeName "Bibata-Modern-Ice"
    Net/EnableEventSounds 1
    EnableInputFeedbackSounds 0
    Xft/Antialias 1
    Xft/Hinting 1
    Xft/HintStyle "hintslight"
    Xft/RGBA "rgb"
  '';

  xdg.configFile."autostart/xsettingsd.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=xsettingsd
    Exec=${pkgs.xsettingsd}/bin/xsettingsd
    Hidden=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
  '';
}
