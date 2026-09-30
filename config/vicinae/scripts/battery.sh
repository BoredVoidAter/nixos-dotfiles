#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Battery
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName System Information
# @raycast.icon 󰁹

# Documentation:
# @raycast.description View live battery status and set charging limits
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

CAP=""
STATUS=""

for b in /sys/class/power_supply/BAT* /sys/class/power_supply/*; do
  if [ -f "$b/capacity" ]; then
    CAP=$(<"$b/capacity")
    if [ -f "$b/status" ]; then
      STATUS=$(<"$b/status")
    fi
    break
  fi
done

if [ -n "$CAP" ]; then
  if [ "$STATUS" = "Charging" ]; then
    INFO="⚡ $CAP% (Charging)"
  elif [ "$STATUS" = "Full" ]; then
    INFO="100% (Full)"
  elif [ -n "$STATUS" ]; then
    INFO="$CAP% ($STATUS)"
  else
    INFO="$CAP%"
  fi
else
  INFO="No Battery Found"
fi

# Display live info in dmenu and offer charging options
OPT_100="󰁹 Set charging limit to 100% (Standard)"
OPT_80="󰂃 Set charging limit to 80% (Custom Longevity)"
OPT_PRIM="󰚥 Set charging mode to Primarily AC (Auto-managed)"

CHOICE=$(printf "%s\n%s\n%s\n" "$OPT_100" "$OPT_80" "$OPT_PRIM" | vicinae dmenu --placeholder "$INFO")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  *"100%"*)
    sudo smbios-battery-ctl --set-charging-mode=standard
    notify-send -i battery-full-charged "Battery" "Charging mode set to Standard (100%)"
    ;;
  *"80%"*)
    sudo smbios-battery-ctl --set-custom-charge-interval=75 80
    sudo smbios-battery-ctl --set-charging-mode=custom
    notify-send -i battery-good "Battery" "Charging mode set to Custom (80%)"
    ;;
  *"Primarily AC"*)
    sudo smbios-battery-ctl --set-charging-mode=primarily_ac
    notify-send -i battery-good "Battery" "Charging mode set to Primarily AC"
    ;;
esac
