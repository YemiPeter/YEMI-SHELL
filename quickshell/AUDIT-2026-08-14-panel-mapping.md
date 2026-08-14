# AUDIT — Yemi-Shell Panel Mapping & Dual-Desktop Readiness

**Date:** 2026-08-14
**Mode:** READ-ONLY audit (evidence gathered via grep/cat)
**Scope:** Inventory of Pill vs Waffle panels in `shell.qml`, current loading logic, and gating recommendation for the dual-desktop toggle.

---

## 1. Executive Summary

Yemi-Shell is mid-transition to a **dual-desktop architecture** where users toggle between the **Pill** family (Yemi's custom glass panels) and the **Waffle** family (iNiR's Fluent panels).

**Key finding:** The `panelFamily` config key **exists but is not consumed** by `shell.qml`. The Pill family is **hardcoded and always loaded**, while only the two Waffle panels (background + backdrop) are gated — and they are gated by `enabledPanels`, **not** by `panelFamily`. The `wBar` panel is declared in `config.json` but has **no loader or component** yet.

---

## 2. Current shell.qml Panel Inventory

Source: `grep -nE "PanelWindow|Window|Loader|Item" shell.qml | head -40`

| Line | Construct | Component | Gating |
|------|-----------|-----------|--------|
| 250–254 | `Loader` `barLoader` | `modules/bar/BarWrapper.qml` | **Hardcoded** — always active |
| 257–261 | `Loader` `waffleBackgroundLoader` | `WaffleBackground` | **Gated** — `enabledPanels.includes("wBackground")` |
| 264–268 | `Loader` `waffleBackdropLoader` | `WaffleBackdrop` | **Gated** — `enabledPanels.includes("wBackdrop")` |
| 270–278 | `Component` `wBgPanel` / `wBackdropPanel` | Waffle source components | — |
| 281–287 | `Variants` over `Quickshell.screens` | `Pill.PillOverlay` (one per screen) | **Hardcoded** — always active |
| 291–294 | `Loader` `musicPanelLoader` | `modules/music/MusicPanel.qml` | **Hardcoded** — always active |
| 74–87 | `Qt.createComponent` | `modules/settings/SettingsWindow.qml` | Dynamic (IPC `settings.toggle`) |

### How components are instantiated

- **Hardcoded (always loaded):** Bar, PillOverlay, MusicPanel.
- **Loader with `active:` condition:** Only the two Waffle panels use a `Loader` with an `active:` condition, gated by `Config.options?.enabledPanels`.
- **Dynamic creation:** Settings window via `Qt.createComponent`.

---

## 3. Pill Panels Inventory

Source: `ls -la modules/pill/` + `grep -n "import.*pill\|modules/pill" shell.qml`

**Import in shell.qml (line 12):**
```qml
import "modules/pill" as Pill
```

### Pill family entry points (loaded from shell.qml)

| Component | File | Role |
|-----------|------|------|
| `Pill.PillOverlay` | `modules/pill/PillOverlay.qml` | `PanelWindow` overlay, one per screen (Variants over `Quickshell.screens`). Reads `PillState.openSurface` to drive the morphing pill. |
| `Pill.Pill` | `modules/pill/Pill.qml` (62KB) | The morphing pill; switches between surfaces based on `overlay.surface`. |
| `QsSingletons.PillState` | `singletons/PillState.qml` | Surface toggle/state singleton. |

### Pill surfaces (from Pill.qml lines 36–56)

`mixer, calendar, launcher, clipboard, wallpaper, power, media, link, bluetooth, battery, settings, keybinds, recorder, sysmon, appearance, updates, display, input, look, idlelock, fontpicker`

### Pill surface backing files (modules/pill/)

```
Ame.qml            Appearance.qml     BatterySurface.qml  Calendar.qml
Clipboard.qml      Display.qml        DisplayLabel.qml    DisplayPicker.qml
Filament.qml       FontPicker.qml     GlyphIcon.qml       HeatHold.qml
HFader.qml         IdleLock.qml       Input.qml           KanjiSkip.qml
Keybinds.qml       Launcher.qml       Link.qml            LinkBt.qml
LinkToggle.qml     LinkWifi.qml       Look.qml            Marquee.qml
Media.qml          MinimizedTray.qml  Mixer.qml           Osd.qml
PillOverlay.qml    Pill.qml           PillSurface.qml     Power.qml
Recorder.qml       SearchField.qml    Settings.qml        SettingsHeader.qml
SettingsRow.qml    SettingsSeg.qml    SettingsSurface.qml SysmonSurface.qml
Toast.qml          Tooltip.qml        Tray.qml            Updates.qml
VFader.qml         Wallpaper.qml      WheelScroller.qml   WifiGlyph.qml
Workspaces.qml     shell.qml          Singletons/         lib/
```

### Pill-styled bar

`modules/bar/Bar.qml` is **Pill-styled** — uses `pillBg`, `pillBorder`, `pillSeparator` and references `PillState` (lines 23–25, 46–57). It is loaded via `BarWrapper.qml` (always active).

---

## 4. Waffle Panels Inventory

Source: `ls -la modules/waffle/` + `grep -n "import.*waffle\|modules/waffle" shell.qml`

**Imports in shell.qml (lines 13–14):**
```qml
import "modules/waffle/background" as WaffleBackgroundModule
import "modules/waffle/backdrop" as WaffleBackdropModule
```

### Waffle components

| Component | File | Gating |
|-----------|------|--------|
| `WaffleBackgroundModule.WaffleBackground` | `modules/waffle/background/WaffleBackground.qml` | `enabledPanels.includes("wBackground")` |
| `WaffleBackgroundClock` | `modules/waffle/background/WaffleBackgroundClock.qml` | Used by WaffleBackground |
| `WaffleBackdropModule.WaffleBackdrop` | `modules/waffle/backdrop/WaffleBackdrop.qml` | `enabledPanels.includes("wBackdrop")` |

### ⚠️ Missing `wBar`

`config.json` lists `"wBar"` in `enabledPanels`, but:
- There is **no** `modules/waffle/bar/` directory.
- There is **no** `wBar` loader in `shell.qml`.
- The bar is still the Pill-styled `Bar.qml`.

---

## 5. Existing panelFamily Logic

Source: `grep -n "panelFamily\|enabledPanels\|Config.options" shell.qml | head -20`

```
260:        active: (Config.options?.enabledPanels ?? []).includes("wBackground")
267:        active: (Config.options?.enabledPanels ?? []).includes("wBackdrop")
```

**Result:** `grep panelFamily shell.qml` returns **nothing**. `shell.qml` never reads `panelFamily`.

### Where `panelFamily` IS defined

`modules/common/Config.qml` (the `Config` singleton that shell.qml resolves to — `property alias options: configOptionsJsonAdapter`, line 10):

```qml
// line 397
property list<string> enabledPanels: ["iiBar", "iiBackground", "iiBackdrop", "iiCheatsheet", "iiControlPanel", "iiDock", "iiLock", "iiMediaControls", "iiNotificationPopup", "iiOnScreenDisplay", "iiOnScreenKeyboard", "iiOverlay", "iiOverview", "iiPolkit", "iiRegionSelector", "iiScreenCorners", "iiSessionScreen", "iiSidebarLeft", "iiSidebarRight", "iiTilingOverlay", "iiVerticalBar", "iiWallpaperSelector", "iiCoverflowSelector", "iiClipboard", "iiShellUpdate"]
// line 399
property string panelFamily: "ii" // "ii" or "waffle"
// line 400
property bool familyTransitionAnimation: true // Show animated overlay when switching families
```

**Conclusion:** The config contract supports `panelFamily` (`"ii"` or `"waffle"`) and `familyTransitionAnimation`, but `shell.qml` only consumes `enabledPanels` — and only for the two Waffle loaders. The Pill family is **not gated at all**.

---

## 6. Current config.json State

Source: `cat ~/.config/yemi-shell/config.json`

Resolved path: `Directories.shellConfigPath` = `~/.config/yemi-shell/config.json` (Directories.qml lines 63–65: `shellConfig = ${configPath}/yemi-shell`, `shellConfigName = "config.json"`).

```json
{
  "panelFamily": "waffle",
  "enabledPanels": [
    "wBackdrop",
    "wBackground",
    "wBar"
  ],
  "appearance": {},
  "background": {},
  "waffles": {
    "settings": {
      "useMaterialStyle": false
    }
  }
}
```

---

## 7. Shared vs Exclusive Components

### Shared (both families should use — loaded unconditionally)

| Component | File | Notes |
|-----------|------|-------|
| Bar infrastructure | `modules/bar/BarWrapper.qml` | Currently Pill-styled; needs a Waffle variant for `wBar` |
| Music panel | `modules/music/MusicPanel.qml` | Loaded unconditionally (shell.qml:291–294) |
| OSD | `modules/osd/Wrapper.qml`, `BrightnessOSD.qml`, `VolumeOSD.qml` | Shared utility; **not currently wired into shell.qml** |
| Notification server | `NotificationServer` (shell.qml:229–248) | Shared |
| Services | `services/` (Audio, Battery, Bluetooth, Brightness, DateTime, Hyprsunset, IdleInhibitor, Logger, MprisController, Network, Notifications, Notifs, Players, PowerProfiles, Screenshot, SystemUsage, TrayService, VolumeMonitor) | Shared |
| Singletons | `singletons/` (Theme, Dyn, Metrics, Flags, PillState) | Shared (PillState is Pill-specific but harmless) |
| Common modules | `modules/common/` (Config, Directories, FileUtils, GlobalStates) | Shared |

### Exclusive to Pill

- `PillOverlay.qml` + `Pill.qml` + `PillState` (surface switching)
- All Pill surfaces (Ame, Launcher, Mixer, Calendar, Clipboard, Power, Settings, Keybinds, Link, LinkBt, Media, Sysmon, Recorder, Appearance, Updates, Display, Input, Look, IdleLock, FontPicker, Battery, Toast, Tooltip, Tray, Wallpaper)
- Pill-styled `Bar.qml`

### Exclusive to Waffle

- `WaffleBackground.qml` + `WaffleBackgroundClock.qml`
- `WaffleBackdrop.qml`
- (Planned) `wBar` — not yet implemented

---

## 8. Recommendation — How to Gate Pill vs Waffle in shell.qml

1. **Gate the PillOverlay `Variants` block** (shell.qml:281–287) in a `Loader`:
   ```qml
   Loader {
       active: Config.options?.panelFamily !== "waffle"
       sourceComponent: pillOverlayComponent
   }
   Component {
       id: pillOverlayComponent
       Variants {
           model: Quickshell.screens
           Pill.PillOverlay {
               modelData: modelData
               barWindow: root.barWindow
           }
       }
   }
   ```
   This unloads all Pill surfaces when Waffle is active.

2. **Add a Waffle bar loader** gated by `enabledPanels.includes("wBar")` (new `modules/waffle/bar/` component), and gate the existing Pill-styled `barLoader` with `active: Config.options?.panelFamily !== "waffle"` so the two bars are **mutually exclusive**.

3. **Use `panelFamily` as the coarse switch** (Pill vs Waffle) and keep `enabledPanels` for fine-grained per-panel control — this matches the existing iNiR-style Config contract (`panelFamily: "ii" | "waffle"`).

4. **Keep shared components unconditional**: MusicPanel, OSD, NotificationServer, services, singletons.

5. **Optionally honor `familyTransitionAnimation`** (Config.qml:400) for the animated switch overlay.

---

## 9. Evidence Reference

| Evidence | Location |
|----------|----------|
| Loaders & Variants | `shell.qml` lines 250–294 |
| PillOverlay Variants | `shell.qml` lines 281–287 |
| Pill import | `shell.qml` line 12 |
| Waffle imports | `shell.qml` lines 13–14 |
| `panelFamily` / `enabledPanels` / `familyTransitionAnimation` | `modules/common/Config.qml` lines 397–400 |
| `options` alias | `modules/common/Config.qml` line 10 |
| Config path resolution | `modules/common/Directories.qml` lines 63–65 |
| Pill surfaces | `modules/pill/Pill.qml` lines 36–56 |
| Pill-styled bar | `modules/bar/Bar.qml` lines 23–25, 46–57 |
| config.json | `~/.config/yemi-shell/config.json` |