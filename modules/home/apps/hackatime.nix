{ pkgs, config, lib, ... }:

let
  # Path to the state file
  stateDir = "${config.home.homeDirectory}/.config/hackatime-tracker";
  stateFile = "${stateDir}/state.json";

  # The Control Script
  hackatime-control = pkgs.writeShellScriptBin "hackatime-control" ''
    mkdir -p ${stateDir}
    
    # Initialize state file if it doesn't exist
    if [ ! -f "${stateFile}" ]; then
      echo '{"active": false, "current": "General", "projects": ["General", "Coding", "CAD", "Gaming"]}' > "${stateFile}"
    fi

    # Read current state
    ACTIVE=$(jq -r '.active' "${stateFile}")
    CURRENT=$(jq -r '.current' "${stateFile}")
    
    # Determine Status Text
    if [ "$ACTIVE" == "true" ]; then
      STATUS_TEXT="🟢 Tracking: $CURRENT"
      TOGGLE_TEXT="Stop Tracking"
    else
      STATUS_TEXT="🔴 Paused"
      TOGGLE_TEXT="Start Tracking"
    fi

    # Main Menu
    ACTION=$(zenity --list --title="Hackatime Control" --text="$STATUS_TEXT" \
      --column="Option" \
      "$TOGGLE_TEXT" \
      "Switch Project" \
      "Add New Project" \
      --width=300 --height=250)

    case "$ACTION" in
      "Start Tracking")
        jq '.active = true' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
        notify-send "Hackatime" "Tracking Started: $CURRENT"
        ;;
      "Stop Tracking")
        jq '.active = false' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
        notify-send "Hackatime" "Tracking Paused"
        ;;
      "Switch Project")
        # Get list of projects
        PROJECTS=$(jq -r '.projects[]' "${stateFile}")
        
        NEW_PROJECT=$(echo "$PROJECTS" | zenity --list --title="Select Project" --column="Projects" --height=300)
        
        if [ -n "$NEW_PROJECT" ]; then
          jq --arg p "$NEW_PROJECT" '.current = $p | .active = true' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
          notify-send "Hackatime" "Switched to: $NEW_PROJECT"
        fi
        ;;
      "Add New Project")
        NEW_NAME=$(zenity --entry --title="New Project" --text="Enter project name:")
        
        if [ -n "$NEW_NAME" ]; then
          # Add to list and set as current
          jq --arg p "$NEW_NAME" '.projects += [$p] | .current = $p | .active = true' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
          notify-send "Hackatime" "Created & Switched to: $NEW_NAME"
        fi
        ;;
    esac
  '';
in
{
  home.packages = with pkgs; [
    wakatime-cli
    zenity # For the GUI dialogs
    jq     # For parsing JSON
    hackatime-control
  ];

  # --- Secrets (Moved from misc.nix) ---
  sops.secrets.wakatime_api_key = { };

  sops.templates.".wakatime.cfg" = {
    path = ".wakatime.cfg";
    content = ''
      [settings]
      api_url = https://waka.hackclub.com/api/v1
      api_key = ${config.sops.placeholder.wakatime_api_key}
      debug = false
    '';
  };

  # --- Desktop Entry (So it shows up in Rofi) ---
  xdg.desktopEntries.hackatime-control = {
    name = "Hackatime Control";
    genericName = "Time Tracker Manager";
    exec = "${hackatime-control}/bin/hackatime-control";
    terminal = false;
    categories = [ "Utility" ];
    icon = "utilities-time-tracker"; # Standard icon, or use a custom path
  };
}
