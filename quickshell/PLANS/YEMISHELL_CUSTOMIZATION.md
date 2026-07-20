# YemiShell Customization Guide

This document lists all files that can be customized with your name "yemiShell" or "Yemi Shell". Files are organized by category with specific recommendations for what to rename in each.

---

## 1. Documentation Files (50+ files)

**Directory**: `YEMI SHELL DOC/`

All `.md` files in this directory contain "Yemi QuickShell" branding in their descriptions. These are auto-generated documentation files.

### Files to customize:
- `YEMI SHELL DOC/doc/index.md` - Main documentation index
- `YEMI SHELL DOC/doc/*.md` - All 50+ component documentation files

### What to change:
- Replace "Yemi QuickShell" with "YemiShell" or "Yemi Shell"
- Replace "Yemi QuickShell desktop" with "YemiShell desktop"

### Example changes:
```markdown
# Before: "Developer reference for the Yemi QuickShell desktop environment."
# After:  "Developer reference for the YemiShell desktop environment."
```

---

## 2. Entry Point & Core Files

### `shell.qml`
**Lines to customize:**
- Line 449: `console.log("QuickShell loaded successfully!")`
- Line 254: `property string configPath: homePath + "/.config/quickshell"`

**Changes:**
```qml
// Before:
console.log("QuickShell loaded successfully!")
property string configPath: homePath + "/.config/quickshell"

// After:
console.log("YemiShell loaded successfully!")
property string configPath: homePath + "/.config/yemi-shell"
```

---

## 3. Scripts

### `install.sh`
**Lines to customize:**
- Line 43: `TARGET_DIR="$HOME/.config/quickshell"`
- Line 48: `# --- packages found from the QuickShell config -------------------------------`
- Line 74-76: Package references
- Line 255: `step "Checking QuickShell config"`
- Line 333: `ok "QuickShell rice install complete"`
- Line 337: `echo " 2. Add this to Hyprland: exec-once = quickshell"`

**Changes:**
```bash
# Before:
TARGET_DIR="$HOME/.config/quickshell"
step "Checking QuickShell config"
ok "QuickShell rice install complete"

# After:
TARGET_DIR="$HOME/.config/yemi-shell"
step "Checking YemiShell config"
ok "YemiShell rice install complete"
```

### `reload-shell.sh`
**Lines to customize:**
- Line 4: `if pgrep -x quickshell > /dev/null; then`
- Line 5: `echo "Stopping QuickShell..."`
- Line 21: `echo "Starting QuickShell..."`
- Line 22: `nohup quickshell > /dev/null 2>&1 &`

**Changes:**
```bash
# Before:
if pgrep -x quickshell > /dev/null; then
echo "Stopping QuickShell..."
nohup quickshell > /dev/null 2>&1 &

# After:
if pgrep -x yemi-shell > /dev/null; then
echo "Stopping YemiShell..."
nohup yemi-shell > /dev/null 2>&1 &
```

### `scripts/after-wall.sh`
**Line 2:**
```bash
# Before:
# Run wallcolors.py to generate ~/.cache/yemi-shell/colors.json from wallpaper

# After (already uses yemi-shell, just update comment):
# Run wallcolors.py to generate YemiShell colors from wallpaper
```

### `scripts/wallcolors.py`
**Line 20:**
```python
# Before:
CACHE = Path.home() / ".cache" / "yemi-shell"

# After (already uses yemi-shell):
CACHE = Path.home() / ".cache" / "yemi-shell"  # Already correct
```

### `scripts/toggle-colormode.sh`
**Lines 5, 43:**
```bash
# Before:
STATE_FILE="$HOME/.config/quickshell/state/colormode"
python3 "$HOME/.config/quickshell/scripts/wallcolors.py" "$wallpaper"

# After:
STATE_FILE="$HOME/.config/yemi-shell/state/colormode"
python3 "$HOME/.config/yemi-shell/scripts/wallcolors.py" "$wallpaper"
```

### `scripts/reset-app-usage.sh`
**Line 4:**
```bash
# Before:
usage_file="${HOME}/.config/quickshell/app_usage.json"

# After:
usage_file="${HOME}/.config/yemi-shell/app_usage.json"
```

### `scripts/start-quickshell.sh`
(If exists - check for quickshell references)

---

## 4. Service Files

### `services/Notifs.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Matugen.qml`
**Lines 10, 22:**
```qml
// Before:
readonly property string colorsPath: Quickshell.env("HOME") + "/.config/quickshell/state/colors.qml"
var matugenConfigPath = Quickshell.env("HOME") + "/.config/quickshell/dist/matugen/config.toml";

// After:
readonly property string colorsPath: Quickshell.env("HOME") + "/.config/yemi-shell/state/colors.qml"
var matugenConfigPath = Quickshell.env("HOME") + "/.config/yemi-shell/dist/matugen/config.toml";
```

### `services/IdleInhibitor.qml`
**Line 35:**
```qml
// Before:
command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='Caffeine mode enabled' sleep infinity & echo $!"]

// After:
command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=YemiShell --why='Caffeine mode enabled' sleep infinity & echo $!"]
```

### `services/VolumeMonitor.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Network.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Bluetooth.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Brightness.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Audio.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/SystemUsage.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Screenshot.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Logger.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/PowerProfiles.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Players.qml`
**No direct branding** - Uses Quickshell API imports only.

### `services/Hyprsunset.qml`
**No direct branding** - Uses Quickshell API imports only.

---

## 5. Singleton Files

### `singletons/Flags.qml`
**Line 8:**
```qml
// Before:
* so every Shell by Yemi daemon (pill, bar, sidebar) reads and writes

// After:
* so every YemiShell daemon (pill, bar, sidebar) reads and writes
```

### `singletons/Dyn.qml`
**Line 37:**
```qml
// Before:
path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yemi-shell/colors.json"

// After (already uses yemi-shell):
path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yemi-shell/colors.json"
```

### `singletons/Metrics.qml`
**No direct branding** - Uses Quickshell API imports only.

### `singletons/Theme.qml`
**No direct branding** - Uses Quickshell API imports only.

### `singletons/PillState.qml`
**No direct branding** - Uses Quickshell API imports only.

---

## 6. Module Files

### `modules/pill/Pill.qml`
**Line 559:**
```qml
// Before:
// 🎛️ TWEAK ZONE — Yemi, adjust these yourself:

// After:
// 🎛️ TWEAK ZONE — YemiShell user, adjust these yourself:
```

### `modules/pill/Launcher.qml`
**Line 49:**
```qml
// Before:
readonly property string usageFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/yemi-shell/launcher-usage.json"

// After (already uses yemi-shell):
readonly property string usageFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/yemi-shell/launcher-usage.json"
```

### `modules/pill/Updates.qml`
**Line 27:**
```qml
// Before:
readonly property string repoDir: "$HOME/.config/quickshell"

// After:
readonly property string repoDir: "$HOME/.config/yemi-shell"
```

### `modules/pill/Display.qml`
**Lines 30-31:**
```qml
// Before:
readonly property string monitorsPath: Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"
readonly property string helper: Quickshell.env("HOME") + "/.config/hypr/scripts/display-apply.sh"

// After (these are Hyprland paths, not quickshell paths - may not need changing):
readonly property string monitorsPath: Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"
readonly property string helper: Quickshell.env("HOME") + "/.config/hypr/scripts/display-apply.sh"
```

### `modules/pill/Input.qml`
**Lines 27-29:**
```qml
// Before:
readonly property string inputPath: Quickshell.env("HOME") + "/.config/hypr/modules/input.lua"
readonly property string envPath: Quickshell.env("HOME") + "/.config/hypr/modules/env.lua"
readonly property string autostartPath: Quickshell.env("HOME") + "/.config/hypr/modules/autostart.lua"

// After (these are Hyprland paths, not quickshell paths - may not need changing):
readonly property string inputPath: Quickshell.env("HOME") + "/.config/hypr/modules/input.lua"
readonly property string envPath: Quickshell.env("HOME") + "/.config/hypr/modules/env.lua"
readonly property string autostartPath: Quickshell.env("HOME") + "/.config/hypr/modules/autostart.lua"
```

### `modules/pill/IdleLock.qml`
**Lines 25-26:**
```qml
// Before:
readonly property string confPath: Quickshell.env("HOME") + "/.config/hypr/hypridle.conf"
readonly property string lockScript: Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"

// After (these are Hyprland paths, not quickshell paths - may not need changing):
readonly property string confPath: Quickshell.env("HOME") + "/.config/hypr/hypridle.conf"
readonly property string lockScript: Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"
```

### `modules/pill/Wallpaper.qml`
**Line 191:**
```qml
// Before:
readonly property string searchScript: Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-search.sh"

// After (this is a Hyprland script path - may not need changing):
readonly property string searchScript: Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-search.sh"
```

### `modules/pill/Power.qml`
**Line 51:**
```qml
// Before:
{ key: "lock", glyph: "lock", label: "Lock", confirm: false, dispatch: "", argv: [Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"] }

// After (this is a Hyprland script path - may not need changing):
{ key: "lock", glyph: "lock", label: "Lock", confirm: false, dispatch: "", argv: [Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"] }
```

### `modules/pill/Keybinds.qml`
**Line 41:**
```qml
// Before:
readonly property string bindsPath: Quickshell.env("HOME") + "/.config/hypr/modules/binds.lua"

// After (this is a Hyprland path - may not need changing):
readonly property string bindsPath: Quickshell.env("HOME") + "/.config/hypr/modules/binds.lua"
```

### `modules/pill/Singletons/Weather.qml`
**Line 27:**
```qml
// Before:
readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yemi-shell"

// After (already uses yemi-shell):
readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yemi-shell"
```

### `modules/pill/Singletons/ScreenRec.qml`
**Lines 39, 49-50:**
```qml
// Before:
* `$XDG_CACHE_HOME/yemi-shell/rec-thumbs`, skipping clips already cached)
readonly property string defaultDir: home + "/Videos/Recordings"
readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/yemi-shell/rec-thumbs/"
readonly property string thumbScript: home + "/.config/hypr/scripts/rec-thumbs.sh"

// After (already uses yemi-shell):
readonly property string defaultDir: home + "/Videos/Recordings"
readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/yemi-shell/rec-thumbs/"
readonly property string thumbScript: home + "/.config/hypr/scripts/rec-thumbs.sh"
```

### `modules/pill/Singletons/Events.qml`
**Line 31:**
```qml
// Before:
readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/yemi-shell"

// After (already uses yemi-shell):
readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/yemi-shell"
```

### `modules/pill/Singletons/Devices.qml`
**Line 20:**
```qml
// Before:
readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/yemi-shell/nvibrant-value"

// After (already uses yemi-shell):
readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/yemi-shell/nvibrant-value"
```

---

## 7. Compositor Files

### `compositor/Compositor.qml`
**No direct branding** - Uses Quickshell API imports only.

### `compositor/Hyprland.qml`
**No direct branding** - Uses Quickshell API imports only.

### `compositor/Niri.qml`
**No direct branding** - Uses Quickshell API imports only.

---

## 8. Config Files

### `config/Config.qml`
**No direct branding** - Uses Quickshell API imports only.

### `config/Appearance.qml`
**No direct branding** - Uses Quickshell API imports only.

### `config/BarConfig.qml`
**No direct branding** - Uses Quickshell API imports only.

### `config/AppearanceConfig.qml`
**No direct branding** - Uses Quickshell API imports only.

---

## 9. Bar Module Files

### `modules/bar/Bar.qml`
**No direct branding** - Uses Quickshell API imports only.

### `modules/bar/BarWrapper.qml`
**No direct branding** - Uses Quickshell API imports only.

### `modules/bar/components/*.qml`
**No direct branding** - All use Quickshell API imports only.

---

## 10. Pill Module Files

### `modules/pill/*.qml`
**Most files have no direct branding** - Use Quickshell API imports only.

**Exception**: `Pill.qml` line 559 has "Yemi" comment (see section 6).

---

## 11. Niri Configuration Files

### `dist/niri/config.d/50-startup.kdl`
**Lines 30-32:**
```kdl
// Before:
// ── Shell by Yemi ───────────────────────────────────────────────────────────
// Start this Quickshell config when Niri starts.
spawn-at-startup "quickshell" "-p" "/home/yemi/.config/quickshell/shell.qml"

// After:
// ── YemiShell ───────────────────────────────────────────────────────────
// Start this YemiShell config when Niri starts.
spawn-at-startup "yemi-shell" "-p" "/home/yemi/.config/yemi-shell/shell.qml"
```

### `dist/niri/config.d/70-binds.kdl`
**Multiple lines with YEMI-SHELL branding:**
- Line 9: `// Once iNiR binds But Now Modify For YEMI-SHELL route through the YEMI-SHELL launcher`
- Line 19: `// YEMI-SHELL built-in overview (zoomed-out workspace view).`
- Line 32: `// ═══════════════════════════════════════════════════════════════════════`
- Line 33: `// YEMI-SHELL overlays & tools`
- Line 35: `// Alt-Tab window switcher (YEMI-SHELL's animated switcher).`
- Line 42: `// Call Yemi's custom shell script for crosshair overlay`
- Line 45: `// YEMI-SHELL app launcher (via QuickShell IPC).`
- Line 48: `// Clipboard history overlay.`
- Line 49: `// Call Yemi's custom shell script for clipboard`
- Line 52: `// Lock screen.`
- Line 53: `// Call Yemi's custom shell script for lock screen`
- Line 59: `// Region selector: screenshot / OCR / Google Lens search.`
- Line 60: `// Call Yemi's custom shell script for region selection`
- Line 71: `// Wallpaper picker (via QuickShell IPC).`
- Line 72: `// Call Yemi's custom shell script for settings`
- Line 74: `// Call Yemi's custom shell script for cheatsheet`
- Line 76: `// Call Yemi's custom shell script for panel family`
- Line 80: `// Call Yemi's custom shell script for session`
- Line 92: `// Call Yemi's custom shell script for browser`

**Changes:**
```kdl
// Before:
// Once iNiR binds But Now Modify For YEMI-SHELL route through the `YEMI-SHELL` launcher
// YEMI-SHELL built-in overview (zoomed-out workspace view).
// YEMI-SHELL overlays & tools
// Alt-Tab window switcher (YEMI-SHELL's animated switcher).
// Call Yemi's custom shell script for crosshair overlay
// YEMI-SHELL app launcher (via QuickShell IPC).

// After:
// Once iNiR binds But Now Modify For YemiShell route through the `YemiShell` launcher
// YemiShell built-in overview (zoomed-out workspace view).
// YemiShell overlays & tools
// Alt-Tab window switcher (YemiShell's animated switcher).
// Call YemiShell's custom shell script for crosshair overlay
// YemiShell app launcher (via QuickShell IPC).
```

### `dist/niri/config.d/40-environment.kdl`
**Line 24:**
```kdl
// Before:
QT_LOGGING_RULES "quickshell.dbus.properties=false"

// After:
QT_LOGGING_RULES "yemi-shell.dbus.properties=false"
```

### `dist/niri/config.d/80-layer-rules.kdl`
**Lines 16, 23:**
```kdl
// Before:
match namespace="quickshell:iiBackdrop"
match namespace="quickshell:wBackdrop"

// After:
match namespace="yemi-shell:iiBackdrop"
match namespace="yemi-shell:wBackdrop"
```

---

## 12. Matugen Configuration

### `dist/matugen/config.toml`
**Lines 2-3:**
```toml
# Before:
input_path = "~/.config/quickshell/dist/matugen/templates/shell-colors.qml"
output_path = "~/.config/quickshell/state/colors.qml"

# After:
input_path = "~/.config/yemi-shell/dist/matugen/templates/shell-colors.qml"
output_path = "~/.config/yemi-shell/state/colors.qml"
```

### `dist/matugen/templates/shell-colors.qml`
**Line 2:**
```qml
// Before:
// Generated by Matugen - do not edit manually
// TODO(yemi): map remaining roles

// After:
// Generated by Matugen - do not edit manually
// TODO: map remaining roles
```

---

## 13. Systemd Service Files

### `quickshell-reset-app-usage.service`
**Lines 2-3, 9:**
```ini
# Before:
Description=Reset QuickShell launcher app usage on session shutdown
Documentation=file:%h/.config/quickshell/app_usage.json
ExecStop=%h/.config/quickshell/scripts/reset-app-usage.sh

# After:
Description=Reset YemiShell launcher app usage on session shutdown
Documentation=file:%h/.config/yemi-shell/app_usage.json
ExecStop=%h/.config/yemi-shell/scripts/reset-app-usage.sh
```

---

## 14. Skill & Rule Files

### `.lingma/rules/SKILL.md`
**Lines 7-8, 37-38, 982-983:**
```markdown
# Before:
for desktop, embedded, and web targets. Includes project-specific rules for the Yemi QuickShell desktop
environment with Hyprland/Niri compositor support.

# After:
for desktop, embedded, and web targets. Includes project-specific rules for the YemiShell desktop
environment with Hyprland/Niri compositor support.
```

### `.lingma/rules/yemi-shell-audit.md`
**Line 1:**
```markdown
# Before:
# Yemi Shell Deep Audit Report

# After:
# YemiShell Deep Audit Report
```

### `.lingma/rules/combined-skill.md`
**Lines 5164-5168:**
```markdown
# Before:
**Shell by Yemi** — a custom QuickShell desktop shell for Wayland.
- Supports both **Hyprland** and **Niri** via a compositor abstraction layer.
- Reorganizing into a clean **modular folder structure**.
- Fixing keybinds that point to the missing `inir` binary — these need to redirect to my own QuickShell services (e.g. `Audio.qml`, `Brightness.qml` via `qs ipc call`).

# After:
**YemiShell** — a custom desktop shell for Wayland.
- Supports both **Hyprland** and **Niri** via a compositor abstraction layer.
- Reorganizing into a clean **modular folder structure**.
- Fixing keybinds that point to the missing `inir` binary — these need to redirect to my own YemiShell services (e.g. `Audio.qml`, `Brightness.qml` via `qs ipc call`).
```

### `.lingma/rules/YemiWorkingRules.md`
**Lines 19-23:**
```markdown
# Before:
**Shell by Yemi** — a custom QuickShell desktop shell for Wayland.
- Supports both **Hyprland** and **Niri** via a compositor abstraction layer.
- Reorganizing into a clean **modular folder structure**.
- Fixing keybinds that point to the missing `inir` binary — these need to redirect to my own QuickShell services (e.g. `Audio.qml`, `Brightness.qml` via `qs ipc call`).

# After:
**YemiShell** — a custom desktop shell for Wayland.
- Supports both **Hyprland** and **Niri** via a compositor abstraction layer.
- Reorganizing into a clean **modular folder structure**.
- Fixing keybinds that point to the missing `inir` binary — these need to redirect to my own YemiShell services (e.g. `Audio.qml`, `Brightness.qml` via `qs ipc call`).
```

---

## 15. Steering Files

### `.kiro/steering/product.md`
**Lines 3-4:**
```markdown
# Before:
Shell by Yemi is a custom QML-based desktop shell for Linux, built on [Quickshell](https://quickshell.outfoxxed.me/). It targets Hyprland as the primary compositor with secondary Niri support in progress.

# After:
YemiShell is a custom QML-based desktop shell for Linux, built on [Quickshell](https://quickshell.outfoxxed.me/). It targets Hyprland as the primary compositor with secondary Niri support in progress.
```

### `.kiro/steering/tech.md`
**Lines 7-8, 17, 33-36, 61-68, 88-90, 97-104:**
```markdown
# Before:
| UI framework | [Quickshell](https://quickshell.outfoxxed.me/) |
| UI language | QML (Qt 6.10) |
- **quickshell** — shell runtime
| Shell entry point | `~/.config/quickshell/shell.qml` |
| Matugen config | `~/.config/quickshell/dist/matugen/config.toml` |
| Generated colors | `~/.config/quickshell/state/colors.qml` |
| App usage data | `~/.config/quickshell/app_usage.json` (also `state/app_usage.json`) |
| Color mode state | `~/.config/quickshell/state/colormode` |
| GIF index state | `~/.config/quickshell/state/gif-index` |
| Wallpapers | `~/wallpapers/` |
| Pywal colors (legacy) | `~/.cache/wal/colors.json` |
| Niri config | `~/.config/quickshell/dist/niri/` |
| Hyprland config | `~/.config/quickshell/dist/hypr/` |
qs -c ~/.config/quickshell
~/.config/quickshell/reload-shell.sh
pkill -f quickshell && qs -c ~/.config/quickshell
journalctl --user -u quickshell -f
cd ~/.config/quickshell
~/.config/quickshell/scripts/toggle-colormode.sh
~/.config/quickshell/scripts/reset-app-usage.sh
~/.config/quickshell/scripts/after-wall.sh
matugen image ~/wallpapers/example.jpg -c ~/.config/quickshell/dist/matugen/config.toml

# After:
| UI framework | [Quickshell](https://quickshell.outfoxxed.me/) |
| UI language | QML (Qt 6.10) |
- **yemi-shell** — shell runtime
| Shell entry point | `~/.config/yemi-shell/shell.qml` |
| Matugen config | `~/.config/yemi-shell/dist/matugen/config.toml` |
| Generated colors | `~/.config/yemi-shell/state/colors.qml` |
| App usage data | `~/.config/yemi-shell/app_usage.json` (also `state/app_usage.json`) |
| Color mode state | `~/.config/yemi-shell/state/colormode` |
| GIF index state | `~/.config/yemi-shell/state/gif-index` |
| Wallpapers | `~/wallpapers/` |
| Pywal colors (legacy) | `~/.cache/wal/colors.json` |
| Niri config | `~/.config/yemi-shell/dist/niri/` |
| Hyprland config | `~/.config/yemi-shell/dist/hypr/` |
qs -c ~/.config/yemi-shell
~/.config/yemi-shell/reload-shell.sh
pkill -f yemi-shell && qs -c ~/.config/yemi-shell
journalctl --user -u yemi-shell -f
cd ~/.config/yemi-shell
~/.config/yemi-shell/scripts/toggle-colormode.sh
~/.config/yemi-shell/scripts/reset-app-usage.sh
~/.config/yemi-shell/scripts/after-wall.sh
matugen image ~/wallpapers/example.jpg -c ~/.config/yemi-shell/dist/matugen/config.toml
```

### `.kiro/steering/structure.md`
**Lines 6-14, 53-54, 86-87:**
```markdown
# Before:
~/.config/quickshell/
├── shell.qml # Entry point — ShellRoot, IPC handlers, all top-level state
├── install.sh # Installation script
├── reload-shell.sh # Kill + restart quickshell
├── ARCHITECTURE.md # Architecture notes
├── NIRI_KEYBINDS_DOCS.md # Niri keybind reference
└── QuickShellKeybinds.conf # Hyprland keybind config
│   ├── BarWrapper.qml Quickshell panel wrapper (loaded via Loader in shell.qml)
├── rmpc/ rmpc music client config
├── quickshell/ Quickshell-specific distributed files
└── templates/ Generic color templates

# After:
~/.config/yemi-shell/
├── shell.qml # Entry point — ShellRoot, IPC handlers, all top-level state
├── install.sh # Installation script
├── reload-shell.sh # Kill + restart yemi-shell
├── ARCHITECTURE.md # Architecture notes
├── NIRI_KEYBINDS_DOCS.md # Niri keybind reference
└── YemiShellKeybinds.conf # Hyprland keybind config
│   ├── BarWrapper.qml YemiShell panel wrapper (loaded via Loader in shell.qml)
├── rmpc/ rmpc music client config
├── yemi-shell/ YemiShell-specific distributed files
└── templates/ Generic color templates
```

---

## 16. Git Configuration

### `.git/config`
**Lines 6-8:**
```ini
# Before:
[user]
name = Yemi Peter
email = yemi.peter@example.com

# After (keep your name, but this is git config not branding):
[user]
name = Yemi Peter
email = yemi.peter@example.com
```

**Note**: Git config is personal preference, not shell branding.

---

## 17. Directory Renaming

If you want to fully rebrand, consider renaming these directories:

| Current Name | Suggested Name |
|--------------|----------------|
| `YEMI SHELL DOC/` | `YEMISHELL DOC/` or `yemi-shell-doc/` |
| `.config/quickshell/` | `.config/yemi-shell/` |
| `.cache/yemi-shell/` | `.cache/yemi-shell/` (already correct) |
| `.local/state/yemi-shell/` | `.local/state/yemi-shell/` (already correct) |

---

## Summary of Critical Changes

### Must Change (Branding):
1. `shell.qml` - console.log and configPath
2. `install.sh` - TARGET_DIR and messages
3. `reload-shell.sh` - process name and messages
4. `quickshell-reset-app-usage.service` - Description and paths
5. `dist/niri/config.d/50-startup.kdl` - spawn command and comments
6. `dist/niri/config.d/70-binds.kdl` - YEMI-SHELL comments
7. `dist/niri/config.d/40-environment.kdl` - QT_LOGGING_RULES
8. `dist/niri/config.d/80-layer-rules.kdl` - namespace
9. `dist/matugen/config.toml` - paths
10. `YEMI SHELL DOC/doc/*.md` - all documentation
11. `.kiro/steering/*.md` - product description
12. `.lingma/rules/*.md` - skill rules

### Already Correct (uses yemi-shell):
- `singletons/Dyn.qml` - path uses `/yemi-shell/`
- `modules/pill/Launcher.qml` - path uses `/yemi-shell/`
- `modules/pill/Singletons/Weather.qml` - path uses `/yemi-shell/`
- `modules/pill/Singletons/ScreenRec.qml` - path uses `/yemi-shell/`
- `modules/pill/Singletons/Events.qml` - path uses `/yemi-shell/`
- `modules/pill/Singletons/Devices.qml` - path uses `/yemi-shell/`
- `scripts/wallcolors.py` - path uses `/yemi-shell/`
- `scripts/after-wall.sh` - path uses `/yemi-shell/`

### Optional Change (Hyprland paths):
- `modules/pill/Display.qml` - Hyprland script paths
- `modules/pill/Input.qml` - Hyprland config paths
- `modules/pill/IdleLock.qml` - Hyprland config paths
- `modules/pill/Wallpaper.qml` - Hyprland script paths
- `modules/pill/Power.qml` - Hyprland script paths
- `modules/pill/Keybinds.qml` - Hyprland config paths

These are Hyprland-specific paths, not QuickShell branding. Only change if you also rename Hyprland config directories.

---

## Quick Rename Script

Create a script to automate the most common renames:

```bash
#!/bin/bash
# rename-to-yemi-shell.sh

# Rename config directory
mv ~/.config/quickshell ~/.config/yemi-shell

# Update paths in key files
find ~/.config/yemi-shell -type f \( -name "*.qml" -o -name "*.sh" -o -name "*.py" -o -name "*.md" -o -name "*.kdl" -o -name "*.toml" -o -name "*.service" \) -exec sed -i 's|/.config/quickshell|/.config/yemi-shell|g' {} +

# Update process names
find ~/.config/yemi-shell -type f \( -name "*.sh" -o -name "*.kdl" -o -name "*.md" \) -exec sed -i 's|quickshell|yemi-shell|g' {} +

# Update branding
find ~/.config/yemi-shell -type f \( -name "*.md" -o -name "*.kdl" \) -exec sed -i 's|QuickShell|YemiShell|g' {} +
find ~/.config/yemi-shell -type f \( -name "*.md" -o -name "*.kdl" \) -exec sed -i 's|Yemi QuickShell|YemiShell|g' {} +
find ~/.config/yemi-shell -type f \( -name "*.md" -o -name "*.kdl" \) -exec sed -i 's|Shell by Yemi|YemiShell|g' {} +

echo "Renaming complete! Review changes with: git diff"
```

**Warning**: Always backup before running automated rename scripts. Review changes with `git diff` before committing.
