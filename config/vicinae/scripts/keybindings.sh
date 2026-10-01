#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Keybindings
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName System
# @raycast.icon 󰌌

# Documentation:
# @raycast.description Search and view all active Hyprland keyboard shortcuts
# @raycast.author BoredVoidAter

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"

CHOICE=$(python3 - << 'EOF' | vicinae dmenu --placeholder "Search keybindings (e.g. terminal, screenshot, workspace)..."
import json
import os
import re
import subprocess
import sys

KEYCODE_MAP = {
    10: "1", 11: "2", 12: "3", 13: "4", 14: "5",
    15: "6", 16: "7", 17: "8", 18: "9", 19: "0",
    49: "^",
}

KEY_MAP = {
    "return": "󰌑",
    "enter": "󰌑",
    "space": "󱁐",
    "escape": "󱊷",
    "esc": "󱊷",
    "backspace": "󰁮",
    "tab": "󰌒",
    "print": "󰹑",
    "grave": "^",
    "slash": "/",
    "question": "?",
    "xf86audioraisevolume": "󰕾",
    "xf86audiolowervolume": "󰝝",
    "xf86audiomute": "󰝟",
    "xf86audioplay": "󰐊",
    "xf86audionext": "󰒭",
    "xf86audioprev": "󰒮",
    "xf86monbrightnessup": "󰃠",
    "xf86monbrightnessdown": "󰃟",
    "xf86display": "󰍹",
    "mouse:272": "󰍽 L",
    "mouse:273": "󰍽 R",
}

for i in range(10, 20):
    KEY_MAP[f"code:{i}"] = KEYCODE_MAP[i]
KEY_MAP["code:49"] = "^"

def decode_modmask(mask):
    parts = []
    if mask & 64:
        parts.append("󰘳")
    if mask & 4:
        parts.append("󰘴")
    if mask & 8:
        parts.append("󰘵")
    if mask & 1:
        parts.append("󰘶")
    return parts

def parse_mods_str(raw_mods):
    tokens = raw_mods.upper().replace("+", " ").split()
    parts = []
    if any(t in tokens for t in ["SUPER", "MOD4"]):
        parts.append("󰘳")
    if any(t in tokens for t in ["CTRL", "CONTROL"]):
        parts.append("󰘴")
    if any(t in tokens for t in ["ALT", "MOD1"]):
        parts.append("󰘵")
    if "SHIFT" in tokens:
        parts.append("󰘶")
    return parts

def format_key(key_raw):
    k_strip = key_raw.strip().lower()
    if k_strip in KEY_MAP:
        return KEY_MAP[k_strip]
    if k_strip.startswith("code:"):
        try:
            num = int(k_strip.split(":")[1])
            return KEYCODE_MAP.get(num, f"Key {num}")
        except ValueError:
            pass
    if len(key_raw.strip()) == 1:
        return key_raw.strip().upper()
    return key_raw.strip().title()

def describe_action(dispatcher, arg):
    disp = dispatcher.strip()
    arg = arg.strip()

    if disp == "exec":
        if "alacritty" in arg:
            return "󰞷 Launch Terminal (Alacritty)"
        if "firefox" in arg:
            return "󰈹 Launch Web Browser (Firefox)"
        if "thunar" in arg:
            return "󰉋 Launch File Manager (Thunar)"
        if "vicinae toggle" in arg:
            return "󰍜 Toggle Vicinae Launcher"
        if "clipboard/history" in arg:
            return "󰅌 Open Clipboard History"
        if "hyprpicker" in arg:
            return "󰈊 Color Picker (Hyprpicker)"
        if "keybindings.sh" in arg:
            return "󰌌 View Keybindings Cheat Sheet"
        if "qr-scanner" in arg:
            return "󰄀 Scan QR Code from Screen"
        if "ocr.sh" in arg:
            return "󰎔 Extract Text from Screen (OCR)"
        if "web-search" in arg:
            return "󰜎 Quick Web Search"
        if "display-mode" in arg:
            return "󰍹 Display Projection / Monitor Mode"
        if "wl-clicker" in arg:
            return "󰍽 Toggle Autoclicker"
        if "grim -g" in arg or "slurp" in arg:
            return "󰹑 Screenshot Selection to Clipboard"
        if "grim" in arg:
            return "󰹑 Screenshot Entire Screen to Clipboard"
        if "pamixer -i" in arg:
            return "󰕾 Volume Up (+5%)"
        if "pamixer -d" in arg:
            return "󰝝 Volume Down (-5%)"
        if "pamixer -t" in arg:
            return "󰝟 Toggle Audio Mute"
        if "playerctl play-pause" in arg:
            return "󰐊 Media Play / Pause"
        if "playerctl next" in arg:
            return "󰒭 Media Next Track"
        if "playerctl previous" in arg:
            return "󰒮 Media Previous Track"
        if "brightnessctl" in arg and "+" in arg:
            return "󰃠 Brightness Up (+5%)"
        if "brightnessctl" in arg and "-" in arg:
            return "󰃟 Brightness Down (-5%)"
        return f"󰅂 Run: {arg}"

    if disp == "killactive":
        return "󰅖 Close Active Window"
    if disp == "exit":
        return "󰗼 Exit Hyprland (Logout)"
    if disp == "togglefloating":
        return "󰉈 Toggle Floating Window"
    if disp == "fullscreen":
        return "󰊓 Toggle Fullscreen"
    if disp == "togglespecialworkspace":
        return f"󱂬 Toggle Scratchpad ({arg.capitalize()})"
    if disp == "movefocus":
        dirs = {"l": "Left 󰁍", "r": "Right 󰁔", "u": "Up 󰁝", "d": "Down 󰁅"}
        return f"󰆾 Focus Window {dirs.get(arg, arg)}"
    if disp == "movewindow":
        if arg in ["", "mouse:272"]:
            return "󰆾 Move Window (Mouse Drag)"
        dirs = {"l": "Left 󰁍", "r": "Right 󰁔", "u": "Up 󰁝", "d": "Down 󰁅"}
        return f"󰪹 Move Window {dirs.get(arg, arg)}"
    if disp == "resizewindow":
        return "󰩨 Resize Window (Mouse Drag)"
    if disp == "resizeactive":
        coords = arg.split()
        if len(coords) == 2:
            try:
                dx, dy = int(coords[0]), int(coords[1])
                if dx < 0: return "󰩨 Resize Window (Shrink Width)"
                if dx > 0: return "󰩨 Resize Window (Expand Width)"
                if dy < 0: return "󰩨 Resize Window (Shrink Height)"
                if dy > 0: return "󰩨 Resize Window (Expand Height)"
            except ValueError:
                pass
        return f"󰩨 Resize Window ({arg})"
    if disp == "workspace":
        return f"󰄰 Switch to Workspace {arg}"
    if disp == "movetoworkspace":
        return f"󰪹 Move Window to Workspace {arg}"

    return f"{disp} {arg}".strip()

def collect_binds():
    entries = []
    seen = set()

    conf_paths = [
        os.path.expanduser("~/.config/hypr/hyprland.conf"),
        os.path.expanduser("~/nixos-dotfiles/config/hypr/hyprland.conf"),
    ]

    for conf in conf_paths:
        if not os.path.exists(conf):
            continue
        variables = {}
        with open(conf, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                s = line.strip()
                if not s or s.startswith("#"):
                    continue
                if s.startswith("$") and "=" in s:
                    var, val = s.split("=", 1)
                    variables[var.strip()] = val.strip()
                    continue

                m = re.match(r"^bind[a-z]*\s*=\s*(.*)", s)
                if m:
                    parts = [p.strip() for p in m.group(1).split(",")]
                    if len(parts) >= 3:
                        raw_mods = parts[0]
                        raw_key = parts[1]
                        dispatcher = parts[2]
                        arg = ",".join(parts[3:]).strip() if len(parts) > 3 else ""

                        for vk, vv in variables.items():
                            raw_mods = raw_mods.replace(vk, vv)
                            raw_key = raw_key.replace(vk, vv)

                        mods = parse_mods_str(raw_mods)
                        key = format_key(raw_key)
                        combo = " + ".join(mods + [key]) if mods else key
                        desc = describe_action(dispatcher, arg)

                        dedup_key = (combo, desc)
                        if dedup_key not in seen:
                            seen.add(dedup_key)
                            entries.append((combo, desc))
        if entries:
            break

    try:
        res = subprocess.run(["hyprctl", "-j", "binds"], capture_output=True, text=True, timeout=1.5)
        if res.returncode == 0:
            for b in json.loads(res.stdout):
                mods = decode_modmask(b.get("modmask", 0))
                k = b.get("key", "")
                kc = b.get("keycode", -1)
                if not k and kc != -1:
                    key = KEYCODE_MAP.get(kc, f"Key {kc}")
                elif b.get("mouse", False):
                    key = KEY_MAP.get(f"mouse:{k}", f"Mouse {k}")
                else:
                    key = format_key(k)

                combo = " + ".join(mods + [key]) if mods else key
                desc = describe_action(b.get("dispatcher", ""), b.get("arg", ""))

                dedup_key = (combo, desc)
                if dedup_key not in seen:
                    seen.add(dedup_key)
                    entries.append((combo, desc))
    except Exception:
        pass

    return entries

for combo, desc in collect_binds():
    padded_combo = f"{combo:<16}"
    print(f"{padded_combo} │  {desc}")
EOF
)

[ -z "$CHOICE" ] && exit 0

COMBO=$(echo "$CHOICE" | awk -F '│' '{print $1}' | sed -e 's/[[:space:]]*$//')
DESC=$(echo "$CHOICE" | awk -F '│' '{print $2}' | sed -e 's/^[[:space:]]*//')

printf "%s" "$COMBO" | wl-copy
notify-send -i input-keyboard "Keybinding Copied" "$COMBO\n$DESC"
