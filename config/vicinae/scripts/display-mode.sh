#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Display Mode
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName System
# @raycast.icon 󰍹

# Documentation:
# @raycast.description Multi-monitor projection menu (PC screen only, Duplicate, Extend, Second screen only)
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

readarray -t MONITORS < <(
  {
    hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2}'
    hyprctl monitors all 2>/dev/null | awk '/^Monitor / {print $2}'
  } | awk '!seen[$0]++'
)

INTERNAL=""
EXTERNALS=()

for m in "${MONITORS[@]}"; do
  [ -z "$m" ] && continue
  if [ -z "$INTERNAL" ] && [[ "$m" =~ ^(eDP|LVDS|DSI) ]]; then
    INTERNAL="$m"
  else
    EXTERNALS+=("$m")
  fi
done

if [ -z "$INTERNAL" ] && [ ${#MONITORS[@]} -gt 0 ]; then
  INTERNAL="${MONITORS[0]}"
  EXTERNALS=("${MONITORS[@]:1}")
fi

EXTERNAL="${EXTERNALS[0]}"

if [ -n "$EXTERNAL" ]; then
  OPT_INTERNAL="󰌢  PC screen only (${INTERNAL:-internal})"
  OPT_DUPLICATE="󰍺  Duplicate (${INTERNAL:-PC} on ${EXTERNAL})"
  OPT_EXTEND_R="󱡶 Extend Right (${INTERNAL:-PC} 󰁔 ${EXTERNAL})"
  OPT_EXTEND_L="󱡶 Extend Left (${EXTERNAL} 󰁔 ${INTERNAL:-PC})"
  OPT_EXTERNAL="󰍹  Second screen only (${EXTERNAL})"
  OPT_RESET="󰁪 Auto-detect / Reset all"

  CHOICE=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
    "$OPT_INTERNAL" \
    "$OPT_DUPLICATE" \
    "$OPT_EXTEND_R" \
    "$OPT_EXTEND_L" \
    "$OPT_EXTERNAL" \
    "$OPT_RESET" |
    vicinae dmenu --placeholder "Select display mode...")
else
  OPT_INTERNAL="󰌢  PC screen only (${INTERNAL:-internal})"
  OPT_RESET="󰍻  Auto-detect / Reset all"

  CHOICE=$(printf "%s\n%s\n" \
    "$OPT_INTERNAL" \
    "$OPT_RESET" |
    vicinae dmenu --placeholder "Only 1 display detected (${INTERNAL:-internal})")
fi

[ -z "$CHOICE" ] && exit 0

# Reset stale runtime keywords (disabled flags, mirror links) and ensure DPMS power is on
prepare_displays() {
  hyprctl reload 2>/dev/null
  sleep 0.15
  hyprctl dispatch dpms on 2>/dev/null
}

case "$CHOICE" in
*"PC screen only"*)
  prepare_displays
  for ext in "${EXTERNALS[@]}"; do
    [ -n "$ext" ] && hyprctl keyword monitor "${ext},disable"
  done
  if [ -n "$INTERNAL" ]; then
    hyprctl keyword monitor "${INTERNAL},preferred,0x0,1"
    hyprctl dispatch dpms on "${INTERNAL}"
    hyprctl dispatch focusmonitor "${INTERNAL}"
    notify-send -i video-display "Display" "PC screen only (${INTERNAL})"
  fi
  ;;

*"Duplicate"*)
  if [ -z "$EXTERNAL" ] || [ -z "$INTERNAL" ]; then
    notify-send -u critical -i dialog-warning "Display" "Requires both internal and external displays"
    exit 0
  fi
  prepare_displays
  # Sync both to 1080p@60Hz matching timing across 120Hz internal and 60Hz external
  hyprctl keyword monitor "${INTERNAL},1920x1080@60,0x0,1"
  hyprctl keyword monitor "${EXTERNAL},1920x1080@60,0x0,1,mirror,${INTERNAL}"
  hyprctl dispatch dpms on
  notify-send -i video-display "Display" "Duplicating ${INTERNAL} on ${EXTERNAL} (1080p@60Hz)"
  ;;

*"Extend Right"*)
  if [ -z "$EXTERNAL" ] || [ -z "$INTERNAL" ]; then
    notify-send -u critical -i dialog-warning "Display" "Requires both internal and external displays"
    exit 0
  fi
  prepare_displays
  hyprctl keyword monitor "${INTERNAL},preferred,0x0,1"
  hyprctl keyword monitor "${EXTERNAL},preferred,auto-right,1"
  hyprctl dispatch dpms on
  notify-send -i video-display "Display" "Extended right (${INTERNAL} | ${EXTERNAL})"
  ;;

*"Extend Left"*)
  if [ -z "$EXTERNAL" ] || [ -z "$INTERNAL" ]; then
    notify-send -u critical -i dialog-warning "Display" "Requires both internal and external displays"
    exit 0
  fi
  prepare_displays
  hyprctl keyword monitor "${INTERNAL},preferred,auto,1"
  hyprctl keyword monitor "${EXTERNAL},preferred,auto-left,1"
  hyprctl dispatch dpms on
  notify-send -i video-display "Display" "Extended left (${EXTERNAL} | ${INTERNAL})"
  ;;

*"Second screen only"*)
  if [ -z "$EXTERNAL" ]; then
    notify-send -u critical -i dialog-warning "Display" "No external display detected"
    exit 0
  fi
  prepare_displays
  [ -n "$INTERNAL" ] && hyprctl keyword monitor "${INTERNAL},disable"
  hyprctl keyword monitor "${EXTERNAL},preferred,0x0,1"
  hyprctl dispatch dpms on "${EXTERNAL}"
  hyprctl dispatch focusmonitor "${EXTERNAL}"
  notify-send -i video-display "Display" "Second screen only (${EXTERNAL})"
  ;;

*"Reset"*)
  prepare_displays
  hyprctl keyword monitor ",preferred,auto,1"
  notify-send -i video-display "Display" "Displays reset to auto-detect"
  ;;
esac
