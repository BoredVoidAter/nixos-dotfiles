{ config, pkgs, lib, ... }:
let
  dotfiles = config.boredvoidater.dotfilesPath;
in
{
  # GTK 3 settings
  xdg.configFile."gtk-3.0/settings.ini" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/gtk-3.0/settings.ini";
  };

  # GTK 4 settings
  xdg.configFile."gtk-4.0/settings.ini" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/gtk-4.0/settings.ini";
  };

  # GTK 2 settings (file chooser, legacy apps)
  xdg.configFile."gtk-2.0/gtkfilechooser.ini" = {
    text = ''
      [Filechooser Settings]
      LocationMode=path-bar
      ShowHidden=false
      ShowSizeColumn=true
      SortColumn=modified
      SortOrder=descending
      StartupMode=recent
    '';
  };

  # Ensure themes are available
  home.packages = with pkgs; [
    papirus-icon-theme
    matcha-gtk-theme
    bibata-cursors
  ];

  # GTK theme environment variables (for non-GTK apps that respect them)
  home.sessionVariables = {
    GTK_THEME = "Matcha-dark-aliz";
    ICON_THEME = "Papirus-Dark";
    CURSOR_THEME = "Bibata-Modern-Ice";
    CURSOR_SIZE = "24";
  };
}