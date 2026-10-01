#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Quick Web Search
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Utility
# @raycast.icon 󰜎

# Documentation:
# @raycast.description Search the web or open a URL directly
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

# Pipe suggestions so vicinae dmenu has stdin and stays open
QUERY=$(printf "DuckDuckGo\nGoogle\nGitHub\nYouTube\nWikipedia" | vicinae dmenu --placeholder "Search the web or enter a URL...")

[ -z "$QUERY" ] && exit 0

# If an engine was selected without typing anything else
case "$QUERY" in
  "DuckDuckGo") xdg-open "https://duckduckgo.com" && exit 0 ;;
  "Google") xdg-open "https://google.com" && exit 0 ;;
  "GitHub") xdg-open "https://github.com" && exit 0 ;;
  "YouTube") xdg-open "https://youtube.com" && exit 0 ;;
  "Wikipedia") xdg-open "https://wikipedia.org" && exit 0 ;;
esac

# Check if query is a URL
if [[ "$QUERY" =~ ^(http|https)://|[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+.* ]]; then
  if ! [[ "$QUERY" =~ ^(http|https):// ]]; then
    QUERY="https://$QUERY"
  fi
  xdg-open "$QUERY"
else
  ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")
  xdg-open "https://duckduckgo.com/?q=${ENCODED}"
fi
