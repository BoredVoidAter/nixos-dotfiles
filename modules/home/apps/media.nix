{ pkgs, ytm-player, ... }:

let
  ytmPkg = ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.ytm-player-full;

  music-runner = pkgs.writeShellScriptBin "music-runner" ''
    set -u
    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"
    while true; do
      start_ts=$(date +%s)
      ${ytmPkg}/bin/ytm
      status=$?
      elapsed=$(( $(date +%s) - start_ts ))
      if [ "$status" -eq 0 ] && [ "$elapsed" -ge 3 ]; then
        break
      fi
      echo ""
      echo "ytm exited with status $status (if this is your first run, you may need to authenticate)."
      echo "Press [s] to run 'ytm setup', [Enter] to retry, or close with Super+W..."
      read -r choice
      if [ "$choice" = "s" ] || [ "$choice" = "S" ]; then
        ${ytmPkg}/bin/ytm setup
      fi
    done
  '';

  music-scratchpad = pkgs.writeShellScriptBin "music-scratchpad" ''
    exec ${pkgs.kitty}/bin/kitty --class music-scratchpad -e ${music-runner}/bin/music-runner
  '';

  music-toggle = pkgs.writeShellScriptBin "music-toggle" ''
    set -u
    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"
    if ! hyprctl clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "music-scratchpad")' >/dev/null 2>&1; then
      ${music-scratchpad}/bin/music-scratchpad >/dev/null 2>&1 &
      for _ in $(seq 1 40); do
        if hyprctl clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "music-scratchpad")' >/dev/null 2>&1; then
          break
        fi
        sleep 0.1
      done
      if hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -e '.[] | select(.focused == true and .specialWorkspace.name == "special:music")' >/dev/null 2>&1; then
        exit 0
      fi
    fi
    exec hyprctl dispatch 'hl.dsp.workspace.toggle_special("music")'
  '';
in
{

  programs.imv = {
    enable = true;
    settings = {
      options = {

        background = "0d0e11";
      };
    };
  };


  programs.zathura = {
    enable = true;
    options = {

      default-bg = "#0d0e11";
      default-fg = "#e6e6ea";
      statusbar-bg = "#131418";
      statusbar-fg = "#8c8f9a";
      inputbar-bg = "#18191e";
      inputbar-fg = "#e6e6ea";
    };
  };

  xdg.configFile."ytm-player/theme.toml".text = ''
    [colors]
    background = "#0d0e11"
    foreground = "#e6e6ea"
    primary = "#4c50bc"
    secondary = "#b5b7c0"
    accent = "#a855f7"
    success = "#3bb36a"
    warning = "#d4a34b"
    error = "#e05555"
    surface = "#131418"
    border = "#27282f"
    muted_text = "#8c8f9a"
    text = "#e6e6ea"
    playback_bar_bg = "#131418"
    active_tab = "#ffffff"
    inactive_tab = "#8c8f9a"
    selected_item = "#27282f"
    progress_filled = "#4c50bc"
    progress_empty = "#27282f"
    lyrics_played = "#5a5c66"
    lyrics_current = "#a855f7"
    lyrics_upcoming = "#e6e6ea"
  '';

  home.packages = with pkgs; [
    ytmPkg
    music-runner
    music-scratchpad
    music-toggle
    xarchiver # GUI archive manager (works perfectly with Thunar)
    playerctl
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {

      "text/html" = [ "librewolf.desktop" ];
      "x-scheme-handler/http" = [ "librewolf.desktop" ];
      "x-scheme-handler/https" = [ "librewolf.desktop" ];
      "x-scheme-handler/about" = [ "librewolf.desktop" ];
      "x-scheme-handler/unknown" = [ "librewolf.desktop" ];

      "image/jpeg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      "image/tiff" = [ "imv.desktop" ];
      "image/bmp" = [ "imv.desktop" ];
      "image/svg+xml" = [ "imv.desktop" ];


      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ]; # mkv
      "video/webm" = [ "mpv.desktop" ];
      "video/x-msvideo" = [ "mpv.desktop" ]; # avi
      "video/quicktime" = [ "mpv.desktop" ]; # mov


      "audio/mpeg" = [ "mpv.desktop" ]; # mp3
      "audio/ogg" = [ "mpv.desktop" ];
      "audio/x-wav" = [ "mpv.desktop" ];
      "audio/flac" = [ "mpv.desktop" ];


      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];


      "application/zip" = [ "xarchiver.desktop" ];
      "application/x-tar" = [ "xarchiver.desktop" ];
      "application/x-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-bzip-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-xz-compressed-tar" = [ "xarchiver.desktop" ];
      "application/x-7z-compressed" = [ "xarchiver.desktop" ];
      "application/vnd.rar" = [ "xarchiver.desktop" ];
    };
  };
}
