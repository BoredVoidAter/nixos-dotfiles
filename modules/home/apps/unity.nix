{ pkgs, lib, ... }:

let
  # Custom Unity Hub wrapper to ensure tools are visible
  my-unityhub = pkgs.unityhub.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.makeWrapper ];
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
    butler
  ];

  # Force Unity/Dotnet to respect your Wayland/Dark theme preferences
  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
    UNITY_IGNORE_DKG = "1";
  };
}
