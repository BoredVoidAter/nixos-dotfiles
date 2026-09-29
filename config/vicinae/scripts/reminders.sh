#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reminders
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Productivity
# @raycast.icon 󰄲

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v todo >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "Reminders" "todoman is not installed"
  exit 1
fi

MENU_ITEMS=""
RAW_TASKS=$(todo list --raw 2>/dev/null)

if [ -n "$RAW_TASKS" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    ID=$(echo "$line" | awk '{print $1}')
    SUMMARY=$(echo "$line" | cut -d' ' -f2-)
    MENU_ITEMS+="$(printf "󰄱 [%s] %s\n" "$ID" "$SUMMARY")"
  done <<< "$RAW_TASKS"
fi

MENU_ITEMS+="$(printf "󰐕 + Add New Reminder\n󰁪  Sync Now\n")"

SELECTED=$(printf "%s" "$MENU_ITEMS" | vicinae dmenu --placeholder "Select reminder to complete or action...")

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
*"+ Add New Reminder"*)
  TITLE=$(vicinae dmenu --placeholder "Enter reminder title...")
  if [ -n "$TITLE" ]; then
    todo new "$TITLE"
    notify-send -i checkbox-checked-symbolic "Reminders" "Created: $TITLE"
    vdirsyncer sync >/dev/null 2>&1 &
  fi
  ;;
*"Sync Now"*)
  notify-send -i view-refresh-symbolic "Reminders" "Syncing with iCloud..."
  vdirsyncer sync >/dev/null 2>&1
  notify-send -i view-refresh-symbolic "Reminders" "Sync completed"
  ;;
*"["*"]"*)
  TASK_ID=$(echo "$SELECTED" | sed -E 's/.*\[([0-9]+)\].*/\1/')
  if [ -n "$TASK_ID" ]; then
    todo done "$TASK_ID"
    notify-send -i checkbox-checked-symbolic "Reminders" "Marked task #$TASK_ID completed"
    vdirsyncer sync >/dev/null 2>&1 &
  fi
  ;;
esac
