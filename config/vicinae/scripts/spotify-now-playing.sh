#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spotify Status
# @raycast.mode inline
# @raycast.refreshTime 5s

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon ./spotify.svg

# Documentation:
# @raycast.description Current Spotify playback state and track
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v playerctl >/dev/null 2>&1; then
  echo "playerctl not found"
  exit 0
fi

STATUS=$(playerctl -p spotify status 2>/dev/null)

if [ "$STATUS" = "Playing" ]; then
  TRACK=$(playerctl -p spotify metadata --format '{{artist}} - {{title}}' 2>/dev/null)
  echo "▶ $TRACK"
elif [ "$STATUS" = "Paused" ]; then
  TRACK=$(playerctl -p spotify metadata --format '{{artist}} - {{title}}' 2>/dev/null)
  echo "⏸ $TRACK"
else
  echo "Spotify offline"
fi
