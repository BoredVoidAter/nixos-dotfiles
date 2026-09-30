#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reminders
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Productivity
# @raycast.icon 󰄲

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v icloud-reminders >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "Reminders" "icloud-reminders is not installed"
  exit 1
fi

RAW_OUTPUT=$(icloud-reminders list 2>&1)
STATUS=$?

if [ $STATUS -ne 0 ] || [ "$RAW_OUTPUT" = "AUTH_REQUIRED" ] || [ "$RAW_OUTPUT" = "2FA_REQUIRED" ]; then
  ACTION=$(printf "󰌆 Log in to iCloud (open terminal)\n" | vicinae dmenu --placeholder "iCloud session expired or not authenticated")
  if [ -n "$ACTION" ]; then
    alacritty -e icloud-reminders auth
  fi
  exit 0
fi

MENU_ITEMS=""

if [ -n "$RAW_OUTPUT" ]; then
  while IFS=$'\t' read -r guid list_name title; do
    [ -z "$guid" ] && continue
    MENU_ITEMS+="$(printf "󰄱 [%s] %s | %s\n" "$list_name" "$title" "$guid")"
  done <<< "$RAW_OUTPUT"
fi

MENU_ITEMS+="$(printf "󰐕 + Add New Reminder\n")"

SELECTED=$(printf "%s" "$MENU_ITEMS" | vicinae dmenu --placeholder "Select reminder to complete or action...")

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
*"+ Add New Reminder"*)
  TITLE=$(vicinae dmenu --placeholder "Enter reminder title...")
  if [ -n "$TITLE" ]; then
    icloud-reminders add "$TITLE"
    notify-send -i checkbox-checked-symbolic "Reminders" "Created: $TITLE"
  fi
  ;;
*" | "*)
  GUID=$(echo "$SELECTED" | awk -F ' \\| ' '{print $2}')
  TITLE=$(echo "$SELECTED" | awk -F ' \\| ' '{print $1}' | sed -E 's/^󰄱 \[[^]]*\] //')
  if [ -n "$GUID" ]; then
    icloud-reminders done "$GUID"
    notify-send -i checkbox-checked-symbolic "Reminders" "Completed: $TITLE"
  fi
  ;;
esac
