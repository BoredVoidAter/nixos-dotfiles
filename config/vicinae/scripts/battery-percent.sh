#!/usr/bin/env bash

# Simple battery percentage output for status bars
# Usage: battery-percent.sh

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
  case "$STATUS" in
    Charging) ICON="⚡" ;;
    Full) ICON="󰁹" ;;
    Discharging) ICON="󰂂" ;;
    *) ICON="󰁿" ;;
  esac
  echo "${ICON} ${CAP}%"
else
  echo "No Battery"
fi