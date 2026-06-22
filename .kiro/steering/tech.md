# Tech Stack

## Core

| Layer | Technology |
|-------|-----------|
| UI framework | [Quickshell](https://quickshell.outfoxxed.me/) |
| UI language | QML (Qt 6.10) |
| Primary compositor | Hyprland |
| Secondary compositor | Niri (in progress) |
| Theming | [matugen](https://github.com/InioX/matugen) — Material You color extraction |
| Wallpaper engine | awww (swww fork) |
| Scripts | Bash |

## Key dependencies

- **quickshell** — shell runtime
- **matugen** — Material You color generation from wallpaper
- **awww** — wallpaper engine
- **pipewire / wireplumber** — audio
- **networkmanager** — network
- **brightnessctl** — display brightness
- **swaync** — notification daemon
- **mpd / mpc / playerctl** — music playback
- **ImageMagick** or **vipsthumbnail** — wallpaper thumbnail generation
- **grim + slurp** — screenshots
- **wl-clipboard + cliphist** — clipboard

## Config file locations

| What | Path |
|------|------|
| Shell entry point | `~/.config/quickshell/shell.qml` |
| Matugen config | `~/.config/quickshell/dist/matugen/config.toml` |
| Generated colors | `~/.config/quickshell/state/colors.qml` |
| App usage data | `~/.config/quickshell/app_usage.json` (also `state/app_usage.json`) |
| Color mode state | `~/.config/quickshell/state/colormode` |
| GIF index state | `~/.config/quickshell/state/gif-index` |
| Wallpapers | `~/wallpapers/` |
| Wallpaper thumbnails | `~/.cache/wallpaper-thumbs/` |
| Pywal colors (legacy) | `~/.cache/wal/colors.json` |
| Niri config | `~/.config/quickshell/dist/niri/` |
| Hyprland config | `~/.config/quickshell/dist/hypr/` |

## QML module namespaces

```
qs.compositor     # Compositor abstraction (Hyprland + Niri)
services/         # Imported as "services" — all singleton services
modules/bar/      # Bar module
modules/osd/      # OSD overlays (Wrapper, VolumeOSD, BrightnessOSD)
config/           # Config, Appearance, BarConfig singletons
```

---

## Common Commands

### Running the shell

```bash
# Start via Quickshell directly
qs -c ~/.config/quickshell

# Restart
~/.config/quickshell/reload-shell.sh
# or
pkill -f quickshell && qs -c ~/.config/quickshell

# Check logs
journalctl --user -u quickshell -f
```

### IPC calls (testing from terminal)

```bash
qs ipc call launcher toggle
qs ipc call wallpaper toggle
qs ipc call wallpaper random
qs ipc call music toggle
qs ipc call colors reload
qs ipc call settings toggle
qs ipc call altSwitcher toggle   # in progress
```

### Install

```bash
cd ~/.config/quickshell
chmod +x install.sh
./install.sh
```

### Scripts

```bash
# Toggle color mode (auto/dark/light)
~/.config/quickshell/scripts/toggle-colormode.sh

# Reset app usage stats
~/.config/quickshell/scripts/reset-app-usage.sh

# After-wallpaper hook (triggers matugen)
~/.config/quickshell/scripts/after-wall.sh
```

### Matugen (theming)

```bash
# Generate colors from a wallpaper manually
matugen image ~/wallpapers/example.jpg -c ~/.config/quickshell/dist/matugen/config.toml
```
