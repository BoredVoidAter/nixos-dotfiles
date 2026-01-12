# modules/vscode.nix
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode; # Official Microsoft VS Code
    
    # -- Extensions --
    # We mix standard nixpkgs extensions with marketplace downloads
    # to ensure you get the specific Unity ones you need.
    extensions = with pkgs.vscode-extensions; [
      # 1. Theme
      enkia.tokyo-night

      # 2. C# Support
      ms-dotnettools.csharp
      
      # 3. Icons (optional, but makes file tree much faster to scan visually)
      pkgs.vscode-extensions.material-icon-theme
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # 4. Official Unity Extension (Downloads directly from Marketplace)
      {
        name = "vscode-unity";
        publisher = "visualstudioexptteam";
        version = "0.9.4"; # Check marketplace for latest if this breaks, but this is stable
        sha256 = "sha256-HelO4POK7eD0sMd7tQtuXGBa6/PyTj9Jd1PmMl/05bw=";
      }
    ];

    # -- Settings --
    userSettings = {
      # --- Theming (Tokyonight) ---
      "workbench.colorTheme" = "Tokyo Night Storm";
      "workbench.iconTheme" = "material-icon-theme";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 14;

      # --- Minimalism (The "Zen" Mode) ---
      "workbench.activityBar.location" = "hidden";   # Hide big left sidebar
      "workbench.statusBar.visible" = true;          # Keep status bar for C# flame icon
      "editor.minimap.enabled" = false;              # Disable code minimap
      "editor.scrollbar.vertical" = "hidden";        # Hide scrollbars
      "breadcrumbs.enabled" = false;                 # Hide top path bar
      "window.menuBarVisibility" = "toggle";         # Hide top menu (Alt to show)
      "explorer.openEditors.visible" = 0;            # Hide open editors list

      # --- Unity & Performance Optimization ---
      # Crucial: Ignore Unity's massive meta/temp folders to stop VS Code from lagging
      "files.watcherExclude" = {
        "**/.git/objects/**" = true;
        "**/.git/subtree-cache/**" = true;
        "**/node_modules/*/**" = true;
        "**/Library/**" = true;   # Unity Library
        "**/Temp/**" = true;      # Unity Temp
        "**/obj/**" = true;       # C# build objs
      };
      
      # Disable Telemetry for speed
      "telemetry.telemetryLevel" = "off";
      "redhat.telemetry.enabled" = false;
      
      # C# Setup
      "omnisharp.useModernNet" = true;
      "omnisharp.organizeImportsOnFormat" = true;
      # Tell it to use the System Dotnet, not download its own
      "omnisharp.dotnetPath" = "${pkgs.dotnet-sdk_8}/bin/dotnet";
    };
  };

  # Ensure the system has the tools VS Code needs to find
  home.packages = with pkgs; [
    dotnet-sdk_8
    mono
    omnisharp-roslyn
  ];
}
