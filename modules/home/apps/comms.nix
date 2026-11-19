{ config, lib, pkgs, ... }:

let
  nchat-record = pkgs.writeShellScriptBin "nchat-record" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.ffmpeg pkgs.opusTools pkgs.coreutils ]}:$PATH"

    OUT_FILE="''${1:-}"
    if [ -z "$OUT_FILE" ]; then
      exit 1
    fi

    exec ${pkgs.python3}/bin/python3 - "$OUT_FILE" << 'EOF'
    import os
    import select
    import signal
    import subprocess
    import sys
    import termios
    import time
    import tty

    out_file = sys.argv[1]
    raw_wav = out_file + ".wav"
    os.makedirs(os.path.dirname(out_file), exist_ok=True)

    # Open /dev/tty directly so ncurses/background subshell stdin does not trigger ioctl error
    try:
        tty_fd = os.open("/dev/tty", os.O_RDWR)
        tty_in = os.fdopen(tty_fd, "rb", buffering=0)
        tty_out = os.fdopen(tty_fd, "wb", buffering=0)
    except Exception:
        tty_in = sys.stdin.buffer
        tty_out = sys.stdout.buffer

    # Capture uncompressed PCM first so live PulseAudio timestamps never leak into Ogg Opus
    rec = subprocess.Popen(
        [
            "ffmpeg", "-y", "-v", "error",
            "-f", "pulse", "-i", "default",
            "-ac", "1", "-ar", "16000",
            "-f", "wav", raw_wav,
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    send_audio = False
    start_ts = time.monotonic()
    old_term = None

    try:
        try:
            old_term = termios.tcgetattr(tty_in.fileno())
            tty.setcbreak(tty_in.fileno())
        except Exception:
            old_term = None

        tty_out.write(b"\n")
        while True:
            if rec.poll() is not None:
                break
            elapsed = int(time.monotonic() - start_ts)
            mins, secs = divmod(elapsed, 60)
            status_line = (
                f"\r  \033[1;31m●\033[0m Recording voice message  {mins:02d}:{secs:02d}   "
                "[Enter/Space] Send   [q/Esc] Cancel   "
            )
            tty_out.write(status_line.encode("utf-8", "ignore"))

            rlist, _, _ = select.select([tty_in.fileno()], [], [], 0.1)
            if rlist:
                ch = tty_in.read(1)
                if ch in (b"\r", b"\n", b" "):
                    send_audio = True
                    break
                if ch in (b"q", b"Q", b"\x1b", b"\x03"):
                    send_audio = False
                    break
    except KeyboardInterrupt:
        send_audio = False
    finally:
        if old_term is not None:
            try:
                termios.tcsetattr(tty_in.fileno(), termios.TCSADRAIN, old_term)
            except Exception:
                pass
        tty_out.write(b"\n\033[0m")

    # Ask ffmpeg to quit gracefully via 'q' so the WAV header and samples flush cleanly
    if rec.poll() is None:
        try:
            if rec.stdin is not None:
                rec.stdin.write(b"q\n")
                rec.stdin.flush()
                rec.stdin.close()
            rec.wait(timeout=3)
        except Exception:
            if rec.poll() is None:
                rec.send_signal(signal.SIGINT)
                try:
                    rec.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    rec.kill()
                    rec.wait()

    encoded_ok = False
    try:
        if send_audio and os.path.isfile(raw_wav) and os.path.getsize(raw_wav) > 44:
            flt = subprocess.Popen(
                [
                    "ffmpeg", "-y", "-v", "error",
                    "-i", raw_wav,
                    "-af", "highpass=f=80",
                    "-ac", "1", "-ar", "16000",
                    "-f", "wav", "-",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
            )
            enc = subprocess.Popen(
                [
                    "opusenc", "--quiet",
                    "--vbr", "--bitrate", "16",
                    "--comp", "10", "--framesize", "20",
                    "--speech", "--discard-comments",
                    "-", out_file,
                ],
                stdin=flt.stdout,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if flt.stdout is not None:
                flt.stdout.close()
            enc_rc = enc.wait()
            flt_rc = flt.wait()
            encoded_ok = (enc_rc == 0) and (flt_rc == 0) and os.path.isfile(out_file) and os.path.getsize(out_file) > 512
    finally:
        if os.path.exists(raw_wav):
            try:
                os.unlink(raw_wav)
            except OSError:
                pass

    if encoded_ok:
        sys.exit(0)

    if os.path.exists(out_file):
        try:
            os.unlink(out_file)
        except OSError:
            pass
    sys.exit(1)
    EOF
  '';

  nchat-patched = pkgs.nchat-patched;

  # Wrap runtime tools outside nchat-patched so tweaking nchat-record or updating
  # ffmpeg/mpv/chafa never triggers a full C++/Go recompile of nchat.
  nchat-wrapped = pkgs.symlinkJoin {
    name = "nchat-wrapped-${nchat-patched.version or "custom"}";
    paths = [ nchat-patched ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/nchat
      makeWrapper ${nchat-patched}/bin/nchat $out/bin/nchat \
        --prefix PATH : "${lib.makeBinPath [ pkgs.chafa pkgs.ffmpeg pkgs.mpv nchat-record ]}"
    '';
  };

  concord-tui-fixed = pkgs.concord-tui-fixed;

  genAercAccountsPy = pkgs.writeText "gen-aerc-accounts.py" ''
    import os
    import sys
    import tempfile
    import urllib.parse

    secret_path = sys.argv[1]
    conf_path = sys.argv[2]

    with open(secret_path, "r", encoding="utf-8") as f:
        pw = f.read().rstrip("\r\n")

    # Strip whitespace (e.g. grouped 4-char blocks or trailing space from Google App Passwords)
    pw = "".join(urllib.parse.unquote(pw).split())
    encoded_pw = urllib.parse.quote(pw, safe="")
    content = (
        "[Personal]\n"
        f"source        = imaps://finnion07%40gmail.com:{encoded_pw}@imap.gmail.com:993\n"
        f"outgoing      = smtp://finnion07%40gmail.com:{encoded_pw}@smtp.gmail.com:587\n"
        "default       = INBOX\n"
        "from          = Finn Degen <finnion07@gmail.com>\n"
        "cache-headers = true\n"
    )

    conf_dir = os.path.dirname(conf_path)
    os.makedirs(conf_dir, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(dir=conf_dir, prefix=".accounts.conf.")
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as out:
            out.write(content)
        os.replace(tmp_path, conf_path)
    except Exception:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        raise
  '';

  syncAercAccounts = pkgs.writeShellScript "sync-aerc-accounts" ''
    SECRET_PATH="${config.sops.secrets."gmail_app_password".path}"
    CONF_PATH="$HOME/.config/aerc/accounts.conf"
    if [ -s "$SECRET_PATH" ]; then
      ${pkgs.python3}/bin/python3 ${genAercAccountsPy} "$SECRET_PATH" "$CONF_PATH"
    fi
  '';

  ensureNchatNotifyPy = pkgs.writeText "ensure-nchat-notify.py" ''
    import os
    import sys

    conf_path = sys.argv[1]
    label = sys.argv[2]
    notify_bin = sys.argv[3]
    cmd_val = f">/dev/null 2>&1 {notify_bin} '{label}' '%1: %2'"

    os.makedirs(os.path.dirname(conf_path), exist_ok=True)
    lines = []
    if os.path.exists(conf_path):
        with open(conf_path, "r", encoding="utf-8") as f:
            lines = f.read().splitlines()

    out = []
    seen_enabled = False
    seen_active_current = False
    seen_active_noncurrent = False
    seen_inactive = False
    seen_cmd = False

    for line in lines:
        if line.startswith("desktop_notify_active="):
            continue
        elif line.startswith("desktop_notify_enabled="):
            out.append("desktop_notify_enabled=1")
            seen_enabled = True
        elif line.startswith("desktop_notify_active_current="):
            out.append("desktop_notify_active_current=1")
            seen_active_current = True
        elif line.startswith("desktop_notify_active_noncurrent="):
            out.append("desktop_notify_active_noncurrent=1")
            seen_active_noncurrent = True
        elif line.startswith("desktop_notify_inactive="):
            out.append("desktop_notify_inactive=1")
            seen_inactive = True
        elif line.startswith("desktop_notify_command="):
            out.append(f"desktop_notify_command={cmd_val}")
            seen_cmd = True
        else:
            out.append(line)

    if not seen_enabled:
        out.append("desktop_notify_enabled=1")
    if not seen_active_current:
        out.append("desktop_notify_active_current=1")
    if not seen_active_noncurrent:
        out.append("desktop_notify_active_noncurrent=1")
    if not seen_inactive:
        out.append("desktop_notify_inactive=1")
    if not seen_cmd:
        out.append(f"desktop_notify_command={cmd_val}")

    with open(conf_path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
  '';

  comms-whatsapp = pkgs.writeShellScriptBin "comms-whatsapp" ''
    set -u
    CONF_DIR="$HOME/.config/nchat-wa"
    UI_CONF="$CONF_DIR/ui.conf"
    mkdir -p "$CONF_DIR"

    ensure_notify_conf() {
      ${pkgs.python3}/bin/python3 ${ensureNchatNotifyPy} "$UI_CONF" "WhatsApp" "${pkgs.libnotify}/bin/notify-send"
    }

    while true; do
      if [ ! -d "$CONF_DIR/profiles" ] || [ -z "$(ls -A "$CONF_DIR/profiles" 2>/dev/null)" ]; then
        clear
        echo "=== WhatsApp (nchat) ==="
        echo "No WhatsApp profile linked yet."
        echo "Press [Enter] to run setup (pick WhatsApp and scan the QR code)..."
        read -r _
        ensure_notify_conf
        ${nchat-wrapped}/bin/nchat -d "$CONF_DIR" -s
        ensure_notify_conf
      else
        ensure_notify_conf
        ${nchat-wrapped}/bin/nchat -d "$CONF_DIR"
        echo ""
        echo "[WhatsApp exited] Press [Enter] to reconnect..."
        read -r _
      fi
    done
  '';

  comms-discord = pkgs.writeShellScriptBin "comms-discord" ''
    set -u
    while true; do
      clear
      echo "=== Discord (concord) ==="
      echo "Status: IDLE (0% CPU / 0% network)"
      echo "Press [Enter] to connect (quit concord to return to idle)..."
      read -r _
      ${concord-tui-fixed}/bin/concord
    done
  '';

  comms-gmail = pkgs.writeShellScriptBin "comms-gmail" ''
    set -u
    while true; do
      clear
      echo "=== Gmail (aerc) ==="
      echo "Status: IDLE (0% CPU / 0% network)"
      if [ ! -s "${config.sops.secrets."gmail_app_password".path}" ]; then
        echo "Warning: SOPS secret 'gmail_app_password' not found."
        echo "Run 'sops-edit' to add gmail_app_password, then rebuild with 'nrs'."
      fi
      echo "Press [Enter] to open aerc (press 'q' in aerc to return to idle)..."
      read -r _
      ${syncAercAccounts}
      ${pkgs.aerc}/bin/aerc
    done
  '';

  commsImv = pkgs.writeShellScriptBin "imv" ''
    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

    BEFORE_ADDRS=""
    if command -v hyprctl >/dev/null 2>&1; then
      BEFORE_ADDRS=$(hyprctl clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "imv" or .class == "imv-wayland" or .initialClass == "imv" or .initialClass == "imv-wayland") | .address' || true)
    fi

    ${pkgs.imv}/bin/imv "$@" &
    IMV_PID=$!

    (
      if command -v hyprctl >/dev/null 2>&1; then
        ADDR=""
        for _ in $(seq 1 60); do
          CLIENTS_JSON=$(hyprctl clients -j 2>/dev/null || echo "[]")
          ADDR=$(printf '%s' "$CLIENTS_JSON" | ${pkgs.jq}/bin/jq -r --argjson pid "$IMV_PID" '.[] | select(.pid == $pid) | .address' | head -n 1)
          if [ -z "$ADDR" ] || [ "$ADDR" = "null" ]; then
            ADDR=$(printf '%s' "$CLIENTS_JSON" | ${pkgs.jq}/bin/jq -r --arg before "$BEFORE_ADDRS" '
              ($before | split("\n") | map(select(length > 0))) as $seen
              | .[]
              | select(.class == "imv" or .class == "imv-wayland" or .initialClass == "imv" or .initialClass == "imv-wayland")
              | select(.address as $a | ($seen | index($a)) | not)
              | .address
            ' | head -n 1)
          fi
          if [ -n "$ADDR" ] && [ "$ADDR" != "null" ]; then
            break
          fi
          sleep 0.05
        done
        if [ -n "$ADDR" ] && [ "$ADDR" != "null" ]; then
          hyprctl --batch "dispatch setfloating address:$ADDR ; dispatch movetoworkspacesilent special:comms,address:$ADDR" >/dev/null 2>&1
          sleep 0.05
          hyprctl --batch "dispatch focuswindow address:$ADDR ; dispatch resizewindowpixel exact 80% 80%,address:$ADDR ; dispatch centerwindow ; dispatch alterzorder top,address:$ADDR" >/dev/null 2>&1
        fi
      fi
    ) &

    wait "$IMV_PID"
  '';

  commsImvXdgData = pkgs.runCommand "comms-imv-xdg-data" { } ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/imv.desktop <<EOF
[Desktop Entry]
Type=Application
Name=imv
Exec=${commsImv}/bin/imv %F
Terminal=false
NoDisplay=true
MimeType=image/bmp;image/gif;image/jpeg;image/png;image/tiff;image/webp;image/svg+xml;
EOF
  '';

  commsKittySession = pkgs.writeText "comms-kitty.session" ''
    new_tab WhatsApp
    launch ${comms-whatsapp}/bin/comms-whatsapp
    focus

    new_tab Discord
    launch ${comms-discord}/bin/comms-discord

    new_tab Gmail
    launch ${comms-gmail}/bin/comms-gmail
  '';

  comms-session = pkgs.writeShellScriptBin "comms-session" ''
    # Force xdg-open inside the comms overlay to use our local PATH/XDG_DATA_DIRS
    # instead of delegating to xdg-desktop-portal outside this environment.
    unset NIXOS_XDG_OPEN_USE_PORTAL
    export PATH="${commsImv}/bin:$PATH"
    export XDG_DATA_DIRS="${commsImvXdgData}/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    exec ${pkgs.kitty}/bin/kitty --class comms-scratchpad --session ${commsKittySession}
  '';

  comms-scratchpad = pkgs.writeShellScriptBin "comms-scratchpad" ''
    exec ${comms-session}/bin/comms-session
  '';
in
{
  home.packages = [
    nchat-wrapped
    nchat-record
    pkgs.chafa
    pkgs.ffmpeg
    concord-tui-fixed
    pkgs.aerc
    comms-whatsapp
    comms-discord
    comms-gmail
    comms-session
    comms-scratchpad
  ];

  sops.secrets."gmail_app_password" = {
    path = "${config.home.homeDirectory}/.config/aerc/.gmail-app-password";
  };

  # aerc refuses to read accounts.conf if permissions are looser than 0600,
  # so write it directly with mode 0600 rather than symlinking a 0444 nix store file.
  home.activation.aercAccounts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${syncAercAccounts}
  '';

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };
    settings = {
      background = "#0d0e11";
      foreground = "#e6e6ea";
      cursor = "#e6e6ea";
      cursor_text_color = "#0d0e11";
      selection_foreground = "#e6e6ea";
      selection_background = "#27282f";
      color0 = "#18191e";
      color1 = "#e05555";
      color2 = "#3bb36a";
      color3 = "#d4a34b";
      color4 = "#3a86ff";
      color5 = "#a855f7";
      color6 = "#2ec4b6";
      color7 = "#e6e6ea";
      color8 = "#5a5c66";
      color9 = "#ea6969";
      color10 = "#4cd47d";
      color11 = "#e5b75f";
      color12 = "#5b9bff";
      color13 = "#bc7cf8";
      color14 = "#4de0d3";
      color15 = "#f4f4f6";
      window_padding_width = 12;
      background_opacity = "0.95";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_min_tabs = 2;
      active_tab_foreground = "#ffffff";
      active_tab_background = "#4c50bc";
      active_tab_font_style = "bold";
      inactive_tab_foreground = "#8c8f9a";
      inactive_tab_background = "#18191e";
      tab_bar_background = "#0d0e11";
    };
    keybindings = {
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
    };
  };
}
