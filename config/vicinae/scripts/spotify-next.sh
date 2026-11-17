#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Music: Next Track
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon 󰒭

# Documentation:
# @raycast.description Skip to next YouTube Music track
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

PLAYER=$(playerctl -l 2>/dev/null | grep -iE 'ytm|youtube' | head -n 1)
if [ -n "$PLAYER" ]; then
  playerctl -p "$PLAYER" next 2>/dev/null
else
  ytm next 2>/dev/null || true
fi
