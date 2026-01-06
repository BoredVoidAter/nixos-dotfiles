#!/bin/sh

# 1. Terminals (Fast)
alacritty &

# 2. KeepassXC (Fast - starts minimized to tray usually if configured, or on group 5)
keepassxc &

# 3. Firefox (Heavy - wait 1s so UI settles)
sleep 1
firefox &

# 4. Obsidian (Medium - wait another 2s)
sleep 2
obsidian &

# 5. Anki (Heavy - wait another 2s)
sleep 2
anki &
