{ pkgs, lib, ... }:

{
  home.pointerCursor = {
    enable = true;
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

    gtk3.extraCss = ''
      window.csd,
      window.solid-csd,
      decoration,
      decoration:backdrop {
        box-shadow: none;
        margin: 0;
        padding: 0;
        border: none;
      }

      dialog,
      messagedialog,
      dialog .dialog-vbox,
      messagedialog .dialog-vbox {
        background-color: #131418;
        color: #e6e6ea;
      }

      dialog headerbar,
      messagedialog headerbar {
        background-color: #131418;
        border-bottom: 1px solid #27282f;
        color: #e6e6ea;
      }

      dialog entry,
      messagedialog entry {
        background-color: #0d0e11;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 8px;
        caret-color: #4c50bc;
      }

      dialog entry:focus,
      messagedialog entry:focus {
        border-color: #4c50bc;
        box-shadow: 0 0 0 1px #4c50bc;
      }

      dialog button,
      messagedialog button {
        background-color: #18191e;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 8px;
      }

      dialog button:hover,
      messagedialog button:hover {
        background-color: #27282f;
        border-color: #3a3c48;
      }

      dialog button.suggested-action,
      messagedialog button.suggested-action {
        background-color: #4c50bc;
        color: #ffffff;
        border-color: #4c50bc;
      }

      dialog button.suggested-action:hover,
      messagedialog button.suggested-action:hover {
        background-color: #5b5fce;
      }
    '';

    gtk4.extraCss = ''
      @define-color accent_color #4c50bc;
      @define-color accent_bg_color #4c50bc;
      @define-color accent_fg_color #ffffff;
      @define-color window_bg_color #0d0e11;
      @define-color window_fg_color #e6e6ea;
      @define-color view_bg_color #0d0e11;
      @define-color view_fg_color #e6e6ea;
      @define-color headerbar_bg_color #131418;
      @define-color headerbar_fg_color #e6e6ea;
      @define-color headerbar_border_color #27282f;
      @define-color card_bg_color #131418;
      @define-color card_fg_color #e6e6ea;
      @define-color dialog_bg_color #131418;
      @define-color dialog_fg_color #e6e6ea;
      @define-color popover_bg_color #131418;
      @define-color popover_fg_color #e6e6ea;

      window.csd,
      window.solid-csd,
      decoration,
      decoration:backdrop {
        box-shadow: none;
        margin: 0;
        padding: 0;
        border: none;
      }

      window,
      dialog,
      alertdialog {
        background-color: #131418;
        color: #e6e6ea;
      }

      entry,
      passwordentry {
        background-color: #0d0e11;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 8px;
      }

      entry:focus-within,
      passwordentry:focus-within {
        border-color: #4c50bc;
        box-shadow: 0 0 0 1px #4c50bc;
      }

      button {
        background-color: #18191e;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 8px;
      }

      button:hover {
        background-color: #27282f;
        border-color: #3a3c48;
      }

      button.suggested-action {
        background-color: #4c50bc;
        color: #ffffff;
        border-color: #4c50bc;
      }

      button.suggested-action:hover {
        background-color: #5b5fce;
      }
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
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
