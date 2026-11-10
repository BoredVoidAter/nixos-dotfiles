{ pkgs, ... }:

let
  usdb-syncer-fhs = pkgs.buildFHSEnv {
    name = "usdb-syncer-fhs";
    targetPkgs = pkgs: (pkgs.appimageTools.defaultFhsEnvArgs.targetPkgs pkgs) ++ (with pkgs; [
      uv
      ffmpeg
      yt-dlp
      zstd
      zlib
      glib
      stdenv.cc.cc.lib
      dbus
      alsa-lib
      libpulseaudio
      portaudio
      libsecret
      mesa
      libGL
      fontconfig
      freetype
      wayland
      libxkbcommon
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      libxcb
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      libxcb-cursor
    ]);

    runScript = "uvx --with 'PySide6<6.8.0' --with keyrings.alt --python 3.12 usdb_syncer";
  };

  usdb-syncer-bin = pkgs.writeShellScriptBin "usdb-syncer" ''
    export QT_QPA_PLATFORM="wayland;xcb"
    exec ${usdb-syncer-fhs}/bin/usdb-syncer-fhs "$@"
  '';

  ultrastar-deluxe-wrapper = pkgs.writeShellScriptBin "ultrastardx" ''
    set -euo pipefail

    CONFIG_DIR="$HOME/.ultrastardx"
    CONFIG_FILE="$CONFIG_DIR/config.ini"
    PLAYLISTS_DIR="$CONFIG_DIR/playlists"
    SONGS_DIR="/run/media/boredvoidater/Karaoke/songs_ultrastar"
    mkdir -p "$CONFIG_DIR" "$PLAYLISTS_DIR"

    # Automatically split SingStar 2-channel USB adapter into two virtual mono mics if present
    SINGSTAR_SRC=$(pactl list sources short 2>/dev/null | grep -iE 'singstar|usbmic' | grep -v 'remapped' | grep -v 'SingStar_' | awk '{print $2}' | head -n 1 || echo "")
    if [ -n "$SINGSTAR_SRC" ]; then
      if ! pactl list sources short 2>/dev/null | grep -q "SingStar_Blue"; then
        pactl load-module module-remap-source \
          source_name="SingStar_Blue" \
          source_properties="device.description='SingStar Blue (Mic 1)'" \
          master="$SINGSTAR_SRC" \
          master_channel_map=front-left \
          channel_map=mono 2>/dev/null || true
      fi
      if ! pactl list sources short 2>/dev/null | grep -q "SingStar_Red"; then
        pactl load-module module-remap-source \
          source_name="SingStar_Red" \
          source_properties="device.description='SingStar Red (Mic 2)'" \
          master="$SINGSTAR_SRC" \
          master_channel_map=front-right \
          channel_map=mono 2>/dev/null || true
      fi
    fi

    # Sync playlists (.upl) into UltraStar Deluxe's expected playlist folder
    if [ -d "$SONGS_DIR" ]; then
      find "$SONGS_DIR" -maxdepth 1 -type f -name "*.upl" 2>/dev/null | while read -r upl; do
        ln -sfn "$upl" "$PLAYLISTS_DIR/$(basename "$upl")"
      done
    fi

    # Ensure song folder and Modern widescreen dark theme are set in config.ini
    if [ ! -f "$CONFIG_FILE" ]; then
      cat << 'EOF' > "$CONFIG_FILE"
Theme=Modern
Skin=Blue
Color=Blue

[Directories]
SongDir1=/run/media/boredvoidater/Karaoke/songs_ultrastar
EOF
    else
      if ! grep -q "songs_ultrastar" "$CONFIG_FILE"; then
        if grep -q "\[Directories\]" "$CONFIG_FILE"; then
          sed -i '/\[Directories\]/a SongDir1=/run/media/boredvoidater/Karaoke/songs_ultrastar' "$CONFIG_FILE"
        else
          printf "\n[Directories]\nSongDir1=/run/media/boredvoidater/Karaoke/songs_ultrastar\n" >> "$CONFIG_FILE"
        fi
      fi

      # Switch to Modern theme if still on default Deluxe theme
      sed -i 's/^Theme=Deluxe/Theme=Modern/' "$CONFIG_FILE" 2>/dev/null || true
    fi

    exec ${pkgs.ultrastardx}/bin/ultrastardx "$@"
  '';

  ultrastar-alias = pkgs.writeShellScriptBin "ultrastar" ''
    exec ${ultrastar-deluxe-wrapper}/bin/ultrastardx "$@"
  '';

  ultrastar-create-playlist = pkgs.writeShellScriptBin "ultrastar-create-playlist" ''
    set -euo pipefail

    export PATH="${pkgs.gnused}/bin:${pkgs.findutils}/bin:${pkgs.coreutils}/bin:$PATH"

    if [ -z "''${1:-}" ]; then
        echo "Usage: ultrastar-create-playlist <song_directory>"
        echo "Example: ultrastar-create-playlist /run/media/boredvoidater/Karaoke/songs_ultrastar"
        exit 1
    fi

    TARGET_DIR="$1"
    PLAYLIST_DIR="$HOME/.ultrastardx/playlists"
    mkdir -p "$PLAYLIST_DIR"

    echo "========================================="
    echo "Generating Playlists (.upl) for: $TARGET_DIR"
    echo "========================================="

    find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d "" DIR; do
        PLAYLIST_NAME=$(basename "$DIR")
        PLAYLIST_FILE="$TARGET_DIR/$PLAYLIST_NAME.upl"
        USER_PLAYLIST_FILE="$PLAYLIST_DIR/$PLAYLIST_NAME.upl"
        TEMP_PLAYLIST=$(mktemp)

        find "$DIR" -type f -iname "*.txt" -print0 | while IFS= read -r -d "" TXT; do
            ARTIST=$(sed -n 's/^#ARTIST:\(.*\)/\1/Ip' "$TXT" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' || true)
            TITLE=$(sed -n 's/^#TITLE:\(.*\)/\1/Ip' "$TXT" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' || true)

            if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
                echo "$ARTIST : $TITLE" >> "$TEMP_PLAYLIST"
            fi
        done

        if [ -s "$TEMP_PLAYLIST" ]; then
            echo "#Name: $PLAYLIST_NAME" > "$PLAYLIST_FILE"
            cat "$TEMP_PLAYLIST" >> "$PLAYLIST_FILE"
            cp -f "$PLAYLIST_FILE" "$USER_PLAYLIST_FILE"
            echo "  -> Created '$PLAYLIST_NAME.upl' ($(wc -l < "$TEMP_PLAYLIST") songs)."
        fi

        rm -f "$TEMP_PLAYLIST"
    done

    echo "========================================="
    echo "Done! Playlists created and synced to UltraStar."
    echo "========================================="
  '';

  # UltraStar Karaoke Maker (USKMaker) runner with dedicated NVIDIA CUDA acceleration for AI
  uskmaker-runner = pkgs.writeShellScriptBin "uskmaker-runner" ''
    set -euo pipefail

    APP_DIR="$HOME/.local/share/USKMaker"
    REPO_DIR="$APP_DIR/repo"
    VENV_DIR="$APP_DIR/venv"
    mkdir -p "$APP_DIR"

    # Dedicated NVIDIA CUDA device configuration for PyTorch / AI sidecar
    export CUDA_VISIBLE_DEVICES=0
    export CUDA_DEVICE_ORDER=PCI_BUS_ID
    export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True,garbage_collection_threshold:0.8"

    # Ensure host system NVIDIA CUDA libraries are discoverable
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:/usr/lib64:/usr/lib:''${LD_LIBRARY_PATH:-}"

    # SSL CA certificates configuration for Python requests / downloads
    if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
      export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
    elif [ -f "/etc/ssl/certs/ca-bundle.crt" ]; then
      export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
    fi
    export REQUESTS_CA_BUNDLE="''${SSL_CERT_FILE:-}"

    # Keep Tauri / WebKitGTK on Intel iGPU to reserve full 6GB VRAM for PyTorch AI models
    export GDK_BACKEND="wayland,x11"
    export QT_QPA_PLATFORM="wayland;xcb"
    export WEBKIT_DISABLE_DMABUF_RENDERER=1

    configure_sidecar_rescue() {
      # Remove any corrupted partial model downloads under 500MB
      find /tmp/audio-separator-models -type f -name "*.ckpt" -size -500M -delete 2>/dev/null || true

      # Clean onnxruntime-gpu if present to avoid reserving an unused 2GB VRAM arena
      if [ -f "$VENV_DIR/bin/python" ]; then
        uv pip uninstall --python "$VENV_DIR" onnxruntime-gpu 2>/dev/null || true
      fi

      # Force audio-separator Separator invocation in the sidecar to use CPU
      # This prevents VRAM OOM collision with WhisperX without touching GPU models (Demucs, WhisperX, Swift-F0)
      if [ -d "$REPO_DIR/python-sidecar" ]; then
        find "$REPO_DIR/python-sidecar" -type f -name "*.py" -exec sed -i 's/Separator(torch_device="cpu", /Separator(/g' {} + 2>/dev/null || true
        find "$REPO_DIR/python-sidecar" -type f -name "*.py" -exec sed -i 's/Separator(/Separator(torch_device="cpu", /g' {} + 2>/dev/null || true
      fi
    }

    setup_ai_env() {
      echo "=========================================================="
      echo " Configuring UltraStar Karaoke Maker AI (PyTorch + CUDA 12)"
      echo "=========================================================="
      rm -rf "$VENV_DIR"
      echo "[1/5] Creating Python 3.12 virtualenv..."
      uv venv "$VENV_DIR" --python 3.12

      export VIRTUAL_ENV="$VENV_DIR"
      export PATH="$VENV_DIR/bin:$PATH"

      echo "[2/5] Installing PyTorch with CUDA 12.6 support..."
      uv pip install --python "$VENV_DIR" torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu126

      echo "[3/5] Installing AI pipeline dependencies (WhisperX, Demucs, SwiftF0, librosa)..."
      if [ -f "$REPO_DIR/python-sidecar/requirements.txt" ]; then
        uv pip install --python "$VENV_DIR" --extra-index-url https://download.pytorch.org/whl/cu126 -r "$REPO_DIR/python-sidecar/requirements.txt"
      else
        uv pip install --python "$VENV_DIR" --extra-index-url https://download.pytorch.org/whl/cu126 whisperx demucs librosa swift-f0 pyphen yt-dlp soundfile numpy scipy
      fi

      uv pip uninstall --python "$VENV_DIR" onnxruntime-gpu 2>/dev/null || true
      uv pip install --python "$VENV_DIR" onnxruntime "audio-separator[cpu]"

      configure_sidecar_rescue

      echo "[4/5] Pre-downloading NLTK tokenizer models (punkt, punkt_tab)..."
      "$VENV_DIR/bin/python" -c "import ssl, nltk; ssl._create_default_https_context = ssl._create_unverified_context; nltk.download('punkt_tab', quiet=True); nltk.download('punkt', quiet=True)" 2>/dev/null || true

      echo "[5/5] Verifying NVIDIA CUDA acceleration:"
      "$VENV_DIR/bin/python" -c "import torch; print('   CUDA Available: ', torch.cuda.is_available()); print('   Device Name:    ', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU (CUDA not detected)')"
      echo "=========================================================="
    }

    # Ensure repository is cloned
    if [ ! -d "$REPO_DIR/.git" ]; then
      echo "Fetching UltraStar Karaoke Maker repository..."
      git clone https://github.com/walterfr/UltraStarKaraokeMaker.git "$REPO_DIR"
    fi

    # Explicit AI setup flag
    if [ "''${1:-}" = "--setup-ai" ] || [ "''${1:-}" = "setup-ai" ]; then
      shift || true
      setup_ai_env
      exit 0
    fi

    # Explicit repository & AI update flag
    if [ "''${1:-}" = "--update" ] || [ "''${1:-}" = "update" ]; then
      shift || true
      echo "Updating UltraStar Karaoke Maker..."
      cd "$REPO_DIR" && git pull || true
      setup_ai_env
      exit 0
    fi

    # Build release binary flag
    if [ "''${1:-}" = "--build" ] || [ "''${1:-}" = "build" ]; then
      shift || true
      cd "$REPO_DIR"
      [ ! -d "node_modules" ] && npm install
      echo "Compiling UltraStar Karaoke Maker release binary via Tauri..."
      npm run tauri build
      exit 0
    fi

    # Check and initialize AI environment if missing or lacking CUDA
    if [ ! -f "$VENV_DIR/bin/python" ]; then
      setup_ai_env
    elif ! "$VENV_DIR/bin/python" -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
      echo "CUDA is not active in the existing Python environment. Reinstalling..."
      setup_ai_env
    fi

    export VIRTUAL_ENV="$VENV_DIR"
    export PATH="$VENV_DIR/bin:$PATH"

    configure_sidecar_rescue

    # Ensure NLTK tokenizer datasets are present with SSL fallback
    "$VENV_DIR/bin/python" -c "import ssl, nltk; ssl._create_default_https_context = ssl._create_unverified_context; nltk.download('punkt_tab', quiet=True); nltk.download('punkt', quiet=True)" 2>/dev/null || true

    # Ensure the sidecar links to the shared environment expected by USKMaker
    mkdir -p "$REPO_DIR/python-sidecar"
    ln -sfn "$VENV_DIR" "$REPO_DIR/python-sidecar/venv"

    cd "$REPO_DIR"

    # Launch compiled release binary if already built
    RELEASE_BIN=$(find "$REPO_DIR/src-tauri/target/release" -maxdepth 1 -type f -executable ! -name "*.so" ! -name "build-script-*" 2>/dev/null | head -n 1 || echo "")
    if [ -n "$RELEASE_BIN" ] && [ -x "$RELEASE_BIN" ]; then
      echo "Launching UltraStar Karaoke Maker (NVIDIA CUDA active)..."
      exec "$RELEASE_BIN" "$@"
    fi

    # Otherwise install npm modules and run dev mode
    if [ ! -d "$REPO_DIR/node_modules" ]; then
      echo "Installing frontend dependencies..."
      npm install
    fi

    echo "Starting UltraStar Karaoke Maker via Tauri (NVIDIA CUDA active)..."
    exec npm run tauri dev -- "$@"
  '';

  uskmaker-fhs = pkgs.buildFHSEnv {
    name = "uskmaker-fhs";
    extraOutputsToInstall = [ "dev" "lib" ];
    targetPkgs = pkgs: (pkgs.appimageTools.defaultFhsEnvArgs.targetPkgs pkgs) ++ (with pkgs; [
      # Python & environment tools
      python312
      uv
      git
      git-lfs
      curl
      wget
      which
      procps
      coreutils
      gnused
      gnugrep
      cacert

      # Build toolchain for native modules & Tauri
      stdenv.cc
      stdenv.cc.cc.lib
      gcc
      binutils
      gnumake
      cmake
      pkg-config
      nodejs
      rustc
      cargo

      # Media processing
      ffmpeg
      ffmpeg_7
      yt-dlp
      sox
      portaudio
      alsa-lib
      libpulseaudio

      # Tauri GUI & WebKit dependencies
      gtk3
      webkitgtk_4_1
      libsoup_3
      librsvg
      glib
      cairo
      pango
      harfbuzz
      gdk-pixbuf
      atk
      openssl
      zlib
      dbus
      libayatana-appindicator

      # Graphics, Display & NVIDIA CUDA
      mesa
      libGL
      libGLU
      libglvnd
      libdrm
      vulkan-loader
      ocl-icd
      cudatoolkit
      fontconfig
      freetype
      wayland
      libxkbcommon
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      libxcb
      libxinerama
      libxscrnsaver
    ]);

    profile = ''
      export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:''${PKG_CONFIG_PATH:-}"
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:/usr/lib64:/usr/lib:''${LD_LIBRARY_PATH:-}"
      if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
        export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
      elif [ -f "/etc/ssl/certs/ca-bundle.crt" ]; then
        export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
      fi
      export REQUESTS_CA_BUNDLE="''${SSL_CERT_FILE:-}"
    '';

    runScript = "${uskmaker-runner}/bin/uskmaker-runner";
  };

  uskmaker-bin = pkgs.writeShellScriptBin "uskmaker" ''
    exec ${uskmaker-fhs}/bin/uskmaker-fhs "$@"
  '';

  uskmaker-alias = pkgs.writeShellScriptBin "ultrastar-karaoke-maker" ''
    exec ${uskmaker-bin}/bin/uskmaker "$@"
  '';

  uskmaker-setup-ai = pkgs.writeShellScriptBin "uskmaker-setup-ai" ''
    exec ${uskmaker-bin}/bin/uskmaker --setup-ai "$@"
  '';

  uskmaker-build = pkgs.writeShellScriptBin "uskmaker-build" ''
    exec ${uskmaker-bin}/bin/uskmaker --build "$@"
  '';
in
{
  home.packages = with pkgs; [
    usdb-syncer-bin
    ultrastar-deluxe-wrapper
    ultrastar-alias
    ultrastar-create-playlist
    uskmaker-bin
    uskmaker-alias
    uskmaker-setup-ai
    uskmaker-build
    uv
    yt-dlp
    ffmpeg
  ];

  xdg.desktopEntries = {
    usdb-syncer = {
      name = "USDB Syncer";
      genericName = "Karaoke Song Downloader";
      comment = "Download and sync UltraStar karaoke songs from USDB";
      exec = "usdb-syncer";
      icon = "multimedia-audio-player";
      terminal = false;
      categories = [ "AudioVideo" "Audio" ];
    };

    ultrastardx = {
      name = "UltraStar Deluxe";
      genericName = "Karaoke Game";
      comment = "Free and open source singing game (Native Linux Build with FFmpeg & PipeWire)";
      exec = "ultrastardx";
      icon = "ultrastardx";
      terminal = false;
      categories = [ "Game" "AudioVideo" "Audio" ];
      settings = {
        StartupWMClass = "ultrastardx";
      };
    };

    uskmaker = {
      name = "UltraStar Karaoke Maker";
      genericName = "AI Karaoke Package Generator";
      comment = "Generate UltraStar karaoke songs with forced alignment (Demucs + WhisperX on NVIDIA GPU)";
      exec = "uskmaker";
      icon = "multimedia-audio-player";
      terminal = false;
      categories = [ "AudioVideo" "Audio" ];
    };
  };
}
