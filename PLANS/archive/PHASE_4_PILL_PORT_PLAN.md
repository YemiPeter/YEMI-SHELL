# Phase 4: Pill-Surface Launcher — Full Port Plan
**Status:** IN PROGRESS
**Scope:** Full Ricelin pill system (Option A — all 18 surfaces)
**Source:** `.Ricelin/configs/quickshell/pill/`

---

## Architecture

```
Bar (5 pills total)
├── LEFT: Workspaces — fixed, stays as-is
├── CENTER: Full Pill.qml — morphs between all 18 surfaces
│   ├── Launcher (search + app list)
│   ├── Calendar
│   ├── Mixer (audio)
│   ├── Media (MPRIS)
│   ├── Clipboard
│   ├── Wallpaper
│   ├── Power
│   ├── Link (network/BT)
│   ├── BatterySurface
│   ├── Settings → Appearance, Updates, Display, Input, Look, IdleLock, FontPicker
│   ├── Keybinds
│   ├── Recorder
│   ├── SysmonSurface
│   └── Toast (notification popups)
├── RIGHT-1: WiFi/BT — fixed, stays as-is
├── RIGHT-2: Brightness/Volume — fixed, stays as-is
└── RIGHT-3: Battery/charging — fixed, stays as-is
```

---

## File Inventory

### Core (must port first)
| File | Lines | Role |
|------|-------|------|
| `Pill.qml` | 1,646 | Pill body — morphing container, surface gating, all state |
| `PillSurface.qml` | 52 | Base class for all surfaces |
| `shell.qml` | 399 | Top-level ShellRoot — PanelWindows, monitor management |
| `qmldir` | — | Module registration |

### Surfaces (18 files)
| Surface | File | Key Dependencies |
|---------|------|-----------------|
| Launcher | `Launcher.qml` | Quickshell.Io, fuzzy.js |
| Calendar | `Calendar.qml` | QtQuick.Controls |
| Mixer | `Mixer.qml` | Quickshell.Io, **Pipewire** |
| Media | `Media.qml` | Quickshell.Widgets, **Mpris** |
| Clipboard | `Clipboard.qml` | — |
| Wallpaper | `Wallpaper.qml` | Quickshell.Io, Quickshell.Widgets |
| Power | `Power.qml` | Quickshell, Quickshell.Hyprland, Quickshell.Widgets |
| Link | `Link.qml` | Quickshell.Io, Quickshell.Networking, Quickshell.Bluetooth |
| Battery | `BatterySurface.qml` | — |
| Settings | `Settings.qml` | — |
| Appearance | `Appearance.qml` | Quickshell.Io |
| Updates | `Updates.qml` | Quickshell.Io |
| Display | `Display.qml` | Quickshell.Io, monitors.js |
| Input | `Input.qml` | Quickshell.Io, setInput.js |
| Look | `Look.qml` | Quickshell.Io, setDeco.js |
| IdleLock | `IdleLock.qml` | Quickshell.Io |
| Keybinds | `Keybinds.qml` | Quickshell.Io |
| FontPicker | `FontPicker.qml` | QtQuick.Controls |
| Sysmon | `SysmonSurface.qml` | — |
| Recorder | `Recorder.qml` | Quickshell.Widgets, **Pipewire** |

### Support Components
| File | Role |
|------|------|
| `SearchField.qml` | Search input for launcher |
| `GlyphIcon.qml` | Icon renderer |
| `Marquee.qml` | Scrolling text |
| `Tooltip.qml` | Hover tooltips |
| `Toast.qml` | Notification popup surface |
| `Tray.qml` | System tray surface |
| `MinimizedTray.qml` | Minimized window tray |
| `WifiGlyph.qml` | WiFi signal icon |
| `Workspaces.qml` | Workspace selector (pill version) |
| `Osd.qml` | OSD overlay |
| `SettingsHeader.qml` | Settings section header |
| `SettingsRow.qml` | Settings row |
| `SettingsSeg.qml` | Settings segmented control |
| `SettingsSurface.qml` | Settings base surface |
| `DisplayLabel.qml` | Display setting label |
| `DisplayPicker.qml` | Display setting picker |
| `Filament.qml` | Visual effect |
| `HFader.qml` | Horizontal fader |
| `VFader.qml` | Vertical fader |
| `HeatHold.qml` | Hold-to-confirm |
| `WheelScroller.qml` | Scroll wheel handler |
| `Ame.qml` | Cursor flame effect |
| `LinkBt.qml` | Bluetooth device row |
| `LinkToggle.qml` | Toggle switch |
| `LinkWifi.qml` | WiFi network row |

### Libraries (JS)
| File | Role |
|------|------|
| `lib/fuzzy.js` | Fuzzy search (already in project) |
| `lib/binds.js` | Keybind parsing |
| `lib/keychord.js` | Key chord capture |
| `lib/monitors.js` | Display monitor parsing |
| `lib/setDeco.js` | Decoration (rounded corners) |
| `lib/setInput.js` | Input method switching |

### Ricelin Singletons (14 files — need bridging)
| Singleton | Purpose | Action |
|-----------|---------|--------|
| `Theme.qml` | Colors, fonts, borders | **BRIDGE** to QsSingletons.Theme |
| `Dyn.qml` | Dynamic colors from matugen | **BRIDGE** to QsSingletons.Dyn |
| `Flags.qml` | Time format, glyphs, DND, opacity | **PORT** (no equivalent) |
| `Motion.qml` | Animation timings, easing curves | **PORT** (no equivalent) |
| `Notifs.qml` | Notification state | **BRIDGE** to QsServices.Notifs |
| `Battery.qml` | Battery state | **BRIDGE** to UPower |
| `ScreenRec.qml` | Screen recording | **PORT** (or stub) |
| `Sysmon.qml` | CPU/RAM stats | **BRIDGE** to QsServices.SystemUsage |
| `Weather.qml` | Weather data | **PORT** (or stub) |
| `Workspacerules.qml` | Workspace rules | **PORT** (or stub) |
| `Events.qml` | Event tracking | **PORT** (or stub) |
| `Cliphist.qml` | Clipboard history | **PORT** (or stub) |
| `Devices.qml` | Device management | **PORT** (or stub) |
| `Walls.qml` | Wallpaper management | **BRIDGE** to existing wall system |

---

## Services to Add

| Service | Needed By | Status |
|---------|-----------|--------|
| `Mpris` | Media, Osd, Pill.qml | **MISSING** — needs implementation |
| `Pipewire` | Mixer, Recorder, Osd | **MISSING** — needs implementation |
| `SystemTray` | Tray | **MISSING** — needs implementation |
| `Notifications` | Toast, Link | **MISSING** — needs implementation |

---

## Porting Sequence

### Phase 4A: Foundation (singletons + services)
1. Port `Flags.qml` — no dependencies, used everywhere
2. Port `Motion.qml` — no dependencies, used everywhere
3. Bridge `Theme.qml` → map Ricelin's Theme properties to QsSingletons.Theme
4. Bridge `Dyn.qml` → map to QsSingletons.Dyn
5. Bridge `Notifs.qml` → map to QsServices.Notifs
6. Bridge `Battery.qml` → map to UPower
7. Bridge `Sysmon.qml` → map to QsServices.SystemUsage
8. Stub `ScreenRec.qml` — minimal implementation
9. Stub `Weather.qml` — minimal implementation
10. Stub `Workspacerules.qml` — minimal implementation
11. Stub `Events.qml` — minimal implementation
12. Stub `Cliphist.qml` — minimal implementation
13. Stub `Devices.qml` — minimal implementation
14. Bridge `Walls.qml` → map to existing wall system

### Phase 4B: Core Pill
15. Port `PillSurface.qml` — base class
16. Port `Pill.qml` — the orchestrator (1,646 lines)
17. Port `shell.qml` — top-level ShellRoot

### Phase 4C: Surfaces (vertical slice — launcher first)
18. Port `SearchField.qml` — launcher dependency
19. Port `Launcher.qml` — first surface to verify
20. Port remaining surfaces one by one

### Phase 4D: Integration
21. Update `Bar.qml` center slot: replace Clock loader with Pill loader
22. Theme integration: ensure all Ricelin Theme.* refs resolve
23. Add missing services (Mpris, Pipewire, SystemTray, Notifications)
24. Full runtime verification

---

## Critical Adaptation Points

### Theme Bridging
Ricelin's `Theme.qml` has ~40 properties. Your `QsSingletons.Theme` has a different set. The bridge must:
- Map Ricelin's `Theme.cream` → `QsSingletons.Theme.cream`
- Map Ricelin's `Theme.dim` → `QsSingletons.Theme.dim`
- Map Ricelin's `Theme.verm` → `QsSingletons.Theme.verm` (or equivalent)
- Handle any properties that don't exist in your Theme (fallback to hardcoded values)

### Usage File Path
- Ricelin: `~/.local/state/ricelin/launcher-usage.json`
- Your project: `~/.local/state/quickshell/launcher-usage.json` (already in `modules/launcher/`)

### Icon Path
- Ricelin: `Quickshell.iconPath(entry.icon, true)`
- Your project: same function, should work as-is

### Hyprland Scripts
Many surfaces reference `.config/hypr/scripts/` and `.config/hypr/modules/` paths. These are Ricelin-specific. Each must be checked:
- Does the script exist in your system?
- If not, stub the surface or implement the script

---

## Estimated Scope

| Category | Count |
|----------|-------|
| Core files | 4 |
| Surfaces | 18 |
| Support components | ~22 |
| JS libraries | 6 |
| Singletons (port/bridge/stub) | 14 |
| New services needed | 4 |
| **Total files to handle** | **~68** |

This is a **full architecture port**, not a 7-task phase. The old Phase 4 plan in QUICKSHELL_CHECKLIST.md is obsolete and must be replaced.
