#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Music: Previous Track
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon 󰒮

# Documentation:
# @raycast.description Return to previous YouTube Music track
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

PLAYER=$(playerctl -l 2>/dev/null | grep -iE 'ytm|youtube' | head -n 1)
if [ -n "$PLAYER" ]; then
  playerctl -p "$PLAYER" previous 2>/dev/null
fi
