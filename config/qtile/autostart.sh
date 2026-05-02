alacritty &

firefox &

copyq --start-server &

# Export Wayland variables to DBus and Systemd so portals and polkit know where to render
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=qtile
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Start the new GNOME Polkit agent
polkit-gnome-agent &
