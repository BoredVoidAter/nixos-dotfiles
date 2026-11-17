#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Music: Play / Pause
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon 󰐎

# Documentation:
# @raycast.description Toggle YouTube Music playback or open ytm-player
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

PLAYER=$(playerctl -l 2>/dev/null | grep -iE 'ytm|youtube' | head -n 1)
if [ -n "$PLAYER" ]; then
  playerctl -p "$PLAYER" play-pause 2>/dev/null
else
  music-toggle >/dev/null 2>&1 &
fi
