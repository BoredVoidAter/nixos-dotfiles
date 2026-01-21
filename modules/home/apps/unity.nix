{ pkgs, lib, ... }:

let
  # 1. Rider dependencies
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
  # This creates a "fake" FHS filesystem (like Ubuntu) containing exactly what Unity needs.
  # This bypasses the Steam Runtime entirely, fixing the libxml2 issue.
  unity-env = pkgs.buildFHSUserEnv {
    name = "unity-run";
    targetPkgs = pkgs: (with pkgs; [
      # The Core Libraries Unity 6 needs
      glibc
      glib
      gtk3
      libxml2
      zlib
      gdk-pixbuf
      cairo
      pango
      freetype
      fontconfig
      
      # X11 / Windowing
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
      libglvnd
      alsa-lib
      
      # System / Networking / Licensing
      nss
      nspr
      libcap
      cups
      dbus
      expat
      libsecret # Important for Hub/Licensing
      openssl
      udev
      
      # Command Line Tools
      ffmpeg
      android-tools
    ]);
    # This runScript makes the FHS env execute whatever command you pass to it
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
    
    # Use our custom dedicated environment
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
