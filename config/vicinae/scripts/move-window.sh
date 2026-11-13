#!/usr/bin/env bash

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

DIR="$1"
DX="$2"
DY="$3"

# Check if the active window is floating
IS_FLOATING=$(hyprctl activewindow -j | jq -r '.floating' 2>/dev/null)

if [ "$IS_FLOATING" = "true" ]; then
    hyprctl dispatch moveactive "$DX" "$DY"
else
    hyprctl dispatch movewindow "$DIR"
fi
