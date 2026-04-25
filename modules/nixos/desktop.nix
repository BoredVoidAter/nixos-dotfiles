{ pkgs, config, ... }:

{
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";

    windowManager.qtile.enable = true;
  };

  # tuigreet via greetd — replaces LightDM
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --remember-user-session \
            --user-menu \
            --sessions ${config.services.xserver.displayManager.sessionData.desktops}/share/xsessions:${config.services.xserver.displayManager.sessionData.desktops}/share/wayland-sessions
        '';
        user = "greeter";
      };
    };
  };

  # Carry over keyboard repeat rate to Wayland via libinput / udev
  services.libinput.enable = true;

  # Keyboard repeat rate for Wayland (set via systemd/environment for compositors that respect it)
  environment.variables = {
    # XKB layout for Wayland sessions
    XKB_DEFAULT_LAYOUT = "de";
  };

  # Key repeat for Wayland via udev hwdb
  services.udev.extraHwdb = ''
    evdev:input:*
     KEYBOARD_KEY_delay=200
  '';

  virtualisation.waydroid.enable = true;
  systemd.services.waydroid-container.wantedBy = [ "multi-user.target" ];
  security.apparmor.enable = true;


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
  programs.firefox.enable = true;

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
    alacritty
    libsForQt5.qt5.qtgraphicaleffects
    system-config-printer
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config = {
      common.default = [ "gtk" ];
      qtile.default = [ "gtk" ]; # <-- Explicitly tell the portal what to use in Qtile
    };
  };

  security.polkit.enable = true;
}
