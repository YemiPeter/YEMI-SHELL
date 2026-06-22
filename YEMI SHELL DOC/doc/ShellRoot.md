# ShellRoot Component

## Component Overview

ShellRoot is the main entry point and central coordinator for the QuickShell desktop shell application. It manages application state, handles IPC (Inter-Process Communication) calls from keybindings, orchestrates various UI modules (bar, music panel, launcher), and coordinates system services like notifications, wallpaper management, and application launching. This component serves as the top-level application controller that integrates with both Hyprland and Niri compositors through the compositor abstraction layer.

## Project Structure and Dependencies

The ShellRoot component is the main application entry point located at `/home/yemi/.config/quickshell/shell.qml`. It imports and integrates with multiple subsystems:

- **Compositor abstraction**: Uses `qs.compositor` to handle both Hyprland and Niri compatibility
- **Services**: Imports from `"services"` as `QsServices` for audio, brightness, notifications, and theming
- **OSD components**: Imports `"modules/osd"` for volume and brightness displays
- **UI Modules**: Instantiates various loaders for bar, music panel, and launcher
- **Quickshell framework**: Depends on `Quickshell`, `Quickshell.Io`, and `Quickshell.Services.Notifications`

The component is instantiated by the Quickshell runtime and serves as the parent for all major UI modules and services.

## Component Hierarchy and Role

ShellRoot extends the `ShellRoot` type from the Quickshell framework, providing a specialized implementation for the QuickShell desktop environment. It adds application-specific state management, IPC handlers for keyboard shortcuts, and coordination between various UI modules and system services.

## Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| compositor | var | Compositor | No | Read-only reference to the compositor abstraction layer that detects and delegates to Hyprland or Niri implementations |
| notifs | var | QsServices.Notifs | No | Reference to the notifications service singleton |
| matugen | var | QsServices.Matugen | No | Reference to the Matugen theming service |
| audio | var | QsServices.Audio | No | Reference to the audio service |
| brightness | var | QsServices.Brightness | No | Reference to the brightness service |
| homePath | string | Quickshell.env("HOME") | No | Path to the user's home directory |
| configPath | string | homePath + "/.config/quickshell" | No | Path to the QuickShell configuration directory |
| wallpaperPath | string | homePath + "/wallpapers" | No | Path to the wallpapers directory |
| cachePath | string | homePath + "/.cache" | No | Path to the user cache directory |
| statePath | string | configPath + "/state" | No | Path to the state storage directory |
| musicVisible | bool | false | No | Controls visibility of the music panel |
| savedGifIndex | int | 0 | No | Index of the currently selected GIF for music visualization |
| launcherVisible | bool | false | No | Controls visibility of the launcher panel |
| activeTab | int | 0 | No | Index of the currently active tab in the launcher (0=apps, 1=wallpapers) |
| searchTerm | string | "" | No | Current search term for filtering applications |
| appList | var | [] | No | Array of available applications |
| appUsage | var | ({}) | No | Dictionary tracking application usage counts |
| filteredApps | var | computed | No | Computed array of applications filtered by search term and sorted by usage |
| selectedIndex | int | 0 | No | Index of the currently selected application |
| wallSearchTerm | string | "" | No | Current search term for filtering wallpapers |
| wallpaperList | var | [] | No | Array of available wallpapers |
| filteredWallpapers | var | computed | No | Computed array of wallpapers filtered by search term |
| wallSelectedIndex | int | 0 | No | Index of the currently selected wallpaper |
| currentWallpaper | string | "" | No | Path to the currently active wallpaper |
| wallsLoaded | bool | false | No | Indicates if wallpapers have been loaded |
| thumbsReady | bool | false | No | Indicates if wallpaper thumbnails are ready |
| walApplying | bool | false | No | Indicates if a wallpaper is currently being applied |
| wallpaperHashes | var | ({}) | No | Dictionary mapping wallpaper paths to their hashes |

## Signals

This component does not declare custom signals, but it uses various Quickshell framework signals and process completion events.

## Methods

#### toggleMusic() : void
Toggles the visibility of the music panel by inverting the musicVisible property.

#### toggleLauncher() : void
Toggles the visibility of the launcher panel by inverting the launcherVisible property.

#### launchApp(app) : void
Launches an application and tracks its usage. Parameters: `app` (object with name, exec, icon properties).

#### applyWallpaper(wallpaper) : void
Applies a wallpaper with transition effects. Parameters: `wallpaper` (object with name and path properties).

#### loadWallpapers() : void
Loads the list of available wallpapers from the wallpaper directory.

#### saveState(key, value) : void
Saves application state to a file. Parameters: `key` (string state key), `value` (string state value).

## Inter-Component Interactions

The ShellRoot component serves as the central hub connecting various parts of the application:

- **IPC Handlers** receive external commands (keyboard shortcuts) and trigger appropriate actions
- **Services** are accessed directly through properties to control system functions
- **UI Modules** are instantiated via Loaders and coordinated through shared state properties
- **Processes** manage system interactions like application discovery, wallpaper management, and state persistence
- **Notification Server** integrates with the system notification bus to receive and handle notifications

The component maintains shared state that is accessed by multiple UI modules, ensuring consistency across the application. It coordinates between the launcher, music panel, and other modules to provide a unified experience.

## Usage Example

```qml
// ShellRoot is the main application component and typically doesn't need instantiation
// It is loaded directly by the Quickshell runtime:
// quickshell -p /home/yemi/.config/quickshell/shell.qml
```