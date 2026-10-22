# /doctor — Fleet Hardware, Firmware & Mesh Diagnostics

Automated diagnostic suite for inspecting host optimization, firmware microcode, hardware health, and inter-node Tailnet mesh reachability.

Usage:
```bash
/doctor [--all | --hardware | --mesh | --firmware]
```
CLI binary: `nfp-doctor [--all | --hardware | --mesh | --firmware]`

---

## Pass 1: Hardware & Firmware Optimization Audit

Inspects local node hardware baseline, kernel tuning, and thermal health:

1. **CPU Governor**: Inspects active governor (`schedutil` or `performance`). Flags power-throttled states.
2. **Microcode Loading**: Confirms AMD/Intel CPU microcode revision loaded early in boot.
3. **Thermal Throttling**: Checks MSR / sysfs thermal throttling event counters (`/sys/devices/system/cpu/cpu*/thermal_throttle/*`).
4. **GPU Acceleration**: Verifies DRM render nodes (`/dev/dri/renderD*`) and driver acceleration.
5. **SSD Health & TRIM**: Audits `fstrim.timer` status and Btrfs corruption / I/O error counters via `btrfs device stats`.
6. **Battery & Power Profiles**: For mobile workstations (`z0r0`, laptops), audits battery capacity, health degradation percentage, and power profile.

---

## Pass 2: Inter-Node Mesh Reachability & Latency Matrix

Probes the end-to-end Tailnet communication fabric across all fleet machines:

1. **Tailscale Daemon Status**: Verifies local daemon connectivity and MagicDNS resolver state.
2. **Ping & RTT Latency Matrix**: Measures ICMP response times across fleet nodes (`z0r0.nfp.nix`, `luffy.nfp.nix`, `sanji.nfp.nix`).
3. **WireGuard Path Verification**: Differentiates direct peer-to-peer WireGuard connections from DERP relay fallbacks (`tailscale status`).
4. **Service Reachability Matrix**:
   - Brain-Service (`luffy.nfp.nix:8010`)
   - Grafana Dashboard (`luffy.nfp.nix:3008`)
   - Prometheus Metrics (`luffy.nfp.nix:9090`)
   - Loki Log Ingestion (`luffy.nfp.nix:3100`)
   - Kong Gateway (`sanji.nfp.nix:8090`)
   - Headplane Management (`sanji.nfp.nix:3050`)
   - OpenTelemetry Collector (`z0r0.nfp.nix:4318`)

---

## Output & Exit Codes

- `0`: All required health checks, hardware governors, and network reachability tests passed.
- `1`: Failures detected (offline node, degraded battery, failed systemd unit, Btrfs I/O errors).
