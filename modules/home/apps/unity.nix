{ pkgs, lib, ... }:

let
  extra-path = with pkgs; [
    dotnet-sdk_8
    mono
    msbuild
  ];

  extra-lib = with pkgs; [ ];

  rider = pkgs.jetbrains.rider.overrideAttrs (attrs: {
    postInstall = ''
      mv $out/bin/rider $out/bin/.rider-toolless
      makeWrapper $out/bin/.rider-toolless $out/bin/rider \
        --argv0 rider \
        --prefix PATH : "${lib.makeBinPath extra-path}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath extra-lib}"
      shopt -s extglob
      ln -s $out/rider/!(bin) $out/
      shopt -u extglob
    '' + (attrs.postInstall or "");
  });

  my-unityhub = pkgs.unityhub.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/unityhub \
        --prefix PATH : "${lib.makeBinPath [ pkgs.ffmpeg pkgs.android-tools pkgs.p7zip rider ]}"
    '';
  });

  # --- CUSTOM UNITY RUNNER ---
  # We override steam-run to include libxml2 and other common Unity dependencies
  custom-steam-run = (pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      libxml2
      libz
      freetype
      gtk3
      glib
      nss
      nspr
      # Add more here if you hit other "missing shared library" errors
    ];
  }).run;

  # Create a unique binary name 'unity-run' to avoid conflicts with system steam-run
  unity-run = pkgs.runCommand "unity-run" {} ''
    mkdir -p $out/bin
    ln -s ${custom-steam-run}/bin/steam-run $out/bin/unity-run
  '';

in
{
  home.packages = with pkgs; [
    my-unityhub
    dotnet-sdk_8
    mono
    omnisharp-roslyn
    netcoredbg
    ffmpeg
    android-tools
    p7zip
    rider
    butler
    
    # Use our custom runner instead of generic steam-run
    unity-run
  ];

  xdg.dataFile."applications/jetbrains-rider.desktop".text = ''
    [Desktop Entry]
    Name=JetBrains Rider
    Exec=${rider}/bin/rider
    Icon=rider
    Type=Application
    Categories=Development;IDE;
    NoDisplay=true
  '';

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
    UNITY_IGNORE_DKG = "1";
  };
}
