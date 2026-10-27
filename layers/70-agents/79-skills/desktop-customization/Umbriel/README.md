# Umbriel Compositor — Architectural Overview & Integration

> Upstream Repository: [github.com/noctalia-dev/umbriel](https://github.com/noctalia-dev/umbriel)  
> Documentation: [https://docs.noctalia.dev/](https://docs.noctalia.dev/)

Umbriel is an independent Wayland compositor built specifically to pair seamlessly with Noctalia Shell. It features:
* **Hybrid Layout Engines**: Infinite scrolling columns, dwindle binary-tree tiling, and traditional master-stack layouts.
* **Modern Rendering Pipeline**: Native GPU-accelerated dual-kawase blur, drop shadows, and fluid bezier animations.
* **Dedicated IPC Protocol**: Fast UNIX domain socket with streaming JSON events.
* **Noctalia Companion Integration**: Native support for the `umbriel-companion` plugin for real-time workspace and submap synchronization.

---

## Socket & IPC Interface

Umbriel creates a UNIX domain socket at:
```bash
$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock
```
*(or via the `UMBRIEL_SOCKET` environment variable)*

### CLI Interface:
The `umbriel` binary interacts with the socket directly:

```bash
# Query current workspaces in JSON
umbriel workspaces --json

# Query active outputs
umbriel outputs --json

# Dispatch window action
umbriel dispatch close-window
umbriel dispatch toggle-floating
umbriel dispatch layout scrolling
```

Alternatively, commands can be piped over JSON using `socat`:
```bash
printf '{"cmd":"workspaces"}\n' | socat - UNIX-CONNECT:"$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock"
```
