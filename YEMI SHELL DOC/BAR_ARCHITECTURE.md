# Bar Module Architecture
**Shell by Yemi** — Component hierarchy, data flow, and dependency map for `modules/bar/`.
**Audited:** 2026-06-26 | **Status:** ✅ Clean — 0 dangling/circular imports

---

## 1. Component Hierarchy

```
shell.qml
└── BarWrapper.qml                          (Scope → PanelWindow per screen)
    ├── bluetoothPopupLoader  → BluetoothPopupWindow.qml
    ├── networkPopupLoader   → NetworkPopupWindow.qml
    ├── volumePopupLoader    → VolumePopupWindow.qml
    ├── brightnessPopupLoader → BrightnessPopupWindow.qml
    └── barLoader            → Bar.qml
        ├── [LEFT]  Workspaces pill
        │   └── workspacesLoader → Workspaces.qml
        │       └── Repeater (N times) → Workspace.qml
        ├── [CENTER] Clock pill
        │   └── clockLoader → Clock.qml
        ├── [RIGHT-1] Connectivity pill
        │   ├── networkLoader   → Network.qml
        │   └── bluetoothLoader → Bluetooth.qml
        ├── [RIGHT-2] Audio/Display pill
        │   ├── brightnessLoader → Brightness.qml
        │   └── volumeLoader     → Volume.qml
        ├── [RIGHT-3] Power pill
        │   ├── statusIndicatorsLoader → StatusIndicators.qml
        │   ├── batteryLoader          → Battery.qml
        │   └── systemTrayLoader       → SystemTray.qml
        └── [TOP-LEVEL] NotificationPopups.qml  (loaded separately in shell.qml)
```

---

## 2. Data Flow

### 2.1 BarWrapper → Bar (parent → child bindings)

`BarWrapper.qml` creates the `PanelWindow` per screen and binds popup references + screen data into `Bar.qml`:

| Property | Source | Target |
|----------|--------|--------|
| `screen` | `modelData` (from `Quickshell.screens`) | `Bar.qml` → component loaders |
| `barWindow` | `window` (the PanelWindow itself) | `Bar.qml` → component loaders |
| `bluetoothPopup` | `bluetoothPopupLoader.item` | `Bar.qml` → `Bluetooth.qml` |
| `networkPopup` | `networkPopupLoader.item` | `Bar.qml` → `Network.qml` |
| `volumePopup` | `volumePopupLoader.item` | `Bar.qml` → `Volume.qml` |
| `brightnessPopup` | `brightnessPopupLoader.item` | `Bar.qml` → `Brightness.qml` |

All bindings use `Qt.binding()` with `restoreMode: Binding.RestoreBinding` — safe for async loaders.

### 2.2 Bar → Components (Loader pattern)

`Bar.qml` loads each component via `Loader` with `asynchronous: true`. After load, it binds:
- `barWindow` — for popup windows that need to anchor to the bar
- `barWindow.networkPopup` / `barWindow.bluetoothPopup` etc. — specific popup references

### 2.3 Component → Services (singleton access)

Each component accesses backend services through the `QsServices` namespace:

| Component | Service(s) Used | Access Pattern |
|-----------|-----------------|----------------|
| `Workspaces.qml` | `QsCompositor.Compositor` | `compositor.activeWsId`, `compositor.dispatch()` |
| `Workspace.qml` | `QsSingletons.Theme`, `Material3Anim` | Theme colors + animation curves |
| `Clock.qml` | — (no service) | `Qt.formatDateTime()` |
| `Network.qml` | `QsServices.Network` | `network.active`, `network.wifiEnabled` |
| `Bluetooth.qml` | `Quickshell.Bluetooth`, `QsServices.Bluetooth` | `Bluetooth.defaultAdapter`, `Bluetooth.devices` |
| `Volume.qml` | `QsServices.Audio`, `QsServices.VolumeMonitor` | `volumeMonitor.muted`, `volumeMonitor.percentage` |
| `Brightness.qml` | `QsServices.Brightness` | `brightness.percentage` |
| `Battery.qml` | `Quickshell.Services.UPower`, `QsServices.PowerProfiles` | `UPower.displayDevice`, `powerProfiles` |
| `MediaPlayer.qml` | `qs.services` (Players) | `Players.active` |
| `StatusIndicators.qml` | `QsServices.IdleInhibitor`, `QsServices.Notifs` | `idleInhibitor.inhibited`, `notifs.dnd` |
| `SystemTray.qml` | `Quickshell.Services.SystemTray` | `SystemTray.items` |
| `NotificationPopups.qml` | `QsServices.Notifs`, `QsServices.Logger` | `notifs.activeNotifications` |

### 2.4 Popup Windows (independent PanelWindows)

The four popup windows (`NetworkPopupWindow.qml`, `BluetoothPopupWindow.qml`, `VolumePopupWindow.qml`, `BrightnessPopupWindow.qml`) are standalone `PanelWindow` items loaded by `BarWrapper.qml`. They:
- Anchor to top-right of screen
- Show/hide based on `shouldShow` property (set by parent component hover/click)
- Use `Process` for settings launchers (`nm-connection-editor`, `blueman-manager`)

---

## 3. Module Registration

| Module | qmldir | Registered As |
|--------|--------|---------------|
| `singletons/` | `module singletons` | `QsSingletons.Theme`, `QsSingletons.Dyn`, `QsSingletons.Flags` |
| `services/` | `module qs.services` | `QsServices.*` (14 singletons) |
| `config/` | `module qs.config` | `QsConfig.Config`, `QsConfig.Appearance`, `QsConfig.AppearanceConfig`, `QsConfig.BarConfig` |
| `compositor/` | `module qs.compositor` | `QsCompositor.Compositor`, `Hyprland`, `Niri` |
| `components/effects/` | `module effects` | `Material3Anim` |
| `modules/bar/` | `module modules.bar` | (Bar.qml, BarWrapper.qml) |

---

## 4. Theme Integration

All bar components use `QsSingletons.Theme.*` for colors. Key theme properties used:

| Theme Property | Used By |
|----------------|---------|
| `Theme.cream` | Workspace, Network, Bluetooth, Volume, Brightness, Battery, Clock, StatusIndicators |
| `Theme.dim` | Clock |
| `Theme.dim2` | (not used in bar) |
| `Theme.verm` | Volume, Brightness (high level), StatusIndicators |
| `Theme.vermBurn` | NotificationPopups (error color) |
| `Theme.onGlow` | Workspace (active), Network (hover), Bluetooth (hover), Volume (hover), StatusIndicators |
| `Theme.cardBot` | Bar pill background, popup surfaces |
| `Theme.cardTop` | Popup container surfaces |
| `Theme.bright` | (not used in bar) |
| `Theme.hair` | (not used in bar) |
| `Theme.font` | (not used in bar — uses system fonts) |

---

## 5. Known Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | `Bar.qml` line 5: `import "components" as BarComponents` — imported but never used | Low | Dead import, harmless |
| 2 | `MediaPlayer.qml` line 4: `import qs.services` — uses namespace import (different from other components' `import "../../../services" as QsServices`) | Low | Works, but inconsistent style |
| 3 | `Battery.qml` references `QsServices.PowerProfiles` — service exists but may error if `powerprofiles-daemon` not running | Medium | Expected — service handles missing daemon |

---

## 6. Design Notes

- **Modular per-component architecture** — deliberate divergence from Ricelin's monolithic `topbar/Bar.qml`
- **Async loading** — all components use `asynchronous: true` on Loaders for non-blocking startup
- **Binding restoration** — `restoreMode: Binding.RestoreBinding` prevents stale bindings on loader re-load
- **Height uniformity** — all pills use `height: 28`, components use `implicitHeight: 20` or `24`
- **Phase 4 scaffold** — `BarWrapper.qml` is the composition point for the PillSurface center pill
