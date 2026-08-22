# ShellRoot

## 1. Component Overview

ShellRoot is the top-level entry point for the Yemi QuickShell desktop environment. It is the root object of the shell QML application and is responsible for:

- Registering IPC handlers for external control of shell features (wallpaper, music, colors, settings, pill surfaces, alt-switcher)
- Initializing core services (notifications, matugen, audio, brightness)
- Managing the wallpaper pipeline (loading, thumbnail generation, hashing, applying)
- Loading the bar window and pill overlay windows per screen
- Providing path properties for config, wallpaper, cache, and state directories

A developer would reach for ShellRoot when they need to understand how the shell boots, how IPC is structured, or how the wallpaper system works end-to-end.

## 2. Project Structure and Dependencies

- **File**: `shell.qml`
- **Imports**: `Quickshell`, `Quickshell.Io`, `Quickshell.Services.Notifications`, `qs.compositor`, `QtQuick 6.10`, local `services`, `singletons`, and `modules/pill`
- **Instantiated by**: The QuickShell runtime as the root object
- **Instantiates**: `NotificationServer`, `Loader` for `BarWrapper.qml`, `Variants` of `Pill.PillOverlay`, `Loader` for `MusicPanel.qml`, multiple `Process` objects for wallpaper management

## 3. Component Hierarchy and Role

ShellRoot extends `ShellRoot` (from Quickshell), which provides the base shell window and lifecycle. It composes:

- Multiple `IpcHandler` objects for external command dispatch
- A `NotificationServer` for D-Bus notification handling
- A `QtObject` for settings window state
- `Loader` instances for the bar and music panel
- `Variants` over `Quickshell.screens` to create one `Pill.PillOverlay` per monitor
- Multiple `Process` objects for wallpaper discovery, thumbnail generation, hashing, and application

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| barWindow | var | null | No | Reference to the loaded bar window, set when BarWrapper loads |
| compositor | var | Compositor | No | Read-only reference to the compositor singleton |
| notifs | var | QsServices.Notifs | No | Read-only reference to the notifications service |
| matugen | var | QsServices.Matugen | No | Read-only reference to the matugen color theme service |
| audio | var | QsServices.Audio | No | Read-only reference to the audio service |
| brightness | var | QsServices.Brightness | No | Read-only reference to the brightness service |
| homePath | string | Quickshell.env("HOME") | No | User home directory path |
| configPath | string | homePath + "/.config/quickshell" | No | QuickShell configuration directory |
| wallpaperPath | string | homePath + "/wallpapers" | No | Wallpaper storage directory |
| cachePath | string | homePath + "/.cache" | No | Cache directory |
| statePath | string | configPath + "/state" | No | State persistence directory |
| musicVisible | bool | false | No | Whether the music panel is currently visible |
| savedGifIndex | int | 0 | No | Persisted index for GIF wallpaper cycling |
| wallSearchTerm | string | "" | No | Current search filter for wallpaper list |
| wallpaperList | list | [] | No | Discovered wallpaper files |
| filteredWallpapers | var | derived | No | Wallpapers filtered by search term |
| wallSelectedIndex | int | 0 | No | Currently selected wallpaper index |
| currentWallpaper | string | "" | No | Path to the currently applied wallpaper |
| wallsLoaded | bool | false | No | Whether wallpaper discovery has completed |
| thumbsReady | bool | false | No | Whether thumbnail generation has completed |
| walApplying | bool | false | No | Whether a wallpaper apply operation is in progress |
| wallpaperHashes | var | {} | No | Map of wallpaper paths to their MD5 hashes |

## 5. Signals

ShellRoot does not define custom signals. It relies on Quickshell's `ShellRoot` base signals and the signals emitted by child objects (e.g., `NotificationServer.onNotification`).

## 6. Methods

#### toggleMusic() : void
Toggles the visibility of the music panel by flipping `musicVisible`.

#### applyWallpaper(wallpaper) : void
Applies the given wallpaper object (with `name` and `path` properties) by:
1. Setting `currentWallpaper` to the wallpaper path
2. Setting `walApplying` to true
3. Launching a `Process` that runs `awww img` for wallpaper transition and `matugen image` for color theme generation

#### loadWallpapers() : void
Resets wallpaper discovery state and triggers the `wallpaperListProc` to scan the wallpaper directory for supported image files.

#### saveState(key, value) : void
Persists a key-value pair to the state directory by writing to a file named after the key.

## 7. Inter-Component Interactions

- **IpcHandler**: Six IPC handlers expose shell functionality to external callers via the QuickShell IPC system. Targets are `wallpaper`, `music`, `colors`, `altSwitcher`, `settings`, and `pill`.
- **NotificationServer**: Receives D-Bus notifications and forwards them to `QsServices.Notifs.addNotification()`.
- **BarWrapper**: Loaded via `barLoader`; the loaded item is assigned to `root.barWindow`.
- **PillOverlay**: Created via `Variants` over `Quickshell.screens`; each overlay receives `modelData` (the screen) and `barWindow`.
- **MusicPanel**: Loaded via `musicPanelLoader`; visibility controlled by `musicVisible`.
- **PillState**: Used by the `pill` IPC handler to toggle surfaces on specific monitors.
- **Process objects**: Multiple background processes handle wallpaper discovery (`wallpaperListProc`), thumbnail generation (`thumbGenProc`), hashing (`hashAllProc`), current wallpaper resolution (`currentWallProc`), random selection (`randomWallProc`), application (`applyWallProc`), and state initialization (`initStateDir`).

## 8. Usage Example

ShellRoot is the application root and is not instantiated by other QML components. It is loaded directly by the QuickShell runtime. External control is via IPC:

```qml
// Example: toggle the launcher surface on the focused monitor
// From a terminal or keybind:
// qs ipc call pill launcher eDP-1
```
