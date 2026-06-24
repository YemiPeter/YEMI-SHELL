# Shell by Yemi — Bug Report

> Generated: 2026-06-22
> Scope: `~/.config/quickshell/` — excludes `.iNiR/` entirely
> Method: Read-only source inspection. Every finding backed by file + line evidence.

---

## Contents

1. [Bug Category Definitions](#1-bug-category-definitions)
2. [Critical Bugs](#2-critical-bugs)
3. [High Severity Bugs](#3-high-severity-bugs)
4. [Medium Severity Bugs](#4-medium-severity-bugs)
5. [Minor Issues](#5-minor-issues)
6. [Newly Discovered Critical Issues](#6-newly-discovered-critical-issues)
7. [Keybind Bugs](#7-keybind-bugs)
8. [Orphan Artifacts](#8-orphan-artifacts)
9. [Prioritized Fix List](#9-prioritized-fix-list)

---

## 1. Bug Category Definitions

| Category | Meaning |
|----------|---------|
| **A** | Phantom reference — uses a property, method, or singleton that does not exist in this project |
| **B** | Bad import — points to a module or path that doesn't resolve |
| **C** | Wrong root type — `Scope` used where `PanelWindow` is needed; visible UI as direct child of a non-rendering root |
| **Dead/Unwired** | Component not instantiated anywhere in the live tree |

---

## 2. Critical Bugs

These will crash, throw null references, or produce zero output at runtime.

---

### BUG-001 — `AltSwitcher.qml`: Root is `Scope`, panel never renders

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** C
**Line:** 1 (root declaration)

`Scope` has no visual surface. `Rectangle id: altSwitcherPanel` is a direct child of `Scope` and will never be instantiated on screen. The component's own header comment confirms this: "REAL BLOCKER: root is `Scope`".

**Fix:** Convert root to `PanelWindow`, mirroring `modules/osd/Wrapper.qml`'s pattern.

---

### BUG-002 — `AltSwitcher.qml`: Component never loaded

**File:** `modules/altswitcher/AltSwitcher.qml` / `shell.qml`
**Category:** Dead/Unwired
**Line:** `shell.qml` ~line 128

The real `Loader` is commented out. In its place:

```qml
// Loader {
//     id: altSwitcherLoader
//     source: "modules/altswitcher/AltSwitcher.qml"
// }
Item { id: altSwitcherLoader; property var item: null }
```

All five `IpcHandler` functions in `shell.qml` guard on `if (altSwitcherLoader.item)` — they all short-circuit silently.

**Fix:** Resolve BUG-001 first, then restore the `Loader`.

---

### BUG-003 — `AltSwitcher.qml`: `Config` not imported

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** A
**Line:** 22

```qml
readonly property var altSwitcherOptions: Config.options?.altSwitcher ?? {}
```

`Config` (`qs.config`) is never imported in this file. While the `??` fallback to `{}` prevents a hard crash, `Config` as an unresolved identifier will produce a QML binding warning and silently use defaults for every option.

**Fix:** Add `import "../../config" as QsConfig` and replace `Config.options` with `QsConfig.Config.options`.

---

### BUG-004 — `AltSwitcher.qml`: `autoHideTimer` and animations inside non-rendering Rectangle

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** C + A

`autoHideTimer`, `slideInAnim`, `slideOutAnim`, and `skewCardShowTimer` are all declared as children of `Rectangle id: altSwitcherPanel`. Because `altSwitcherPanel` is a child of `Scope` (which renders nothing), these objects are never created.

The public API functions `toggle()`, `open()`, `next()`, `previous()`, `showPanel()`, and `hidePanel()` all call `autoHideTimer.restart()` or reference the animations — these will throw null reference errors if the component is ever loaded.

**Fix:** Move all Timer and Animation objects to be direct children of the `Scope` root (or the future `PanelWindow` root).

---

### BUG-005 — `AltSwitcher.qml`: `panelVisible` never declared

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** A
**Lines:** 357, 377, 381

`showPanel()` sets `panelVisible = true` and `hidePanel()` reads and sets `panelVisible`. No `property bool panelVisible` exists anywhere in the file. The iNiR original had this declared on the `PanelWindow` root — it was lost during the port.

**Fix:** Add `property bool panelVisible: false` as a root-level property.

---

### BUG-006 — `AltSwitcher.qml`: `window` not defined on `Scope`

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** A
**Line:** ~51

```qml
readonly property real skewScale: Math.max(0.58, Math.min(1.0,
    (window.height - 120) / baseSkewSliceHeight,
    (window.width - 96) / baseSkewExpandedWidth
))
```

`window` is not a property of `Scope` and is not passed in. Evaluates to `undefined` — `skewScale` is always `NaN`, making all skew geometry `NaN`.

**Fix:** After root conversion to `PanelWindow`, `window` will resolve correctly as the enclosing window reference. Until then, guard with `?? 0`.

---

### BUG-007 — `services/Matugen.qml`: `applyWallpaper()` calls non-existent API

**File:** `services/Matugen.qml`
**Category:** A
**Line:** ~17

```qml
function applyWallpaper(imagePath: string): void {
    var proc = Quickshell.Process();
    ...
}
```

`Quickshell.Process()` does not exist. `Process` is a declarative QML component type — it cannot be instantiated via a factory call. The function silently does nothing.

**Fix:** Replace with a declarative `Process` element, or spawn matugen via `shell.qml`'s existing `applyWallProc` which already calls matugen inline.

---

### BUG-008 — `services/Screenshot.qml`: `stdout` read as Process property (region capture)

**File:** `services/Screenshot.qml`
**Category:** A

```qml
Process {
    id: slurpProc
    onExited: code => {
        if (code === 0 && stdout.trim() !== "") {  // BUG: stdout is not a Process property
```

`Process` in Quickshell has no `.stdout` string property. Output is only accessible through a connected `SplitParser` or `StdioCollector`. `stdout` evaluates to `undefined` — region screenshot always fails silently.

Same bug exists in `windowGeomProc.onExited`.

**Fix:** Add a `StdioCollector` to both processes and read output from there.

---

### BUG-009 — `services/Screenshot.qml`: Shell redirect passed as literal argument

**File:** `services/Screenshot.qml`
**Category:** A

```qml
function copyLastScreenshot() {
    copyProc.exec(["wl-copy", "<", lastScreenshotPath])
}
```

Array-based `exec()` bypasses the shell. The `<` character is passed as a literal argument to `wl-copy`, not interpreted as stdin redirection. `wl-copy` receives three arguments and errors silently.

**Fix:** Use `["sh", "-c", "wl-copy < \"" + lastScreenshotPath + "\""]` to invoke through the shell.

---

## 3. High Severity Bugs

These produce wrong behavior or silently disable features.

---

### BUG-010 — `AltSwitcher.qml`: `_noUiRebuildPending` never declared

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** A
**Lines:** 291–295

```qml
function rebuildNoUiSnapshot() {
    if (_noUiRebuildPending) return   // always undefined on first call
    _noUiRebuildPending = true
```

No `property bool _noUiRebuildPending` exists in the file. The guard always fails on first invocation, but since it's a bare JS variable subsequent assignments do persist within the JS scope. The coalescing guard is unreliable.

**Fix:** Add `property bool _noUiRebuildPending: false`.

---

### BUG-011 — `AltSwitcher.qml`: Property name typo breaks MRU ordering

**File:** `modules/altswitcher/AltSwitcher.qml`
**Category:** A
**Line declared:** 29 / **Line used:** 229

Declared:
```qml
readonly property bool altUseMostRecent: altSwitcherOptions.useMostRecentFirst ?? true
```

Used:
```qml
const useMostRecentFirst = root.altUseMostRecentFirst  // undefined
```

`altUseMostRecentFirst` does not exist — it should be `altUseMostRecent`. MRU window ordering never activates regardless of config.

**Fix:** Rename the property to `altUseMostRecentFirst` to match usage, or fix the usage to `root.altUseMostRecent`.

---

### BUG-012 — `services/Matugen.qml`: `reload()` is a no-op

**File:** `services/Matugen.qml`
**Category:** A (functional)

```qml
function reload(): void {
    console.log("🔄 [Matugen] Colors reloaded from:", colorsPath)
}
```

No color reload occurs. `state/colors.qml` does not exist on disk — Matugen has never run. The shell's `qs ipc call colors reload` command calls this function, so that IPC target is effectively broken.

The active color system is `services/Pywal.qml` which watches `~/.cache/wal/colors.json`.

**Fix:** Either implement Matugen pipeline (run matugen, watch output file) or update `colors` IPC handler to call `Pywal.reload()`.

---

### BUG-013 — `modules/launcher/LauncherPanel.qml`: Dead import creates hard dependency

**File:** `modules/launcher/LauncherPanel.qml`
**Category:** B
**Line:** 7

```qml
import Qt5Compat.GraphicalEffects
```

No type from this module is used anywhere in the file. If the `qt5compat` package is not installed, the entire launcher panel fails to load at startup with a module-not-found error.

**Fix:** Remove the import.

---

### BUG-014 — `modules/bar/components/MediaPlayer.qml`: Dangling import path

**File:** `modules/bar/components/MediaPlayer.qml`
**Category:** B
**Line:** ~7

```qml
import "../../../components"
```

`components/` contains only an `effects/` subdirectory. There is no `qmldir` at the `components/` level and no QML files directly there. The import resolves to a directory with no exported types.

**Fix:** Change to `import "../../../components/effects"` which has a `qmldir` and exports `Material3Anim`.

---

## 4. Medium Severity Bugs

These produce wrong visual output (incorrect colors, invisible elements) but don't crash.

---

### BUG-015 — `ControlCenterWindow.qml`: 4 undefined Pywal color properties

**File:** `modules/controlcenter/ControlCenterWindow.qml`
**Category:** A

The following properties are read from `pywal` but do not exist in `services/Pywal.qml`:

| Property Used | Used For | Evaluates To | Correct Substitute |
|---|---|---|---|
| `pywal.warning` | DND toggle color, Night Light color | `undefined` (invisible) | `pywal.color3` |
| `pywal.info` | Caffeine toggle color | `undefined` (invisible) | `pywal.color4` |
| `pywal.error` | Power Mode active color | `undefined` (invisible) | `pywal.color1` |
| `pywal.secondary` | Screenshot toggle color | `undefined` (invisible) | `pywal.color5` |

**Fix:** Either substitute the correct `colorN` values at the call sites, or add semantic alias properties to `Pywal.qml`:
```qml
readonly property color warning: color3
readonly property color info: color4
readonly property color error: color1
readonly property color secondary: color5
```

---

### BUG-016 — `services/Network.qml`: Duplicate Bluetooth polling

**File:** `services/Network.qml`
**Category:** Design issue

`Network.qml` contains a complete parallel Bluetooth polling implementation (`bluetoothTimer` at 5 s, `bluetoothStatusProc`, `bluetoothConnected`, `bluetoothDeviceName`, `bluetoothDeviceAddress`) that duplicates the entire responsibility of `services/Bluetooth.qml` (which polls at 2 s).

Two services call `bluetoothctl` on different intervals — the resulting state may be inconsistent between the two.

**Fix:** Remove the Bluetooth block from `Network.qml`. Any consumer reading `Network.bluetoothConnected` should be migrated to `QsServices.Bluetooth.connected`.

---

### BUG-017 — `config/Appearance.qml`: Cross-module relative import

**File:** `config/Appearance.qml`
**Category:** B (potential)
**Line:** ~3

```qml
import "../services" as QsServices
```

This is a relative import crossing module boundaries — from `config/` (registered as `qs.config`) into `services/` (registered as `qs.services`). Whether this resolves depends on Quickshell's module lookup order. It works in practice on some setups but is fragile.

**Fix:** Use the canonical import: `import "qs.services" as QsServices` or `import "../services" as QsServices` verified against the actual lookup path.

---

## 5. Minor Issues

Non-breaking but worth cleaning up.

---

### BUG-018 — `SettingsWindow.qml`: Qt5-era versioned imports

**File:** `modules/settings/SettingsWindow.qml`

```qml
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
```

Qt 6 imports are unversioned. These still work in Qt 6 but are deprecated style and will produce warnings in strict lint passes.

**Fix:** Drop version numbers: `import QtQuick.Window`, `import QtQuick.Controls`, `import QtQuick.Layouts`.

---

### BUG-019 — `SettingsWindow.qml`: `ApplicationWindow` root

**File:** `modules/settings/SettingsWindow.qml`

Root type is `ApplicationWindow` (from QtQuick.Controls) — creates a plain Qt window without Wayland layer-shell positioning. It won't integrate with compositor layer rules and may not respect window management conventions on Niri.

This is a placeholder stub, so acceptable short-term. When the settings UI is built out, migrate to a Quickshell window type.

---

### BUG-020 — `dist/quickshell/`: Stale pre-restructure snapshot

**Directory:** `dist/quickshell/`

Contains old copies of `shell.qml`, `Bar.qml`, `LauncherPanel.qml`, `Dashboard.qml`, `MusicPanel.qml` with `Qt5Compat.GraphicalEffects` imports and a completely different structure from the current project. These are not part of the live shell.

**Fix:** Delete `dist/quickshell/` to avoid agent/tooling confusion.

---

## 6. Newly Discovered Critical Issues

Additional critical issues identified through comprehensive codebase analysis:

### BUG-021 — Unsafe `Loader.item` Access Without Status Guards

**Files:** `shell.qml`
**Category:** A (Runtime Error Risk)
**Lines:** Multiple locations throughout the file

The code repeatedly accesses `loader.item` without checking if `loader.status === Loader.Ready`. With `asynchronous: true`, `Loader.item` is `null` until the component is fully loaded, causing potential TypeError exceptions.

**Examples:**
- Lines ~70, 75, 84, 88, 92, 96, 100 in IPC handlers
- Lines ~148, 153, 158, 164, 169, 174, 179 for various loaders

**Fix:** Always guard with `if (loader.status === Loader.Ready && loader.item)` or use optional chaining (`loader.item?.property`).

---

### BUG-022 — Qt.createComponent with String URL

**File:** `shell.qml`
**Category:** B (Tooling & Type Safety)
**Line:** ~132

Using `Qt.createComponent("modules/settings/SettingsWindow.qml")` loses tooling support and type checking. This approach is discouraged in favor of inline Component definitions.

**Fix:** Use inline Component definition or ensure proper error handling.

---

### BUG-023 — Heavy Use of `property var` Instead of Typed Properties

**Files:** `shell.qml`, `Bar.qml`, `Launcher.qml`
**Category:** Performance & Compilation
**Lines:** Multiple property declarations

Using `property var` instead of typed properties (`property string`, `property int`, `property color`, etc.) prevents `qmlsc` compilation to C++, eliminates meta-object overhead, and blocks type checking.

**Examples:**
- `shell.qml`: `property var compositor`, `property var notifs`, `property var matugen`, etc.
- `Bar.qml`: `property var screen`, `property var barWindow`, etc.

**Fix:** Replace `property var` with appropriate typed properties.

---

### BUG-024 — Improper Use of `clip: true`

**Files:** `Bar.qml`, `Launcher.qml`, `AppRow.qml`
**Category:** Performance
**Lines:** Multiple components

Using `clip: true` forces Qt to create a separate scene graph batch (scissor/stencil), which is expensive. Clipping should only be used when content genuinely overflows and must be masked.

**Examples:**
- `Bar.qml` frame rectangle and mediaModule
- `Launcher.qml` frame rectangle

**Fix:** Remove `clip: true` unless visually necessary.

---

### BUG-025 — Security Risk: External Command Injection

**File:** `shell.qml`
**Category:** Security
**Lines:** ~226 and other Process commands

Constructing bash commands with string interpolation poses potential command injection risks if user-controlled inputs (like wallpaper paths) contain special characters.

**Example:**
```qml
applyWallProc.command = ["bash", "-c",
    "awww img '" + wallpaper.path + "' --transition-type any --transition-duration 2 & " +
    "matugen image '" + wallpaper.path + "' -c '" + root.configPath + "/dist/matugen/config.toml'"
]
```

**Fix:** Sanitize inputs or use safer alternatives to prevent command injection.

---

### BUG-026 — Expensive Expressions in Property Bindings

**File:** `shell.qml`
**Category:** Performance
**Line:** ~204-212

Complex computations in reactive bindings like the `filteredWallpapers` property that performs array filtering and iteration on every change.

**Example:**
```qml
property var filteredWallpapers: {
    if (wallSearchTerm === "") return wallpaperList
    var result = []
    for (var i = 0; i < wallpaperList.length; i++) {
        if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm)) {
            result.push(wallpaperList[i])
        }
    }
    return result
}
```

**Fix:** Cache expensive computations or use more efficient approaches.

---

### BUG-027 — Use of `var` Instead of `let/const`

**Files:** Throughout all QML files
**Category:** JavaScript Quality
**Lines:** Multiple function declarations

Using outdated `var` declarations instead of modern `let/const` which have block scope and better optimization potential.

**Fix:** Replace `var` with `let` or `const` as appropriate.

---

## 7. Keybind Bugs

### Hyprland — `dist/hypr/hyprland.conf`

| Keybind | Issue | Severity |
|---|---|---|
| `SUPER A` | Calls `qs ipc call dashboard toggle` — no `dashboard` IPC handler registered | High |
| `SUPER SHIFT W` | Points to `~/.config/scripts/random-wallpaper.sh` — script is at `~/.config/quickshell/scripts/` | High |
| Volume keys (`F1/F2/F3`, `XF86Audio*`) | Use `amixer` (ALSA) — shell uses PipeWire/wpctl internally, inconsistent | Medium |
| `Print` | Saves to `~/screenshots/` — `Screenshot.qml` uses `~/Pictures/Screenshots/` | Low |

### Niri — `dist/niri/config.d/70-binds.kdl`

| Keybind Group | Issue | Count | Severity |
|---|---|---|---|
| `Alt+Tab`, `Alt+Shift+Tab` | Hardcoded `spawn "/home/yemi/.config/quickshell/shell"` — binary doesn't exist; AltSwitcher disabled | 2 | Critical |
| All hardware keys (volume, brightness, media) | Call `spawn "inir" ...` — `inir` is the iNiR shell binary, not this project | 16 | Critical |
| `Mod+Q`, `Mod+Shift+R` | Call `spawn "inir" ...` same issue | 2 | Critical |
| `Mod+Space`, `Ctrl+Alt+T`, overlay binds | Phantom IPC targets — not registered in `shell.qml` | 10+ | High |
| `Mod+Comma` | Missing function name argument — `settings` alone, needs `settings toggle` | 1 | Medium |

---

## 8. Orphan Artifacts

### `QuickShellKeybinds.conf`

Root-level file claiming to be "Auto-generated by Quickshell". Nothing generates it and nothing reads it. All 16 IPC targets it calls are phantom (e.g. `dashboard-stats`, `wallpaper-toggle`, `bluetooth-toggle`). Created by an earlier agent session.

**Action:** Delete.

---

## 9. Prioritized Fix List

### Immediate (blocking other work)

1. **BUG-001 + BUG-002** — Convert `AltSwitcher` root to `PanelWindow`, restore `Loader` in `shell.qml`
2. **BUG-007** — Fix `Matugen.applyWallpaper()` or remove the stub
3. **BUG-008 + BUG-009** — Fix `Screenshot.qml` stdout reading and wl-copy call
4. **BUG-021** — Add proper guards for all `Loader.item` accesses
5. **BUG-025** — Address security risks in command construction

### Before next feature work

6. **BUG-003** — Add `Config` import to `AltSwitcher.qml`
7. **BUG-004** — Move Timer/Animation objects out of the non-rendering Rectangle
8. **BUG-005 + BUG-006 + BUG-010 + BUG-011** — Remaining `AltSwitcher` property bugs
9. **BUG-015** — Fix 4 undefined Pywal color properties in `ControlCenterWindow`
10. **BUG-013** — Remove dead `Qt5Compat.GraphicalEffects` import from `LauncherPanel`
11. **BUG-023** — Replace `property var` with typed properties where possible
12. **BUG-026** — Optimize expensive property bindings

### Cleanup

13. **BUG-014** — Fix dangling `components` import in `MediaPlayer`
14. **BUG-016** — Remove duplicate Bluetooth polling from `Network.qml`
15. **BUG-017** — Verify cross-module relative import in `Appearance.qml`
16. **BUG-012** — Implement or replace `Matugen.reload()`
17. **BUG-018 + BUG-019** — Clean up `SettingsWindow` imports and root type
18. **BUG-020** — Delete `dist/quickshell/` stale snapshot
19. **BUG-022** — Improve component creation approach
20. **BUG-024** — Optimize clip usage
21. **BUG-027** — Update JavaScript variable declarations
22. Delete `QuickShellKeybinds.conf`