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

set -e
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

DOTFILES_DIR="$HOME/nixos-dotfiles"
cd "$DOTFILES_DIR" || exit 1

notify() {
  local urgency="$1"
  local title="$2"
  local msg="$3"
  notify-send -u "$urgency" -i system-software-update "$title" "$msg"
}

notify "normal" "System Update" "Checking for updates..."

# 1. Update flake inputs
echo "==> Updating flake inputs..."
nix flake update

# 2. Inspect update requirements (dry-run)
echo "==> Inspecting update requirements..."
DRY_RUN=$(nix build .#nixosConfigurations.nixos-btw.config.system.build.toplevel --dry-run 2>&1 || true)

BUILD_COUNT=$(echo "$DRY_RUN" | awk '/derivations will be built:/ {print $2}' || echo "0")
BUILD_COUNT=${BUILD_COUNT:-0}

# Filter out standard NixOS environment & system wrapper derivations
CUSTOM_BUILDS=$(echo "$DRY_RUN" | grep -E '\.drv$' | grep -vE '(etc-|unit-|X-Restart|hm-|nixos-system|system-path|user-environment)' || true)

if [ -n "$CUSTOM_BUILDS" ]; then
  if ! gh auth status >/dev/null 2>&1; then
    notify "critical" "Update Failed" "GitHub CLI ('gh') is not logged in. Run 'gh auth login' in a terminal."
    exit 1
  fi

  notify "normal" "System Update" "Heavy compilation needed ($BUILD_COUNT packages). Offloading to GitHub..."

  git add flake.lock
  git commit -m "chore(flake): lockfile update" || true
  git push origin HEAD || true

  if ! gh workflow run maintenance.yml; then
    notify "critical" "Update Failed" "Could not trigger maintenance.yml on GitHub."
    exit 1
  fi

  sleep 5
  RUN_ID=$(gh run list --workflow=maintenance.yml --limit 1 --json databaseId -q '.[0].databaseId')

  notify "normal" "System Update" "Cloud build running on GitHub"

  if ! gh run watch "$RUN_ID" --exit-status; then
    notify "critical" "Update Failed" "Cloud build failed! Check 'gh run view' for details."
    exit 1
  fi

  notify "normal" "System Update" "Cloud build passed! Pulling lockfile..."
  git pull --rebase
else
  echo "==> All heavy packages have pre-built binaries available. Skipping cloud build!"
fi

# 3. Fast parallel background download (pre-stage all closures into /nix/store)
notify "normal" "System Update" "Downloading pre-built binaries..."
nix build .#nixosConfigurations.nixos-btw.config.system.build.toplevel --no-link

# 4. Instant activation switch (packages are already downloaded on SSD)
notify "normal" "System Update" "Applying update..."
if ! sudo nixos-rebuild switch --flake "$DOTFILES_DIR#nixos-btw"; then
  notify "critical" "Update Failed" "Local switch failed. Run 'nrs' to inspect errors."
  exit 1
fi

# 5. Clean unused store garbage and optimize
sudo nix-collect-garbage -d >/dev/null 2>&1
sudo nix-store --optimise >/dev/null 2>&1

notify "normal" "System Update Complete" "System upgraded successfully! ✨"
