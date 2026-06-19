# Shell by Yemi Architecture Documentation

## Overview
Shell by Yemi is a modern, QML-based shell designed for the Hyprland compositor. It combines dynamic theming via Pywal with an integrated workflow featuring launcher, music controls, and wallpaper management.

## Project Structure

### Main Components
```
/home/yemi/.config/quickshell/
├── shell.qml                 # Main shell entry point
├── install.sh               # Installation script
├── reload-quickshell.sh     # Shell restart utility
├── hyprland-layer-config.conf # Hyprland layer rules
├── README.md               # Project documentation
├── app_usage.json          # App usage statistics
├── ARCHITECTURE.md         # This file
├── [dir] assets/           # Assets (currently only gifs/)
├── [dir] components/       # Shared UI components
├── [dir] config/           # Configuration files
├── [dir] modules/          # Core functional modules
├── [dir] outsideFile/      # Configuration templates
├── [dir] scripts/          # Utility scripts
├── [dir] services/         # Backend services
├── [dir] state/            # Runtime state files
└── [dir] screenshots/      # Project screenshots
```

### Module Structure
- **[modules/bar/](file:///home/yemi/.config/quickshell/modules/bar)** - Status bar with workspaces, clock, and system controls
- **[modules/controlcenter/](file:///home/yemi/.config/quickshell/modules/controlcenter)** - Control center with sliders and quick toggles
- **[modules/launcher/](file:///home/yemi/.config/quickshell/modules/launcher)** - Application launcher with search and wallpaper browser
- **[modules/music/](file:///home/yemi/.config/quickshell/modules/music)** - Music player interface
- **[modules/osd/](file:///home/yemi/.config/quickshell/modules/osd)** - On-screen displays for volume and brightness

### Service Architecture
- **[services/Pywal.qml](file:///home/yemi/.config/quickshell/services/Pywal.qml)** - Dynamic color system from wallpaper
- **[services/Audio.qml](file:///home/yemi/.config/quickshell/services/Audio.qml)** - Audio control service
- **[services/Network.qml](file:///home/yemi/.config/quickshell/services/Network.qml)** - Network management
- **[services/Bluetooth.qml](file:///home/yemi/.config/quickshell/services/Bluetooth.qml)** - Bluetooth control
- **[services/Brightness.qml](file:///home/yemi/.config/quickshell/services/Brightness.qml)** - Display brightness control
- **[services/Notifs.qml](file:///home/yemi/.config/quickshell/services/Notifs.qml)** - Notification management

## Control Flow

### Startup Sequence
1. **Hyprland Launches** → Executes `quickshell -c $HOME/.config/quickshell/Brain_Shell/.`
2. **shell.qml Loads** → Initializes services and loads UI components
3. **Services Initialize** → Pywal, Audio, Network, etc. start
4. **UI Components Load** → Bar, Control Center, Launcher, etc.
5. **System Ready** → All components connected and operational

### Pywal Color Pipeline
1. **User changes wallpaper** → Shell triggers awww image change
2. **awww executes** → Calls `~/.config/skwd-wall/after-wall.sh` (currently missing)
3. **after-wall.sh runs** → Executes `wal -i <wallpaper>` to generate colors
4. **Pywal writes** → Colors to `~/.cache/wal/colors.json`
5. **QML watches** → `services/Pywal.qml` monitors the file
6. **UI Updates** → All components receive new color scheme

### IPC Communication
- **`qs ipc call launcher toggle`** → Toggles launcher panel
- **`qs ipc call wallpaper toggle`** → Toggles wallpaper panel  
- **`qs ipc call music toggle`** → Toggles music panel
- **Custom IpcHandler targets** in [shell.qml](file:///home/yemi/.config/quickshell/shell.qml) manage these calls

## Key Dependencies

### Core Components
- **Hyprland** (compositor)
- **QuickShell** (shell interface)
- **awww** (wallpaper engine - swww fork)
- **python-pywal** (dynamic color generation)

### Audio Stack
- **Pipewire/Wireplumber** (audio management)
- **MPD/MPC** (music player)
- **playerctl** (media control)

### Utilities
- **SwayNotificationCenter** (notifications)
- **brightnessctl** (display brightness)
- **ImageMagick/VIPS** (image processing)

## Configuration Files

### [hyprland.conf](file:///home/yemi/.config/quickshell/outsideFile/.config/hypr/hyprland.conf)
Located in [outsideFile/.config/hypr/hyprland.conf](file:///home/yemi/.config/quickshell/outsideFile/.config/hypr/hyprland.conf), this contains the main Hyprland configuration template. **Note:** Contains a hardcoded reference to a non-existent directory [Brain_Shell](file:///home/yemi/.config/quickshell/Brain_Shell).

### [shell.qml](file:///home/yemi/.config/quickshell/shell.qml)
Main application file that:
- Initializes all services
- Manages IPC handlers
- Loads UI components
- Handles launcher functionality
- Manages wallpaper loading and application launching

### [services/Pywal.qml](file:///home/yemi/.config/quickshell/services/Pywal.qml)
Singleton service that:
- Monitors `~/.cache/wal/colors.json`
- Provides color tokens to all UI components
- Handles light/dark mode switching
- Manages semantic color system

## Critical Issues

### 🔴 Broken Startup Path
**Location:** [outsideFile/.config/hypr/hyprland.conf](file:///home/yemi/.config/quickshell/outsideFile/.config/hypr/hyprland.conf) line 7
```
exec-once = quickshell -c $HOME/.config/quickshell/Brain_Shell/.
```
**Issue:** References non-existent directory [Brain_Shell](file:///home/yemi/.config/quickshell/Brain_Shell)
**Fix:** Remove the `-c $HOME/.config/quickshell/Brain_Shell/.` parameter

### 🔴 Broken Pywal Pipeline
**Location:** [shell.qml](file:///home/yemi/.config/quickshell/shell.qml) line ~108
```
root.homePath + "/.config/skwd-wall/after-wall.sh '" + wallpaper.path + "'"
```
**Issue:** `after-wall.sh` script doesn't exist at the expected location
**Fix:** Create the missing script or update the path

### ⚠️ Unmatched IPC Handler
**Location:** [outsideFile/.config/hypr/hyprland.conf](file:///home/yemi/.config/quickshell/outsideFile/.config/hypr/hyprland.conf) line ~47
```
bind = $mod, A, exec, qs ipc call dashboard toggle
```
**Issue:** No corresponding IPC handler for "dashboard" in [shell.qml](file:///home/yemi/.config/quickshell/shell.qml)
**Fix:** Either remove the keybind or add the handler

## State Management

### Runtime State Files
- `~/.config/quickshell/state/colormode` - Stores current theme mode (dark/light/auto)
- `~/.config/quickshell/state/gif-index` - Tracks current GIF index
- `~/.config/quickshell/app_usage.json` - Maintains application usage statistics

### Configuration Files
- `~/.config/quickshell/config/` - QML configuration modules
- `~/.cache/wal/colors.json` - Pywal-generated color scheme
- `~/.cache/wallpaper-thumbs/` - Thumbnail cache for wallpapers

## Scripts

### [scripts/toggle-colormode.sh](file:///home/yemi/.config/quickshell/scripts/toggle-colormode.sh)
Cycles through color modes: auto → dark → light → auto
Updates state file and re-applies Pywal colors based on mode

### [scripts/reset-app-usage.sh](file:///home/yemi/.config/quickshell/scripts/reset-app-usage.sh)
Resets the application usage statistics to empty

### [reload-quickshell.sh](file:///home/yemi/.config/quickshell/reload-quickshell.sh)
Gracefully kills and restarts the QuickShell process

## UI Components

### Bar Components ([modules/bar/components/](file:///home/yemi/.config/quickshell/modules/bar/components))
- **[Battery.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Battery.qml)** - Battery indicator
- **[Bluetooth.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Bluetooth.qml)** - Bluetooth status and popup
- **[Brightness.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Brightness.qml)** - Brightness control
- **[Clock.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Clock.qml)** - Time display
- **[MediaPlayer.qml](file:///home/yemi/.config/quickshell/modules/bar/components/MediaPlayer.qml)** - Music player controls
- **[Network.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Network.qml)** - Network status and popup
- **[Volume.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Volume.qml)** - Volume control
- **[Workspaces.qml](file:///home/yemi/.config/quickshell/modules/bar/components/Workspaces.qml)** - Workspace indicators
- **[NotificationPopups.qml](file:///home/yemi/.config/quickshell/modules/bar/components/NotificationPopups.qml)** - Notification display

### Control Center Components ([modules/controlcenter/components/](file:///home/yemi/.config/quickshell/modules/controlcenter/components))
- **[BrightnessSlider.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/BrightnessSlider.qml)** - Brightness slider
- **[MediaCard.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/MediaCard.qml)** - Music player card
- **[NotificationList.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/NotificationList.qml)** - Notification list
- **[QuickToggle.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/QuickToggle.qml)** - Generic toggle component
- **[SystemStats.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/SystemStats.qml)** - System resource monitoring
- **[ThemeToggle.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/ThemeToggle.qml)** - Color mode toggle
- **[VolumeSlider.qml](file:///home/yemi/.config/quickshell/modules/controlcenter/components/VolumeSlider.qml)** - Volume slider

## Styling & Theming

### Color System
The project uses a semantic color system defined in [services/Pywal.qml](file:///home/yemi/.config/quickshell/services/Pywal.qml) with:
- Base Pywal colors (color0-color15)
- Semantic tokens (primary, secondary, surface, etc.)
- Light/dark mode awareness
- Material Design 3 inspired naming

### Animations
Animations are defined in the Hyprland config using custom beziers:
- `bounce`, `buttery`, `smooth`, `linear`
- Applied to windows, fades, workspaces, and layer shells

## Installation Process

The [install.sh](file:///home/yemi/.config/quickshell/install.sh) script:
1. Checks for Arch-based system
2. Installs required packages via pacman and yay
3. Copies configuration to `~/.config/quickshell/`
4. Enables systemd services
5. Creates runtime directories
6. Initializes Pywal with default wallpaper

## Renaming Considerations

To rename from "quickshell" to "Shell by Yemi":

### Files to Update:
1. **Configuration references** in [install.sh](file:///home/yemi/.config/quickshell/install.sh), [README.md](file:///home/yemi/.config/quickshell/README.md), scripts
2. **State directory paths** in all scripts
3. **Service filenames** like [quickshell-reset-app-usage.service](file:///home/yemi/.config/quickshell/quickshell-reset-app-usage.service)
4. **Documentation** throughout the project

### Priority Updates:
1. Fix the [Brain_Shell](file:///home/yemi/.config/quickshell/Brain_Shell) path issue first
2. Ensure all hardcoded paths use relative references where possible
3. Update documentation to reflect new branding