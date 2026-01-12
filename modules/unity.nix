# modules/unity.nix
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
  # This script wraps Rider to include necessary PATHs and rearranges 
  # the file structure so the Unity plugin can find the binary.
  rider = pkgs.jetbrains.rider.overrideAttrs (attrs: {
    postInstall = ''
      # Wrap rider with extra tools and libraries
      mv $out/bin/rider $out/bin/.rider-toolless
      makeWrapper $out/bin/.rider-toolless $out/bin/rider \
        --argv0 rider \
        --prefix PATH : "${lib.makeBinPath extra-path}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath extra-lib}"

      # Making Unity Rider plugin work!
      # The plugin expects the binary to be at /rider/bin/rider,
      # with bundled files at /rider/
      # It does this by going up two directories from the binary path.
      # Our rider binary is at $out/bin/rider, so we need to link $out/rider/ to $out/
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
    
    # We add our custom 'rider' here instead of the standard jetbrains.rider
    rider
  ];

  # 4. Create the .desktop file Unity looks for
  # Unity looks for "jetbrains-rider.desktop" in ~/.local/share/applications
  # to determine where the executable is.
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
    
    # Workaround for some Unity graphical glitches on Wayland
    UNITY_IGNORE_DKG = "1";
  };
}
