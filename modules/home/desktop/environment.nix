{ config, pkgs, lib, ... }:
{
  # Environment variables from ~/.config/environment.d/
  home.sessionVariables = {
    # Qt paths (needed for Qt apps to find plugins/themes on NixOS)
    QML2_IMPORT_PATH = "${pkgs.qt5.qtdeclarative}/lib/qt-5.15/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
    QT_PLUGIN_PATH = "${pkgs.qt5.qtbase}/lib/qt-5.15/plugins:${pkgs.qt6.qtbase}/lib/qt-6/plugins";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };
}