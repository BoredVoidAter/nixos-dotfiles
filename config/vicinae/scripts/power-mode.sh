#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Power Mode
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName System
# @raycast.icon 󰌪

# Documentation:
# @raycast.description Switch between Power Saver, Balanced, Performance, and Wall-Plugged modes
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

get_effective_mode() {
  if [ -f "$STATE_DIR/mode" ] && [ "$(cat "$STATE_DIR/mode" 2>/dev/null)" = "wall-plugged" ]; then
    echo "wall-plugged"
  else
    get_profile
  fi
}

is_ac_online() {
  local ps_dir ps_type online
  for ps_dir in /sys/class/power_supply/*; do
    [ -d "$ps_dir" ] || continue
    [ -r "$ps_dir/online" ] || continue
    ps_type=$(cat "$ps_dir/type" 2>/dev/null || true)
    if [ "$ps_type" = "Mains" ] || [ -z "$ps_type" ]; then
      online=$(cat "$ps_dir/online" 2>/dev/null || echo 0)
      if [ "$online" = "1" ]; then
        return 0
      fi
    fi
  done
  return 1
}

get_bat_info() {
  local bat_dir cap status
  for bat_dir in /sys/class/power_supply/BAT*; do
    [ -d "$bat_dir" ] || continue
    cap=$(cat "$bat_dir/capacity" 2>/dev/null || true)
    status=$(cat "$bat_dir/status" 2>/dev/null || true)
    printf '%s|%s\n' "$cap" "$status"
    return 0
  done
  printf '|\n'
}

set_charge_bypass() {
  local enable="$1"
  local bat_dir behav start_f end_f cons_f cap target_end cur_start cur_end

  if [ "$enable" = "1" ]; then
    for bat_dir in /sys/class/power_supply/BAT*; do
      [ -d "$bat_dir" ] || continue
      behav="$bat_dir/charge_behaviour"
      if [ -w "$behav" ] && grep -q "inhibit-charge" "$behav" 2>/dev/null; then
        printf "inhibit-charge" > "$behav" 2>/dev/null || true
      fi

      start_f="$bat_dir/charge_control_start_threshold"
      end_f="$bat_dir/charge_control_end_threshold"
      if [ -w "$end_f" ]; then
        cur_end=$(cat "$end_f" 2>/dev/null || echo 100)
        [ -f "$STATE_DIR/prev_end_threshold" ] || echo "$cur_end" > "$STATE_DIR/prev_end_threshold"

        cap=$(cat "$bat_dir/capacity" 2>/dev/null || echo 80)
        if [ "$cap" -ge 80 ] 2>/dev/null; then
          target_end=80
        elif [ "$cap" -ge 60 ] 2>/dev/null; then
          target_end="$cap"
        else
          target_end=60
        fi

        if [ -w "$start_f" ]; then
          cur_start=$(cat "$start_f" 2>/dev/null || echo 0)
          [ -f "$STATE_DIR/prev_start_threshold" ] || echo "$cur_start" > "$STATE_DIR/prev_start_threshold"
          if [ "$cur_start" -ge "$target_end" ] 2>/dev/null; then
            printf "%s" "$((target_end - 5))" > "$start_f" 2>/dev/null || true
          fi
        fi
        printf "%s" "$target_end" > "$end_f" 2>/dev/null || true
      fi
    done

    for cons_f in /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode; do
      [ -w "$cons_f" ] || continue
      printf "1" > "$cons_f" 2>/dev/null || true
    done
  else
    for bat_dir in /sys/class/power_supply/BAT*; do
      [ -d "$bat_dir" ] || continue
      behav="$bat_dir/charge_behaviour"
      if [ -w "$behav" ] && grep -q "auto" "$behav" 2>/dev/null; then
        printf "auto" > "$behav" 2>/dev/null || true
      fi

      start_f="$bat_dir/charge_control_start_threshold"
      end_f="$bat_dir/charge_control_end_threshold"
      if [ -w "$end_f" ]; then
        cur_end=100
        if [ -f "$STATE_DIR/prev_end_threshold" ]; then
          cur_end=$(cat "$STATE_DIR/prev_end_threshold" 2>/dev/null || echo 100)
          rm -f "$STATE_DIR/prev_end_threshold"
        fi
        printf "%s" "$cur_end" > "$end_f" 2>/dev/null || true
      fi
      if [ -w "$start_f" ] && [ -f "$STATE_DIR/prev_start_threshold" ]; then
        cur_start=$(cat "$STATE_DIR/prev_start_threshold" 2>/dev/null || echo 0)
        rm -f "$STATE_DIR/prev_start_threshold"
        printf "%s" "$cur_start" > "$start_f" 2>/dev/null || true
      fi
    done

    for cons_f in /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode; do
      [ -w "$cons_f" ] || continue
      printf "0" > "$cons_f" 2>/dev/null || true
    done
  fi
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
  current=$(get_effective_mode)

  if [ "$target" = "wall-plugged" ]; then
    rm -f "$STATE_DIR/manual_override"
    echo "wall-plugged" > "$STATE_DIR/mode"
    if command -v powerprofilesctl >/dev/null 2>&1; then
      powerprofilesctl set balanced 2>/dev/null || true
    fi
    set_charge_bypass 1
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

    notify-send -i ac-adapter "Power Mode" "Wall-Plugged active (AC power, battery charging paused where supported)"
    pkill -RTMIN+8 waybar 2>/dev/null || true
    return 0
  fi

  rm -f "$STATE_DIR/mode"
  if is_ac_online; then
    local bat_info cap
    bat_info=$(get_bat_info)
    cap="${bat_info%%|*}"
    if [ -n "$cap" ] && [ "$cap" -ge 100 ] 2>/dev/null; then
      touch "$STATE_DIR/manual_override"
    fi
  fi

  set_charge_bypass 0

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

check_auto_wall_plugged() {
  local current bat_info cap status prev
  current=$(get_effective_mode)
  bat_info=$(get_bat_info)
  cap="${bat_info%%|*}"
  status="${bat_info#*|}"

  if is_ac_online; then
    if [ -n "$cap" ] && [ "$cap" -lt 100 ] 2>/dev/null; then
      rm -f "$STATE_DIR/manual_override"
    fi

    if [ "$current" != "wall-plugged" ] && [ ! -f "$STATE_DIR/manual_override" ] && [ -n "$cap" ] && [ "$cap" -ge 100 ] 2>/dev/null; then
      if [ "$status" = "Full" ] || [ "$status" = "Charging" ] || [ "$status" = "Not charging" ]; then
        echo "$current" > "$STATE_DIR/prev_mode"
        apply_mode "wall-plugged"
      fi
    fi
  else
    rm -f "$STATE_DIR/manual_override"
    if [ "$current" = "wall-plugged" ]; then
      prev="balanced"
      if [ -f "$STATE_DIR/prev_mode" ]; then
        prev=$(cat "$STATE_DIR/prev_mode" 2>/dev/null || echo "balanced")
        rm -f "$STATE_DIR/prev_mode"
      fi
      [ "$prev" = "wall-plugged" ] && prev="balanced"
      apply_mode "$prev"
    fi
  fi
}

print_status_json() {
  check_auto_wall_plugged
  local mode
  mode=$(get_effective_mode)
  case "$mode" in
    wall-plugged)
      printf '{"text":"󰚥","class":"wall-plugged","tooltip":"Power Mode: Wall-Plugged (AC Power / Battery Protected)"}\n'
      ;;
    power-saver)
      printf '{"text":"󰌪","class":"power-saver","tooltip":"Power Mode: Power Saver (Click to toggle)"}\n'
      ;;
    performance)
      printf '{"text":"󱐋","class":"performance","tooltip":"Power Mode: Performance (Click to toggle)"}\n'
      ;;
    *)
      printf '{"text":"󰗑","class":"balanced","tooltip":"Power Mode: Balanced (Click to toggle)"}\n'
      ;;
  esac
}

case "${1:-}" in
  --status)
    print_status_json
    exit 0
    ;;
  --toggle)
    if [ "$(get_effective_mode)" = "power-saver" ]; then
      apply_mode "balanced"
    else
      apply_mode "power-saver"
    fi
    exit 0
    ;;
  power-saver|balanced|performance|wall-plugged)
    apply_mode "$1"
    exit 0
    ;;
esac

CURRENT=$(get_effective_mode)
OPT_WALL="󰚥  Wall-Plugged (AC power, pause battery charging)"
OPT_SAVER="󰌪  Power Saver (60Hz, no blur/animations, low power)"
OPT_BALANCED="󰗑  Balanced (Default)"
OPT_PERF="󱐋  Performance (Max power)"

CHOICE=$(printf "%s\n%s\n%s\n%s\n" \
  "$OPT_WALL" \
  "$OPT_SAVER" \
  "$OPT_BALANCED" \
  "$OPT_PERF" | \
  vicinae dmenu --placeholder "Current Power Mode: $CURRENT")

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  *"Wall-Plugged"*)
    if ! is_ac_online; then
      notify-send -u normal -i dialog-warning "Power Mode" "Connect AC power to enable Wall-Plugged mode"
      exit 0
    fi
    echo "$CURRENT" > "$STATE_DIR/prev_mode"
    apply_mode "wall-plugged"
    ;;
  *"Power Saver"*) apply_mode "power-saver" ;;
  *"Balanced"*) apply_mode "balanced" ;;
  *"Performance"*) apply_mode "performance" ;;
esac
