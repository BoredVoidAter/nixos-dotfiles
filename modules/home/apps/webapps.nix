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
      pkg = mkChromeWebApp {
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
