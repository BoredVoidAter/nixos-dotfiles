#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Battery
# @raycast.mode inline
# @raycast.refreshTime 10s

# Optional parameters:
# @raycast.packageName System Information

# Documentation:
# @raycast.description Current battery percentage and status
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
    echo "⚡ $CAP% (Charging)"
  elif [ "$STATUS" = "Full" ]; then
    echo "100% (Full)"
  elif [ -n "$STATUS" ]; then
    echo "$CAP% ($STATUS)"
  else
    echo "$CAP%"
  fi
else
  echo "No Battery Found"
fi
