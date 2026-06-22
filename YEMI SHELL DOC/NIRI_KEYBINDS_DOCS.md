# Niri Compositor Key Bindings Documentation

## Overview

Niri is a Wayland compositor that uses a scrollable-tiling layout where windows arrange in an infinite horizontal strip. Users scroll left/right to navigate between columns of windows. This documentation covers the key bindings and configuration for the iNiR shell, which is a custom shell built on top of Niri.

## Configuration Structure

The Niri configuration is modularly organized in the `dist/niri/config.d/` directory with the following files:

- `10-input-and-cursor.kdl`: Input devices, gestures & cursor settings
- `20-layout-and-overview.kdl`: Layout, gaps, borders, shadows & overview settings
- `30-window-rules.kdl`: Window rules and application-specific configurations
- `40-environment.kdl`: Environment variables (Qt, XDG, theming)
- `50-startup.kdl`: Processes spawned at login
- `60-animations.kdl`: Animation settings and spring physics
- `70-binds.kdl`: Key bindings (the primary focus of this documentation)
- `80-layer-rules.kdl`: Layer rules for bars, panels, and overlays
- `90-user-extra.kdl`: User-specific overrides (never touched by updates)

## Key Binding Structure

In Niri, key bindings are defined in the `binds` block. The "Mod" key refers to:
- Super key when running on bare metal
- Alt key when running inside a nested Niri window

## Key Bindings Reference

### Session & Compositor

| Key Combination | Action | Description |
|----------------|--------|-------------|
| `Mod+Tab` | Toggle Overview | Shows Niri's built-in overview (zoomed-out workspace view) |
| `Mod+Shift+E` | Quit | Quits Niri (shows confirmation dialog) |
| `Mod+Escape` | Toggle Keyboard Shortcuts Inhibit | Escape hatch to re-enable keybinds if an app inhibits them (e.g. RDP client) |
| `Mod+Shift+O` | Power Off Monitors | Powers off all monitors. Any input wakes them up |

### Shell Overlays & Tools

| Key Combination | Action | Description |
|----------------|--------|-------------|
| `Alt+Tab` | Alt Switcher Next | Switches to the next window using Shell by Yemi |
| `Alt+Shift+Tab` | Alt Switcher Previous | Switches to the previous window using Shell by Yemi |
| `Super+G` | Overlay Toggle | Toggles crosshair overlay |
| `Mod+Space` | Overview Toggle | Opens iNiR app launcher / overview |
| `Mod+V` | Clipboard Toggle | Toggles clipboard history overlay |
| `Mod+Alt+L` | Lock Screen | Activates lock screen |
| `Mod+Ctrl+Shift+L` | Lock Focus | Re-focuses the lock surface (workaround when input feels dead after suspend/resume) |

### Region Selector Tools

| Key Combination | Action | Description |
|----------------|--------|-------------|
| `Mod+Shift+S` | Region Screenshot | Opens region selector for screenshots |
| `Mod+Shift+X` | Region OCR | Opens region selector for OCR (Optical Character Recognition) |
| `Mod+Shift+A` | Region Search | Opens region selector for Google Lens search |
| `Ctrl+Shift+S` | Region Menu | Opens unified snip menu with action/scope toolbar |

### System Tools

| Key Combination | Action | Description |
|----------------|--------|-------------|
| `Ctrl+Alt+T` | Wallpaper Selector | Toggles wallpaper selector |
| `Mod+Comma` | Settings | Opens settings panel |
| `Mod+Slash` | Cheatsheet | Toggles help/cheatsheet |
| `Mod+Shift+W` | Panel Family | Cycles through panel families |
| `Mod+Shift+Q` | Session Dialog | Toggles session/power dialog |

### App Launchers

| Key Combination | Action | Description |
|----------------|--------|-------------|
| `Mod+T` | Terminal | Launches terminal via Shell by Yemi |
| `Mod+Return` | Terminal | Launches terminal via Shell by Yemi |
| `Super+E` | File Manager | Launches Nautilus file manager |
| `Super+W` | Browser | Launches web browser via Shell by Yemi |

## Configuration Details

### Input & Cursor Settings
- Keyboard layout: US English (`layout "us"`)
- Repeat delay: 250ms
- Repeat rate: 50 chars/sec
- Touchpad: Tap enabled with left-right-middle button mapping
- Mouse acceleration: Flat profile (raw movement)
- Cursor theme: Capitaine Light (24px size)
- Cursor hides when typing

### Layout Settings
- Gaps between windows: 25px
- Focus ring: Disabled
- Border: Disabled
- Shadow: Softness 30px, spread 5px, offset 0x5px
- Default column width: 50% of output width
- Preset column widths: 33%, 50%, 66% of output width
- Single column always centered on empty workspace

### Animation Settings
All animations use spring physics with configurable damping ratio and stiffness:
- Workspace switch: Critically damped (0.98) with 300 stiffness
- Window open/close: Critically damped (0.98) with 300 stiffness (close has low damping for fade effect)
- Horizontal view movement: Critically damped (0.98) with 300 stiffness
- Window movement: Critically damped (0.98) with 900 stiffness (faster for dragging)
- Window resize: Critically damped (0.98) with 300 stiffness

### Window Rules
- All windows have rounded corners (16px radius)
- Unfocused windows have slightly reduced opacity (0.9)
- Special handling for WezTerm, Firefox, Zen, and Steam applications

### Startup Services
- XDG environment variables imported to systemd user session
- Clipboard history with separate watchers for text and images
- Polkit authentication agent for GUI sudo prompts
- QuickShell launched with the Shell by Yemi configuration

## Customization

The `90-user-extra.kdl` file is reserved for user-specific customizations that won't be overwritten during updates. You can add:

- Named workspaces
- Per-app workspace assignments
- Extra key bindings
- Output configurations
- Custom window rules

Example for adding named workspaces:
```kdl
workspace "browser"
workspace "code"
workspace "music"

window-rule {
    match app-id="firefox"
    open-on-workspace "browser"
}
```

## Shell by Yemi Integration

The key bindings are designed to integrate with Shell by Yemi, which provides:
- QML-based shell interface
- Application launcher
- Wallpaper picker
- Music controls
- Notification management
- System controls

The shell uses IPC (Inter-Process Communication) handlers to respond to key bindings for:
- Launcher (`target: "launcher"`)
- Wallpaper (`target: "wallpaper"`)
- Music (`target: "music"`)
- Colors (`target: "colors"`)
- Settings (`target: "settings"`)

## Troubleshooting

### Key Bindings Not Working
- Check that your configuration files are syntactically correct
- Ensure you're using the correct modifier key (Super vs Alt depending on context)
- Verify that no other applications are capturing the same key combinations

### Shell Not Responding
- Make sure Shell by Yemi is running: `quickshell -p /home/yemi/.config/quickshell/shell.qml`
- Check that the IPC handlers are properly configured in shell.qml
- Verify that all required dependencies are installed

### Missing Features
- Some features may require additional tools to be installed separately
- Check the README.md for complete dependency list
- Ensure all configuration files are in the correct locations