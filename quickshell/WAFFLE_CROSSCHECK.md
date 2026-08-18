# Waffle Cross-Check vs iNiR (Reference Main Repo)

> **Diagnostic only.** No edits were made to either repo.
> - Reference (main): `/home/yemi/iNiR`
> - Fork: `/home/yemi/.config/quickshell`
> Generated: 2026-08-18

## TL;DR

All 8 waffle QML files in the task (`WeatherButton`, `Tasks`, `Tray`, `TrayOverflowMenu`,
`TimerButton`, `UpdatesButton`, `SystemButton`, `WIcons`) are **byte-identical** to iNiR.
`GlassBackground` and `Directories` are not under `modules/waffle` (they live in
`modules/common/widgets/` and `modules/common/`). The 10 "missing-singleton"
ReferenceErrors are **not** dropped import lines — they are a restructured
singleton namespace in the fork's `services/qmldir` (and `Icons` moved out of
`modules/common`). Every case is classified **(b) structural**.

---

## 1. Directory structure diff (three lists)

### `modules/waffle/`
- **Only in iNiR (132 files):** entire `actionCenter/`, `altSwitcher/`, `clipboard/`,
  `lock/`, `notificationCenter/`, `notificationPopup/`, `onScreenDisplay/`, `polkit/`,
  `regionSelector/`, `sessionScreen/`, `settings/`, `startMenu/`, `taskview/`,
  `widgets/` trees, `modules/waffle/README.md`, and the `qmldir` files inside each
  of those subdirs.
- **Only in yours (2 files):**
  - `modules/waffle/looks/Translation.qml`
  - `modules/waffle/qmldir` *(fork added a root `module qs.modules.waffle` qmldir;
    iNiR has none at that level)*
- **In both (77 files):** `backdrop/*`, `background/*`, `bar/*` (incl. `bar/tasks/*`,
  `bar/tray/*`), `looks/*` (minus the added `Translation.qml`).

### `services/` (iNiR 92 files, yours 51)
- **Only in iNiR (54 files):** all of `services/ai/*`, `AppCatalog`, `AppLauncher`,
  `AppSearch`, `Autostart`, `AwwwBackend`, `Booru*`, `calendar_ics.js`, `CalendarSync`,
  `CavaTheme`, `ConflictKiller`, `CustomWidgets`, `Events`, `FirstRunExperience`,
  `FontSyncService`, `GlobalActions`, `HyprlandData`, `IconThemeService`, `Idle`,
  `MaterialThemeLoader`, `MemoryPressureService`, `MinimizedWindows`, `network/*`,
  `Notepad`, `Polkit*`, `PowerProfilePersistence`, `ResourceUsage`, `ScreenTime`,
  `ShellUpdates`, `SystemInfo`, `ThemeService`, `Todo`, `Translation`, `VoiceSearch`,
  `Wallhaven`, `WallpaperListener`, `WidgetPowerManager`, `WindowPreviewService`, `YtMusic`.
- **Only in yours (10 files):** `Bluetooth`, `Icons`, `IdleInhibitor`, `Logger`,
  `Notifs`, `Players`, `PowerProfiles`, `Screenshot`, `SystemUsage`, `VolumeMonitor`.
- **In both (41 files):** `Audio`, `Battery`, `BluetoothStatus`, `Brightness`,
  `CompositorService`, `DankSocket`, `DateTime`, `deferred/*` (21), `GameMode`,
  `Hyprsunset`, `KeyboardIndicators`, `MprisController`, `Network`, `NiriService`,
  `Notifications`, `Privacy`, `RecorderStatus`, `TaskbarApps`, `TimerService`,
  `TrayService`, `Updates`, `Wallpapers`, `Weather` (+ `qmldir`).

### `modules/common/widgets/` (iNiR 159, yours 157)
- **Only in iNiR (2):** `FluidRipple.frag`, `FluidRipple.qsb`.
- **Only in yours (0).**
- **In both (157):** everything else, including `GlassBackground.qml`.

### `config/`
- Exists **only in yours** (10 files; `config/qmldir` registers `Config`,
  `AppearanceConfig`, `BarConfig`). iNiR has **no `config/` directory**.

---

## 2. Byte-compare of "in both" `modules/waffle` files

```
DIFFERS: modules/waffle/backdrop/WaffleBackdrop.qml (1 changed lines)
IDENTICAL: modules/waffle/backdrop/qmldir
DIFFERS: modules/waffle/background/WaffleBackground.qml (1 changed lines)
DIFFERS: modules/waffle/background/WaffleBackgroundClock.qml (1 changed lines)
IDENTICAL: modules/waffle/background/qmldir
IDENTICAL: modules/waffle/bar/AppButton.qml
IDENTICAL: modules/waffle/bar/BarButton.qml
IDENTICAL: modules/waffle/bar/BarIconButton.qml
IDENTICAL: modules/waffle/bar/BarMenu.qml
IDENTICAL: modules/waffle/bar/BarPopup.qml
IDENTICAL: modules/waffle/bar/BarToolTip.qml
IDENTICAL: modules/waffle/bar/DesktopPeekButton.qml
IDENTICAL: modules/waffle/bar/SearchButton.qml
IDENTICAL: modules/waffle/bar/StartButton.qml
IDENTICAL: modules/waffle/bar/SystemButton.qml
IDENTICAL: modules/waffle/bar/TaskViewButton.qml
IDENTICAL: modules/waffle/bar/TimeButton.qml
IDENTICAL: modules/waffle/bar/TimerButton.qml
IDENTICAL: modules/waffle/bar/UpdatesButton.qml
IDENTICAL: modules/waffle/bar/WaffleBar.qml
DIFFERS: modules/waffle/bar/WaffleBarContent.qml (11 changed lines)
IDENTICAL: modules/waffle/bar/WeatherButton.qml
IDENTICAL: modules/waffle/bar/WidgetsButton.qml
IDENTICAL: modules/waffle/bar/qmldir
IDENTICAL: modules/waffle/bar/tasks/TaskAppButton.qml
DIFFERS: modules/waffle/bar/tasks/TaskPreview.qml (1 changed lines)
IDENTICAL: modules/waffle/bar/tasks/Tasks.qml
IDENTICAL: modules/waffle/bar/tasks/WindowPreview.qml
DIFFERS: modules/waffle/bar/tasks/qmldir (1 changed lines)
IDENTICAL: modules/waffle/bar/tray/Tray.qml
IDENTICAL: modules/waffle/bar/tray/TrayButton.qml
IDENTICAL: modules/waffle/bar/tray/TrayOverflowMenu.qml
IDENTICAL: modules/waffle/bar/tray/WaffleTrayMenu.qml
IDENTICAL: modules/waffle/bar/tray/WaffleTrayMenuEntry.qml
DIFFERS: modules/waffle/bar/tray/qmldir (1 changed lines)
IDENTICAL: modules/waffle/looks/AcrylicButton.qml
IDENTICAL: modules/waffle/looks/AcrylicRectangle.qml
IDENTICAL: modules/waffle/looks/BodyRectangle.qml
IDENTICAL: modules/waffle/looks/CloseButton.qml
IDENTICAL: modules/waffle/looks/FluentIcon.qml
IDENTICAL: modules/waffle/looks/FooterMoreButton.qml
IDENTICAL: modules/waffle/looks/FooterRectangle.qml
DIFFERS: modules/waffle/looks/Looks.qml (101 changed lines)
IDENTICAL: modules/waffle/looks/WAmbientShadow.qml
IDENTICAL: modules/waffle/looks/WAppIcon.qml
IDENTICAL: modules/waffle/looks/WBarAttachedPanelContent.qml
IDENTICAL: modules/waffle/looks/WBorderedButton.qml
IDENTICAL: modules/waffle/looks/WBorderlessButton.qml
IDENTICAL: modules/waffle/looks/WButton.qml
IDENTICAL: modules/waffle/looks/WChoiceButton.qml
IDENTICAL: modules/waffle/looks/WFadeLoader.qml
IDENTICAL: modules/waffle/looks/WIcons.qml
IDENTICAL: modules/waffle/looks/WIndeterminateProgressBar.qml
IDENTICAL: modules/waffle/looks/WListView.qml
IDENTICAL: modules/waffle/looks/WMenu.qml
IDENTICAL: modules/waffle/looks/WMenuItem.qml
IDENTICAL: modules/waffle/looks/WPageLoader.qml
DIFFERS: modules/waffle/looks/WPane.qml (1 changed lines)
IDENTICAL: modules/waffle/looks/WPanelIconButton.qml
IDENTICAL: modules/waffle/looks/WPanelPageColumn.qml
IDENTICAL: modules/waffle/looks/WPanelSeparator.qml
IDENTICAL: modules/waffle/looks/WPopupToolTip.qml
IDENTICAL: modules/waffle/looks/WProgressBar.qml
IDENTICAL: modules/waffle/looks/WRectangularShadow.qml
IDENTICAL: modules/waffle/looks/WScrollBar.qml
IDENTICAL: modules/waffle/looks/WSlider.qml
IDENTICAL: modules/waffle/looks/WStackView.qml
IDENTICAL: modules/waffle/looks/WSwitch.qml
IDENTICAL: modules/waffle/looks/WTaskbarSeparator.qml
IDENTICAL: modules/waffle/looks/WText.qml
IDENTICAL: modules/waffle/looks/WTextField.qml
IDENTICAL: modules/waffle/looks/WTextInput.qml
IDENTICAL: modules/waffle/looks/WTextWithFixedWidth.qml
IDENTICAL: modules/waffle/looks/WToolTip.qml
IDENTICAL: modules/waffle/looks/WToolTipContent.qml
IDENTICAL: modules/waffle/looks/WUserAvatar.qml
DIFFERS: modules/waffle/looks/qmldir (1 changed lines)
```

All 8 task waffle files are IDENTICAL to iNiR. `GlassBackground.qml` and
`Directories.qml` are not under `modules/waffle`.

---

## 3. Import blocks — iNiR vs fork (side by side)

**WeatherButton.qml** — identical:
```
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
```

**Tasks.qml** — identical:
```
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
```

**Tray.qml** — identical:
```
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.bar
```

**TrayOverflowMenu.qml** — identical:
```
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.bar
```

**TimerButton.qml** — identical:
```
import qs
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
```

**UpdatesButton.qml** — identical:
```
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.bar
```

**SystemButton.qml** — identical:
```
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import Quickshell.Services.Pipewire
```

**WIcons.qml** — identical:
```
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services
```

**GlassBackground.qml** — DIFFERS (fork added `import qs.config`):
```
iNiR:                                    | yours:
import qs.modules.common                 | import qs.config            <-- added; iNiR has no qs.config
import qs.modules.common.functions       | import qs.modules.common
import qs.services                       | import qs.modules.common.functions
import QtQuick                           | import qs.services
import QtQuick.Effects                   | import QtQuick
import Qt5Compat.GraphicalEffects as GE  | import QtQuick.Effects
import Quickshell                         | import Qt5Compat.GraphicalEffects as GE
                                         | import Quickshell
```

**Directories.qml** — identical:
```
pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import qs.services
import QtCore
import QtQuick
import Quickshell
```

**Conclusion:** No import line was dropped in any of the 8 waffle files. The
divergence is in what the imported `qs.services` / `qs.modules.common` namespace
actually *registers*.

---

## 4. qmldir registration check

**iNiR model:** no root `qmldir`, no `config/` dir. Singletons registered
per-directory. `services/qmldir` (`module qs.services`) registers **62
singletons**, including every Waffle dependency: `Weather, TaskbarApps,
TimerService, Updates, GlobalActions, KeyboardIndicators, Privacy,
RecorderStatus, AppSearch, SystemInfo, Wallpapers, Translation, TrayService,
Notifications`, etc. `Icons` is registered by **`modules/common/qmldir`**
(`singleton Icons 1.0 Icons.qml`, file at `modules/common/Icons.qml`).

**Fork model:** added a top-level **`qmldir`** (`module qs` → singletons `Theme,
Dyn, Flags, PillState, Metrics` under `singletons/`), a **`config/`** module
(`Config`, `AppearanceConfig`, `BarConfig`), and a **reduced/renamed
`services/qmldir`** (~22 entries; renames: `Idle→IdleInhibitor`,
`ResourceUsage→SystemUsage`, `PowerProfilePersistence→PowerProfiles`; new:
`Players/Notifs/Screenshot/Logger/VolumeMonitor/Bluetooth`). Absent: `Weather,
TaskbarApps, TimerService, Updates, GlobalActions, KeyboardIndicators, Privacy,
RecorderStatus, AppSearch, SystemInfo, Wallpapers, Translation`.

`Weather` is **not** in the fork's `services/qmldir` — it is registered under
**`modules/pill/Singletons/qmldir`** (`singleton Weather Weather.qml`), a
pill-specific location iNiR does not have.

**Verdict:** the fork does **not** register these singletons the same way. iNiR
exposes them through `qs.services` (and `qs.modules.common` for `Icons`); the
fork dropped/renamed them during its services rebase. Most `.qml` source files
*still exist* in the fork's `services/` — they were just removed from
`services/qmldir`:

| Singleton | iNiR reg | fork file present | fork reg |
|---|---|---|---|
| TaskbarApps | yes | yes | **no** |
| TimerService | yes | yes | **no** |
| Updates | yes | yes | **no** |
| KeyboardIndicators | yes | yes | **no** |
| Privacy | yes | yes | **no** |
| RecorderStatus | yes | yes | **no** |
| Wallpapers | yes | yes | **no** |
| Icons | yes (modules/common) | yes (services/Icons.qml) | **no** |
| GlobalActions | yes | **no file** | **no** |
| AppSearch | yes | **no file** | **no** |
| SystemInfo | yes | **no file** | **no** |

`TrayService` and `Notifications` ARE registered in both.

---

## 5. Summary table — 10 "missing-singleton" errors

- **(a)** trivial — add a missing import line, iNiR does it identically.
- **(b)** structural — the `qs.services`/`qs.modules.common` namespace the fork
  exposes differs from iNiR's; requires a real decision, not a copy-paste.

| # | File | Missing singleton(s) | iNiR | Fork status | Class |
|---|------|---------------------|------|-------------|-------|
| 1 | WeatherButton.qml | `Icons` (line 29 `Icons.getWeatherIcon`) | reg. in `modules/common` | file `services/Icons.qml` exists, **unregistered** | **(b)** |
| 2 | Tasks.qml | `TaskbarApps` | reg. in services | file exists, **unregistered** | **(b)** |
| 3 | Tray.qml | none directly — refs `Config, GameMode, Translation, TrayService`, all registered in both | reg. | all present in fork | **(b)** *nuance* — no missing singleton in file; likely a transitive/cascade dependency or property. Needs runtime log. |
| 4 | TrayOverflowMenu.qml | none directly — only `TrayService` (registered both) | reg. | present | **(b)** *nuance* — same as above; no missing singleton in file. |
| 5 | TimerButton.qml | `TimerService` | reg. | file exists, **unregistered** | **(b)** |
| 6 | UpdatesButton.qml | `Updates` | reg. | file exists, **unregistered** | **(b)** |
| 7 | SystemButton.qml | `GlobalActions` (file+reg missing), `KeyboardIndicators`, `Privacy`, `RecorderStatus` (files exist, unregistered) | all reg. | mixed | **(b)** |
| 8 | WIcons.qml | `AppSearch` (file+reg missing); `PowerProfile` enum — iNiR exposes via `PowerProfilePersistence`, fork registers `PowerProfiles` (plural, name mismatch) | reg. | mixed / mismatch | **(b)** |
| 9 | GlassBackground.qml | `Wallpapers` (unregistered) | reg. | file exists, **unregistered** | **(b)** |
| 10 | Directories.qml | `SystemInfo` (file+reg missing), `Wallpapers` (unregistered) | reg. | mixed | **(b)** |

### Bottom line
Every one of the 10 is **(b)**, not (a). Because the 8 waffle QML files are
byte-identical to iNiR, no import line was dropped — the errors come from the
fork's restructured singleton namespace (`services/qmldir` was reduced/renamed
and `Icons` moved out of `modules/common` was never re-registered;
`GlobalActions`, `AppSearch`, `SystemInfo` source files were removed entirely).
The concrete remediation is to re-register the surviving-but-unregistered
service files in `services/qmldir` (and restore/re-implement `GlobalActions`,
`AppSearch`, `SystemInfo`, plus a `PowerProfile` enum) — a namespace/registration
decision, not a per-file import paste. `Tray.qml` and `TrayOverflowMenu.qml`
show no missing singleton in static analysis and warrant a runtime error log to
confirm their actual failing symbol.
