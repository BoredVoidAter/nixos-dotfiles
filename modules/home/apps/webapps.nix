{ pkgs, ... }:

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

  # Reference google-chrome-stable directly instead of adding pkgs.google-chrome to
  # home.packages so Chrome itself stays hidden from $PATH and application launchers.
  mkChromeWebApp = { execName, url }:
    pkgs.writeShellScriptBin execName ''
      DATA_DIR="$HOME/.local/share/webapps/${execName}"
      mkdir -p "$DATA_DIR"
      exec ${pkgs.google-chrome}/bin/google-chrome-stable \
        --app="${url}" \
        --user-data-dir="$DATA_DIR" \
        --class="${execName}" \
        --ozone-platform-hint=auto \
        --no-first-run \
        --no-default-browser-check
    '';

  xbox-live = mkChromeWebApp {
    execName = "xbox-live";
    url = "https://www.xbox.com/play";
  };

  teams = mkChromeWebApp {
    execName = "teams";
    url = "https://teams.microsoft.com";
  };
in
{
  home.packages = [
    xbox-live
    teams
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

  xdg.dataFile."icons/hicolor/scalable/apps/xbox-live.svg".source = xboxSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/xbox-live.png".source = xboxPng;
  xdg.dataFile."icons/hicolor/scalable/apps/teams.svg".source = teamsSvg;
  xdg.dataFile."icons/hicolor/512x512/apps/teams.png".source = teamsPng;
}
