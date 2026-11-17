#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Music: Open Library
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Media
# @raycast.icon 󰋑

# Documentation:
# @raycast.description Open the YouTube Music TUI scratchpad (press g l inside for Library / Liked Songs)
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

music-toggle >/dev/null 2>&1 &
