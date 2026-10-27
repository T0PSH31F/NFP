# Aesthetic Archetypes & Animation Design Systems Reference

This document catalogs reference implementations and design systems for advanced Linux ricing, informed by 11 cutting-edge open-source repositories across sci-fi, YoRHa military UI, Persona pop art, liquid glassmorphism, and anime bouncy aesthetics.

---

## 1. Catalog of Reference Implementations

### 1. Space Dots (`vdawg-git/space_dots`)
* **Repository**: [https://github.com/vdawg-git/space_dots](https://github.com/vdawg-git/space_dots)
* **Design Core**: Space exploration, celestial minimalism, deep cosmos starfields, orbital HUD geometry.
* **Color Palette**:
  - Deep Space Void: `#0B0E14`
  - Nebula Slate: `#1B2234`
  - Starlight Blue: `#5C78E6`
  - Aurora Ice: `#93B4FA`
  - Cosmic Dust: `#E0E6F8`
* **Key Mechanics**:
  - Floating micro-bars with thin borders (`1px`) and rounded pill capsules (`radius = 12`).
  - Orbital battery/cpu radial gauges.
  - Smooth starfield wallpaper shaders and particle drift animations.

---

### 2. YoRHa GRUB & Military Bootloader (`OliveThePuffin/yorha-grub-theme`)
* **Repository**: [https://github.com/OliveThePuffin/yorha-grub-theme](https://github.com/OliveThePuffin/yorha-grub-theme)
* **Design Core**: NieR:Automata military terminal UI, mission dispatch screens, monochrome tactical styling.
* **Visual Elements**:
  - Scanlines and phosphor CRT grain.
  - Bracketed terminal tags: `[ SYSTEM BOOT ]`, `[ AUTHENTICATED ]`, `[ DISPATCH ]`.
  - Muted parchment beige (`#dcd8c0`) over charcoal tactical brown (`#57544a`).
  - Monospace telemetry and hexagonal grid status indicators.

---

### 3. Unit-3 Cybernetic Interface (`samyns/Unit-3`)
* **Repository**: [https://github.com/samyns/Unit-3](https://github.com/samyns/Unit-3)
* **Design Core**: High-tech cybernetic HUD, mech cockpit diagnostics, sharp angular cuts.
* **Visual Elements**:
  - Chamfered 45-degree polygon edges on bars and notifications.
  - High-intensity warning cyan (`#00F0FF`) and hazard amber (`#FFB800`).
  - Diagnostic system telemetry widgets (CPU thread bars, memory matrix, net duplex gauges).

---

### 4. Hyprland YoRHa (`flickowoa/dotfiles/tree/hyprland-yorha`)
* **Repository**: [https://github.com/flickowoa/dotfiles/tree/hyprland-yorha](https://github.com/flickowoa/dotfiles/tree/hyprland-yorha)
* **Design Core**: Complete NieR:Automata desktop environment on Hyprland.
* **Hyprland Architecture**:
  - Custom Waybar with angled dividers and Pod telemetry.
  - Glitch-decay window opening and closing animations.
  - Dunst notification toasts styled as Pod tactical transmissions: `[POD 042: ALERT]`.
  - Rofi launcher styled as a weapon/pod selection matrix.

---

### 5. Cyber Hyprland (`taylor85345/cyber-hyprland-theme`)
* **Repository**: [https://github.com/taylor85345/cyber-hyprland-theme](https://github.com/taylor85345/cyber-hyprland-theme)
* **Design Core**: Cyberpunk high-glow, fast reactive window physics, neon-bordered glass.
* **Physics & Colors**:
  - Gradient borders: `45deg, #00ffff, #ff007f`.
  - Fast snappy animations (`menu_accel`, `md3_decel`).
  - Heavy drop shadows with colored corona (`shadow_color = rgba(00ffff33)`).

---

### 6. NieR:Automata Design System (`Kndgy/NieR-Automata-Design-System`)
* **Repository**: [https://github.com/Kndgy/NieR-Automata-Design-System](https://github.com/Kndgy/NieR-Automata-Design-System)
* **Design Specifications**:
  - **Colors**:
    - Light Background / Beige: `#dcd8c0` (YoRHa White)
    - Dark Background / Slate: `#4d493e` (Android Chassis)
    - Surface Dark: `#36332a`
    - Inactive / Border: `#57544a`
    - Muted Accent: `#737061`
    - Warning / Combat Alert: `#cf5b28`
    - Pod HUD Cyan: `#8be9fd`
  - **Typography**: Rodin Bokutoh, ITC Franklin Gothic, Droid Sans Fallback.
  - **UI Principles**: Flat, non-skeuomorphic, military functionalism, strict grid alignment, vertical text accents, subtle noise/scanline texturing.

---

### 7. NieR Cursors (`Beinsezii/NieR-Cursors`)
* **Repository**: [https://github.com/Beinsezii/NieR-Cursors](https://github.com/Beinsezii/NieR-Cursors)
* **Pointer Dynamics**:
  - Default pointer: Pod 042 targeting reticle / geometric needle pointer.
  - Hover pointer: Crosshair lock-on animation with rotating inner reticle.
  - Drag / Resize: Dual tactical calipers.
  - Busy / Waiting: Pod rotating laser scan indicator.

---

### 8. NieR Automata Full Rice (`anteczko/Nier-Automata-Rice`)
* **Repository**: [https://github.com/anteczko/Nier-Automata-Rice](https://github.com/anteczko/Nier-Automata-Rice)
* **Audio & Shader FX**:
  - Tactical audio blips on window focus, workspace switch, and menu click (`Navi`, `NieR UI SFX`).
  - CRT / Scanline GLSL post-processing shaders integrated with Hyprland shader pipeline.
  - Full EWW/Quickshell companion HUD for weapon (app) switching and combat mode layout.

---

### 9. Persona Quickshell (`Yujonpradhananga/Persona-Quickshell`)
* **Repository**: [https://github.com/Yujonpradhananga/Persona-Quickshell](https://github.com/Yujonpradhananga/Persona-Quickshell)
* **Design Core**: Persona 5 / Persona 3 Reload comic-book action pop art.
* **Visuals & Motion**:
  - 15°–20° slanted polygon panels, jagged ribbon edges, action starbursts.
  - Halftone comic dot textures and high-contrast duotone imagery.
  - Elastic / Overshot animation physics:
    - `bezier = overshot, 0.05, 0.85, 0.07, 1.04`
    - `bezier = OutBack, 0.28, 1.40, 0.58, 1`
  - Dynamic menus that whip across the screen with snap-to-rest spring physics.

---

### 10. Liquify (`NMWplays/Liquify`)
* **Repository**: [https://github.com/NMWplays/Liquify](https://github.com/NMWplays/Liquify)
* **Design Core**: Jelly physics, fluid glassmorphism, dynamic organic deformation.
* **Visuals & Motion**:
  - Jelly window drag physics: windows subtly deform/stretch along velocity vectors.
  - Liquid glass blur with high vibrancy and multi-pass refraction.
  - Fluid ease-in-out transitions (`easeInOutCirc`, `softAcDecel`).

---

### 11. SekaiPop (`Blapples/SekaiPop`)
* **Repository**: [https://github.com/Blapples/SekaiPop](https://github.com/Blapples/SekaiPop)
* **Design Core**: Project Sekai anime pop aesthetic, hyper-bouncy interactive widgets.
* **Visuals & Motion**:
  - Rounded bubble capsules (`radius = 20+`), pill-shaped docks.
  - Pastel neon gradient accents (candy pink, mint green, soda blue, lemonade yellow).
  - Bouncy tactile button squish animations (`scale: 0.92` on press, `1.08` rebound on release).
  - Audio visualizer pulsing rings and dynamic particle float.

---

## 2. Integrated Animation Curves for Hyprland & Umbriel

Combining the snappiness of YoRHa with the bouncy, joyful elastic dynamics of Persona, Liquify, and SekaiPop yields the following master bezier curves:

```ini
# Bouncy & Elastic Springs (Persona / SekaiPop)
bezier = popBouncy, 0.175, 0.885, 0.32, 1.275
bezier = elasticOut, 0.34, 1.56, 0.64, 1
bezier = overshot, 0.05, 0.85, 0.07, 1.04
bezier = winIn, 0.07, 0.88, 0.04, 0.99
bezier = winOut, 0.20, -0.15, 0, 1

# Liquid & Fluid Deceleration (Liquify / Space Dots)
bezier = fluidDecel, 0.05, 0.9, 0.1, 1.05
bezier = softAcDecel, 0.20, 0.20, 0.15, 1
bezier = easeOutCirc, 0, 0.48, 0.38, 1

# Tactical Fast Snap (YoRHa / Cyber)
bezier = tacticalSnap, 0.05, 0.82, 0, 1
bezier = menu_accel, 0.20, 0, 0.82, 0.10
```

### Motion Assignments

* **Windows Spawn (`windowsIn`)**: `1, 3.8, popBouncy, popin 75%` — Pops into view with a playful slight rebound.
* **Windows Close (`windowsOut`)**: `1, 3.0, winOut, popin 80%` — Snaps closed with clean acceleration.
* **Windows Move (`windowsMove`)**: `1, 3.5, fluidDecel, slide` — Moves like liquid with smooth settling.
* **Workspace Slide (`workspaces`)**: `1, 5.0, popBouncy, slide` — Smooth horizontal whip with subtle bounce on arrival.
* **Special Workspace (`specialWorkspace`)**: `1, 3.0, elasticOut, slidefadevert 20%` — Drops down like an action panel.

---

## 3. Dedicated 7-Workspace Functional Topology

1. `1: Agents` — Hermes, GLaDOS, OpenCode, Antigravity, LLM telemetry daemons.
2. `2: Browser` — Zen Browser, Brave, Firefox, web navigation.
3. `3: IDE` — VS Code, Zed, Neovim, development workstations.
4. `4: Media/Games` — Spotify, Spicetify, Steam, Gamescope, MPV.
5. `5: File-Manager` — Yazi, Thunar, Nautilus, Dolphin.
6. `6: E-mail/messaging` — Himalaya IMAP, Thunderbird, Discord, Vesktop, Slack, Signal.
7. `7: Overviews` — Grafana, Homepage dashboard, btop, bottom, tmog, system vitals.
