{ pkgs, config, ... }:

{
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";
  };

  programs.regreet = {
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

  environment.variables = {
    XKB_DEFAULT_LAYOUT = "de";
  };

  services.udev.extraHwdb = ''
    evdev:input:*
     KEYBOARD_KEY_delay=200
  '';

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };

  services.tumbler.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;

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
