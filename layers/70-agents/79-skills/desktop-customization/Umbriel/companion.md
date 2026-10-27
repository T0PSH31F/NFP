# Umbriel Companion Plugin Integration

The bridge between Noctalia Shell and the Umbriel compositor is provided by the official **Umbriel Companion** plugin (`noctalia/umbriel-companion`).

---

## 1. How the Companion Operates

1. **Service Process**: Starts in the background when Noctalia initializes within an Umbriel session.
2. **Event Streaming**: Connects to `$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock`, streaming workspace switch, window focus, layer map, and submap events.
3. **Reactive UI Updates**:
   - Updates workspace dots / pills on `noctalia-bar-*` in real time.
   - Feeds window title and active app metadata to the top status bar.
   - Syncs active monitor geometry with launcher and control center positioning.
4. **Action Proxying**: When the user clicks a workspace button or uses the interactive window switcher, the companion proxies the command directly to the Umbriel compositor socket.

---

## 2. Enabling the Companion

In NixOS / NFP, the companion plugin is declaratively fetched and linked into `~/.config/noctalia/plugins/` under `layers.layer-40.desktop.noctalia.plugins`:

```nix
layers.layer-40.desktop.noctalia.plugins = [
  "assistant-panel"
  "umbriel-companion"
  "workspace-overview"
  "screen-toolkit"
];
```

Manual verification via Noctalia IPC:
```bash
noctalia msg plugins list
# Verify umbriel-companion is active
```
