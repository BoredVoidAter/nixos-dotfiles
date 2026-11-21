#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Control4Free Set PS4 IP
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Gaming
# @raycast.icon 󰊗

# Documentation:
# @raycast.description Set or update the PS4 IP address for Control4Free and launch it in Chrome
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

exec control4free --set-ip
