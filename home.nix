{ config, pkgs, lib, ... }:
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
    userName = "Boredvoidater";             # e.g. "John Doe"
    userEmail = "boredvoidater@proton.me";    # e.g. "john@example.com"
    
    # This setup allows 'git push' to use the login details you just saved with 'gh'
    extraConfig = {
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw";
      n = "nvim";
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

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium; # The de-Microsofted version
    
    # Install extensions declaratively
    extensions = with pkgs.vscode-extensions; [
      enkia.tokyo-night         # The Tokyonight theme
      ms-dotnettools.csharp     # C# support (Patched for NixOS)
      # Note: Install the 'Unity' extension manually via the IDE sidebar
      # as it is not always available in the standard nixpkgs list.
    ];

    # Enforce your Minimal + Tokyonight look
    userSettings = {
      # --- Theming ---
      "workbench.colorTheme" = "Tokyo Night Storm"; # Matches your Neovim
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 14;

      # --- Minimalism (Hide everything) ---
      "workbench.activityBar.location" = "hidden";   # Hides the big left sidebar icons
      "editor.minimap.enabled" = false;              # Hides the code preview on right
      "editor.scrollbar.vertical" = "hidden";        # Hides scrollbar (optional)
      "window.menuBarVisibility" = "toggle";         # Hides top menu (Alt to show)
      "breadcrumbs.enabled" = false;                 # Hides path at top of file
      "workbench.sideBar.location" = "left";
      "explorer.openEditors.visible" = 0;            # Hides 'Open Editors' in file tree
      
      # --- NixOS C# Specifics ---
      # Stop the extension from trying to download its own Mono/Dotnet
      "omnisharp.useGlobalMono" = "always";
      "omnisharp.waitForDebugger" = true;
    };
  };

  home.packages = with pkgs; [
    rofi
    # Thunar removed here; it is enabled in configuration.nix
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
    
    # REQUIRED for apps to load settings
    gsettings-desktop-schemas
    pamixer
    xfce.xfconf
    repomix
    bluetuith
    polkit_gnome
    google-chrome
    pavucontrol

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
