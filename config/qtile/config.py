from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
import os
import subprocess

mod = "mod4"
terminal = "alacritty"

# --- Autostart Hook ---
@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~')
    subprocess.Popen(['sh', home + '/.config/qtile/autostart.sh'])

keys = [
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "tab", lazy.layout.next(), desc="Move window focus to other window"),
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "space", lazy.spawn("rofi -show drun -show-icons"), desc='Run Launcher'),
    Key(
        [mod], 
        "s",
        lazy.spawn('sh -c "maim -s | xclip -selection clipboard -t image/png -i"'),
        desc="Screenshot"
    ),
    Key([mod, "shift"], "b", lazy.spawn("firefox"), desc="Run Browser"),
    Key([mod, "shift"], "f", lazy.spawn("thunar"), desc="Run Filemanager"),

    # Volume Control
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5"), desc="Volume Up"),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5"), desc="Volume Down"),
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t"), desc="Toggle Mute"),

    # Brightness Control
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +5%")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-")),

    Key([mod], "b", lazy.spawn(terminal + " -e bluetuith"), desc="Bluetooth TUI"),
]

# Add key bindings to switch VTs in Wayland.
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

# --- GROUPS & ICONS CONFIGURATION ---
groups = [
    # 1. Terminal (Always Alacritty)
    Group("1", label="", layout="columns"), 

    # 2. Firefox (Matches firefox class)
    Group("2", label="󰈹", layout="monadtall", 
          matches=[Match(wm_class=["firefox", "Firefox", "Navigator"])]),

    Group("3", label="", layout="columns"),
    Group("4", label="", layout="columns"),
    Group("5", label="", layout="columns"),

    Group("6", label="", layout="columns"),
    Group("7", label="", layout="columns"),
    Group("8", label="", layout="columns"),
    Group("9", label="", layout="columns"),
]

for i, group in enumerate(groups):
    # Determine the key name (1, 2, 3...) based on the group name
    # We use the group name "1", "2" etc.
    key_name = group.name
    
    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                key_name,
                lazy.group[group.name].toscreen(),
                desc=f"Switch to group {group.name}",
            ),
            # mod + shift + group number = move focused window to group
            Key(
                [mod, "shift"],
                key_name,
                lazy.window.togroup(group.name),
                desc="move focused window to group {}".format(group.name),
            ),
        ]
    )

colors = [
    ["#1a1b26", "#1a1b26"],  # bg        (primary.background)
    ["#a9b1d6", "#a9b1d6"],  # fg        (primary.foreground)
    ["#32344a", "#32344a"],  # color01   (normal.black)
    ["#f7768e", "#f7768e"],  # color02   (normal.red)
    ["#9ece6a", "#9ece6a"],  # color03   (normal.green)
    ["#e0af68", "#e0af68"],  # color04   (normal.yellow)
    ["#7aa2f7", "#7aa2f7"],  # color05   (normal.blue)
    ["#ad8ee6", "#ad8ee6"],  # color06   (normal.magenta)
    ["#0db9d7", "#0db9d7"],  # color15   (bright.cyan)
    ["#444b6a", "#444b6a"]   # color[9]  (bright.black)
]

layout_theme = {
    "border_width" : 1,
    "margin" : 0, # Increased margin slightly for aesthetics
    "border_focus" : colors[6],
    "border_normal" : colors[0],
}

layouts = [
    layout.Columns(**layout_theme),
    layout.Max(),
    layout.MonadTall(**layout_theme),
]

widget_defaults = dict(
    font="JetBrainsMono Nerd Font Propo Bold",
    fontsize=16,
    padding=0,
    background=colors[0],
)

extension_defaults = widget_defaults.copy()

sep = widget.Sep(linewidth=1, padding=8, foreground=colors[9])

screens = [
    Screen(
        top=bar.Bar(
            widgets = [
                widget.GroupBox(
                    fontsize = 22, # Increased size for Icons
                    margin_y = 3,
                    margin_x = 5,
                    padding_y = 5,
                    padding_x = 5,
                    borderwidth = 3,
                    active = colors[8],
                    inactive = colors[9],
                    rounded = False,
                    highlight_color = colors[0],
                    highlight_method = "line",
                    this_current_screen_border = colors[7],
                    this_screen_border = colors [4],
                    other_current_screen_border = colors[7],
                    other_screen_border = colors[4],
                    disable_drag = True,
                ),
                widget.TextBox(
                    text = '|',
                    font = "JetBrainsMono Nerd Font Propo Bold",
                    foreground = colors[9],
                    padding = 2,
                    fontsize = 14
                ),
                widget.CurrentLayout(
                    foreground = colors[1],
                    padding = 5
                ),
                widget.TextBox(
                    text = '|',
                    font = "JetBrainsMono Nerd Font Propo Bold",
                    foreground = colors[9],
                    padding = 2,
                    fontsize = 14
                ),
                widget.WindowName(
                    foreground = colors[6],
                    padding = 8,
                    max_chars = 40,
                    markup=False,
                ),
                widget.Spacer(), # Pushes widgets to the right
                widget.Systray(padding = 6),
                sep,
                widget.CPU(
                    foreground = colors[4],
                    padding = 8, 
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(terminal + ' -e btop')},
                    format="CPU: {load_percent}%",
                ),
                sep,
                widget.Memory(
                    foreground = colors[8],
                    padding = 8, 
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(terminal + ' -e btop')},
                    format = 'Mem: {MemUsed:.0f}{mm}',
                ),
                sep,
                widget.GenPollText(
                    update_interval = 0.1,
                    func = lambda: subprocess.check_output("pamixer --get-volume-human", shell=True, text=True).strip(),
                    foreground = colors[7],
                    padding = 8,
                    fmt = 'Vol: {}',
                    mouse_callbacks = {
                        'Button1': lambda: qtile.cmd_spawn("pamixer -t"), # Click to mute
                        'Button4': lambda: qtile.cmd_spawn("pamixer -i 5"), # Scroll up
                        'Button5': lambda: qtile.cmd_spawn("pamixer -d 5"), # Scroll down
                    }
                ), 
                sep,
                widget.Clock(
                    foreground = colors[8],
                    padding = 8, 
                    mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('notify-date')},
                    format = "%a, %b %d - %H:%M",
                ),
                widget.Spacer(length = 8),
            ],
            margin=[0, 0, 0, 0], 
            size=30
        ),
        wallpaper='/home/boredvoidater/Pictures/wallpaper.png',
        wallpaper_mode='fill',    
    ),
]

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
        # Added specific float rules for potential popups
        Match(wm_class="pavucontrol"),
        Match(wm_class="nm-connection-editor"),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wl_xcursor_theme = None
wl_xcursor_size = 24
wmname = "LG3D"
