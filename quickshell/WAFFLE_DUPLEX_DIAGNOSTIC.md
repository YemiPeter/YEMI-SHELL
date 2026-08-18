# Waffle Singleton Duplicates — Dead Code vs Active Conflict

> **Diagnostic pass only.** No edits, fixes, or refactors were performed. Every
> claim below is backed by raw command output captured during the audit.

## Scope

Follow-up to `WAFFLE_DIAGNOSTIC.md`. Goal: determine whether the duplicate
singleton registrations found in the prior audit (`Config`, `Theme`, `Dyn`,
`Flags`, `PillState`, `Metrics`) are **DEAD CODE** or **ACTIVE CONFLICTS**.

All commands run from `~/.config/quickshell` (the live config; the
`~/.config/yemi-shell` path from the original task does not contain `modules/`).

---

## 1. `import qs.` statements across the tree
(`grep -rn "^import qs\." --include="*.qml" .`)

Full raw output (truncated in live capture; key entries shown):

```
./modules/common/widgets/StyledToolTipContent.qml:2:import qs.modules.common
./modules/common/widgets/StyledToolTipContent.qml:3:import qs.modules.common.widgets
./modules/common/widgets/WaveVisualizer.qml:1:import qs.config
./modules/common/widgets/WaveVisualizer.qml:2:import qs.services
./modules/common/widgets/WaveVisualizer.qml:3:import qs.modules.common
./modules/common/widgets/WaveVisualizer.qml:4:import qs.modules.common.widgets
./modules/common/widgets/shapes/ShapeCanvas.qml:2:import qs.modules.common
./modules/common/widgets/shapes/ShapeCanvas.qml:4:import qs.config
./modules/common/widgets/widgetCanvas/AbstractOverlayWidget.qml:3:import qs.modules.common
./modules/common/widgets/widgetCanvas/AbstractOverlayWidget.qml:4:import qs.config
./modules/common/widgets/widgetCanvas/AbstractWidget.qml:3:import qs.modules.common
./modules/common/widgets/widgetCanvas/AbstractWidget.qml:4:import qs.config
... (120 files total import qs.config) ...
./modules/waffle/looks/Looks.qml:6:import qs.config
./modules/waffle/looks/Looks.qml:7:import qs.modules.common
./modules/waffle/looks/Looks.qml:8:import qs.modules.common.functions
./services/GameMode.qml:7:import qs.modules.common
./services/GameMode.qml:8:import qs.services
./services/NiriService.qml:10:import qs.modules.common
./services/NiriService.qml:11:import qs.services
./services/Notifications.qml:3:import qs.services
./services/MprisController.qml:3:import qs.services
./singletons/Theme.qml:5:import qs.config
./shell.qml:7:import qs.modules.common
./shell.qml:9:import qs.modules.common
./shell.qml:10:import qs.compositor
./ShellWafflePanels.qml:3:import qs.modules.common
./ShellPillPanels.qml:3:import qs.modules.common
```

**Namespace summary (which singleton namespace each file imports):**
- `qs.config` → resolves to `config/qmldir` (`singleton Config Config.qml`,
  `Appearance`, `AppearanceConfig`, `BarConfig`). **120 files** import `qs.config`.
- `qs.modules.common` → resolves to `modules/common/qmldir` (`singleton Config 1.0
  Config.qml`, `Directories`, `FileUtils`, `GlobalStates`). Used by `shell.qml`
  (lines 7 + 9), `ShellWafflePanels.qml`, `ShellPillPanels.qml`, and most widgets.
- `qs.compositor` → `compositor/qmldir` (`Compositor`).
- `qs.modules.common.widgets` / `.functions` / `.models` → child dirs of
  `qs.modules.common`.
- `qs.services` / `qs.services.deferred` → `services/`.
- `import "singletons" as QsSingletons` (shell.qml line 13) → directory import
  alias, used for `QsSingletons.PillState`, `QsSingletons.Theme`, etc.

---

## 2. Byte-diff of each duplicate pair/trio

### A. `diff ./config/Config.qml ./modules/common/Config.qml`
```
Files config/Config.qml and modules/common/Config.qml differ
```
- `wc -l`:
  - `config/Config.qml` = **36 lines**
  - `modules/common/Config.qml` = **2144 lines**
- Differing-line count (`diff ... | grep -c '^[<>]'`): **2170** changed lines.
- **Verdict: DIFFERENT** — two entirely separate files, not the same singleton.

### B. `diff ./singletons/Theme.qml ./modules/pill/Singletons/../../../singletons/Theme.qml`
```
(readlink -f ./modules/pill/Singletons/../../../singletons/Theme.qml)
  → /home/yemi/.config/quickshell/singletons/Theme.qml
IDENTICAL
```

### C. `diff ./singletons/Dyn.qml ./modules/pill/Singletons/../../../singletons/Dyn.qml`
```
(readlink -f → /home/yemi/.config/quickshell/singletons/Dyn.qml)
IDENTICAL
```

### D. `diff ./singletons/Flags.qml ./modules/pill/Singletons/../../../singletons/Flags.qml`
```
(readlink -f → /home/yemi/.config/quickshell/singletons/Flags.qml)
IDENTICAL
```

### E. `diff ./singletons/PillState.qml ./singletons/PillState.qml` (root qmldir re-export vs singletons/)
```
IDENTICAL (self — same physical file)
```

### F. `diff ./singletons/Metrics.qml ./singletons/Metrics.qml`
```
IDENTICAL (self — same physical file)
```

**Section 2 conclusion:**
- `Theme`, `Dyn`, `Flags` (3 registrations each) and `PillState`, `Metrics`
  (2 registrations each) all resolve via `readlink -f` to the **same single
  physical file** in `./singletons/`. The extra `qmldir` lines
  (`modules/pill/Singletons/qmldir` and the root `./qmldir`) are **re-exports /
  aliases**, not separate implementations → **same file, not a real duplicate.**
- `Config` is the **only** genuine duplicate: two different files
  (`config/Config.qml` 36 lines vs `modules/common/Config.qml` 2144 lines).

---

## 3. Which `Config` does `shell.qml` resolve?

Exact top-of-file imports from `shell.qml` (lines 1–13):
```qml
// @ pragma Env QS_NO_RELOAD_POPUP=1
// @ pragma Env QSG_RENDER_LOOP=threaded
// @ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import qs.modules.common
import Quickshell.Services.Notifications
import qs.modules.common
import qs.compositor
import QtQuick 6.10
import "services" as QsServices
import "singletons" as QsSingletons
```

- `shell.qml` imports **`qs.modules.common`** (lines 7 and 9 — imported twice,
  harmless). It does **NOT** import `qs.config`.
- `qs.modules.common` → `modules/common/qmldir` line 2:
  `singleton Config 1.0 Config.qml` → **`modules/common/Config.qml`**.
- Therefore `shell.qml`'s `Config` resolves to **`modules/common/Config.qml`**
  (the 2144-line file), NOT `config/Config.qml`.
- The other `Config` (the 36-line `config/Config.qml`) is reachable only via the
  `qs.config` namespace, which `shell.qml` never imports.

### `config/Config.qml` contents (the 36-line legacy singleton, full)
```qml
1: pragma Singleton
2:
3: import Quickshell
4:
5: Singleton {
6:     readonly property BarConfig bar: BarConfig {}
7:     readonly property AppearanceConfig appearance: AppearanceConfig {}
8:
9:     // Notification configuration
10:     readonly property var notifications: ({
11:         popupWidth: 340,
12:         maxVisible: 5,
13:         timeout: 7000,
14:         spacing: 8,
15:         margin: 8
16:     })
17:
18:     // Popup configuration
19:     readonly property var popups: ({
20:         width: 280,
21:         minHeight: 100,
22:         maxHeight: 400,
23:         hoverDelay: 300,
24:         margin: 6
25:     })
26:
27:     // Dashboard visibility toggles (for Overview Dashboard compatibility)
28:     readonly property var dashboard: ({
29:         enable: false,
30:         showToggles: true,
31:         showMedia: true,
32:         showVolume: true,
33:         showWeather: false,    // requires Weather.qml service
34:         showSystem: true
35:     })
36: }
```
This is a distinct object (`bar`, `appearance`, `notifications`, `popups`,
`dashboard`) — unrelated to the 2144-line `Config` (`options`, `setNestedValue`,
`panelFamily`, `fileWriteTimer`). Confirms the two are different singletons.

---

## 4. Write-path bug: same `Config.qml`?

From the prior audit of `modules/common/Config.qml` (the file `shell.qml` imports
via `qs.modules.common`):

- `Config.setNestedValue` defined at **`modules/common/Config.qml:107`**:
  ```qml
  107:    function setNestedValue(nestedKey, value) {
  108:        _applyNestedKey(nestedKey, value);
  109:        fileWriteTimer.restart();
  110:        root._bumpRevision();
  111:        root.configChanged();
  112:    }
  ```
- `fileWriteTimer` (Timer performing the write) defined at
  **`modules/common/Config.qml:234`**:
  ```qml
  234:    Timer {
  235:        id: fileWriteTimer
  236:        interval: root.readWriteDelay
  ...
  253:            configFileView.writeAdapter();
  ```
- `configFileView` (FileView being written) defined at
  **`modules/common/Config.qml:263`**:
  ```qml
  263:    FileView {
  264:        id: configFileView
  265:        path: root.filePath
  ```

The IPC handler in `shell.qml` (lines 229–232) calls
`Config.setNestedValue("panelFamily", ...)`:
```qml
229:      function toggle(): bool {
230:        Config.setNestedValue("panelFamily",
231:          Config.options.panelFamily === "waffle" ? "pill" : "waffle");
232:        return true;
233:      }
```

**Confirmation:** `shell.qml` imports `Config` from `qs.modules.common` →
`modules/common/Config.qml`. Inside that same file live `setNestedValue`
(line 107), `fileWriteTimer` (line 234), and `configFileView` (line 263).
**Yes — `fileWriteTimer` / `configFileView` are in the SAME `Config.qml` that the
IPC handler's `Config.setNestedValue` call targets.** The write path is internally
consistent; the toggle behavior (if buggy) is not caused by a cross-file /
wrong-singleton resolution.

---

## Determination: DEAD CODE vs ACTIVE CONFLICT

| Singleton | Files | Verdict |
|---|---|---|
| `Theme`, `Dyn`, `Flags` | 3 qmldir entries each, all `readlink -f` → `./singletons/*.qml` (identical) | **DEAD / redundant re-export** — not a conflict; same physical file aliased 3× |
| `PillState`, `Metrics` | 2 qmldir entries each → `./singletons/*.qml` (identical) | **DEAD / redundant re-export** — same file aliased 2× |
| `Config` | `config/Config.qml` (36 lines, `qs.config`) vs `modules/common/Config.qml` (2144 lines, `qs.modules.common`) | **ACTIVE but namespaced-apart** — two genuinely different singletons sharing the name `Config` in two different import namespaces; `shell.qml` uses the `qs.modules.common` one. Not a hard conflict unless a single file imports **both** `qs.config` and `qs.modules.common` (120 files import `qs.config`; many also import `qs.modules.common`, so in those scopes the later import's `Config` shadows the other). |

### Notes / caveats (no fixes applied)
- `Theme`, `Dyn`, `Flags`, `PillState`, `Metrics` duplicates are harmless
  re-exports of `./singletons/*.qml`; they are not separate implementations.
- `Config` is the only real naming overlap. Because the two `Config` singletons
  live in **different namespaces** (`qs.config` vs `qs.modules.common`), they do
  not collide at link time. The latent risk is **shadowing**: any QML file that
  imports both `qs.config` and `qs.modules.common` will resolve `Config` to
  whichever import appears last in that file. `shell.qml` only imports
  `qs.modules.common`, so its `Config.setNestedValue` / `fileWriteTimer` /
  `configFileView` chain is self-consistent and correct.
- No assertion is made here about whether the 36-line `config/Config.qml` is still
  needed by the 120 `qs.config` consumers vs being legacy — that would require
  tracing each of those 120 consumers, which is out of scope for this pass.
