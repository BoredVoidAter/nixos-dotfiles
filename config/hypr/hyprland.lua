-- ============================================================================
-- Hyprland 0.57+ Configuration
-- Translated from legacy hyprland.conf
-- ============================================================================

local mainMod = "SUPER"

-- ----------------------------------------------------------------------------
-- Environment & NVIDIA Driver Fixes
-- ----------------------------------------------------------------------------
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("AQ_DRM_DEVICES", "/dev/dri/card0:/dev/dri/card1")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("GTK_THEME", "Matcha-dark-aliz")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- ----------------------------------------------------------------------------
-- Monitor Configuration
-- ----------------------------------------------------------------------------
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- ----------------------------------------------------------------------------
-- General Settings, Decoration & Layout
-- ----------------------------------------------------------------------------
hl.config({
	cursor = {
		no_hardware_cursors = true,
	},
	input = {
		kb_layout = "de",
		repeat_rate = 28,
		repeat_delay = 200,
		follow_mouse = 1,
		touchpad = {
			natural_scroll = false,
			tap_to_click = true,
		},
	},
	general = {
		gaps_in = 5,
		gaps_out = 5,
		border_size = 0,
		col = {
			active_border = "rgba(4c50bcff)",
			inactive_border = "rgba(1e1f25ff)",
		},
		layout = "dwindle",
		resize_on_border = true,
		extend_border_grab_area = 24,
		hover_icon_on_border = true,
	},
	decoration = {
		rounding = 12,
		blur = {
			enabled = true,
			size = 6,
			passes = 3,
		},
		shadow = {
			enabled = true,
			range = 20,
			render_power = 4,
			color = "rgba(07080aee)",
		},
	},
	dwindle = {
		preserve_split = true,
	},
	animations = {
		enabled = true,
	},
})

-- ----------------------------------------------------------------------------
-- Touch Gestures (Touchscreen & Touchpad)
-- ----------------------------------------------------------------------------
hl.gesture({ fingers = 3, direction = "pinch", action = "resize" })

-- ----------------------------------------------------------------------------
-- Animations & Curves
-- ----------------------------------------------------------------------------
hl.curve("myBezier", {
	type = "bezier",
	points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

-- ----------------------------------------------------------------------------
-- Autostart Daemons & Apps (exec-once)
-- ----------------------------------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR GTK_THEME XCURSOR_THEME XCURSOR_SIZE QT_QPA_PLATFORMTHEME"
	)
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("cbatticon")
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("polkit-gnome-agent")
	hl.exec_cmd("vicinae server")
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd("comms-scratchpad")
end)

-- ----------------------------------------------------------------------------
-- Window Rules & Scratchpads
-- ----------------------------------------------------------------------------
-- Unified Comms TUI Scratchpad (WhatsApp, Telegram, Discord, Gmail)
hl.window_rule({
	name = "comms-scratchpad",
	match = { class = "^(comms-scratchpad)$" },
	workspace = "special:comms silent",
	float = true,
	size = "85% 85%",
	center = true,
})

-- Music TUI Scratchpad (ytm-player)
hl.window_rule({
	name = "music-scratchpad",
	match = { class = "^(music-scratchpad)$" },
	workspace = "special:music silent",
	float = true,
	size = "80% 80%",
	center = true,
})

-- Waypaper Wallpaper Picker
hl.window_rule({
	name = "waypaper",
	match = { class = "^([Ww]aypaper)$" },
	float = true,
	size = "65% 65%",
	center = true,
})

-- UltraStar
hl.window_rule({
	name = "ultrastar-rules",
	match = { title = "^(UltraStar.*)$" },
	float = true,
	center = true,
})

-- ----------------------------------------------------------------------------
-- Keybindings: Core Applications & Window Management
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("alacritty"))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("librewolf"))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Scratchpads
hl.bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("comms"))
hl.bind(mainMod .. " + code:49", hl.dsp.workspace.toggle_special("comms"))
hl.bind(mainMod .. " + grave", hl.dsp.workspace.toggle_special("comms"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("music-toggle"))

-- Tools & Scripts
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/power-mode.sh --toggle"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/power-mode.sh"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/display-mode.sh"))
hl.bind("XF86Display", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/display-mode.sh"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("vicinae deeplink vicinae://launch/clipboard/history"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/qr-scanner.sh"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/ocr.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("bash ~/.config/vicinae/scripts/web-search.sh"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("wl-clicker toggle"))

-- Audio & Brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })

-- Focus Movement (Vim keys)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Window Movement (Shift + Vim keys)
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Smooth Live Resizing (Super + Ctrl + Vim keys)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Mouse Controls (LMB = Drag, RMB = Resize)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ----------------------------------------------------------------------------
-- Workspaces 1-10 (Hardware keycodes 10-19)
-- ----------------------------------------------------------------------------
for i = 1, 10 do
	local code = 9 + i -- 1 -> code:10, ..., 10 -> code:19
	hl.bind(mainMod .. " + code:" .. code, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + code:" .. code, hl.dsp.window.move({ workspace = i }))
end
