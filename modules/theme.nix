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
      name = "Tokyonight-Dark-B";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Tokyonight-Dark-B";
      cursor-theme = "Bibata-Modern-Ice";
      icon-theme = "Papirus-Dark";
    };
  };

  xresources.properties = {
    "Xcursor.theme" = "Bibata-Modern-Ice";
    "Xcursor.size" = 24;
  };

  # Forces PCManFM and other stubborn GTK apps to use the theme
  home.sessionVariables = {
    GTK_THEME = "Tokyonight-Dark-B";
    GTK2_RC_FILES = lib.mkForce "${pkgs.tokyonight-gtk-theme}/share/themes/Tokyonight-Dark-B/gtk-2.0/gtkrc";
  };
  
  home.packages = with pkgs; [
    xsettingsd
  ];

  # Create xsettingsd config for runtime theme enforcement
  xdg.configFile."xsettingsd/xsettingsd.conf".text = ''
    Net/ThemeName "Tokyonight-Dark-B"
    Net/IconThemeName "Papirus-Dark"
    Gtk/CursorThemeName "Bibata-Modern-Ice"
    Net/EnableEventSounds 1
    EnableInputFeedbackSounds 0
    Xft/Antialias 1
    Xft/Hinting 1
    Xft/HintStyle "hintslight"
    Xft/RGBA "rgb"
  '';

  # Autostart xsettingsd
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
