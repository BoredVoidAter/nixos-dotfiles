# modules/vscode.nix
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode; 

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      
      extensions = with pkgs.vscode-extensions; [
        enkia.tokyo-night          # Theme
        ms-dotnettools.csharp      # C# (Base support)
        pkief.material-icon-theme  # Icons
        # Remember: Install "Unity" extension manually in VS Code sidebar
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

        # --- Performance ---
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
        
        # --- C# & Unity Fixes (The Important Part) ---
        
        # 1. Force the use of the classic OmniSharp server (Stable on Nix)
        "dotnet.server.useOmnisharp" = true;
        
        # 2. Point explicitly to the NixOS-installed OmniSharp binary
        "omnisharp.path" = "${pkgs.omnisharp-roslyn}/bin/OmniSharp";
        
        # 3. Disable the extension's attempt to download/manage dotnet itself
        "omnisharp.useGlobalMono" = "always";
        "omnisharp.waitForDebugger" = true;
        "omnisharp.enableRoslynAnalyzers" = true;
        
        # 4. Remove 'omnisharp.dotnetPath' and 'omnisharp.useModernNet' 
        #    as these cause the "Save settings.json" loop.
      };
    };
  };

  # Ensure the environment has the tools
  home.packages = with pkgs; [
    dotnet-sdk_8
    mono
    omnisharp-roslyn
  ];
}
