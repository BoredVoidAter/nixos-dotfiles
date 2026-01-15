{ config, pkgs, pkgs-stable, lib, ... }:
let
    dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
    create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
    configs = {
        qtile = "qtile";
        # rofi is handled via symlink
        rofi = "rofi";
        nvim = "nvim";
    };
in
{
  imports = [
    ./modules/theme.nix
    ./modules/neovim.nix
    ./modules/firefox.nix
    ./modules/anki.nix
    ./modules/unity.nix
  ];

  home.username = "boredvoidater";
  home.homeDirectory = "/home/boredvoidater";
  home.stateVersion = "25.05";

  programs.git = {
    enable = true;
    userName = "Boredvoidater";             
    userEmail = "boredvoidater@proton.me";    
    
    extraConfig = {
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw";
      n = "nvim";
      # Since we installed Unity via Nix, we can usually just run unityhub
      unity = "nvidia-offload unityhub";         
    };
  };

  # Symlink dotfiles (Qtile, Rofi)
  xdg.configFile = builtins.mapAttrs (name: subpath: {
        source = create_symlink "${dotfiles}/${subpath}";
        recursive = true;
    }) configs;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };
  
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };

  home.packages = with pkgs; [
    rofi
    xfce.tumbler
    obsidian
    brightnessctl
    wireplumber
    lxappearance
    prismlauncher
    jdk17
    localsend
    mpv
    keepassxc
    gh

    gtk-engine-murrine
    gnome-themes-extra
    
    gsettings-desktop-schemas
    pamixer
    xfce.xfconf
    repomix
    bluetuith
    polkit_gnome
    google-chrome
    pavucontrol

    # Unity/Rider/Dotnet packages have been moved to modules/unity.nix
    # to avoid duplication and apply the Rider fix.
    omnisharp-roslyn
    netcoredbg

    xsel   # Required by Repomix's clipboard library
    xclip  # General clipboard tool for X11
    gimp
    inkscape
    pkgs-stable.aseprite
  ];

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
    };
  };
}
