from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy
import os
import subprocess
import time
import json

mod = "mod4"
terminal = "alacritty"
browser = "firefox"

colors = [
    ["#0D0D0D", "#0D0D0D"], # 0 bg (Dark Background)
    ["#D9BC9A", "#D9BC9A"], # 1 fg (Tan Text)
    ["#0D0D0D", "#0D0D0D"], # 2 black
    ["#590202", "#590202"], # 3 red (Dark Red Accent)
    ["#BF8845", "#BF8845"], # 4 green (Mapped to Gold)
    ["#BF8845", "#BF8845"], # 5 yellow (Gold)
    ["#23A5D9", "#23A5D9"], # 6 blue (Light Blue)
    ["#23A5D9", "#23A5D9"], # 7 magenta (Mapped to Light Blue)
    ["#23A5D9", "#23A5D9"], # 8 cyan (Mapped to Light Blue)
    ["#D9BC9A", "#D9BC9A"]  # 9 bright black (Mapped to Tan)
]

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~')
    subprocess.Popen(['sh', home + '/.config/qtile/autostart.sh'])

keys = [
    # Window navigation
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "Tab", lazy.layout.next(), desc="Move window focus to other window"),

    # Window moving
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Window resizing
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    # Layouts and essential spawns
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle split"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    
    # Apps
    Key([mod], "space", lazy.spawn("rofi -show drun -show-icons"), desc='Run Launcher'),
    Key([mod, "shift"], "b", lazy.spawn("firefox"), desc="Run Browser"),
    Key([mod, "shift"], "f", lazy.spawn("thunar"), desc="Run Filemanager"),

    # Multimedia Keys
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5")),
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t")),
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +5%")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-")),

    # Workspace iteration
    Key([mod], "period", lazy.screen.next_group(), desc="Next Workspace"),
    Key([mod], "comma", lazy.screen.prev_group(), desc="Prev Workspace"),
    
    # Utilities
    Key([mod], "s", lazy.spawn("flameshot gui"), desc="Screenshot (Flameshot)"),
]

# VT switching setup for Wayland (if applicable)
for vt in range(1, 8):
    keys.append(Key(["control", "mod1"], f"f{vt}", lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland")))

groups = []
workspace_labels = ["", "󰈹", "", "", "", "", "", "", ""]

for i in range(1, 10):
    groups.append(Group(name=str(i), label=workspace_labels[i-1], layout="columns"))

for i in groups:
    keys.extend([
        # mod + letter of group = switch to group
        Key([mod], i.name, lazy.group[i.name].toscreen(), desc="Switch to group {}".format(i.name)),
        # mod + shift + letter of group = switch to & move focused window to group
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True), desc="Switch to & move focused window to group {}".format(i.name)),
    ])

layout_theme = {
    "border_width": 1,
    "margin": 0, 
    "border_focus": colors[6],
    "border_normal": colors[0],
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

sep = widget.Sep(linewidth=1, padding=10, foreground=colors[9])

screens = [
    Screen(
        top=bar.Bar(
            widgets=[
                # NixOS Icon launcher button
                widget.TextBox(
                    text=" ",
                    foreground=colors[6],
                    padding=15,
                    fontsize=20,
                    mouse_callbacks={'Button1': lambda: qtile.cmd_spawn("rofi -show drun -show-icons")}
                ),
                
                widget.GroupBox(
                    fontsize=20,
                    margin_y=3,
                    margin_x=5,
                    padding_y=5,
                    padding_x=5,
                    borderwidth=3,
                    active=colors[8],
                    inactive=colors[9],
                    rounded=False,
                    highlight_color=colors[0],
                    highlight_method="line",
                    this_current_screen_border=colors[7],
                    this_screen_border=colors[4],
                    other_current_screen_border=colors[7],
                    other_screen_border=colors[4],
                    disable_drag=True,
                ),

                widget.TextBox(text='|', foreground=colors[9], padding=2, fontsize=14),
                widget.CurrentLayout(foreground=colors[1], padding=5),
                widget.TextBox(text='|', foreground=colors[9], padding=2, fontsize=14),
                
                widget.WindowName(
                    foreground=colors[6],
                    padding=8,
                    max_chars=40,
                    markup=False,
                ),
                
                widget.Spacer(),
                
                widget.Systray(padding=6),
                sep,
                
                # Network activity
                widget.Net(
                    foreground=colors[5],
                    padding=8,
                    format='↓ {down:6.2f}{down_suffix:<2} ↑ {up:6.2f}{up_suffix:<2}',
                    mouse_callbacks={'Button1': lambda: qtile.cmd_spawn(terminal + ' -e nmtui')}
                ),
                sep,

                widget.CPU(
                    foreground=colors[4],
                    padding=8,
                    mouse_callbacks={'Button1': lambda: qtile.cmd_spawn(terminal + ' -e btop')},
                    format="CPU: {load_percent}%",
                ),
                sep,
                widget.Memory(
                    foreground=colors[8],
                    padding=8,
                    mouse_callbacks={'Button1': lambda: qtile.cmd_spawn(terminal + ' -e btop')},
                    format='Mem: {MemUsed:.0f}{mm}',
                ),
                sep,
                widget.PulseVolume(
                    foreground=colors[7],
                    padding=8,
                    fmt='Vol: {}',
                    update_interval=0.1,
                    mouse_callbacks={
                        'Button1': lambda: qtile.cmd_spawn("pamixer -t"),
                        'Button4': lambda: qtile.cmd_spawn("pamixer -i 5"),
                        'Button5': lambda: qtile.cmd_spawn("pamixer -d 5"),
                    }
                ),
                sep,
                widget.Clock(
                    foreground=colors[8],
                    padding=8,
                    mouse_callbacks={'Button1': lambda: qtile.cmd_spawn('notify-date')},
                    format="%a, %b %d - %H:%M",
                ),
                widget.Spacer(length=8),
            ],
            margin=[0, 0, 0, 0],
            size=30
        ),
        wallpaper='/home/boredvoidater/Pictures/wallpaper.jpg',
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
        Match(wm_class="pavucontrol"),
        Match(wm_class="nm-connection-editor"),
        Match(title="UnityDropShadowWindow"),    # Unity dropdowns/menus
        Match(wm_class="Unity", title="Unity"),  # General Unity popups/color pickers
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

TRACKED_APPS = {
    "kicad": "PCB Design",
    "pcbnew": "PCB Design",
    "eeschema": "PCB Design",
    "gerbview": "PCB Design",
    "de-neemann-digital-gui-Main": "Digital Logic",
    "Onshape": "CAD",
    "Blender": "3D Modeling",
    "OpenSCAD": "Code",
    "Unity": "Game Dev",
    "Rider": "Code",
    "jetbrains-rider": "Code",
    "code": "Code",
    "nvim": "Code",
    "neovim": "Code",
}

LOG_FILE = "/tmp/qtile_wakatime.log"

def log_debug(message):
    """Simple file logger for debugging"""
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")
    except:
        pass

def get_hackatime_state():
    """Reads the JSON state file managed by the hackatime-control script"""
    home = os.path.expanduser('~')
    state_file = os.path.join(home, '.config', 'hackatime-tracker', 'state.json')
    
    if not os.path.exists(state_file):
        return None
        
    try:
        with open(state_file, 'r') as f:
            return json.load(f)
    except:
        return None

def send_heartbeat(entity, category, project_name):
    """Sends a heartbeat to Hackatime via CLI"""
    log_debug(f"Sending heartbeat: Project={project_name}, Entity={entity}, Cat={category}")
    subprocess.Popen([
        "wakatime-cli",
        "--entity", entity,
        "--entity-type", "app",
        "--category", "designing", 
        "--language", category,
        "--project", project_name,
        "--plugin", "qtile-nixos-watcher",
        "--write"
    ])

def check_active_window(qtile):
    """Checks the currently focused window and logs time if applicable"""
    try:
        state = get_hackatime_state()
        if not state or not state.get('active', False):
            log_debug("Tracking paused.")
            return

        current_project = state.get('current', 'General')
        window = qtile.current_window
        
        if not window:
            return

        wm_class = window.get_wm_class() 
        wm_name = window.name
        
        matched = False

        if wm_class:
            for cls in wm_class:
                lower_cls = cls.lower()
                for key, category in TRACKED_APPS.items():
                    if key.lower() in lower_cls:
                        send_heartbeat(wm_name or cls, category, current_project)
                        matched = True
                        break
                if matched: break

        if not matched and wm_name:
            lower_name = wm_name.lower()
            if "onshape" in lower_name:
                send_heartbeat("Onshape", "CAD", current_project)
            elif "digital" in lower_name:
                send_heartbeat("Digital", "Digital Logic", current_project)

    except Exception as e:
        log_debug(f"Error in check_active_window: {e}")

def poll_wakatime():
    check_active_window(qtile)
    qtile.call_later(120, poll_wakatime)

@hook.subscribe.startup_complete
def start_polling():
    poll_wakatime()

@hook.subscribe.client_focus
def on_focus_change(window):
    check_active_window(qtile)
