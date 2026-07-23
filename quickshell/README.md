# Yemi Shell

<p align="center"><em>Yemi Shell</em>, from Latin: conscientious action for the Linux desktop.</p>

Yemi Shell is a custom Hyprland/QuickShell (QML) desktop environment featuring a morphing pill-based UI. Built on the Quickshell framework, it transforms the traditional top bar into an interactive morphing pill that breathes with your wallpaper's colors. Every surface, from the launcher to the power menu, emerges dynamically from a single animated element, ready to be summoned with a keystroke.

---

## ✨ Features

### Morphing Pill UI

A single `Pill.qml` component transforms fluidly between 20+ surfaces using state-driven animations. The pill grows in-place without overshoot, governed by `Motion.morph` easing curves. Key surfaces include:

| Surface | Dimensions | Purpose |
|:-------:|:----------:|:--------|
| `rest` | 160×38px | Default breathing pill (idle animation) |
| `launcher` | 360×332px | App launcher with fuzzy search |
| `mixer` | 93×max(4,faders)×38px | Audio faders for all sinks/sources |
| `calendar` | 58×70px | Monthly calendar picker |
| `power` | 330×150px | Session operations (lock/reboot/power) |
| `wallpaper` | 720×172px | Wallpaper gallery with GIF support |

### Dual Compositor Support

Native abstraction layer supports both:

| Compositor | Detection | Status |
|:----------:|:----------:|:-------|
| **Hyprland** | `XDG_CURRENT_DESKTOP=Hyprland` | Primary |
| **Niri** | `XDG_CURRENT_DESKTOP=Niri` | Secondary (polling) |

### Dynamic Theming Pipeline

```
┌─────────────┐     ┌────────────┐     ┌──────────────┐
│  Wallpaper  │────▶│wallcolors.py│────▶│ colors.json  │
└─────────────┘     └────────────┘     └──────┬───────┘
                                              │
┌───────────────┐                     ┌────────┴────────┐
│  Matugen      │◀────────────────────│  terminal.json  │
└───────────────┘                     └─────────────────┘
```

**Color extraction** uses ImageMagick histogram analysis with:
- 30° hue family binning to find "area-dominant chromatic hue"
- Mean lightness to determine light/dark theme
- 6-step surface lightness ramp (surface → surface_highest)

### Two-Window Architecture

The `PillOverlay` uses a specialized layer-shell split:

```
┌────────────────────────────────────────────────────┐
│ shell.qml                                          │
│  ├── BarWrapper (WlrLayer.Bottom)                   │
│  └── PillOverlay (per screen)                       │
│       ├── reserve (WlrLayer.Top)                    │
│       │   └── Excluded zone (38px resting height)   │
│       └── overlay (WlrLayer.Overlay)                │
│           └── Pill QML + Surfaces                   │
└────────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture

### Core Components

| Component | File | Purpose |
|:---------:|:-----|:--------|
| `ShellRoot` | `shell.qml` | Root entry point, IPC handlers, service initialization |
| `PillOverlay` | `modules/pill/PillOverlay.qml` | Per-screen overlay container with reserve/overlay windows |
| `Pill` | `modules/pill/Pill.qml` | Main morphing body with state management |
| `PillState` | `singletons/PillState.qml` | Global surface state (per-monitor) |
| `Flags` | `singletons/Flags.qml` | Session preferences (DND, paletteMode, etc.) |
| `Theme` | `singletons/Theme.qml` | Static color palette tokens |
| `Dyn` | `singletons/Dyn.qml` | Dynamic colors from wallpaper |
| `Compositor` | `compositor/Compositor.qml` | Hyprland/Niri abstraction layer |

### Service Architecture

| Service | File | Protocol |
|:-------:|:-----|:----------|
| Notifs | `services/Notifs.qml` | D-Bus Notifications |
| Audio | `services/Audio.qml` | PipeWire MPRIS |
| Network | `services/Network.qml` | NetworkManager |
| Bluetooth | `services/Bluetooth.qml` | BlueZ |
| Matugen | `services/Matugen.qml` | External process |
| IdleInhibitor | `services/IdleInhibitor.qml` | systemd/logind |

### Data Flow

```
Wallpaper → wallcolors.py → colors.json → Dyn singleton
                                              │
                                    ┌───────┴────────┐
                                    │                │
                          Pill surfaces      Theme singleton
                                    │                │
                                    └───────┬────────┘
                                            ▼
                                     Color tokens
```

---

## 🔧 Installation

### Dependencies

```bash
# Core
quickshell hyprland hyprsunset python

# Wallpaper pipeline
imagemagick matugen python-pywal

# System services
brightnessctl playerctl network-manager-applet
pipewire pipewire-pulse wireplumber
networkmanager bluez bluez-utils upower
wl-clipboard slurp wf-recorder libnotify

# Fonts
ttf-jetbrains-mono-nerd ttf-material-icons inter-font
```

### Install Script

```bash
# Arch-based systems (recommended)
./install.sh

# Dry run to preview changes
./install.sh --dry-run
```

The installer:
1. Checks for required packages (pacman + AUR)
2. Sets `RICE_HOME` in `environment.d` and Hyprland env
3. Copies config to `~/.config/quickshell/`
4. Enables systemd services (NetworkManager, Bluetooth, etc.)
5. Initializes state files
6. Runs `wal -i` on first wallpaper

---

## ⚙️ Configuration

### Flag Definitions

| Property | Type | Default | Purpose |
|:---------|:-----|:--------|:--------|
| `paletteMode` | `string` | `"dynamic"` | Color mode (`"static"` or `"dynamic"`) |
| `uiScale` | `real` | `1.0` | Global scaling factor |
| `pillOpacity` | `real` | `0.55` | Resting pill transparency |
| `pillBlur` | `bool` | `false` | Enable background blur |
| `uiFont` | `string` | `""` | Custom font override |
| `time12h` | `bool` | `false` | 12-hour clock mode |
| `reduceMotion` | `bool` | `false` | Disable animations |

### Theme Modes

**Static Mode** — Fixed palette, no wallpaper dependency:
```qml
Flags.paletteMode = "static"
```

**Dynamic Mode** — Live wallpaper theming:
```qml
Flags.paletteMode = "dynamic"  // Changes on wallpaper update
```

### Compositor Detection

Located in [`compositor/Niri.qml:78-85`](compositor/Niri.qml):

```javascript
function detectCompositor(): string {
    const xdg = Quickshell.env("XDG_CURRENT_DESKTOP");
    if (xdg?.includes("Hyprland")) return "hyprland";
    if (xdg?.includes("Niri")) return "niri";
    return "hyprland";
}
```

### Debug Mode

Enable verbose logging:

```bash
export QS_DEBUG=1
```

Or set in `flags.json`:
```json
{ "debug": true }
```

---

## ⚠️ Known Limitations

### Niri Support (Secondary)

| Limitation | Impact |
|:-----------|:-------|
| Polling-based updates | 500ms delay for state changes |
| Approximate fullscreen | Compares `tile_size` to monitor dimensions |
| Partial keybind editing | Format differs (KDL vs Lua) |
| Workspace key mapping | Niri workspaces keyed by `id`, mapped via `output` |

### Other Caveats

- **Magick Required**: `wallcolors.py` needs ImageMagick (`magick` command)
- **Material Icons**: Pills use Material Icons; custom glyphs may fail
- **GIF Thumbnails**: First frame only; animations not rendered in UI
- **No Color Management**: Colors extracted once per wallpaper change

---

## 🛠️ Fixes & Future Work

### Niri Support Enhancements

Niri support is currently functional but is undergoing active improvements to reach full parity with Hyprland:

| Area | Status | Planned |
|:-----------|:-------|:--------|
| IPC events | Polling (500ms) | Native event streaming |
| Fullscreen detection | Approximate | Pixel-perfect measurement |
| Keybind editing | Partial (KDL format) | Full GUI editor support |
| Workspace mapping | `id` → `output` translation | Direct workspace binding |

**Timeline:** Niri backend will reach full feature parity in the upcoming release.

---

## 🔗 Related Projects

This project builds on work from:

- **[Ricelin](https://github.com/Gakuseei/Ricelin)** — Original morphing pill UI
- **[iNiR](https://github.com/YemiPeter/iNiR)** — Yemi's Niri rice
- **[qylock](https://github.com/Darkkal44/qylock)** — Lock screen implementation
- **[skwd-wall](https://github.com/liixini/skwd-wall)** — Wallpaper changer
- **[quickshell](https://github.com/YemiPeter/quickshell)** — Extended QML framework
- **[tripathiji/quickshell](https://github.com/tripathiji1312/quickshell)** — Original quickshell

---

## 📜 License

This project is licensed under the MIT License. See `LICENSE` for details.

---

*Built with ❤️ by Yemi for the Linux desktop community.*