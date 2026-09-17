# Luffy Noctalia Runtime Diagnostics (Addendum 2026-09-17)

Evaluation proves `luffy` is GUI-capable (desktop tag, experience noctalia-hyprland, hyprland+noctalia true, UWSM true, no failed assertions). Treat any black-screen/crash as runtime/session, not evaluation.

## Checklist (do not change Noctalia settings before this)
```bash
# 1. graphical-session.target
systemctl --user status graphical-session.target --no-pager -l
loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type -p Display -p State

# 2. noctalia.service journal (current boot)
journalctl --user -u noctalia.service --since "10 min ago" --no-pager | tail -n 100
journalctl --user -u noctalia.service -b --no-pager | grep -i -E "error|fail|broken pipe|wayland" | tail -n 50

# 3. UWSM/Hyprland/Noctalia process state
systemctl --user status noctalia.service --no-pager -l
systemctl --user status hypridle.service --no-pager -l
ps aux | grep -E "Hyprland|noctalia|uwsm" | grep -v grep
hyprctl instances 2>&1 | head -n 20

# 4. systemd user environment
systemctl --user show-environment | grep -E "WAYLAND_DISPLAY|XDG_RUNTIME_DIR|DBUS_SESSION_BUS_ADDRESS"
echo $WAYLAND_DISPLAY; echo $XDG_RUNTIME_DIR; echo $DBUS_SESSION_BUS_ADDRESS
ls -l /run/user/$(id -u)/noctalia.sock ~/.cache/noctalia/noctalia.sock 2>&1 | head
noctalia msg --help 2>&1 | head -n 20
```
Report exact journal error line before changing Noctalia settings.
