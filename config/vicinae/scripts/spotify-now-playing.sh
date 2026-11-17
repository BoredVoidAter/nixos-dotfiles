#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Music Status
# @raycast.mode inline
# @raycast.refreshTime 5s

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon 󰎈

# Documentation:
# @raycast.description Current YouTube Music playback state and track
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v playerctl >/dev/null 2>&1; then
  echo "playerctl not found"
  exit 0
fi

PLAYER=$(playerctl -l 2>/dev/null | grep -iE 'ytm|youtube' | head -n 1)
[ -z "$PLAYER" ] && { echo "Music offline"; exit 0; }

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)

if [ "$STATUS" = "Playing" ]; then
  TRACK=$(playerctl -p "$PLAYER" metadata --format '{{artist}} - {{title}}' 2>/dev/null)
  echo "▶ $TRACK"
elif [ "$STATUS" = "Paused" ]; then
  TRACK=$(playerctl -p "$PLAYER" metadata --format '{{artist}} - {{title}}' 2>/dev/null)
  echo "⏸ $TRACK"
else
  echo "Music offline"
fi
