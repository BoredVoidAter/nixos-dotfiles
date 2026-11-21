{ pkgs, lib, ... }:

let
  version = "2.5.0";

  # Download the release binaries with verified hashes
  pkgripper-exe = pkgs.fetchurl {
    url = "https://github.com/enriquesomolinos/pkgRipper/releases/download/v${version}/PkgRipper.exe";
    sha256 = "sha256-UcMDuZ5zlCXtv/umCGUN4likKYY4BipTRPlZmZyjzvI=";
    name = "PkgRipper.exe";
    executable = true;
  };

  dotnetzip-dll = pkgs.fetchurl {
    url = "https://github.com/enriquesomolinos/pkgRipper/releases/download/v${version}/DotNetZip.dll";
    sha256 = "sha256-jpwDYum/s8Sa9Z4bTTdtPoWxOu0PvD9cDh68mcBzRfM=";
    name = "DotNetZip.dll";
  };

  # Fake PKG Tools (required by pkgRipper) - from https://github.com/CyB1K/PS4-Fake-PKG-Tools-3.87
  gengp4-app = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/gengp4_app.exe";
    sha256 = "sha256-kMTRgTDkOwheeuoZwvgExll9pep8Sq5JaPVN8oH44Gs=";
    name = "gengp4_app.exe";
    executable = true;
  };

  gengp4-patch = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/gengp4_patch.exe";
    sha256 = "sha256-WGmPRZpq8Wnpk4pQW1AfxN/UAHfoenyXUfJW5y7KrD8=";
    name = "gengp4_patch.exe";
    executable = true;
  };

  orbis-pub-cmd = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/orbis-pub-cmd.exe";
    sha256 = "sha256-CQvDN6iFQy8RuIABt/jF6LS3PsmEIyOuCgbweElrr3g=";
    name = "orbis-pub-cmd.exe";
    executable = true;
  };

  orbis-pub-chk = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/orbis-pub-chk.exe";
    sha256 = "sha256-+akdrAz0H9v6W73RqFQqF1ksi/bhMwRZpxib5gijEIM=";
    name = "orbis-pub-chk.exe";
    executable = true;
  };

  orbis-pub-gen = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/orbis-pub-gen.exe";
    sha256 = "sha256-S8VGeSHrw80R0tS480VAi4SCwpWrZF9bZG9pUQQVahw=";
    name = "orbis-pub-gen.exe";
    executable = true;
  };

  orbis-pub-prx = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/orbis-pub-prx.dll";
    sha256 = "sha256-EUl46kKYQvmJPOzWZVI0G4O2Rav7Z7uPk3uBR3bxVCc=";
    name = "orbis-pub-prx.dll";
  };

  orbis-pub-sfo = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/orbis-pub-sfo.exe";
    sha256 = "sha256-QBD2Bw/tGnNxh/EbTVIxGLPOzY06VfcvQx81P3t1nNk=";
    name = "orbis-pub-sfo.exe";
    executable = true;
  };

  orbis-pub-trp = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/CyB1K/PS4-Fake-PKG-Tools-3.87/master/orbis-pub-trp.exe";
    sha256 = "sha256-BmBaGrIdxK5nZGClSzdAz73cncYY34FEkWfdvhrFKhM=";
    name = "orbis-pub-trp.exe";
    executable = true;
  };

  pkgripper-bin = pkgs.runCommand "pkgripper-bin-${version}" {
    preferLocalBuild = true;
  } ''
    mkdir -p $out
    cp ${pkgripper-exe} $out/PkgRipper.exe
    cp ${dotnetzip-dll} $out/DotNetZip.dll
    # Fake PKG Tools (required by pkgRipper per README)
    cp ${gengp4-app} $out/gengp4_app.exe
    cp ${gengp4-patch} $out/gengp4_patch.exe
    cp ${orbis-pub-cmd} $out/orbis-pub-cmd.exe
    cp ${orbis-pub-chk} $out/orbis-pub-chk.exe
    cp ${orbis-pub-gen} $out/orbis-pub-gen.exe
    cp ${orbis-pub-prx} $out/orbis-pub-prx.dll
    cp ${orbis-pub-sfo} $out/orbis-pub-sfo.exe
    cp ${orbis-pub-trp} $out/orbis-pub-trp.exe
    chmod +x $out/*.exe
  '';

in
{
  # Create a Wine-based package for pkgRipper
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "pkgripper" ''
      #!/bin/sh
      export WINEPREFIX="$HOME/.wine-pkgripper"
      export WINEDEBUG=-all
      # Prevent Wine from generating Uninstall / menu .desktop entries
      export WINEDLLOVERRIDES="winemenubuilder.exe=d"
      export PATH="${pkgs.wine}/bin:${pkgs.winetricks}/bin:$PATH"

      # Create wine prefix if it doesn't exist
      if [ ! -d "$WINEPREFIX" ]; then
        echo "Creating Wine prefix for pkgRipper..."
        wineboot -i
        # Install .NET Framework 4.8 which is commonly needed for VB.NET apps
        winetricks -q dotnet48 corefonts 2>/dev/null || true
      fi

      # Set up writable pkgRipper directory in Wine prefix (app needs write access for temp folder)
      PKGRIPPER_DIR="$WINEPREFIX/drive_c/pkgripper"
      if [ ! -d "$PKGRIPPER_DIR" ]; then
        echo "Setting up pkgRipper in Wine prefix..."
        mkdir -p "$PKGRIPPER_DIR"
        cp -r "${pkgripper-bin}"/* "$PKGRIPPER_DIR"/
      fi

      # Run pkgRipper from writable directory
      cd "$PKGRIPPER_DIR"
      exec wine PkgRipper.exe "$@"
    '')
  ];
}
