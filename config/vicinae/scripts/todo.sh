#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Todo
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Productivity
# @raycast.icon 󰄲

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

if ! command -v todoist >/dev/null 2>&1; then
  notify-send -u critical -i dialog-warning "Todo" "todoist CLI is not installed"
  exit 1
fi

# Check if authenticated
if ! todoist l >/dev/null 2>&1; then
  ACTION=$(printf "Log in to Todoist (open terminal)\n" | vicinae dmenu --placeholder "Todoist requires your API Token")
  if [ -n "$ACTION" ]; then
    alacritty -e bash -c 'echo "Get your API token from: https://todoist.com/prefs/integrations"; echo; todoist; echo; read -p "Press Enter to close..."'
  fi
  exit 0
fi

MENU_ITEMS=""

# 1. Fetch tasks, skip header (tail)
# 2. Strip all hidden ANSI color codes (sed)
CLEAN_OUTPUT=$(todoist l 2>/dev/null | tail -n +2 | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')

if [ -n "$CLEAN_OUTPUT" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    # First column is the UUID
    ID=$(echo "$line" | awk '{print $1}')
    
    # Remove the UUID, then strip the Priority (e.g. "p4") and Project (e.g. "#Inbox") from the front
    DISPLAY_TEXT=$(echo "$line" | awk '{$1=""; print $0}' | xargs | sed -E 's/^p[1-4] #[^ ]+ //')
    
    if [ -n "$ID" ] && [ -n "$DISPLAY_TEXT" ]; then
      MENU_ITEMS+="[ ] $DISPLAY_TEXT | $ID"$'\n'
    fi
  done <<< "$CLEAN_OUTPUT"
fi

MENU_ITEMS+="+ Add New Task"$'\n'
MENU_ITEMS+=" Sync Now"$'\n'

SELECTED=$(printf "%s" "$MENU_ITEMS" | vicinae dmenu --placeholder "Select task to complete, or add a new one...")

[ -z "$SELECTED" ] && exit 0

case "$SELECTED" in
*"+ Add New Task"*)
  TITLE=$(vicinae dmenu --placeholder "e.g. 'Buy milk tomorrow at 5pm' (Natural language supported!)")
  if [ -n "$TITLE" ]; then
    notify-send -i view-refresh-symbolic "Todo" "Adding task..."
    todoist a "$TITLE" >/dev/null 2>&1
    todoist sync >/dev/null 2>&1
    notify-send -i checkbox-checked-symbolic "Todo" "Created: $TITLE"
    # Instantly relaunch the script to show the new list!
    exec "$0"
  fi
  ;;
*"Sync Now"*)
  notify-send -i view-refresh-symbolic "Todo" "Syncing Todoist..."
  if todoist sync >/dev/null 2>&1; then
    notify-send -i view-refresh-symbolic "Todo" "Sync completed"
  else
    notify-send -u critical -i dialog-warning "Todo" "Sync failed"
  fi
  # Instantly relaunch the script to show the fresh list!
  exec "$0"
  ;;
*" | "*)
  ID=$(echo "$SELECTED" | awk -F ' \\| ' '{print $NF}')
  TITLE=$(echo "$SELECTED" | awk -F ' \\| ' '{print $1}' | sed -E 's/^\[ \] //')
  if [ -n "$ID" ]; then
    todoist c "$ID" >/dev/null 2>&1
    notify-send -i checkbox-checked-symbolic "Todo" "Completed: $TITLE"
    # Sync in the background so the server registers it
    todoist sync >/dev/null 2>&1 &
  fi
  ;;
esac
