{ pkgs, lib, ... }:

let
  # 1. Define the dependencies Rider needs to see in its PATH
  extra-path = with pkgs; [
    dotnet-sdk_8
    mono
    msbuild
    # Add any other tools you might need here
  ];

  # 2. Define libraries (usually empty for modern Rider, but kept for compatibility)
  extra-lib = with pkgs; [
  ];

  # 3. Create the Custom Rider Package
  rider = pkgs.jetbrains.rider.overrideAttrs (attrs: {
    postInstall = ''
      # Wrap rider with extra tools and libraries
      mv $out/bin/rider $out/bin/.rider-toolless
      makeWrapper $out/bin/.rider-toolless $out/bin/rider \
        --argv0 rider \
        --prefix PATH : "${lib.makeBinPath extra-path}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath extra-lib}"

      # Making Unity Rider plugin work!
      shopt -s extglob
      ln -s $out/rider/!(bin) $out/
      shopt -u extglob
    '' + (attrs.postInstall or "");
  });
in
{
  home.packages = with pkgs; [
    unityhub
    dotnet-sdk_8
    mono
    omnisharp-roslyn
    netcoredbg
    
    rider
  ];

  # 4. Create the .desktop file Unity looks for
  xdg.dataFile."applications/jetbrains-rider.desktop".text = ''
    [Desktop Entry]
    Name=JetBrains Rider
    Exec=${rider}/bin/rider
    Icon=rider
    Type=Application
    Categories=Development;IDE;
    NoDisplay=true
  '';

  # Force Unity/Dotnet to respect your Wayland/Dark theme preferences
  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
    UNITY_IGNORE_DKG = "1";
  };
}