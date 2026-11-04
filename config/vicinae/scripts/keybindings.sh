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

# Config file for action descriptions (key=value format, one per line)
ACTION_DESC_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/vicinae/keybinding-descriptions.conf"

CHOICE=$(python3 - << 'PYEOF' | vicinae dmenu --placeholder "Search keybindings (e.g. terminal, screenshot, workspace)..."
import json
import os
import re
import subprocess
import sys

# Key code to symbol mapping
KEYCODE_MAP = {
    10: "1", 11: "2", 12: "3", 13: "4", 14: "5",
    15: "6", 16: "7", 17: "8", 18: "9", 19: "0",
    49: "^",
}

# Load custom action descriptions from config file
ACTION_DESC = {}
desc_file = os.path.expanduser("~/.config/vicinae/keybinding-descriptions.conf")
if os.path.exists(desc_file):
    with open(desc_file, "r") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                ACTION_DESC[k.strip()] = v.strip()

KEY_MAP = {
    "return": "󰌑", "enter": "󰌑", "space": "󱁐", "escape": "󱊷", "esc": "󱊷",
    "backspace": "󰁮", "tab": "󰌒", "print": "󰹑", "grave": "^", "slash": "/",
    "question": "?", "xf86audioraisevolume": "󰕾", "xf86audiolowervolume": "󰝝",
    "xf86audiomute": "󰝟", "xf86audioplay": "󰐊", "xf86audionext": "󰒭",
    "xf86audioprev": "󰒮", "xf86monbrightnessup": "󰃠", "xf86monbrightnessdown": "󰃟",
    "xf86display": "󰍹", "mouse:272": "󰍽 L", "mouse:273": "󰍽 R",
}

for i in range(10, 20):
    KEY_MAP[f"code:{i}"] = KEYCODE_MAP[i]
KEY_MAP["code:49"] = "^"

MOD_ICONS = {
    "SUPER": "󰘳", "MOD4": "󰘳", "CTRL": "󰘴", "CONTROL": "󰘴",
    "ALT": "󰘵", "MOD1": "󰘵", "SHIFT": "󰘶",
}

def decode_modmask(mask):
    parts = []
    if mask & 64: parts.append("󰘳")
    if mask & 4:  parts.append("󰘴")
    if mask & 8:  parts.append("󰘵")
    if mask & 1:  parts.append("󰘶")
    return parts

def parse_mods_str(raw_mods):
    tokens = raw_mods.upper().replace("+", " ").split()
    return [MOD_ICONS[t] for t in tokens if t in MOD_ICONS]

def format_key(key_raw):
    k = key_raw.strip().lower()
    if k in KEY_MAP:
        return KEY_MAP[k]
    if k.startswith("code:"):
        try:
            num = int(k.split(":")[1])
            return KEYCODE_MAP.get(num, f"Key {num}")
        except ValueError:
            pass
    if len(key_raw.strip()) == 1:
        return key_raw.strip().upper()
    return key_raw.strip().title()

def describe_action(dispatcher, arg):
    """Generate human-readable description for a hyprland dispatcher action."""
    disp = dispatcher.strip().lower()
    arg = arg.strip()

    # Check custom descriptions first
    custom_key = f"{disp}:{arg}"
    if custom_key in ACTION_DESC:
        return ACTION_DESC[custom_key]
    if disp in ACTION_DESC:
        return ACTION_DESC[disp]

    # Built-in descriptions for common actions
    if disp == "exec":
        arg_lower = arg.lower()
        if "alacritty" in arg_lower: return "󰞷 Launch Terminal (Alacritty)"
        if "firefox" in arg_lower: return "󰈹 Launch Web Browser (Firefox)"
        if "thunar" in arg_lower: return "󰉋 Launch File Manager (Thunar)"
        if "vicinae toggle" in arg_lower: return "󰍜 Toggle Vicinae Launcher"
        if "clipboard/history" in arg_lower: return "󰅌 Open Clipboard History"
        if "hyprpicker" in arg_lower: return "󰈊 Color Picker (Hyprpicker)"
        if "keybindings.sh" in arg_lower: return "󰌌 View Keybindings Cheat Sheet"
        if "qr-scanner" in arg_lower: return "󰄀 Scan QR Code from Screen"
        if "ocr.sh" in arg_lower: return "󰎔 Extract Text from Screen (OCR)"
        if "web-search" in arg_lower: return "󰜎 Quick Web Search"
        if "display-mode" in arg_lower: return "󰍹 Display Projection / Monitor Mode"
        if "wl-clicker" in arg_lower: return "󰍽 Toggle Autoclicker"
        if "grim -g" in arg_lower or "slurp" in arg_lower: return "󰹑 Screenshot Selection to Clipboard"
        if "grim" in arg_lower: return "󰹑 Screenshot Entire Screen to Clipboard"
        if "pamixer -i" in arg_lower: return "󰕾 Volume Up (+5%)"
        if "pamixer -d" in arg_lower: return "󰝝 Volume Down (-5%)"
        if "pamixer -t" in arg_lower: return "󰝟 Toggle Audio Mute"
        if "playerctl play-pause" in arg_lower: return "󰐊 Media Play / Pause"
        if "playerctl next" in arg_lower: return "󰒭 Media Next Track"
        if "playerctl previous" in arg_lower: return "󰒮 Media Previous Track"
        if "brightnessctl" in arg_lower and "+" in arg_lower: return "󰃠 Brightness Up (+5%)"
        if "brightnessctl" in arg_lower and "-" in arg_lower: return "󰃟 Brightness Down (-5%)"
        return f"󰅂 Run: {arg}"

    builtin = {
        "killactive": "󰅖 Close Active Window",
        "exit": "󰗼 Exit Hyprland (Logout)",
        "togglefloating": "󰉈 Toggle Floating Window",
        "fullscreen": "󰊓 Toggle Fullscreen",
        "togglespecialworkspace": f"󱂬 Toggle Scratchpad ({arg.capitalize()})",
        "movefocus": {"l": "Left 󰁍", "r": "Right 󰁔", "u": "Up 󰁝", "d": "Down 󰁅"}.get(arg, f"Focus Window {arg}"),
        "movewindow": {"l": "Left 󰁍", "r": "Right 󰁔", "u": "Up 󰁝", "d": "Down 󰁅"}.get(arg, f"Move Window {arg}") if arg not in ["", "mouse:272"] else "󰆾 Move Window (Mouse Drag)",
        "resizewindow": "󰩨 Resize Window (Mouse Drag)",
        "resizeactive": lambda a: {
            True: "󰩨 Resize Window (Expand Width)" if int(a.split()[0]) > 0 else "󰩨 Resize Window (Shrink Width)" if int(a.split()[0]) < 0 else
                 "󰩨 Resize Window (Expand Height)" if int(a.split()[1]) > 0 else "󰩨 Resize Window (Shrink Height)" if int(a.split()[1]) < 0 else f"󰩨 Resize Window ({a})"
        }.get(False, f"󰩨 Resize Window ({a})"),
        "workspace": f"󰄰 Switch to Workspace {arg}",
        "movetoworkspace": f"󰪹 Move Window to Workspace {arg}",
    }

    if disp in builtin:
        val = builtin[disp]
        return val(arg) if callable(val) else val

    return f"{disp} {arg}".strip()

def collect_binds():
    entries = []
    seen = set()

    # Config files to check (in order of preference)
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
                        raw_mods, raw_key, dispatcher = parts[0], parts[1], parts[2]
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

    # Also query hyprctl for runtime binds
    try:
        res = subprocess.run(["hyprctl", "-j", "binds"], capture_output=True, text=True, timeout=1.5)
        if res.returncode == 0:
            for b in json.loads(res.stdout):
                mods = decode_modmask(b.get("modmask", 0))
                k, kc = b.get("key", ""), b.get("keycode", -1)
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
    padded_combo = f"{combo:<18}"
    print(f"{padded_combo} │  {desc}")
PYEOF
)

[ -z "$CHOICE" ] && exit 0

COMBO=$(echo "$CHOICE" | awk -F '│' '{print $1}' | sed -e 's/[[:space:]]*$//')
DESC=$(echo "$CHOICE" | awk -F '│' '{print $2}' | sed -e 's/^[[:space:]]*//')

printf "%s" "$COMBO" | wl-copy
notify-send -i input-keyboard "Keybinding Copied" "$COMBO\n$DESC"