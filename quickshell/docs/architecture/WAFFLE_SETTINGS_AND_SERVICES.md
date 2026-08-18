# Waffle — Settings & Services Inventory

**Purpose:** List the files that make up the **Settings** subsystem and the **Services** subsystem
feeding Waffle (and, by the unified-services rule, Pill too). See `WAFFLE_BAR_FUNCTIONAL_MAP.md` for the bar tree.

---

## A. SETTINGS Subsystem

### 1. Waffle settings UI (`modules/waffle/settings/`) — PARKED
Copied from iNiR. Bar-tied, **NOT** a standalone app (the standalone launcher needed iNiR-only
singletons `ThemeService`, `MaterialThemeLoader`, `AppLauncher`, `ShellUpdates`, `Idle` we are NOT porting).

| File | Role |
|------|------|
| `WSettingsPage.qml` | Page frame. |
| `WSettingsCard.qml` | Card container. |
| `WSettingsRow.qml` | Settings row. |
| `WSettingsSwitch.qml` | Toggle row. |
| `WSettingsSpinBox.qml` | Numeric row. |
| `WSettingsDropdown.qml` | Dropdown row. |
| `WSettingsButton.qml` | Button row. |
| `WSettingsNavItem.qml` | Sidebar nav item. |
| `WSettingsContent.qml` | Scrollable content host. |
| `WKeybindRow.qml` | Keybind capture row. |
| `WSettingsTextField.qml` | Text input row. |
| `WSettingsSection.qml` | Section header. |
| `WSettingsSlider.qml` | Slider row. |
| `WSettingsInfoBar.qml` | Info banner. |
| `WSettingsChoiceGroup.qml` | Choice group. |
| `WSettingsFontSelector.qml` | Font picker row. |
| `qmldir` | `module qs.modules.waffle.settings` (exports above). |

**Pages (`modules/waffle/settings/pages/`):** `WQuickPage`, `WGeneralPage`, `WBarPage`,
`WBackgroundPage`, `WThemesPage`, `WInterfacePage`, `WModulesPage`, `WWaffleStylePage`,
`WAboutPage`, `WShortcutsPage`, `WMonitorVisibilityPage`, `WGowallPage` + `qmldir`.

### 2. Shared settings config (`modules/settings/`)
| File | Role |
|------|------|
| `WaffleConfig.qml` | Waffle-specific config bindings (registered in `modules/settings/qmldir`). |
| `qmldir` | `module qs.modules.settings` (exports `WaffleConfig`). |

### 3. Root settings entry
| File | Role |
|------|------|
| `waffleSettings.qml` | Top-level Waffle settings window/sheet (loaded by the bar's settings action). |

> NOTE: These settings read/write via `Config`/`Appearance` (unified `qs.config`), not a merged app.
> They are currently **PARKED** pending the theme-bridge work noted in the bar map (§5.4).

---

## B. SERVICES Subsystem

### 1. Unified services (`services/`) — single source for BOTH Waffle & Pill
53 `.qml` files + `deferred/`. Registered in `services/qmldir` (`module qs.services`).
Key singletons consumed by Waffle (see bar map §4):

`Players, Network, Brightness, Audio, VolumeMonitor, SystemUsage, IdleInhibitor, Notifs,
PowerProfiles, PowerProfile, Screenshot, Logger, Bluetooth, Hyprsunset, Notifications,
MprisController, Battery, DateTime, TrayService, GameMode, CompositorService, NiriService,
TaskbarApps, TimerService, Updates, KeyboardIndicators, Privacy, RecorderStatus, Wallpapers,
Icons, GlobalActions, AppSearch, SystemInfo, Weather, BluetoothStatus, WindowPreviewService`

Plus the non-singleton helper: `DankSocket 1.0 DankSocket.qml`.
`deferred/` holds `HyprlandKeybinds.qml`, `HyprlandXkb.qml` (lazy Hyprland-only binds).

### 2. Theme/state singletons (`singletons/`) — `module qs.singletons`
| File | Role |
|------|------|
| `Theme.qml` | Public theme facade (UI consumes this). |
| `Dyn.qml` | Watches `~/.cache/yemi-shell/colors.json` via FileView; `reload()` is async (onLoaded parse). |
| `Flags.qml` | Feature flags. |
| `PillState.qml` | Pill family state (fixed this commit: `import qs.modules.common`). |
| `Metrics.qml` | Layout metrics. |

### 3. Config singletons (`config/`) — `module qs.config`
| File | Role |
|------|------|
| `Config.qml` | Root config (bar options `waffles.bar.*`, etc.). |
| `Appearance.qml` | Mood fallbacks + adapts `Dyn` tokens. |
| `AppearanceConfig.qml` | Appearance config binding. |
| `BarConfig.qml` | Bar config binding. |

### 4. Window-preview service + capture scripts (Waffle-specific, in unified services)
| File | Role |
|------|------|
| `services/WindowPreviewService.qml` | Captures & serves window thumbnails (registered `1.0` this commit). |
| `scripts/capture-windows.sh` | Capture backend (bash). |
| `scripts/capture-windows.fish` | Capture backend (fish). |
| Deps | `Cliphist`, `ShellExec`, `FileUtils`, `Directories`, `NiriService`. |

### 5. Clone-drift WARNING (unification workstream)
`modules/pill/Singletons/` carries its **own** Pill-local duplicates of `services/` capabilities:
`Battery, Cliphist, Devices, Events, Motion, Notifs, ScreenRec, Sysmon, Walls, Weather, Workspacerules`.
These overlap with the unified `services/` singletons. Per architecture §9, fold Pill-local caps into
`services/` where `services/` lacks them; adopt Waffle `looks/` primitives into Pill for UX upgrades.

---

## C. File-count summary
- Settings: `modules/waffle/settings/` (16) + `pages/` (12 + qmldir) + `modules/settings/` (2) + `waffleSettings.qml` (1).
- Services: `services/` (53 .qml + deferred) + `singletons/` (5) + `config/` (4) + capture scripts (2).
