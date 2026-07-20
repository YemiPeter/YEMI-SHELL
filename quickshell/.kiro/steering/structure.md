# Project Structure

## Root

```
~/.config/quickshell/
├── shell.qml               # Entry point — ShellRoot, IPC handlers, all top-level state
├── install.sh              # Installation script
├── reload-shell.sh         # Kill + restart quickshell
├── ARCHITECTURE.md         # Architecture notes
├── README.md               # Project readme
├── app_usage.json          # App launch frequency (root-level copy)
├── NIRI_KEYBINDS_DOCS.md   # Niri keybind reference
└── QuickShellKeybinds.conf # Hyprland keybind config
```

## Directories

```
compositor/        Compositor abstraction layer
├── Compositor.qml   Singleton — detects Hyprland vs Niri at runtime, unified interface
├── Hyprland.qml     Hyprland implementation (toplevels, workspaces, dispatch)
├── Niri.qml         Niri implementation (in progress)
└── qmldir

config/            QML config singletons
├── Config.qml       Top-level config (BarConfig, AppearanceConfig, controlCenter, notifications)
├── Appearance.qml   Visual tokens (colors, rounding, font sizes)
├── AppearanceConfig.qml
├── BarConfig.qml
└── qmldir

services/          Runtime singleton services
├── Matugen.qml      Color system — watches state/colors.qml, triggers matugen on wallpaper change
├── Audio.qml        PipeWire volume + mute
├── Brightness.qml   Display brightness via brightnessctl
├── Notifs.qml       Notification state (stores/manages notifications from NotificationServer)
├── Players.qml      MPRIS player tracking
├── Network.qml      NetworkManager integration
├── Bluetooth.qml    Bluetooth control
├── Hyprsunset.qml   Night light (hyprsunset)
├── IdleInhibitor.qml
├── Logger.qml       Logging utility
├── Pywal.qml        Legacy Pywal color system (being replaced by Matugen)
├── PowerProfiles.qml
├── Screenshot.qml
├── SystemUsage.qml  CPU/RAM monitoring
├── VolumeMonitor.qml
└── qmldir

modules/           UI modules
├── bar/
│   ├── Bar.qml              Bar content
│   ├── BarWrapper.qml       Quickshell panel wrapper (loaded via Loader in shell.qml)
│   └── components/          Battery, Bluetooth, Brightness, Clock, MediaPlayer,
│                            Network, NotificationPopups, Volume, Workspaces
├── controlcenter/
│   ├── ControlCenterWindow.qml
│   └── components/          BrightnessSlider, MediaCard, NotificationList,
│                            QuickToggle, SystemStats, ThemeToggle, VolumeSlider
├── launcher/
│   └── LauncherPanel.qml    App launcher + wallpaper browser (two-tab panel)
├── music/
│   └── MusicPanel.qml       Music controls with album art
├── osd/
│   ├── Wrapper.qml          Loaded in shell.qml — hosts both OSD overlays
│   ├── VolumeOSD.qml
│   ├── BrightnessOSD.qml
│   └── qmldir
├── settings/
│   ├── SettingsWindow.qml   Dynamically created on first toggle
│   └── components/
├── altswitcher/
│   ├── AltSwitcher.qml      Alt+Tab window switcher (in progress)
│   └── CHECKLIST.md
└── qmldir

dist/              Distributed config files for external tools
├── matugen/       matugen config.toml + templates
├── hypr/          Hyprland config templates
├── niri/          Niri config + keybinds (70-binds.kdl etc.)
├── cava/          Cava visualizer config
├── fastfetch/     Fastfetch config
├── swaync/        SwayNotificationCenter config
├── wal/           Pywal templates (legacy)
├── rmpc/          rmpc music client config
├── quickshell/    Quickshell-specific distributed files
├── templates/     Generic color templates
├── scripts/       Distributed scripts
└── starship.toml

scripts/           Shell utility scripts
├── after-wall.sh          Wallpaper hook — calls matugen, reloads colors
├── toggle-colormode.sh    Cycles auto/dark/light, updates state/colormode
└── reset-app-usage.sh     Clears app_usage.json

assets/gifs/       Animated GIF assets
components/effects/ Shared visual effect components
state/             Runtime state files
├── colormode      Current theme mode: auto | dark | light
├── gif-index      Current GIF index
└── colors.qml     Matugen-generated color output
screenshots/       Project screenshots
```

## Key architecture patterns

### shell.qml is the state owner
All top-level state lives in `shell.qml` as `ShellRoot` properties: `launcherVisible`, `activeTab`, `appList`, `appUsage`, `wallpaperList`, `currentWallpaper`, `musicVisible`, etc. Modules receive state via property bindings or direct reads from root.

### Services are singletons
All services under `services/` use `pragma Singleton`. They're imported via `import "services" as QsServices` and accessed by name. New services must be added to `services/qmldir`.

### Compositor abstraction
`compositor/Compositor.qml` detects the running compositor from `XDG_CURRENT_DESKTOP` / `DESKTOP_SESSION` and delegates to either `Hyprland.qml` or `Niri.qml`. Always use `Compositor.toplevels`, `Compositor.workspaces`, `Compositor.dispatch()` — never call compositor-specific APIs directly in UI modules.

### Color system
Matugen is the active theming system. It reads `dist/matugen/config.toml`, processes a wallpaper image, and outputs `state/colors.qml`. `services/Matugen.qml` handles reload signaling. `services/Pywal.qml` is legacy — kept for reference, being phased out.

### IPC
Handlers are declared as `IpcHandler { target: "name" }` blocks inside `shell.qml`. All shell-controllable actions must have a corresponding handler. Called externally with `qs ipc call <target> <function>`.

### Module loading
UI modules are loaded via `Loader { source: "..." }` in `shell.qml` or inline. The settings window is dynamically created (`Qt.createComponent`) on first toggle to avoid startup cost.
