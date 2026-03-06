{ pkgs, lib, ... }:

let
  # Merge .NET 8 (for Unity) and .NET 9 (for csharp-ls)
  my-dotnet = with pkgs.dotnetCorePackages; combinePackages[ sdk_8_0 sdk_9_0 ];

  # Fake VS Code wrapper
  unity-neovim-wrapper = pkgs.writeShellScriptBin "code" ''
    PROJECT_PATH="$1"
    if[ "$2" = "-g" ]; then
      FILE_ARG=$3
      FILE_PATH=$(echo "$FILE_ARG" | cut -d':' -f1)
      LINE=$(echo "$FILE_ARG" | cut -d':' -f2)
      exec ${pkgs.alacritty}/bin/alacritty --working-directory "$PROJECT_PATH" -e nvim "+$LINE" "$FILE_PATH"
    else
      exec ${pkgs.alacritty}/bin/alacritty --working-directory "$PROJECT_PATH" -e nvim .
    fi
  '';

  # Custom Unity Hub wrapper
  my-unityhub = pkgs.unityhub.overrideAttrs (old: {
    buildInputs = (old.buildInputs or[]) ++[ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/unityhub \
        --prefix PATH : "${lib.makeBinPath[ pkgs.ffmpeg pkgs.android-tools pkgs.p7zip ]}"
    '';
  });
in
{
  home.packages = with pkgs;[
    my-unityhub
    my-dotnet      # <-- Our combined .NET SDK!
    mono
    netcoredbg
    ffmpeg        
    android-tools 
    p7zip         
    
    unity-neovim-wrapper
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${my-dotnet}"; # Points both Unity and csharp-ls to the merged SDKs
    UNITY_IGNORE_DKG = "1";
  };
}
