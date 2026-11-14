#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Power Mode
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName System
# @raycast.icon 󰌪

# Documentation:
# @raycast.description Switch between Power Saver, Balanced, and Performance modes (CPU profile, Hyprland effects, 60Hz panel, brightness)
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/power-mode"
mkdir -p "$STATE_DIR"

get_profile() {
  if command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl get 2>/dev/null || echo "balanced"
  else
    echo "balanced"
  fi
}

print_status_json() {
  local profile
  profile=$(get_profile)
  case "$profile" in
    power-saver)
      printf '{"text":"󰌪","class":"power-saver","tooltip":"Power Mode: Power Saver (Click to toggle)"}\n'
      ;;
    performance)
      printf '{"text":"󱐋","class":"performance","tooltip":"Power Mode: Performance (Click to toggle)"}\n'
      ;;
    *)
      printf '{"text":"󰁿","class":"balanced","tooltip":"Power Mode: Balanced (Click to toggle)"}\n'
      ;;
  esac
}

set_internal_refresh() {
  local target_hz="$1"
  command -v hyprctl >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local mon_json
  mon_json=$(hyprctl monitors -j 2>/dev/null | jq -c '.[] | select(.name | test("^(eDP|LVDS|DSI)"))' | head -n 1)
  [ -z "$mon_json" ] && return 0

  local name mirror_of width height pos_x pos_y scale
  name=$(echo "$mon_json" | jq -r '.name')
  mirror_of=$(echo "$mon_json" | jq -r '.mirrorOf // "none"')
  [ "$mirror_of" != "none" ] && return 0

  width=$(echo "$mon_json" | jq -r '.width')
  height=$(echo "$mon_json" | jq -r '.height')
  pos_x=$(echo "$mon_json" | jq -r '.x')
  pos_y=$(echo "$mon_json" | jq -r '.y')
  scale=$(echo "$mon_json" | jq -r '.scale')

  if [ "$target_hz" = "60" ]; then
    local has_60
    has_60=$(echo "$mon_json" | jq -r --arg res "${width}x${height}@60" '[.availableModes[] | select(startswith($res))] | length')
    if [ "${has_60:-0}" -gt 0 ]; then
      hyprctl keyword monitor "${name},${width}x${height}@60,${pos_x}x${pos_y},${scale}" >/dev/null 2>&1
    fi
  else
    hyprctl keyword monitor "${name},preferred,${pos_x}x${pos_y},${scale}" >/dev/null 2>&1
  fi
}

apply_mode() {
  local target="$1"
  local current
  current=$(get_profile)

  if command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl set "$target" 2>/dev/null || true
  fi

  case "$target" in
    power-saver)
      if command -v hyprctl >/dev/null 2>&1; then
        hyprctl --batch "keyword decoration:blur:enabled 0 ; keyword decoration:shadow:enabled 0 ; keyword animations:enabled 0" >/dev/null 2>&1
      fi
      set_internal_refresh "60"

      if [ "$current" != "power-saver" ] && command -v brightnessctl >/dev/null 2>&1; then
        local cur_bright
        cur_bright=$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%')
        if [ -n "$cur_bright" ] && [ "$cur_bright" -gt 35 ]; then
          echo "$cur_bright" > "$STATE_DIR/prev_brightness"
          brightnessctl -q set 35% 2>/dev/null || true
        fi
      fi

      notify-send -i battery-low "Power Saving Mode" "Enabled (power-saver, 60Hz, effects off)"
      ;;

    balanced|performance)
      if command -v hyprctl >/dev/null 2>&1; then
        hyprctl --batch "keyword decoration:blur:enabled 1 ; keyword decoration:shadow:enabled 1 ; keyword animations:enabled 1" >/dev/null 2>&1
      fi
      set_internal_refresh "preferred"

      if [ "$current" = "power-saver" ] && [ -f "$STATE_DIR/prev_brightness" ] && command -v brightnessctl >/dev/null 2>&1; then
        local prev_bright
        prev_bright=$(cat "$STATE_DIR/prev_brightness")
        rm -f "$STATE_DIR/prev_brightness"
        if [ -n "$prev_bright" ]; then
          brightnessctl -q set "${prev_bright}%" 2>/dev/null || true
        fi
      fi

      if [ "$target" = "performance" ]; then
        notify-send -i battery-full-charged "Power Mode" "Performance enabled"
      else
        notify-send -i battery-good "Power Mode" "Balanced mode restored"
      fi
      ;;
  esac

  pkill -RTMIN+8 waybar 2>/dev/null || true
}

case "${1:-}" in
  --status)
    print_status_json
    exit 0
    ;;
  --toggle)
    if [ "$(get_profile)" = "power-saver" ]; then
      apply_mode "balanced"
    else
      apply_mode "power-saver"
    fi
    exit 0
    ;;
  power-saver|balanced|performance)
    apply_mode "$1"
    exit 0
    ;;
esac

CURRENT=$(get_profile)
OPT_SAVER="󰌪  Power Saver (60Hz, no blur/animations, low power)"
OPT_BALANCED="󰗑  Balanced (Default)"
OPT_PERF="󱐋  Performance (Max power)"

CHOICE=$(printf "%s\n%s\n%s\n" \
  "$OPT_SAVER" \
  "$OPT_BALANCED" \
  "$OPT_PERF" | \
  vicinae dmenu --placeholder "Current Power Mode: $CURRENT")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  *"Power Saver"*) apply_mode "power-saver" ;;
  *"Balanced"*) apply_mode "balanced" ;;
  *"Performance"*) apply_mode "performance" ;;
esac
