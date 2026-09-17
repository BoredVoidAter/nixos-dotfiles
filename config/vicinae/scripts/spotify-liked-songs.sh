#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spotify: Liked Songs
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon ./spotify.svg

# Documentation:
# @raycast.description Open and play your Spotify Liked Songs collection
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

URI="spotify:collection:tracks"

if playerctl -p spotify status >/dev/null 2>&1; then
  playerctl -p spotify open "$URI" 2>/dev/null
else
  spotify "$URI" >/dev/null 2>&1 &
fi
