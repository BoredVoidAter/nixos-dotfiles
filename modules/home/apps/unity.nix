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

      libx11
      libxcursor
      libxrandr
      libxi
      libxext
      libxfixes
      libxrender
      libxcb
      libxinerama
      libxxf86vm

      udev
      alsa-lib

      stdenv.cc.cc.lib

      git
      git-lfs
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

  steam-test-run = pkgs.writeShellScriptBin "steam-test-run" ''
    TARGET="$1"
    if [ -z "$TARGET" ]; then
      echo "Usage: steam-test-run <path-to-unity-build.x86_64> [args...]"
      exit 1
    fi
    shift
    TARGET_ABS=$(realpath "$TARGET")
    TARGET_DIR=$(dirname "$TARGET_ABS")
    exec flatpak run --filesystem=host --command=bash com.valvesoftware.Steam -c "cd \"$TARGET_DIR\" && exec \"$TARGET_ABS\" \"\$@\"" -- "$@"
  '';

  my-unityhub = pkgs.unityhub.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/unityhub \
        --prefix PATH : "${lib.makeBinPath [ pkgs.ffmpeg pkgs.android-tools pkgs.p7zip pkgs.git pkgs.git-lfs ]}"
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
    git-lfs

    unity-neovim-wrapper
    steam-test-run
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${my-dotnet}";
    UNITY_IGNORE_DKG = "1";
  };
}
