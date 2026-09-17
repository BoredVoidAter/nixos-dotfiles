#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spotify: Play / Pause
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon ./spotify.svg

# Documentation:
# @raycast.description Toggle Spotify playback or launch client
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

playerctl -p spotify play-pause 2>/dev/null || spotify &
