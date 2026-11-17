{ pkgs, config, ... }:

{
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    xkb.layout = "de";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # This automatically launches Hyprland after you type your password!
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --theme 'border=gray;text=white;prompt=gray;time=gray;action=white;button=gray;container=black;input=white' --cmd start-hyprland";
        user = "greeter";
      };
    };
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
