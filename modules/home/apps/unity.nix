{ pkgs, lib, ... }:

let
  # 1. Fake VS Code executable to trick Unity
  # Unity sends arguments formatted like: "project/path" -g "file/path.cs:line:column"
  # This wrapper extracts the file and line number, then opens it in Neovim via Alacritty!
  unity-neovim-wrapper = pkgs.writeShellScriptBin "code" ''
    # If Unity passes the -g argument (meaning it wants to open a specific file)
    if [ "$2" = "-g" ]; then
      # Extract file path and line number from "filepath:line:column"
      FILE_ARG=$3
      FILE_PATH=$(echo "$FILE_ARG" | cut -d':' -f1)
      LINE=$(echo "$FILE_ARG" | cut -d':' -f2)
      
      # Launch Neovim in a new Alacritty window directly at the correct line
      exec ${pkgs.alacritty}/bin/alacritty -e nvim "+$LINE" "$FILE_PATH"
    else
      # Fallback: Just open Alacritty in the project folder
      exec ${pkgs.alacritty}/bin/alacritty -e nvim "$1"
    fi
  '';

  # 2. Custom Unity Hub wrapper to ensure tools are visible
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
    
    # Add our fake VS Code wrapper
    unity-neovim-wrapper # will be at /etc/profiles/per-user/boredvoidater/bin/code hmhmhm im so smart
  ];

  # Force Unity/Dotnet to respect your Wayland/Dark theme preferences
  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
    UNITY_IGNORE_DKG = "1";
  };
}
