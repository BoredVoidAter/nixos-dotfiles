{ pkgs, lib, ... }:

let
  # 1. Fake VS Code executable to trick Unity
  unity-neovim-wrapper = pkgs.writeShellScriptBin "code" ''
    # Unity passes: "ProjectPath" -g "FilePath:Line:Column"
    PROJECT_PATH="$1"
    
    if [ "$2" = "-g" ]; then
      FILE_ARG=$3
      FILE_PATH=$(echo "$FILE_ARG" | cut -d':' -f1)
      LINE=$(echo "$FILE_ARG" | cut -d':' -f2)
      
      # Launch Alacritty locked to the Project Directory
      exec ${pkgs.alacritty}/bin/alacritty --working-directory "$PROJECT_PATH" -e nvim "+$LINE" "$FILE_PATH"
    else
      # Fallback: Just open Alacritty in the project folder
      exec ${pkgs.alacritty}/bin/alacritty --working-directory "$PROJECT_PATH" -e nvim .
    fi
  '';

  # 2. Custom Unity Hub wrapper
  my-unityhub = pkgs.unityhub.overrideAttrs (old: {
    buildInputs = (old.buildInputs or[]) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/unityhub \
        --prefix PATH : "${lib.makeBinPath[ pkgs.ffmpeg pkgs.android-tools pkgs.p7zip ]}"
    '';
  });
in
{
  home.packages = with pkgs;[
    my-unityhub
    dotnet-sdk_8
    mono
    omnisharp-roslyn
    netcoredbg
    ffmpeg        
    android-tools 
    p7zip         
    
    unity-neovim-wrapper
  ];

  home.sessionVariables = {
    # REMOVED: DOTNET_ROOT = "''${pkgs.dotnet-sdk_8}"; 
    # (Setting this globally breaks csharp-ls which requires newer .NET runtimes)
    UNITY_IGNORE_DKG = "1";
  };
}
