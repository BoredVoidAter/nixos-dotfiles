{ pkgs, lib, ... }:

let
  xboxSvg = pkgs.writeText "xbox-live.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
      <defs>
        <clipPath id="xbox-sphere">
          <circle cx="256" cy="256" r="236"/>
        </clipPath>
      </defs>
      <circle cx="256" cy="256" r="236" fill="#107C10"/>
      <g clip-path="url(#xbox-sphere)">
        <path d="M 120 75 Q 256 205 405 420" stroke="#ffffff" stroke-width="54" stroke-linecap="round" fill="none"/>
        <path d="M 392 75 Q 256 205 107 420" stroke="#ffffff" stroke-width="54" stroke-linecap="round" fill="none"/>
      </g>
    </svg>
  '';

  xboxPng = pkgs.runCommand "xbox-live.png" { } ''
    ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${xboxSvg} $out
  '';

  teamsSvg = pkgs.writeText "teams.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
      <rect x="20" y="20" width="472" height="472" rx="96" fill="#4B53BC"/>
      <circle cx="348" cy="176" r="46" fill="#7B83EB"/>
      <path d="M 288 242 H 392 A 36 36 0 0 1 428 278 V 352 A 64 64 0 0 1 300 352 V 254 A 12 12 0 0 1 288 242 Z" fill="#7B83EB"/>
      <rect x="92" y="136" width="212" height="212" rx="28" fill="#5059C9"/>
      <path d="M 144 196 H 252 M 198 196 V 300" stroke="#ffffff" stroke-width="32" stroke-linecap="round"/>
    </svg>
  '';

  teamsPng = pkgs.runCommand "teams.png" { } ''
    ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${teamsSvg} $out
  '';

  onshapeSvg = pkgs.writeText "onshape.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
      <rect x="20" y="20" width="472" height="472" rx="96" fill="#1B642A"/>
      <polygon points="256,88 402,172 402,340 256,424 110,340 110,172" fill="#2A8C3C"/>
      <polygon points="256,88 402,172 256,256 110,172" fill="#82D647"/>
      <polygon points="256,256 402,172 402,340 256,424" fill="#4BA834"/>
      <polygon points="256,256 110,172 110,340 256,424" fill="#1E7430"/>
      <polygon points="256,162 338,209 338,303 256,350 174,303 174,209" fill="none" stroke="#ffffff" stroke-width="22" stroke-linejoin="round"/>
      <polyline points="174,209 256,256 338,209" fill="none" stroke="#ffffff" stroke-width="22" stroke-linejoin="round"/>
      <line x1="256" y1="256" x2="256" y2="350" stroke="#ffffff" stroke-width="22" stroke-linecap="round"/>
    </svg>
  '';

  onshapePng = pkgs.runCommand "onshape.png" { } ''
    ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${onshapeSvg} $out
  '';

  notionSvg = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
    curlOptsList = [ "-H" "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" ];
    sha256 = "sha256-G1KhhdgWbZM59cFt1ReJ7jD0mmW01Ac4KQtgQj4zEWA=";
  };

  notionPng = pkgs.runCommand "notion.png" { } ''
    ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${notionSvg} $out
  '';

  aistudioSvg = pkgs.writeText "aistudio.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
      <defs>
        <linearGradient id="aistudio-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#1a73e8"/>
          <stop offset="100%" stop-color="#4c50bc"/>
        </linearGradient>
      </defs>
      <rect x="20" y="20" width="472" height="472" rx="96" fill="url(#aistudio-bg)"/>
      <path d="M 256 96 C 268 188 324 244 416 256 C 324 268 268 324 256 416 C 244 324 188 268 96 256 C 188 244 244 188 256 96 Z" fill="#ffffff"/>
      <path d="M 372 108 C 376 132 392 148 416 152 C 392 156 376 172 372 196 C 368 172 352 156 328 152 C 352 148 368 132 372 108 Z" fill="#dbeafe"/>
    </svg>
  '';

  aistudioPng = pkgs.runCommand "aistudio.png" { } ''
    ${pkgs.resvg}/bin/resvg -w 512 -h 512 ${aistudioSvg} $out
  '';

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

  xbox-live = mkChromeWebApp {
    execName = "xbox-live";
    url = "https://www.xbox.com/play";
  };

  teams = mkChromeWebApp {
    execName = "teams";
    url = "https://teams.microsoft.com";
  };

  onshape = mkChromeWebApp {
    execName = "onshape";
    url = "https://cad.onshape.com";
    extraFlags = [
      "--enable-webgl"
      "--ignore-gpu-blocklist"
    ];
  };

  notion = mkChromeWebApp {
    execName = "notion";
    url = "https://www.notion.so";
  };

  aistudio = mkChromeWebApp {
    execName = "aistudio";
    url = "https://aistudio.google.com";
    extraFlags = [
      "--enable-webgl"
      "--ignore-gpu-blocklist"
    ];
  };
in
{
  home.packages = [
    xbox-live
    teams
    onshape
    notion
    aistudio
  ];

  xdg.desktopEntries.xbox-live = {
    name = "Xbox Live";
    genericName = "Xbox Cloud Gaming";
    comment = "Xbox Cloud Gaming web app";
    exec = "xbox-live";
    icon = "${xboxPng}";
    terminal = false;
    categories = [ "Game" ];
    settings = {
      StartupWMClass = "xbox-live";
    };
  };

  xdg.desktopEntries.teams = {
    name = "Microsoft Teams";
    genericName = "Team Collaboration";
    comment = "Microsoft Teams web app";
    exec = "teams";
    icon = "${teamsPng}";
    terminal = false;
    categories = [ "Network" "InstantMessaging" ];
    settings = {
      StartupWMClass = "teams";
    };
  };

  xdg.desktopEntries.onshape = {
    name = "Onshape";
    genericName = "Cloud CAD";
    comment = "Onshape 3D CAD web app";
    exec = "onshape";
    icon = "${onshapePng}";
    terminal = false;
    categories = [ "Graphics" "Engineering" "3DGraphics" ];
    settings = {
      StartupWMClass = "onshape";
    };
  };

  xdg.desktopEntries.notion = {
    name = "Notion";
    genericName = "Notes & Workspace";
    comment = "Connected workspace for notes, docs, and projects";
    exec = "notion %U";
    icon = "${notionPng}";
    terminal = false;
    categories = [ "Office" "Utility" "TextEditor" ];
    mimeType = [ "x-scheme-handler/notion" ];
    settings = {
      StartupWMClass = "notion";
    };
  };

  xdg.desktopEntries.aistudio = {
    name = "Google AI Studio";
    genericName = "AI Prototyping Studio";
    comment = "Google AI Studio web app";
    exec = "aistudio";
    icon = "${aistudioPng}";
    terminal = false;
    categories = [ "Development" "Utility" ];
    settings = {
      StartupWMClass = "aistudio";
    };
  };

  xdg.dataFile."icons/hicolor/scalable/apps/xbox-live.svg".source = xboxSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/xbox-live.png".source = xboxPng;
  xdg.dataFile."icons/hicolor/scalable/apps/teams.svg".source = teamsSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/teams.png".source = teamsPng;
  xdg.dataFile."icons/hicolor/scalable/apps/onshape.svg".source = onshapeSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/onshape.png".source = onshapePng;
  xdg.dataFile."icons/hicolor/scalable/apps/notion.svg".source = notionSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/notion.png".source = notionPng;
  xdg.dataFile."icons/hicolor/scalable/apps/aistudio.svg".source = aistudioSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/aistudio.png".source = aistudioPng;
}
