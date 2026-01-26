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

# --- CONFIGURATION ---
NUM_DESKTOPS = 4  # You have 4 total "Desktops" available (0, 1, 2, 3)

# --- COLORS ---
colors = [
    ["#1a1b26", "#1a1b26"],  # 0  bg
    ["#a9b1d6", "#a9b1d6"],  # 1  fg
    ["#32344a", "#32344a"],  # 2  black
    ["#f7768e", "#f7768e"],  # 3  red
    ["#9ece6a", "#9ece6a"],  # 4  green
    ["#e0af68", "#e0af68"],  # 5  yellow
    ["#7aa2f7", "#7aa2f7"],  # 6  blue
    ["#ad8ee6", "#ad8ee6"],  # 7  magenta
    ["#0db9d7", "#0db9d7"],  # 8  cyan
    ["#444b6a", "#444b6a"]   # 9  bright black
]

# --- AUTOSTART ---
@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~')
    subprocess.Popen(['sh', home + '/.config/qtile/autostart.sh'])

# --- DESKTOP MANAGER ---
class DesktopManager:
    def __init__(self):
        self.current_desktop = 0 # Start at Desktop 0
        self.initialized = {0}   # Desktop 0 is assumed ready (handled by autostart.sh)

    def get_group_name(self, index):
        """Returns the internal group name. 
           Desktop 0: "1", "2"... 
           Desktop 1: "D1_1", "D1_2"...
        """
        if self.current_desktop == 0:
            return str(index)
        return f"D{self.current_desktop}_{index}"

desktop_manager = DesktopManager()

def switch_desktop(direction):
    """
    direction: 1 (Next) or -1 (Prev)
    """
    def _inner(qtile):
        # 1. Calculate new index
        new_index = (desktop_manager.current_desktop + direction) % NUM_DESKTOPS
        desktop_manager.current_desktop = new_index

        # 2. Update Indicator
        widget_text = f"[ DSK {new_index} ]"
        qtile.widgets_map["desktop_indicator"].update(widget_text)

        # 3. Determine visible groups for the bar
        if new_index == 0:
            visible = [str(i) for i in range(1, 10)]
        else:
            visible = [f"D{new_index}_{i}" for i in range(1, 10)]
        
        gb = qtile.widgets_map["groupbox"]
        gb.visible_groups = visible
        gb.bar.draw()

        # 4. Check if needs initialization (Auto-spawn apps)
        if new_index not in desktop_manager.initialized:
            desktop_manager.initialized.add(new_index)
            
            # Name of Group 1 and Group 2 for this new desktop
            g1 = f"D{new_index}_1"
            g2 = f"D{new_index}_2"

            # Switch to group 2 and spawn browser
            qtile.groups_map[g2].toscreen()
            qtile.spawn(browser)
            
            # After a delay, switch to group 1 and spawn terminal
            def spawn_terminal_on_g1():
                qtile.groups_map[g1].toscreen()
                qtile.spawn(terminal)
            
            qtile.call_later(0.5, spawn_terminal_on_g1)
        else:
            # Just switch to the first workspace of that desktop
            if new_index == 0:
                qtile.groups_map["1"].toscreen()
            else:
                qtile.groups_map[f"D{new_index}_1"].toscreen()

    return _inner

def go_to_group(key_index):
    """Switch to workspace X of CURRENT desktop"""
    def _inner(qtile):
        target = desktop_manager.get_group_name(key_index)
        qtile.groups_map[target].toscreen()
    return _inner

def move_window(key_index):
    """Move window to workspace X of CURRENT desktop"""
    def _inner(qtile):
        target = desktop_manager.get_group_name(key_index)
        if qtile.current_window:
            qtile.current_window.togroup(target)
    return _inner

# --- KEYS ---
keys = [
    # Navigation
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "Tab", lazy.layout.next(), desc="Move window focus to other window"),

    # Window Moving
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Resizing
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    # Layouts & System
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle split"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    
    # Apps
    Key([mod], "space", lazy.spawn("rofi -show drun -show-icons"), desc='Run Launcher'),
    Key([mod], "s", lazy.spawn('sh -c "maim -s | xclip -selection clipboard -t image/png -i"'), desc="Screenshot"),
    Key([mod, "shift"], "b", lazy.spawn("firefox"), desc="Run Browser"),
    Key([mod, "shift"], "f", lazy.spawn("thunar"), desc="Run Filemanager"),

    # Hardware
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5")),
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t")),
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +5%")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-")),

    # --- DESKTOP MANAGEMENT ---
    # Cycle through Desktops
    Key([mod], "period", lazy.function(switch_desktop(1)), desc="Next Desktop"),
    Key([mod], "comma", lazy.function(switch_desktop(-1)), desc="Prev Desktop"),
    Key([mod], "s", lazy.spawn("flameshot gui"), desc="Screenshot (Flameshot)"),
]

# Add Wayland VT switching
for vt in range(1, 8):
    keys.append(Key(["control", "mod1"], f"f{vt}", lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland")))

# --- GROUPS ---
groups = []

# Workspace labels with icons
workspace_labels = ["", "󰈹", "", "", "", "", "", "", ""]

# 1. Desktop 0 (Standard 1-9)
for i in range(1, 10):
    groups.append(Group(name=str(i), label=workspace_labels[i-1], layout="columns"))

# 2. Desktops 1 to NUM_DESKTOPS-1
for d in range(1, NUM_DESKTOPS):
    for i in range(1, 10):
        groups.append(Group(name=f"D{d}_{i}", label=workspace_labels[i-1], layout="columns"))

# 3. Bind Keys 1-9 (Context Aware)
for i in range(1, 10):
    key_name = str(i)
    keys.extend([
        Key([mod], key_name, lazy.function(go_to_group(i))),
        Key([mod, "shift"], key_name, lazy.function(move_window(i))),
    ])

# --- LAYOUTS ---
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

# --- WIDGETS ---
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
                # DESKTOP INDICATOR
                widget.TextBox(
                    name="desktop_indicator",
                    text="[ DSK 0 ]",
                    foreground=colors[6],
                    padding=10,
                    fontsize=16,
                ),
                
                # GROUPBOX (Dynamic)
                widget.GroupBox(
                    name="groupbox",
                    visible_groups=[str(i) for i in range(1, 10)], # Start showing Desktop 0
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
                widget.GenPollText(
                    update_interval=0.1,
                    func=lambda: subprocess.check_output("pamixer --get-volume-human", shell=True, text=True).strip(),
                    foreground=colors[7],
                    padding=8,
                    fmt='Vol: {}',
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
        wallpaper='/home/boredvoidater/Pictures/wallpaper.png',
        wallpaper_mode='fill',
    ),
]

# --- MOUSE & FLOATING ---
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
    "de-neemann-digital-gui-Main": "Digital Logic", # Added exact class from your xprop
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
        # 1. Check if Tracking is Enabled
        state = get_hackatime_state()
        if not state or not state.get('active', False):
            log_debug("Tracking paused.")
            return

        current_project = state.get('current', 'General')
        window = qtile.current_window
        
        if not window:
            return

        wm_class = window.get_wm_class() # Returns a list like ['code', 'Code']
        wm_name = window.name
        
        matched = False

        # log_debug(f"Checking Window: Name='{wm_name}', Class='{wm_class}'")

        # 2. Check Window Classes
        if wm_class:
            for cls in wm_class:
                lower_cls = cls.lower()
                for key, category in TRACKED_APPS.items():
                    if key.lower() in lower_cls:
                        send_heartbeat(wm_name or cls, category, current_project)
                        matched = True
                        break
                if matched: break

        # 3. Check Window Titles (Fallback for Java apps like Digital or Web Apps)
        if not matched and wm_name:
            lower_name = wm_name.lower()
            if "onshape" in lower_name:
                send_heartbeat("Onshape", "CAD", current_project)
            # Digital Logic Sim usually has "Digital" in the title
            elif "digital" in lower_name:
                send_heartbeat("Digital", "Digital Logic", current_project)

    except Exception as e:
        log_debug(f"Error in check_active_window: {e}")

# --- HOOKS ---

# 1. Poll every 2 minutes (120 seconds) to capture duration
#    Wakatime needs periodic heartbeats to track "time spent".
def poll_wakatime():
    check_active_window(qtile)
    qtile.call_later(120, poll_wakatime)

@hook.subscribe.startup_complete
def start_polling():
    # Start the polling loop once Qtile is fully ready
    poll_wakatime()

# 2. Trigger immediately on focus change (for responsiveness)
@hook.subscribe.client_focus
def on_focus_change(window):
    check_active_window(qtile)
