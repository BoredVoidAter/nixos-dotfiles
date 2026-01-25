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

    while true; do
      # Read current state
      ACTIVE=$(jq -r '.active' "${stateFile}")
      CURRENT=$(jq -r '.current' "${stateFile}")
      
      # Determine Status Text and Icons
      if [ "$ACTIVE" == "true" ]; then
        STATUS_TEXT="Tracking: $CURRENT"
        TOGGLE_OPT="  Stop Tracking"
        ICON="media-playback-start"
      else
        STATUS_TEXT="Paused"
        TOGGLE_OPT="  Start Tracking"
        ICON="media-playback-pause"
      fi

      # Main Menu
      ACTION=$(zenity --list --title="Hackatime Control" \
        --text="<span size='x-large' weight='bold'>$STATUS_TEXT</span>" \
        --column="Action" \
        "$TOGGLE_OPT" \
        "  Switch Project" \
        "  Add New Project" \
        "  Exit" \
        --width=400 --height=350 \
        --hide-header \
        --window-icon="$ICON")

      # Handle Cancel/Exit
      if [ -z "$ACTION" ] || [ "$ACTION" == "  Exit" ]; then
        break
      fi

      case "$ACTION" in
        *"Start Tracking")
          jq '.active = true' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
          notify-send -u low "Hackatime" "Started: $CURRENT"
          ;;
        *"Stop Tracking")
          jq '.active = false' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
          notify-send -u low "Hackatime" "Paused"
          ;;
        *"Switch Project")
          # Get list of projects
          PROJECTS=$(jq -r '.projects[]' "${stateFile}")
          
          NEW_PROJECT=$(echo "$PROJECTS" | zenity --list --title="Select Project" --column="Projects" --height=400 --width=300)
          
          if [ -n "$NEW_PROJECT" ]; then
            jq --arg p "$NEW_PROJECT" '.current = $p | .active = true' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
            notify-send -u low "Hackatime" "Switched to: $NEW_PROJECT"
          fi
          ;;
        *"Add New Project")
          NEW_NAME=$(zenity --entry --title="New Project" --text="Enter project name:")
          
          if [ -n "$NEW_NAME" ]; then
            # Add to list and set as current
            jq --arg p "$NEW_NAME" '.projects += [$p] | .current = $p | .active = true' "${stateFile}" > "${stateFile}.tmp" && mv "${stateFile}.tmp" "${stateFile}"
            notify-send -u low "Hackatime" "Created: $NEW_NAME"
          fi
          ;;
      esac
    done
  '';
in
{
  home.packages = with pkgs; [
    wakatime-cli
    zenity 
    jq
    libnotify # Required for notify-send
    hackatime-control
  ];

  # --- Secrets ---
  sops.secrets.wakatime_api_key = { };

  # We use an absolute path so sops-nix writes directly to the home folder
  # This avoids the symlink error you encountered
  sops.templates.".wakatime.cfg" = {
    path = "${config.home.homeDirectory}/.wakatime.cfg";
    content = ''
      [settings]
      api_url = https://waka.hackclub.com/api/v1
      api_key = ${config.sops.placeholder.wakatime_api_key}
      debug = false
    '';
  };

  # --- Desktop Entry ---
  xdg.desktopEntries.hackatime-control = {
    name = "Hackatime Control";
    genericName = "Time Tracker Manager";
    exec = "${hackatime-control}/bin/hackatime-control";
    terminal = false;
    categories = [ "Utility" ];
    icon = "utilities-time-tracker";
  };
}
