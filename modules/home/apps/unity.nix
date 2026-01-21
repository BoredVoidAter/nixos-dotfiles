{ pkgs, lib, ... }:

let
  # 1. Setup Rider
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

  # 2. CUSTOM UNITY BUILDER ENV
  # Replaced buildFHSUserEnv with buildFHSEnv to fix the "missing attribute" error.
  unity-env = pkgs.buildFHSEnv {
    name = "unity-run";
    targetPkgs = pkgs: (with pkgs; [
      # Core System
      glibc
      zlib
      glib
      libxml2
      libuuid
      
      # Graphics & UI
      gtk3
      gdk-pixbuf
      cairo
      pango
      freetype
      fontconfig
      libglvnd
      mesa
      
      # X11 Windowing
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXrender
      xorg.libXi
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXfixes
      xorg.libXtst
      xorg.libXext
      xorg.libXScrnSaver
      
      # Audio
      alsa-lib
      
      # Unity Internal Dependencies
      nss
      nspr
      libcap
      cups
      dbus
      expat
      libsecret
      openssl
      udev
      
      # Command Line Tools
      ffmpeg
      android-tools
    ]);
    # Using 'exec' ensures the exit code is passed back correctly
    runScript = "bash -c 'exec \"$@\"' --";
  };

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
    
    # The custom environment
    unity-env
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
