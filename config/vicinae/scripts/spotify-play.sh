#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Music: Open Player
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon 󰎈

# Documentation:
# @raycast.description Open or toggle the YouTube Music TUI scratchpad
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

music-toggle >/dev/null 2>&1 &
