{ config, pkgs, lib, ... }:
{
  # Environment variables from ~/.config/environment.d/
  home.sessionVariables = {
    # Qt paths (needed for Qt apps to find plugins/themes on NixOS)
    QML2_IMPORT_PATH = "${pkgs.qt5.qtdeclarative}/lib/qt-5.15/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
    QT_PLUGIN_PATH = "${pkgs.qt5.qtbase}/lib/qt-5.15/plugins:${pkgs.qt6.qtbase}/lib/qt-6/plugins";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  # Immediately unmount and clear any stale ~/.gvfs FUSE mount on rebuild/switch
  home.activation.cleanupStaleGvfs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    is_gvfs_mounted() {
      ${pkgs.gawk}/bin/awk -v mp="$1" '$2 == mp { found=1; exit } END { exit !found }' /proc/mounts
    }

    if is_gvfs_mounted "$HOME/.gvfs"; then
      for candidate in /run/wrappers/bin/fusermount3 /run/wrappers/bin/fusermount ${pkgs.fuse3}/bin/fusermount3; do
        if [ -x "$candidate" ]; then
          "$candidate" -uz "$HOME/.gvfs" 2>/dev/null || true
          break
        fi
      done
    fi

    if ! is_gvfs_mounted "$HOME/.gvfs"; then
      ${pkgs.coreutils}/bin/rmdir "$HOME/.gvfs" 2>/dev/null || true
    fi
  '';
}
