# modules/vscode.nix
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode; 

    # New Home Manager syntax uses 'profiles.default'
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      
      extensions = with pkgs.vscode-extensions; [
        # 1. Theme
        enkia.tokyo-night

        # 2. C# Support (Official)
        ms-dotnettools.csharp
        
        # 3. Icons
        pkief.material-icon-theme
        
        # Note: We removed the declarative Unity extension download because 
        # Microsoft/Unity constantly changes the URL, breaking your Nix build.
        # Please install the "Unity" extension manually in the sidebar once.
      ];

      userSettings = {
        # --- Theming ---
        "workbench.colorTheme" = "Tokyo Night Storm";
        "workbench.iconTheme" = "material-icon-theme";
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 14;

        # --- Minimalism ---
        "workbench.activityBar.location" = "hidden";
        "workbench.statusBar.visible" = true;
        "editor.minimap.enabled" = false;
        "editor.scrollbar.vertical" = "hidden";
        "breadcrumbs.enabled" = false;
        "window.menuBarVisibility" = "toggle";
        "explorer.openEditors.visible" = 0;

        # --- Performance & Unity ---
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/*/**" = true;
          "**/Library/**" = true;
          "**/Temp/**" = true;
          "**/obj/**" = true;
        };
        
        "telemetry.telemetryLevel" = "off";
        "redhat.telemetry.enabled" = false;
        
        # --- C# Configuration ---
        "omnisharp.useModernNet" = true;
        "omnisharp.organizeImportsOnFormat" = true;
        "omnisharp.dotnetPath" = "${pkgs.dotnet-sdk_8}/bin/dotnet";
      };
    };
  };

  # System tools needed for C#
  home.packages = with pkgs; [
    dotnet-sdk_8
    mono
    omnisharp-roslyn
  ];
}
