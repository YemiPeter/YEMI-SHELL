# Waffle Bar — Complete Reference (Files & Services)

**Scope:** Every file and service that makes the Niri-focused **Waffle bar** run.
Waffle is a *copy* of iNiR; never modify iNiR source. All paths below are
verified to exist in this repo (`OK` = present as of 2026-08-18).

## 1. Load Chain (how the bar gets on screen)

```
shell.qml
  └─ LazyLoader { source: "ShellWafflePanels.qml" }        (shell.qml:269)
       └─ ShellWafflePanels.qml
            └─ WaffleBarModule.WaffleBar {}                (ShellWafflePanels.qml:45)
                 └─ WaffleBarContent {}                    (the actual bar UI)
```

- `WaffleBar.qml` is a `Scope` that spawns a `PanelWindow` per screen (`Variants`
  over `Quickshell.screens`, filtered by `Config.options.waffles.bar.screenList`).
- Exposes IPC handler `target: "wbar"` → `toggle()` / `close()` / `open()`
  (drives `GlobalStates.barOpen`).

## 2. Complete File Inventory (verified)

### 2.1 Load / wiring
| File | Role | Status |
|------|------|--------|
| `shell.qml` | Root shell; lazy-loads Waffle panels | OK |
| `ShellWafflePanels.qml` | Instantiates `WaffleBar` | OK |

### 2.2 Bar core — `modules/waffle/bar/`
| File | Role | Status |
|------|------|--------|
| `WaffleBar.qml` | Screen-scoped `PanelWindow` host + IPC `wbar` | OK |
| `WaffleBarContent.qml` | Bar layout: app group, taskbar, tray group, right-click menu, glass bg | OK |
| `AppButton.qml` | Generic app-launch button | OK |
| `BarButton.qml` | Base bar button | OK |
| `BarIconButton.qml` | Icon-only bar button | OK |
| `BarMenu.qml` | Right-click context menu (task manager / settings) | OK |
| `BarPopup.qml` | Popup container | OK |
| `BarToolTip.qml` | Tooltip | OK |
| `DesktopPeekButton.qml` | Niri desktop-peek toggle | OK |
| `SearchButton.qml` | Search launcher | OK |
| `StartButton.qml` | Start/menu button | OK |
| `SystemButton.qml` | System menu button (GlobalActions) | OK |
| `TaskViewButton.qml` | Task-view / overview | OK |
| `TimeButton.qml` | Clock | OK |
| `TimerButton.qml` | Timer | OK |
| `UpdatesButton.qml` | Update indicator | OK |
| `WeatherButton.qml` | Weather | OK |
| `WidgetsButton.qml` | Widgets panel toggle | OK |

### 2.3 Taskbar — `modules/waffle/bar/tasks/`
| File | Role | Status |
|------|------|--------|
| `Tasks.qml` | Taskbar app list | OK |
| `TaskAppButton.qml` | Per-running-app button | OK |
| `TaskPreview.qml` | Hover preview shell | OK |
| `WindowPreview.qml` | Window thumbnail (uses `WindowPreviewService` + `scripts/capture-windows.*`) | OK |

### 2.4 System tray — `modules/waffle/bar/tray/`
| File | Role | Status |
|------|------|--------|
| `Tray.qml` | Tray host | OK |
| `TrayButton.qml` | Tray item button | OK |
| `TrayOverflowMenu.qml` | Overflow menu | OK |
| `WaffleTrayMenu.qml` | Tray context menu | OK |
| `WaffleTrayMenuEntry.qml` | Menu entry | OK |

### 2.5 Looks primitives used — `modules/waffle/looks/`
| File | Role | Status |
|------|------|--------|
| `Looks.qml` | Singleton: colors, scaling, transitions, glass state | OK |
| `WIcons.qml` | Singleton: Fluent icon name map | OK |
| `FluentIcon.qml` | Icon renderer | OK |
| `WTaskbarSeparator.qml` | Taskbar separator | OK |
| `WFadeLoader.qml` | Fade-in loader | OK |

### 2.6 Shared widgets the bar needs — `modules/common/widgets/`
| File | Role | Status |
|------|------|--------|
| `GlassBackground.qml` | Glass/aurora background (imported by `WaffleBarContent`) | OK |
| `FadeLoader.qml` | Generic fade loader (imported by `WaffleBarContent`) | OK |

### 2.7 Shared i18n — `modules/common/`
| File | Role | Status |
|------|------|--------|
| `Translation.qml` | Singleton `Translation.tr()` passthrough stub (moved here from `waffle.looks` in commit `78426bd`) | OK |

## 3. Shared Modules the Bar Imports
| Module | Provides |
|--------|----------|
| `qs` (root) | `Quickshell` global, `Config` shortcuts |
| `qs.config` | `Config` (`waffles.bar.*` options), `Appearance`, `BarConfig`, `AppearanceConfig` |
| `qs.services` | All runtime singletons in §4 |
| `qs.modules.common` | `GlobalStates` (`barOpen`), `Directories`, `FileUtils`, `Config`, `Translation` |
| `qs.modules.common.widgets` | `GlassBackground`, `FadeLoader`, `ContextMenu`, … |
| `qs.modules.common.functions` | `Session` (launchTaskManager), `ShellExec`, … |
| `qs.singletons` | `Theme`, `Dyn`, `Flags`, `PillState`, `Metrics` |

## 4. Services the Bar Consumes (`services/`, registered in `services/qmldir`)
| Service | Used for |
|---------|----------|
| `GlobalStates` (common) | `barOpen` toggle, panel state |
| `NiriService` | Niri workspaces, layers, desktop-peek, focus — **bar is Niri-only** |
| `GameMode` | `shouldHidePanels` (hide bar in game mode) |
| `TimerService` | Timer button |
| `Audio` | Volume in system button |
| `WindowPreviewService` | Window thumbnails on taskbar hover (capture scripts) |
| `Battery` | Battery indicator |
| `Weather` | Weather button |
| `TrayService` | System tray |
| `Network` | Network state |
| `KeyboardIndicators` | Keyboard layout LED |
| `CompositorService` | Multi-compositor bridge (live one in `services/`) |
| `AppSearch` | Search button |
| `Updates` | Update count |
| `Notifications` / `Notifs` | Notification dot |
| `DateTime` | Clock |
| `TaskbarApps` | Running apps list |
| `BluetoothStatus` | BT indicator |
| `Wallpapers` | Wallpaper control |
| `RecorderStatus` | Screen-rec indicator |
| `Privacy`, `PowerProfiles`, `Icons`, `Hyprsunset` | Misc indicators |

All listed services are registered in `services/qmldir` (incl.
`WindowPreviewService 1.0`, added in commit `93049ba`). No missing registration
for the bar.

## 5. Singletons & Config the Bar Reads
- `qs.singletons`: `Theme` (facade), `Dyn` (colors.json watcher, async reload),
  `Flags` (mood/palette mode), `PillState`, `Metrics`.
- `qs.config`: `Config` (bar options), `Appearance` (colors + **`animation`
  compat layer added in `78426bd`**, `animationsEnabled`).

## 6. What "Fully Functional" Requires
1. **Niri compositor** — bar is Niri-focused; under Hyprland the NiriService
   paths are inert.
2. **Window-preview capture scripts** present & executable:
   `scripts/capture-windows.sh` / `.fish` (committed `93049ba`), with deps
   `Cliphist`, `ShellExec`, `FileUtils`, `Directories`, `NiriService`.
3. **Settings launch** wired — currently the right-click → Settings action calls
   `Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])`,
   but `scripts/inir` does **not** exist. Settings UI is PARKED (bar-tied, not a
   merged app). See §8.

## 7. Known Gaps / Blockers
- **`scripts/inir` missing** → bar's Settings launcher fails. Settings UI is
  PARKED; either wire to `waffleSettings.qml` or leave parked.
- **Glass/aurora theme bridge stubbed** in `WaffleBarContent.qml` (border +
  `auroraTransparency: 0.9` hardcoded, with `ORIGINAL … restore when theme
  bridge is built` comments) — visual only, not a crash.
- **Missing fluent asset** `assets/icons/fluent/alert-snooze.svg` — cosmetic;
  `FluentIcon` falls back to the icon name text.
- **AltSwitcher** `IconImage is not a type` bug from the bible is **stale**:
  `modules/altSwitcher/AltSwitcher.qml` no longer exists, so it is not a current
  boot blocker.

## 8. Verification Status
- All **36 bar-related files** verified present (see §2, every row `OK`).
- Two load-blocking errors from the live log are **fixed & committed**
  (`78426bd`):
  - `MaterialSymbol` / `elementMoveFast of undefined` → `Appearance.animation`
    compat layer + `animationsEnabled`.
  - `services/Weather.qml` `ReferenceError: Translation is not defined` →
    `Translation` moved to `qs.modules.common`.
- **Live test not possible in this environment**: the active `quickshell`
  process here runs a different config (`/usr/share/skwd-wall/shell.qml`), not
  our `~/.config/quickshell/shell.qml`. On the target machine, reload yemishell
  and confirm with:
  `grep -aE "elementMoveFast|Translation is not defined|is not a type" /run/user/1004/quickshell/by-id/*/log.qslog`
  (clean output = bar loads).
