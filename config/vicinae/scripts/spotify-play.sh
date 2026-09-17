#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Spotify: Play or Search
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon ./spotify.svg
# @raycast.argument1 { "type": "text", "placeholder": "Song, artist, playlist or Spotify URL" }

# Documentation:
# @raycast.description Search for music or open a Spotify track/playlist URI
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

QUERY="$1"

if [ -z "$QUERY" ]; then
  exit 0
fi

if [[ "$QUERY" =~ open\.spotify\.com/(track|playlist|album|artist)/([a-zA-Z0-9]+) ]]; then
  URI="spotify:${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
elif [[ "$QUERY" =~ ^spotify: ]]; then
  URI="$QUERY"
else
  ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY" 2>/dev/null || echo "$QUERY" | sed 's/ /%20/g')
  URI="spotify:search:${ENCODED}"
fi

if playerctl -p spotify status >/dev/null 2>&1; then
  playerctl -p spotify open "$URI" 2>/dev/null
else
  spotify "$URI" >/dev/null 2>&1 &
fi
