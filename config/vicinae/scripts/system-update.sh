#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Update System
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName System
# @raycast.icon 󰚰

# Documentation:
# @raycast.description Offload package builds and flake updates to GitHub Actions and Cachix, then apply locally
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

DOTFILES_DIR="$HOME/nixos-dotfiles"
cd "$DOTFILES_DIR" || exit 1

notify() {
  local urgency="$1"
  local title="$2"
  local msg="$3"
  notify-send -u "$urgency" -i system-software-update "$title" "$msg"
}

# 1. Verify GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
  notify "critical" "Update Failed" "GitHub CLI ('gh') is not logged in. Run 'gh auth login' in a terminal."
  exit 1
fi

notify "normal" "System Update" "Pushing changes and triggering cloud build..."

# 2. Push any local commits so GitHub compiles your current configuration
git push origin HEAD 2>/dev/null || true

# 3. Trigger the workflow in the cloud
if ! gh workflow run maintenance.yml; then
  notify "critical" "Update Failed" "Could not trigger maintenance.yml on GitHub."
  exit 1
fi

# 4. Wait for GitHub to queue and register the run ID
sleep 5
RUN_ID=$(gh run list --workflow=maintenance.yml --limit 1 --json databaseId -q '.[0].databaseId')

notify "normal" "System Update" "Cloud build running on GitHub (fans stay quiet)..."

# 5. Watch the build; if it fails in the cloud, abort without touching local system
if ! gh run watch "$RUN_ID" --exit-status; then
  notify "critical" "Update Failed" "Cloud build failed! Your local system was untouched."
  exit 1
fi

notify "normal" "System Update" "Cloud build passed! Downloading binaries and applying..."

# 6. Pull the flake.lock committed by GitHub Actions
git pull --rebase

# 7. Rebuild locally (downloads prebuilt binaries from Cachix & cache.nixos.org)
if ! sudo nixos-rebuild switch --flake "$DOTFILES_DIR#nixos-btw"; then
  notify "critical" "Update Failed" "Local switch failed. Run 'nrs' to inspect errors."
  exit 1
fi

# 8. Clean up unused store garbage and optimize
sudo nix-collect-garbage -d >/dev/null 2>&1
sudo nix-store --optimise >/dev/null 2>&1

notify "normal" "System Update Complete" "System upgraded successfully with 0% local build load! ✨"
