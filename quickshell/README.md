# QuickShell QML Rice Config

> **Repository:** `$HOME/.config/quickshell`  
> **Framework:** Quickshell (Qt 6.10 QML framework)  
> **Shell ID:** `yemi-shell`  
> **Desktop:** Linux (Hyprland/Niri compatible)  
> **Last Updated:** 2026-08-05

A dynamic, wallpaper-driven shell interface built on Quickshell. Features:

- **Dynamic color theming** - Extracts Material 3 colors from wallpaper
- **Pill UI** - Unified settings panel with keyboard controls
- **OSD** - On-screen display for volume, brightness, notifications
- **Bar panel** - Status bar with system indicators
- **IPC control** - Hot-reloading via `qs ipc call` commands

## Quick Start

```bash
# Start the shell
./scripts/start-quickshell.sh

# Apply new wallpaper (triggers color regeneration)
./scripts/after-wall.sh

# Reload colors
qs ipc call colors reload
```

## Project Structure

```
quickshell/
├── config/           # Configuration singletons
│   ├── Config.qml    # Main config (37 lines)
│   └── Appearance.qml # Appearance singleton
│
├── singletons/       # Core singletons
│   ├── Theme.qml     # Color token facade (31 tokens)
│   ├── Dyn.qml       # Dynamic colors (FileView + JsonAdapter)
│   └── Flags.qml     # Session flags
│
├── services/         # Backend services
│   └── *.qml         # Audio, Network, Brightness, etc.
│
├── modules/          # UI components
│   ├── bar/          # Top status bar
│   ├── pill/         # Settings/launcher panel
│   └── osd/          # On-screen displays
│
├── scripts/          # Automation scripts
│   ├── after-wall.sh # Wallpaper change and color pipeline
│   ├── dominance-engine.py # Material 3 palette derivation
│   ├── dominance-extract.py # Dominance-ranked color extraction
│   └── wallcolors.py # Compatibility color pipeline
```

## Color System

The default color pipeline is wallpaper-driven:

1. `dominance-extract.py` ranks eight representative colors from the wallpaper.
2. `dominance-engine.py` derives dark and light Material 3 token sets.
3. `after-wall.sh` writes the v2 `colors.json` contract consumed by `Dyn.qml`.

`wallcolors.py` remains available only for the `YEMI_LEGACY_COLORS=1` compatibility path.

Colors flow: `wallpaper → dominance-extract.py → dominance-engine.py → colors.json → Dyn.qml → Theme.qml → UI components`

### Color Files

| File | Purpose |
|------|---------|
| `~/.cache/yemi-shell/colors.json` | Wallpaper-derived colors (snake_case schema) |
| `~/.cache/yemi-shell/terminal.json` | Terminal colors (kitty, ghostty, etc.) |
| `~/.cache/yemi-shell/hypr-colors.lua` | Hyprland colors |
| `~/.local/state/quickshell/flags.json` | Session flags |

## IPC Commands

```bash
# Pill commands
qs ipc call pill.launcher show
qs ipc call pill.mixer show
qs ipc call pill.calendar show
qs ipc call pill.clipboard show
qs ipc call pill.power show
qs ipc call pill.settings show
qs ipc call pill.keybinds show
qs ipc call pill.wallpaper show
qs ipc call pill.media show
qs ipc call pill.sysmon show

# Colors
qs ipc call colors reload
```

## License

This is a personal dotfile repository - not intended for public use.