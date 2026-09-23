{ pkgs, lib, config, ... }:

let
  codex-fhs = pkgs.buildFHSEnv {
    name = "codex-desktop";
    targetPkgs = pkgs: with pkgs; [
      dpkg
      gtk3
      glib
      nss
      nspr
      atk
      at-spi2-atk
      at-spi2-core
      dbus
      cups
      libdrm
      libgbm
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxkbfile
      mesa
      alsa-lib
      systemd
      libxshmfence
      libGL
      libGLU
      pango
      cairo
      gdk-pixbuf
      expat
      libxkbcommon
      libxscrnsaver
      libxtst
      libxcursor
      libxi
      libxrender
      fontconfig
      freetype
      libsecret
      libnotify
      vulkan-loader
      wayland
      zlib
      stdenv.cc.cc.lib
      udev
      bubblewrap
    ];

    extraBuildCommands = ''
      mkdir -p lib64 usr/lib64
      ln -s -f ../usr/lib/* lib64/ 2>/dev/null || true
      ln -s -f ../usr/lib/* usr/lib64/ 2>/dev/null || true
    '';

    runScript = pkgs.writeShellScript "codex-runner" ''
      APP_DIR="$HOME/.local/share/codex-desktop"
      export CODEX_ELECTRON_SKIP_SHELL_ENV=1
      export LD_LIBRARY_PATH="/usr/lib:/usr/lib64:/lib:/lib64:/run/opengl-driver/lib:/run/opengl-driver-32/lib:$APP_DIR/usr/lib/chatgpt:$APP_DIR/opt/ChatGPT:$APP_DIR''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export NIX_LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${NIX_LD_LIBRARY_PATH:+:$NIX_LD_LIBRARY_PATH}"

      BIN=""
      for candidate in \
        "$APP_DIR/usr/lib/chatgpt/ChatGPT" \
        "$APP_DIR/usr/bin/chatgpt" \
        "$APP_DIR/opt/ChatGPT/chatgpt" \
        "$APP_DIR/opt/Codex/codex" \
        "$APP_DIR/codex" \
        "$APP_DIR/usr/bin/codex" \
        "$APP_DIR/usr/lib/codex/codex"; do
        if [ -f "$candidate" ]; then
          chmod +x "$candidate" 2>/dev/null || true
          BIN="$candidate"
          break
        fi
      done

      if [ -n "$BIN" ]; then
        exec "$BIN" "$@"
      else
        DEB=$(ls -t "$HOME/Downloads/"*[Cc]odex*.deb "$HOME/Downloads/"*[Cc]hat[Gg]pt*.deb "$HOME/Downloads/chatgpt_amd64.deb" 2>/dev/null | head -n 1)
        if [ -n "$DEB" ] && [ -f "$DEB" ]; then
          echo "Found Debian package: $DEB"
          echo "Extracting to $APP_DIR..."
          mkdir -p "$APP_DIR"
          dpkg-deb -x "$DEB" "$APP_DIR"
          for candidate in \
            "$APP_DIR/usr/lib/chatgpt/ChatGPT" \
            "$APP_DIR/usr/bin/chatgpt" \
            "$APP_DIR/opt/ChatGPT/chatgpt" \
            "$APP_DIR/opt/Codex/codex" \
            "$APP_DIR/codex" \
            "$APP_DIR/usr/bin/codex" \
            "$APP_DIR/usr/lib/codex/codex"; do
            if [ -f "$candidate" ]; then
              chmod +x "$candidate" 2>/dev/null || true
              exec "$candidate" "$@"
            fi
          done
        else
          echo "Codex desktop app is not installed yet."
          echo "Download the .deb from https://openai.com/de-DE/codex/ into ~/Downloads"
          echo "and run: codex-install <path-to-deb>"
          exit 1
        fi
      fi
    '';
  };

  codex-installer = pkgs.writeShellScriptBin "codex-install" ''
    DEB="$1"
    if [ -z "$DEB" ]; then
      DEB=$(ls -t "$HOME/Downloads/"*[Cc]odex*.deb "$HOME/Downloads/"*[Cc]hat[Gg]pt*.deb "$HOME/Downloads/chatgpt_amd64.deb" 2>/dev/null | head -n 1)
    fi

    if [ -z "$DEB" ] || [ ! -f "$DEB" ]; then
      echo "Usage: codex-install <path-to-deb-file>"
      echo "Or download the .deb file from https://openai.com/de-DE/codex/ into ~/Downloads"
      exit 1
    fi

    APP_DIR="$HOME/.local/share/codex-desktop"
    echo "Installing $DEB into $APP_DIR..."
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR"
    ${pkgs.dpkg}/bin/dpkg-deb -x "$DEB" "$APP_DIR"

    mkdir -p "$HOME/.local/share/pixmaps"

    ICON=""
    for candidate in \
      "$APP_DIR/.codex-linux/codex-desktop.png" \
      $(find "$APP_DIR" -path "*/icons/hicolor/512x512/apps/*.png" 2>/dev/null) \
      $(find "$APP_DIR" -path "*/icons/hicolor/256x256/apps/*.png" 2>/dev/null) \
      $(find "$APP_DIR" -name "*codex-app*-logo*.png" 2>/dev/null) \
      $(find "$APP_DIR" -name "*chatgpt*.png" 2>/dev/null) \
      $(find "$APP_DIR" -name "*openai*.png" 2>/dev/null); do
      if [ -f "$candidate" ]; then
        ICON="$candidate"
        break
      fi
    done

    if [ -n "$ICON" ]; then
      cp -f "$ICON" "$HOME/.local/share/pixmaps/codex.png" 2>/dev/null || true
      echo "Installed icon from $ICON"
    fi

    echo "Installation complete. You can now launch Codex from Vicinae or run 'codex-desktop'."
  '';
in
{
  home.packages = [
    codex-fhs
    codex-installer
    pkgs.bubblewrap
  ];

  xdg.desktopEntries.codex = {
    name = "Codex";
    genericName = "AI Coding Assistant";
    comment = "OpenAI Codex Desktop Application";
    exec = "${codex-fhs}/bin/codex-desktop %U";
    icon = "${config.home.homeDirectory}/.local/share/pixmaps/codex.png";
    terminal = false;
    categories = [ "Development" "Utility" ];
    settings = {
      StartupWMClass = "codex-desktop";
    };
  };
}
