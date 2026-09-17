#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spotify: Previous Track
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon ./spotify.svg

# Documentation:
# @raycast.description Return to previous Spotify track
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

playerctl -p spotify previous 2>/dev/null
