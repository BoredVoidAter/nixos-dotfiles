#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Screen OCR (Text Grabber)
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Utility
# @raycast.icon 󰎔

# Documentation:
# @raycast.description Extract unselectable text from anywhere on the screen
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v tesseract >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "OCR Scanner" "Tesseract is not installed."
  exit 1
fi

REGION=$(slurp 2>/dev/null)
[ -z "$REGION" ] && exit 0

TMP_FILE=$(mktemp --suffix=.png)
grim -g "$REGION" "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
  rm -f "$TMP_FILE"
  exit 0
fi

notify-send -t 1500 -i text-x-generic "OCR" "Extracting text..."

tesseract "$TMP_FILE" stdout 2>/dev/null | awk '{if (NR>1) print prev; prev=$0} END {printf "%s", prev}' | wl-copy

rm -f "$TMP_FILE"

PREVIEW=$(wl-paste | head -c 50)
if [ -n "$PREVIEW" ]; then
  notify-send -i edit-copy "OCR Complete" "Text copied to clipboard:\n\"$PREVIEW...\""
else
  notify-send -u normal -i dialog-warning "OCR" "No text could be identified."
fi
