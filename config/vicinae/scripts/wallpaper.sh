#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Change Wallpaper
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Appearance
# @raycast.icon 󰸉

# Documentation:
# @raycast.description Open Waypaper to browse and change the desktop and login wallpaper
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v waypaper >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "Wallpaper" "waypaper is not installed."
  exit 1
fi

nohup waypaper >/dev/null 2>&1 &
