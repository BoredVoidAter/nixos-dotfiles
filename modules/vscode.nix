# modules/vscode.nix
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode; 
    
    extensions = with pkgs.vscode-extensions; [
      # 1. Theme
      enkia.tokyo-night

      # 2. C# Support
      ms-dotnettools.csharp
      
      # 3. Icons (Corrected Path)
      pkief.material-icon-theme
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # 4. Official Unity Extension
      {
        name = "vscode-unity";
        publisher = "visualstudioexptteam";
        version = "0.9.4";
        sha256 = "sha256-HelO4POK7eD0sMd7tQtuXGBa6/PyTj9Jd1PmMl/05bw=";
      }
    ];

    userSettings = {
      "workbench.colorTheme" = "Tokyo Night Storm";
      "workbench.iconTheme" = "material-icon-theme";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 14;

      "workbench.activityBar.location" = "hidden";
      "workbench.statusBar.visible" = true;
      "editor.minimap.enabled" = false;
      "editor.scrollbar.vertical" = "hidden";
      "breadcrumbs.enabled" = false;
      "window.menuBarVisibility" = "toggle";
      "explorer.openEditors.visible" = 0;

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
      
      "omnisharp.useModernNet" = true;
      "omnisharp.organizeImportsOnFormat" = true;
      "omnisharp.dotnetPath" = "${pkgs.dotnet-sdk_8}/bin/dotnet";
    };
  };

  home.packages = with pkgs; [
    dotnet-sdk_8
    mono
    omnisharp-roslyn
  ];
}
