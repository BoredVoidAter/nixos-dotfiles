{ pkgs, lib, ... }:

let
  notionSvg = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
    curlOptsList = [ "-H" "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" ];
    sha256 = "sha256-G1KhhdgWbZM59cFt1ReJ7jD0mmW01Ac4KQtgQj4zEWA=";
  };

  # Reference google-chrome-stable directly instead of adding pkgs.google-chrome to
  # home.packages so Chrome itself stays hidden from $PATH and application launchers.
  mkChromeWebApp = { execName, url, extraFlags ? [ ] }:
    pkgs.writeShellScriptBin execName ''
      DATA_DIR="$HOME/.local/share/webapps/${execName}"
      mkdir -p "$DATA_DIR"
      TARGET_URL="${url}"
      for arg in "$@"; do
        case "$arg" in
          https://*|http://*)
            TARGET_URL="$arg"
            break
            ;;
          notion://*)
            stripped="''${arg#notion://}"
            case "$stripped" in
              https://*|http://*) TARGET_URL="$stripped" ;;
              www.notion.so*|notion.so*|www.notion.com*|notion.com*) TARGET_URL="https://$stripped" ;;
              *) TARGET_URL="https://www.notion.so/''${stripped#/}" ;;
            esac
            break
            ;;
        esac
      done
      exec ${pkgs.google-chrome}/bin/google-chrome-stable \
        --app="$TARGET_URL" \
        --user-data-dir="$DATA_DIR" \
        --class="${execName}" \
        --ozone-platform-hint=auto \
        --no-first-run \
        --no-default-browser-check \
        ${lib.escapeShellArgs extraFlags}
    '';

  control4freePkg = pkgs.writeShellScriptBin "control4free" ''
    DATA_DIR="$HOME/.local/share/webapps/control4free"
    CONF_DIR="$HOME/.config/control4free"
    CONF_FILE="$CONF_DIR/url"
    mkdir -p "$DATA_DIR" "$CONF_DIR"

    normalize_c4f_url() {
      local raw="$1"
      raw="$(printf '%s' "$raw" | ${pkgs.coreutils}/bin/tr -d '[:space:]')"
      [ -z "$raw" ] && return 1
      case "$raw" in
        http://*|https://*) ;;
        *) raw="http://$raw" ;;
      esac
      local scheme="''${raw%%://*}"
      local rest="''${raw#*://}"
      local hostport="''${rest%%/*}"
      local path=""
      case "$rest" in
        */*) path="/''${rest#*/}" ;;
      esac
      case "$hostport" in
        *:*) ;;
        *) hostport="$hostport:4264" ;;
      esac
      printf '%s://%s%s\n' "$scheme" "$hostport" "$path"
    }

    SET_IP=0
    ARG_URL=""
    for arg in "$@"; do
      case "$arg" in
        --set-ip|--config)
          SET_IP=1
          ;;
        -*)
          ;;
        *)
          ARG_URL="$arg"
          ;;
      esac
    done

    TARGET_URL=""
    if [ -n "$ARG_URL" ]; then
      TARGET_URL="$(normalize_c4f_url "$ARG_URL" || true)"
      [ -n "$TARGET_URL" ] && printf '%s\n' "$TARGET_URL" > "$CONF_FILE"
    elif [ "$SET_IP" -eq 0 ] && [ -s "$CONF_FILE" ]; then
      TARGET_URL="$(normalize_c4f_url "$(cat "$CONF_FILE")" || true)"
    fi

    if [ -z "$TARGET_URL" ] || [ "$SET_IP" -eq 1 ]; then
      DEFAULT_VAL=""
      [ -s "$CONF_FILE" ] && DEFAULT_VAL="$(cat "$CONF_FILE")"
      INPUT="$(${pkgs.zenity}/bin/zenity --entry \
        --title="Control4Free" \
        --text="Enter your PS4 IP address or URL (port 4264 is added automatically):" \
        --entry-text="''${DEFAULT_VAL:-192.168.1.}" 2>/dev/null || true)"
      TARGET_URL="$(normalize_c4f_url "$INPUT" || true)"
      [ -z "$TARGET_URL" ] && exit 0
      printf '%s\n' "$TARGET_URL" > "$CONF_FILE"
    fi

    ORIGIN="$(printf '%s' "$TARGET_URL" | ${pkgs.gnused}/bin/sed -E 's#^(https?://[^/]+).*#\1#')"

    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      --app="$TARGET_URL" \
      --user-data-dir="$DATA_DIR" \
      --class="control4free" \
      --ozone-platform-hint=auto \
      --no-first-run \
      --no-default-browser-check \
      --unsafely-treat-insecure-origin-as-secure="$ORIGIN"
  '';

  webApps = {
    xbox-live = {
      name = "Xbox Live";
      genericName = "Xbox Cloud Gaming";
      comment = "Xbox Cloud Gaming web app";
      url = "https://www.xbox.com/play";
      categories = [ "Game" ];
    };

    teams = {
      name = "Microsoft Teams";
      genericName = "Team Collaboration";
      comment = "Microsoft Teams web app";
      url = "https://teams.microsoft.com";
      categories = [ "Network" "InstantMessaging" ];
    };

    onshape = {
      name = "Onshape";
      genericName = "Cloud CAD";
      comment = "Onshape 3D CAD web app";
      url = "https://cad.onshape.com";
      categories = [ "Graphics" "Engineering" "3DGraphics" ];
      extraFlags = [
        "--enable-webgl"
        "--ignore-gpu-blocklist"
      ];
    };

    notion = {
      name = "Notion";
      genericName = "Notes & Workspace";
      comment = "Connected workspace for notes, docs, and projects";
      url = "https://www.notion.so";
      categories = [ "Office" "Utility" "TextEditor" ];
      mimeType = [ "x-scheme-handler/notion" ];
      iconSvg = notionSvg;
    };

    aistudio = {
      name = "Google AI Studio";
      genericName = "AI Prototyping Studio";
      comment = "Google AI Studio web app";
      url = "https://aistudio.google.com";
      categories = [ "Development" "Utility" ];
      extraFlags = [
        "--enable-webgl"
        "--ignore-gpu-blocklist"
      ];
    };

    control4free = {
      name = "Control4Free";
      genericName = "PS4 Virtual DualShock";
      comment = "Control4Free virtual PS4 DualShock 4 web app";
      pkg = control4freePkg;
      categories = [ "Game" "Utility" ];
    };
  };

  mkExtraIconFiles = execName: app:
    if app ? iconSvg then
      let
        png = pkgs.runCommand "${execName}.png" { } ''
          ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${app.iconSvg} $out
        '';
      in
      {
        inherit png;
        dataFiles = {
          "icons/hicolor/scalable/apps/${execName}.svg".source = app.iconSvg;
          "icons/hicolor/512x512/apps/${execName}.png".source = png;
        };
      }
    else
      {
        png = null;
        dataFiles = { };
      };

  builtApps = lib.mapAttrs (execName: app:
    let
      iconInfo = mkExtraIconFiles execName app;
    in
    {
      pkg =
        if app ? pkg then
          app.pkg
        else
          mkChromeWebApp {
            inherit execName;
            url = app.url;
            extraFlags = app.extraFlags or [ ];
          };
      desktopEntry = {
        inherit (app) name genericName comment categories;
        exec = if (app.mimeType or [ ]) != [ ] then "${execName} %U" else execName;
        icon = if iconInfo.png != null then "${iconInfo.png}" else execName;
        terminal = false;
        settings = {
          StartupWMClass = execName;
        };
      } // lib.optionalAttrs (app ? mimeType) {
        inherit (app) mimeType;
      };
      inherit (iconInfo) dataFiles;
    }
  ) webApps;
in
{
  home.packages = map (app: app.pkg) (builtins.attrValues builtApps);

  xdg.desktopEntries = lib.mapAttrs (_: app: app.desktopEntry) builtApps;

  xdg.dataFile = lib.foldl' (acc: app: acc // app.dataFiles) { } (builtins.attrValues builtApps);
}
