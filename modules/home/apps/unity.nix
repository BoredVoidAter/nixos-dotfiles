{ pkgs, lib, ... }:

let

  my-dotnet = with pkgs.dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ];

  unity-fhs = pkgs.buildFHSEnv {
    name = "unity-fhs";

    targetPkgs = pkgs: with pkgs; [
      gtk3
      glib
      atk
      cairo
      pango
      harfbuzz
      gdk-pixbuf
      fontconfig
      libGL
      libGLU
      zlib
      libxml2
      icu
      openssl

      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libXext
      xorg.libXfixes
      xorg.libXrender
      xorg.libxcb
      xorg.libXinerama
      xorg.libXxf86vm

      udev
      alsa-lib

      stdenv.cc.cc.lib
    ];

    runScript = "bash";
  };


  unity-neovim-wrapper = pkgs.writeShellScriptBin "code" ''
    PROJECT_PATH="$1"
    
    
    if [ "$2" = "-g" ]; then
      FILE_ARG=$3
      FILE_PATH=$(echo "$FILE_ARG" | cut -d':' -f1)
      LINE=$(echo "$FILE_ARG" | cut -d':' -f2)
      exec ${pkgs.alacritty}/bin/alacritty --working-directory "$PROJECT_PATH" -e nvim "+$LINE" "$FILE_PATH"
    else
      exec ${pkgs.alacritty}/bin/alacritty --working-directory "$PROJECT_PATH" -e nvim .
    fi
  '';


  my-unityhub = pkgs.unityhub.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/unityhub \
        --prefix PATH : "${lib.makeBinPath[ pkgs.ffmpeg pkgs.android-tools pkgs.p7zip ]}"
    '';
  });
in
{
  home.packages = with pkgs;[
    my-unityhub
    unity-fhs
    my-dotnet
    mono
    netcoredbg
    ffmpeg
    android-tools
    p7zip

    unity-neovim-wrapper
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${my-dotnet}";
    UNITY_IGNORE_DKG = "1";
  };
}
