#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Scan QR Code
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Utility
# @raycast.icon 󰄀

# Documentation:
# @raycast.description Select an area on your screen to scan and copy a QR code
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v zbarimg >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "QR Scanner" "zbar is not installed."
  exit 1
fi

# Let user select region (exits silently if they press Escape)
REGION=$(slurp 2>/dev/null)
[ -z "$REGION" ] && exit 0

TMP_FILE=$(mktemp --suffix=.png)
grim -g "$REGION" "$TMP_FILE"

# Failsafe if grim failed to write the file
if [ ! -s "$TMP_FILE" ]; then
  rm -f "$TMP_FILE"
  exit 0
fi

# Extract QR code data, ignoring extra text
RESULT=$(zbarimg -q --raw "$TMP_FILE" 2>/dev/null)
rm -f "$TMP_FILE"

if [ -n "$RESULT" ]; then
  # Print the result into the clipboard, removing any trailing newlines if it's a single line
  printf "%s" "$RESULT" | wl-copy
  notify-send -i camera-photo-symbolic "QR Code Scanned" "Copied to clipboard:\n$RESULT"
else
  notify-send -u normal -i dialog-warning "QR Scanner" "No QR code found in selection."
fi
