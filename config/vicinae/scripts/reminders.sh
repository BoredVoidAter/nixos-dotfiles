#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reminders
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Productivity
# @raycast.icon 󰄲

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v todoist >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "Todoist" "todoist CLI is not installed"
  exit 1
fi

# Check if authenticated
if ! todoist l >/dev/null 2>&1; then
  ACTION=$(printf "󰌆 Log in to Todoist (open terminal)\n" | vicinae dmenu --placeholder "Todoist requires your API Token")
  if [ -n "$ACTION" ]; then
    alacritty -e bash -c 'echo "Get your API token from: https://todoist.com/prefs/integrations"; echo; todoist; echo; read -p "Press Enter to close..."'
  fi
  exit 0
fi

MENU_ITEMS=""

# Fetch tasks. Use tail to strip the table header.
RAW_OUTPUT=$(todoist --color=false l 2>/dev/null | tail -n +2)

if [ -n "$RAW_OUTPUT" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Todoist outputs a table where the first column is the numeric ID
    if [[ "$line" =~ ^([0-9]+) ]]; then
      ID="${BASH_REMATCH[1]}"
      # Extract everything after the ID, compress multiple spaces, and strip leading/trailing spaces
      DISPLAY_TEXT=$(echo "$line" | sed -E 's/^[0-9]+(.*)/\1/' | xargs)
      MENU_ITEMS+="$(printf "󰄱 %s | %s\n" "$DISPLAY_TEXT" "$ID")"
    fi
  done <<< "$RAW_OUTPUT"
fi

MENU_ITEMS+="$(printf "󰐕 + Add New Reminder\n")"

SELECTED=$(printf "%s" "$MENU_ITEMS" | vicinae dmenu --placeholder "Select task to complete, or add a new one...")

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
*"+ Add New Reminder"*)
  TITLE=$(vicinae dmenu --placeholder "e.g. 'Buy milk tomorrow at 5pm' (Natural language supported!)")
  if [ -n "$TITLE" ]; then
    todoist a "$TITLE"
    notify-send -i checkbox-checked-symbolic "Todoist" "Created: $TITLE"
  fi
  ;;
*" | "*)
  ID=$(echo "$SELECTED" | awk -F ' \\| ' '{print $NF}')
  TITLE=$(echo "$SELECTED" | awk -F ' \\| ' '{print $1}' | sed -E 's/^󰄱 //')
  if [ -n "$ID" ]; then
    todoist c "$ID"
    notify-send -i checkbox-checked-symbolic "Todoist" "Completed: $TITLE"
  fi
  ;;
esac
