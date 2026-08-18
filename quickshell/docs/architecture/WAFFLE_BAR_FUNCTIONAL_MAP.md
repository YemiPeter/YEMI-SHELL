# Waffle Bar — Functional Composition Map

**Purpose:** Inventory of every file/subsystem that makes the Niri-focused **Waffle bar** run.
This is the pre-fix baseline (see §5 for blockers). Waffle is a *copy* of iNiR, never modify iNiR source.

## 1. Load Chain (how the bar gets on screen)

```
shell.qml
  └─ LazyLoader { source: "ShellWafflePanels.qml" }   (shell.qml:269)
       └─ ShellWafflePanels.qml
            └─ WaffleBarModule.WaffleBar {}            (ShellWafflePanels.qml:45)
                 └─ WaffleBarContent {}                (the actual bar UI)
```

- `WaffleBar.qml` is a `Scope` that spawns a `PanelWindow` per screen (`Variants` over `Quickshell.screens`, filtered by `Config.options.waffles.bar.screenList`).
- Exposes IPC handler `target: "wbar"` → `toggle()` / `close()` / `open()` (drives `GlobalStates.barOpen`).

## 2. Waffle-Owned Component Tree (the bar's own files)

### Entry / shell wiring
| File | Role |
|------|------|
| `modules/waffle/bar/WaffleBar.qml` | Screen-scoped `PanelWindow` host + IPC `wbar`. |
| `modules/waffle/bar/WaffleBarContent.qml` | The bar layout: left apps group, center taskbar, right system tray group, right-click `BarMenu`, glass background. |

### Bar buttons & primitives (`modules/waffle/bar/`)
| File | Role |
|------|------|
| `AppButton.qml` | Generic app-launch button. |
| `BarButton.qml` | Base bar button. |
| `BarIconButton.qml` | Icon-only bar button. |
| `BarMenu.qml` | Right-click context menu (task manager / settings). |
| `BarPopup.qml` | Popup container. |
| `BarToolTip.qml` | Tooltip. |
| `DesktopPeekButton.qml` | Niri desktop-peek toggle. |
| `SearchButton.qml` | Search launcher. |
| `StartButton.qml` | Start/menu button. |
| `SystemButton.qml` | System menu button. |
| `TaskViewButton.qml` | Task-view / overview. |
| `TimeButton.qml` | Clock. |
| `TimerButton.qml` | Timer. |
| `UpdatesButton.qml` | Update indicator. |
| `WeatherButton.qml` | Weather. |
| `WidgetsButton.qml` | Widgets panel toggle. |

### Taskbar (`modules/waffle/bar/tasks/`) — needs `WindowPreviewService`
| File | Role |
|------|------|
| `Tasks.qml` | Taskbar app list. |
| `TaskAppButton.qml` | Per-running-app button. |
| `TaskPreview.qml` | Hover preview shell. |
| `WindowPreview.qml` | Window thumbnail (uses `WindowPreviewService` + `scripts/capture-windows.*`). |

### System tray (`modules/waffle/bar/tray/`) — needs `TrayService`
| File | Role |
|------|------|
| `Tray.qml` | Tray host. |
| `TrayButton.qml` | Tray item button. |
| `TrayOverflowMenu.qml` | Overflow menu. |
| `WaffleTrayMenu.qml` | Tray context menu. |
| `WaffleTrayMenuEntry.qml` | Menu entry. |

### Looks primitives used by the bar (`modules/waffle/looks/`)
**Singletons (must be registered in `looks/qmldir`):**
- `Looks.qml` — colors, scaling, transitions, glass state.
- `WIcons.qml` — icon name → Fluent icon map.
- `Translation.qml` — `Translation.tr()` strings.

**Types referenced by the bar/tasks/tray:**
- `FluentIcon.qml`, `WTaskbarSeparator.qml`, `WFadeLoader.qml` (looks), plus `GlassBackground.qml` and `FadeLoader.qml` from **`qs.modules.common.widgets`** (see §4).

### Separate Waffle windows (NOT required for the bar to display)
`modules/waffle/background/` (`WaffleBackground.qml`, `WaffleBackgroundClock.qml`) and `modules/waffle/backdrop/` (`WaffleBackdrop.qml`) are independent windows. They share `Looks`/`NiriService` but the bar renders without them.

## 3. Shared Modules the Bar Imports

| Module | Provides what the bar needs |
|--------|----------------------------|
| `qs` (root) | `Quickshell` global, `Config` shortcuts. |
| `qs.config` | `Config` (bar options: `waffles.bar.{bottom,leftAlignApps,screenList}`), `Appearance`, `BarConfig`, `AppearanceConfig`. |
| `qs.services` | All runtime singletons below (§4). |
| `qs.modules.common` | `GlobalStates` (`barOpen`), `Directories`, `FileUtils`, `Config`. |
| `qs.modules.common.widgets` | `GlassBackground`, `FadeLoader`, `ContextMenu`, etc. |
| `qs.modules.common.functions` | `Session` (launchTaskManager), `ShellExec`, `ColorUtils`, etc. |
| `qs.singletons` | `Theme`, `Dyn`, `Flags`, `PillState`, `Metrics`. |

## 4. Specific Services / Singletons the Bar Reads (from `services/`)

Confirmed referenced inside `modules/waffle/bar|looks|background|backdrop`:

| Service | Used for |
|---------|----------|
| `GlobalStates` (common) | `barOpen` toggle, panel state. |
| `NiriService` | Niri-focused: workspaces, layers, desktop-peek, focus. **Hard dependency — bar is Niri-only.** |
| `GameMode` | `shouldHidePanels` (hide bar in game mode). |
| `TimerService` | Timer button. |
| `Audio` | Volume in system button. |
| `WindowPreviewService` | Window thumbnails in taskbar hover. |
| `Battery` | Battery indicator. |
| `Weather` | Weather button. |
| `TrayService` | System tray. |
| `Network` | Network state. |
| `KeyboardIndicators` | Keyboard layout LED. |
| `CompositorService` | Multi-compositor bridge (live one in `services/`). |
| `AppSearch` | Search button. |
| `Updates` | Update count. |
| `Notifications` / `Notifs` | Notification dot. |
| `DateTime` | Clock. |
| `TaskbarApps` | Running apps list. |
| `BluetoothStatus` | BT indicator. |
| `Wallpapers` | Wallpaper control. |
| `RecorderStatus` | Screen-rec indicator. |
| `Privacy`, `PowerProfiles`, `Icons`, `Hyprsunset` | Misc indicators. |

All are registered in `services/qmldir` (incl. `WindowPreviewService 1.0`, added this commit). No missing registration for the bar.

## 5. Blockers to "Fully Functional" (fix before/with Waffle work)

From the Project Bible (CONTEXT.md §6) and this audit:
1. **Niri required.** Bar is Niri-focused; under Hyprland the taskbar/desktop-peek paths (`NiriService`) are inert. Verify on the Niri compositor.
2. **`WindowPreviewService` capture scripts** (`scripts/capture-windows.sh`/`.fish`) must be present & executable (committed this pass) and have their deps (`Cliphist`, `ShellExec`, `FileUtils`, `Directories`, `NiriService`). If capture fails, previews degrade but bar still shows.
3. **`AltSwitcher` is a separate component** (`modules/altSwitcher/AltSwitcher.qml`) still throwing `IconImage is not a type` on boot — fix independently; it is not part of the bar tree but shares the Waffle/looks stack.
4. **Glass/aurora theme bridge is stubbed.** In `WaffleBarContent.qml` the border + glass transparency are hardcoded (`"#3a88f2"`, `auroraTransparency: 0.9`) with `ORIGINAL (iNiR, restore when theme bridge is built)` comments — visual only, not a crash.
5. **Bar settings UI is PARKED** (standalone launcher needs iNiR-only singletons we are NOT porting). In-bar settings access via right-click → `Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])` assumes an `inir` script — verify that launcher path exists in yemishell.

## 6. Verification Checklist (when fixing)
- [ ] `qs ipc` shows `Target not found`? → bar failed to load silently; check log `/run/user/1004/quickshell/by-id/*/log.qslog` (`grep -a`).
- [ ] On Niri: `wbar toggle` opens/closes bar.
- [ ] Taskbar lists running apps; hover shows `WindowPreview`.
- [ ] Tray populates (`TrayService`).
- [ ] Right-click → Task Manager / Settings actions fire.
- [ ] Game mode hides bar (`GameMode.shouldHidePanels`).
