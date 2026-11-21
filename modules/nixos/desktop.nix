{ pkgs, config, ... }:

let
  powerSupplyPerms = pkgs.writeShellScript "power-supply-perms" ''
    for f in \
      /sys/class/power_supply/BAT*/charge_control_start_threshold \
      /sys/class/power_supply/BAT*/charge_control_end_threshold \
      /sys/class/power_supply/BAT*/charge_behaviour \
      /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
    do
      if [ -e "$f" ]; then
        ${pkgs.coreutils}/bin/chgrp wheel "$f"
        ${pkgs.coreutils}/bin/chmod 664 "$f"
      fi
    done
  '';

  cleanupGvfsMounts = pkgs.writeShellScript "cleanup-gvfs-mounts" ''
    FUSERMOUNT=""
    for candidate in /run/wrappers/bin/fusermount3 /run/wrappers/bin/fusermount ${pkgs.fuse3}/bin/fusermount3; do
      if [ -x "$candidate" ]; then
        FUSERMOUNT="$candidate"
        break
      fi
    done

    is_mounted() {
      ${pkgs.gawk}/bin/awk -v mp="$1" '$2 == mp { found=1; exit } END { exit !found }' /proc/mounts
    }

    unmount_mp() {
      local mp="$1"
      if is_mounted "$mp" && [ -n "$FUSERMOUNT" ]; then
        "$FUSERMOUNT" -uz "$mp" 2>/dev/null || true
      fi
    }

    # Always remove legacy ~/.gvfs fallback mounts so Thunar never hits ENOTCONN in $HOME
    unmount_mp "$HOME/.gvfs"
    if ! is_mounted "$HOME/.gvfs"; then
      ${pkgs.coreutils}/bin/rmdir "$HOME/.gvfs" 2>/dev/null || true
    fi

    # Unmount disconnected $XDG_RUNTIME_DIR/gvfs so gvfsd-fuse does not fall back to ~/.gvfs
    RUNTIME_GVFS="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/gvfs"
    if is_mounted "$RUNTIME_GVFS"; then
      if ! ${pkgs.coreutils}/bin/stat "$RUNTIME_GVFS" >/dev/null 2>&1; then
        unmount_mp "$RUNTIME_GVFS"
      fi
    fi
  '';
in
{
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";
  };

  services.displayManager.regreet = {
    enable = true;
    cageArgs = [ "-s" "-m" "last" ];
    theme = {
      name = "Matcha-dark-aliz";
      package = pkgs.matcha-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
      size = 12;
    };
    settings = {
      background = {
        path = "/var/lib/wallpaper/current";
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
      };
      appearance = {
        greeting_msg = "Welcome back";
      };
    };
    extraCss = ''
      window {
        background-color: #0d0e11;
        color: #e6e6ea;
        font-family: "JetBrainsMono Nerd Font";
      }

      frame {
        background-color: rgba(19, 20, 24, 0.88);
        border: 1px solid #27282f;
        border-radius: 12px;
        padding: 16px;
      }

      label {
        color: #e6e6ea;
      }

      entry {
        background-color: #0d0e11;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 8px;
        padding: 8px 12px;
        caret-color: #4c50bc;
      }

      entry:focus {
        border-color: #4c50bc;
        box-shadow: 0 0 0 1px #4c50bc;
      }

      selection {
        background-color: #4c50bc;
        color: #ffffff;
      }

      button {
        background-color: #18191e;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 8px;
        padding: 6px 14px;
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

      button.destructive-action {
        color: #e05555;
      }

      popover contents,
      popover > contents {
        background-color: #131418;
        color: #e6e6ea;
        border: 1px solid #27282f;
        border-radius: 10px;
      }
    '';
  };

  # World-readable directory so greeter can read the active wallpaper synced by waypaper
  systemd.tmpfiles.rules = [
    "d /var/lib/wallpaper 0755 ${config.users.users.boredvoidater.name} ${config.users.users.boredvoidater.group} - -"
  ];

  # Force-install uBlock Origin Lite and Vimium C across all Chrome/Chromium webapp profiles
  environment.etc."opt/chrome/policies/managed/extensions.json".text = builtins.toJSON {
    ExtensionInstallForcelist = [
      "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx"
      "hfjbmagddngcpeloejdejnfgbamkjaeg;https://clients2.google.com/service/update2/crx"
    ];
  };

  environment.etc."chromium/policies/managed/extensions.json".text = builtins.toJSON {
    ExtensionInstallForcelist = [
      "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx"
      "hfjbmagddngcpeloejdejnfgbamkjaeg;https://clients2.google.com/service/update2/crx"
    ];
  };

  programs.hyprland.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  services.libinput.enable = true;
  services.joycond.enable = true;

  environment.variables = {
    XKB_DEFAULT_LAYOUT = "de";
  };

  services.udev.extraHwdb = ''
    evdev:input:*
     KEYBOARD_KEY_delay=200
  '';

  # Allow wheel users to toggle battery charge thresholds/bypass for Wall-Plugged mode
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ACTION=="add|change", RUN+="${powerSupplyPerms}"
  '';

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };

  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;

  systemd.user.services.gvfs-cleanup = {
    description = "Clean up stale GVfs FUSE mountpoints";
    wantedBy = [ "default.target" ];
    before = [ "gvfs-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = cleanupGvfsMounts;
    };
  };

  systemd.user.services.gvfs-daemon = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      ExecStartPre = "-${cleanupGvfsMounts}";
      ExecStopPost = "-${cleanupGvfsMounts}";
    };
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [

    file-roller alacritty qt5.qtgraphicaleffects system-config-printer
    (writeShellScriptBin "polkit-gnome-agent" ''
      exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
    '')
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  };

  security.polkit.enable = true;
}
