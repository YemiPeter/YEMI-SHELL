# QuickShell Implementation Checklist — REVISED (Option B)

> **Revision note:** This checklist has been adapted from the original to match
> Ricelin's actual implementation. The end goal is the same (Pywal removed,
> matugen-driven theme, bar renders), but the path respects what's actually on
> disk rather than a simplified design. See `PLANS/MASTER_PLAN.md` for overall
> context and `PLANS/PORTING_PROTOCOL (1).md` for the porting workflow.
>
> **How to use this:**
> - Mark each task as done with `[x]`
> - Commit after each completed task (or batch of small tasks) with a scoped message
> - STOP at every "REPORT BACK" marker; the user will unblock the next task
> - Follow the Porting Protocol: AI scaffolds (empty files + boilerplate), you paste
>   the ported logic by hand
> - Verification commands are mandatory. Paste their output in your report
>
> **Companion docs:** `MASTER_PLAN.md`, `THEME_SYSTEM_PLAN.md`, `PORTING_PROTOCOL (1).md`

---

# Phase 1: Theme System (Matugen-driven, faithful port from Ricelin)

> **Outcome:** Pywal removed. `singletons/Theme.qml`, `singletons/Dyn.qml`, and
> `singletons/Flags.qml` exist. The color pipeline matches Ricelin: `wallcolors.py`
> generates `~/.cache/ricelin/colors.json`, `Dyn.qml` reads it via `JsonAdapter`,
> `Theme.qml` exposes ~44 Ricelin-style properties. All `Pywal.*` references
> rewritten to `Theme.*`. Bar renders with wallpaper-driven colors.

## Pre-flight

- [ ] **P1.0.1** Confirm project is in git: `cd ~/.config/quickshell && git status`
  - If not: STOP and ask the user
- [ ] **P1.0.2** Read `MASTER_PLAN.md`, `CHECKLIST.md`, `PORTING_PROTOCOL (1).md`
- [ ] **P1.0.3** Read `PLANS/THEME_SYSTEM_PLAN.md`
- [ ] **P1.0.4** Read Ricelin's reference: `~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Theme.qml`
- [ ] **P1.0.5** Read Ricelin's reference: `~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml`
- [ ] **P1.0.6** Check matugen is installed: `which matugen` (or `matugen --version`)
  - If not installed: STOP and ask the user
- [ ] **P1.0.7** Read Ricelin's wallcolors.py: `less ~/.config/quickshell/.Ricelin/configs/hypr/scripts/wallcolors.py`

## Build the singletons infrastructure

- [ ] **P1.1.1** Create directory: `mkdir -p ~/.config/quickshell/singletons`
- [ ] **P1.1.2** Create `~/.config/quickshell/singletons/qmldir` with content:
  ```
  module singletons
  singleton Theme 1.0 Theme.qml
  singleton Dyn 1.0 Dyn.qml
  singleton Flags 1.0 Flags.qml
  ```
- [ ] **P1.1.3** Verify qmldir: `cat ~/.config/quickshell/singletons/qmldir`
- [ ] **P1.1.4** Commit: `git add singletons/qmldir && git commit -m "feat(theme): scaffold singletons directory and qmldir"`

## Create Flags.qml — dependency for Theme.qml

- [ ] **P1.1.5** Create `~/.config/quickshell/singletons/Flags.qml`
  - `pragma Singleton`
  - `import QtQuick`
  - Root: `QtObject`
  - Property: `paletteMode` (string, default `"dynamic"`) — `"dynamic"` uses Dyn's wallpaper values, `"static"` uses fallback hex
  - Property: `uiFont` (string, default `""`) — font family override
- [ ] **P1.1.6** Commit: `git add singletons/Flags.qml && git commit -m "feat(theme): add Flags singleton (paletteMode, uiFont)"`

## Port Dyn.qml from Ricelin (matugen JSON loader)

- [ ] **P1.2.1** Create `~/.config/quickshell/singletons/Dyn.qml`
  - Port verbatim from `.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml`
  - `pragma Singleton`
  - `import QtQuick`, `import Quickshell`, `import Quickshell.Io`
  - Root: `Singleton { id: root }`
  - 17 `readonly property string` declarations reading from `JsonAdapter`
  - `FileView` watching `~/.cache/ricelin/colors.json`
  - `JsonAdapter` with fallback hex values (warm dark defaults)
  - `onFileChanged: reload()`
- [ ] **P1.2.2** Verify: `cat ~/.config/quickshell/singletons/Dyn.qml` — confirm 17 properties + FileView + JsonAdapter
- [ ] **P1.2.3** Commit: `git add singletons/Dyn.qml && git commit -m "feat(theme): port Dyn.qml — matugen JSON loader with JsonAdapter"`

## Port Theme.qml from Ricelin

- [ ] **P1.3.1** Create `~/.config/quickshell/singletons/Theme.qml`
  - Port verbatim from `.Ricelin/configs/quickshell/pill/Singletons/Theme.qml`
  - `pragma Singleton`
  - `import QtQuick`, `import Quickshell`
  - Root: `Singleton { }`
  - Property `dyn: Flags.paletteMode !== "static"` (readonly bool)
  - All ~44 Ricelin properties: `onGlow`, `verm`, `vermLit`, `cream`, `bright`, `dim`, `cardTop`, `cardBot`, `border`, `shadow`, `tileBg`, `subtle`, `faint`, `iconDim`, `hair`, `hairSoft`, `sheen`, `vermDim`, `vermDimDeep`, `vermBurn`, `tickRest`, `threadBg`, `flameCore`, `flameGlow`, `flameInk` (string), `flameEmber` (string), `flameBurn` (string), `flameTip` (string), `todayWarm`, `ghost`, `frameBg`, `frameBorder`, `creamMenu`, `shadowOpacity` (real), `fontFamilies`, `font`, `fontJp`
  - Function `joinArtists(artists, single)`
- [ ] **P1.3.2** Verify: `cat ~/.config/quickshell/singletons/Theme.qml` — confirm all properties
- [ ] **P1.3.3** Commit: `git add singletons/Theme.qml && git commit -m "feat(theme): port Theme.qml from Ricelin (~44 properties)"`

## Register singletons module in shell.qml

- [ ] **P1.3.4** Add import line in `~/.config/quickshell/shell.qml`:
  ```
  import "singletons" as QsSingletons
  ```
- [ ] **P1.3.5** Verify: `grep "singletons" ~/.config/quickshell/shell.qml`
- [ ] **P1.3.6** Commit: `git add shell.qml && git commit -m "feat(theme): register singletons module in shell.qml"`

## Verify the theme system standalone (before disabling Pywal)

- [ ] **P1.4.1** Create temporary test file `~/.config/quickshell/_test-theme.qml`:
  ```qml
  import Quickshell
  import QtQuick
  import "singletons" as QsSingletons
  ShellRoot {
      Component.onCompleted: {
          console.log("primary (onGlow):", QsSingletons.Theme.onGlow);
          console.log("cream:", QsSingletons.Theme.cream);
          console.log("cardBot:", QsSingletons.Theme.cardBot);
          console.log("dyn mode:", QsSingletons.Theme.dyn);
          console.log("Flags.paletteMode:", QsSingletons.Flags.paletteMode);
      }
  }
  ```
- [ ] **P1.4.2** Run: `qs -p ~/.config/quickshell/_test-theme.qml`
- [ ] **P1.4.3** Verify: stderr shows console.log lines with actual color values (not `undefined`)
- [ ] **P1.4.4** Delete the test file: `rm ~/.config/quickshell/_test-theme.qml`
- [ ] **P1.4.5** Commit (if any change happened): no commit if the test file was never tracked

> **REPORT BACK — P1.4 complete.** Wait for user to confirm theme system works before disabling Pywal.

## Disable Pywal in services/qmldir

> ### ⚠️ CRITICAL RULE — DO NOT REVERT P1.5
> After P1.5.5, the bar will be visually broken (all `Pywal.*` references resolve
> to `undefined`). This is EXPECTED. The fix is in the refactor tasks (P1.7-P1.10),
> NOT by reverting P1.5.
>
> **Only revert P1.5 if the user explicitly says so.**

- [ ] **P1.5.1** Open `~/.config/quickshell/services/qmldir`
- [ ] **P1.5.2** Comment out Pywal: `# singleton Pywal 1.0 Pywal.qml`
- [ ] **P1.5.3** Verify: `cat ~/.config/quickshell/services/qmldir` shows pywal line is now a comment
- [ ] **P1.5.4** Commit: `git add services/qmldir && git commit -m "refactor(services): disable Pywal in qmldir"`

## Build the pywal → theme mapping (change list)

- [ ] **P1.6.1** Run: `grep -rn "pywal\|Pywal" --include="*.qml" ~/.config/quickshell/ | grep -v ".Ricelin" | grep -v dist/`
- [ ] **P1.6.2** Save the output — this is your change list for the next tasks
- [ ] **P1.6.3** Confirm expected files appear in the list (these are the ones with pywal refs):
  - `config/Appearance.qml`
  - `config/BarConfig.qml`
  - `modules/bar/Bar.qml`
  - `modules/bar/components/Battery.qml`
  - `modules/bar/components/Bluetooth.qml`
  - `modules/bar/components/BluetoothPopupWindow.qml`
  - `modules/bar/components/Brightness.qml`
  - `modules/bar/components/BrightnessPopupWindow.qml`
  - `modules/bar/components/Clock.qml`
  - `modules/bar/components/ControlCenterToggle.qml`
  - `modules/bar/components/MediaPlayer.qml`
  - `modules/bar/components/Network.qml`
  - `modules/bar/components/NetworkPopupWindow.qml`
  - `modules/bar/components/NotificationPopups.qml`
  - `modules/bar/components/StatusIndicators.qml`
  - `modules/bar/components/Volume.qml`
  - `modules/bar/components/VolumePopupWindow.qml`
  - `modules/bar/components/Workspace.qml`
  - `modules/bar/components/Workspaces.qml`
  - `modules/controlcenter/ControlCenterWindow.qml`
  - `modules/controlcenter/components/BrightnessSlider.qml`
  - `modules/controlcenter/components/MediaCard.qml`
  - `modules/controlcenter/components/NotificationList.qml`
  - `modules/controlcenter/components/SystemStats.qml`
  - `modules/controlcenter/components/VolumeSlider.qml`
  - `modules/launcher/AppRow.qml`
  - `modules/launcher/Launcher.qml`
  - `modules/music/MusicPanel.qml`

> **STOP and ask if:** the change list contains files NOT in the expected list above,
> or is missing critical files.

## Rewrite Pywal.* → Theme.* in bar components

> **Mapping table** (use for all edits):
>
> | Old | New |
> |---|---|
> | `import "../../services" as QsServices` (for Pywal only) | `import "../../singletons" as QsSingletons` |
> | `readonly property var pywal: QsServices.Pywal` | Remove the local alias; use `QsSingletons.Theme` directly |
> | `pywal.background` | `Theme.cardBot` (base), `Theme.cardTop` (elevated) |
> | `pywal.foreground` | `Theme.cream` |
> | `pywal.primary` | `Theme.onGlow` |
> | `pywal.color1` / `pywal.error` | `Theme.vermBurn` |
> | `pywal.color2` / `pywal.success` | `Theme.onGlow` |
> | `pywal.color3` / `pywal.warning` | `Theme.verm` |
> | `pywal.color4` | `Theme.verm` or `Theme.onGlow` |
> | `pywal.color5` | `Theme.dim` |
> | `pywal.color8` | `Theme.faint` or `Theme.subtle` |
> | `pywal.surface` | `Theme.tileBg` |
> | `pywal.surfaceBright` | `Theme.bright` |
> | `pywal.surfaceContainer` | `Theme.cardTop` |
> | `pywal.surfaceContainerLow` | `Theme.cardBot` |
> | `pywal.surfaceContainerHigh` | `Theme.border` or `Theme.tileBg` |
> | `pywal.outline` | `Theme.border` |
> | `pywal.secondary` | `Theme.dim` |
> | `Qt.lighter(pywal.background, X)` | `Theme.cardTop` (approximate) |
> | `pywal.isLightMode` | Not used anywhere — no replacement needed |

- [x] **P1.7.x** For each bar component file, apply the mapping table:
  1. Update import path (if needed)
  2. Replace each `pywal.*` reference with `Theme.*` equivalent
- [x] **P1.7.y** Verify mid-progress: `grep -rn "pywal\|Pywal" --include="*.qml" ~/.config/quickshell/ | grep -v ".Ricelin" | grep -v dist/` — should show DECREASING count
- [x] **P1.7.z** Commit: `git add -A && git commit -m "refactor(theme): migrate pywal.* to Theme.* in bar components"`

## Rewrite control center components

- [x] **P1.8.x** For each control center file:
  1. Control center components use `property var pywal` passed from parent
  2. Replace the `pywal` property with a `QtObject` that references `QsSingletons.Theme`
  3. Replace `pywal.background` → `Theme.cardBot`, `pywal.foreground` → `Theme.cream`, etc.
- [x] **P1.8.y** Commit: `git add -A && git commit -m "refactor(theme): migrate pywal.* to Theme.* in control center"`

## Rewrite config/Appearance.qml

- [x] **P1.9.x** Rewrite the ~20 `QsServices.Pywal.*` references in Appearance.qml using the mapping table
  - `pywal.background` → `Theme.cardBot`
  - `pywal.foreground` → `Theme.cream`
  - `pywal.primary` → `Theme.onGlow`
  - `Qt.lighter(pywal.background, X)` → `Theme.cardTop`
- [x] **P1.9.y** Commit: `git add config/Appearance.qml && git commit -m "refactor(theme): migrate pywal.* to Theme.* in Appearance.qml"`

## Rewrite music panel

- [x] **P1.10.x** Rewrite all `root.pywal.*` references in `modules/music/MusicPanel.qml`
  - Replace `pywal.background` → `Theme.cardBot`
  - Replace `pywal.foreground` → `Theme.cream`
  - Replace `pywal.primary` → `Theme.onGlow`
  - Replace `pywal.color1` → `Theme.vermBurn`
  - Replace `pywal.color2` → `Theme.onGlow`
  - Replace `pywal.color8` → `Theme.faint`
- [x] **P1.10.y** Commit: `git add modules/music/MusicPanel.qml && git commit -m "refactor(theme): migrate pywal.* to Theme.* in music panel"`

## Rewrite launcher (Phase 3 will replace this, but fix refs for now)

- [x] **P1.11.x** Rewrite `modules/launcher/AppRow.qml` and `modules/launcher/Launcher.qml`
- [x] **P1.11.y** Commit

## Remove Pywal service file

- [x] **P1.12.1** Delete: `rm ~/.config/quickshell/services/Pywal.qml`
- [x] **P1.12.2** Verify: `ls ~/.config/quickshell/services/Pywal.qml` should error
- [x] **P1.12.3** Commit: `git add -A && git commit -m "refactor: remove Pywal.qml service"`

## Remove Pywal state files and infrastructure

- [x] **P1.13.1** Delete: `rm -f ~/.config/quickshell/state/colormode`
- [x] **P1.13.2** Delete: `rm -rf ~/.cache/wal`
- [x] **P1.13.3** Delete: `rm -rf ~/.config/quickshell/dist/wal`
- [x] **P1.13.4** Delete: `rm -rf ~/.config/quickshell/dist/quickshell`
- [x] **P1.13.5** Inspect `~/.config/quickshell/scripts/toggle-colormode.sh` — if it ONLY writes to colormode, delete it. If more, STOP and ask.
- [x] **P1.13.6** Inspect `~/.config/quickshell/scripts/after-wall.sh` — if it calls `wal` or `pywal`, replace with `wallcolors.py` call. If only wal work, STOP and ask.
- [x] **P1.13.7** Commit: `git add -A && git commit -m "refactor: remove Pywal state and infrastructure"`

## Wire the wallcolors.py pipeline

- [x] **P1.14.1** Confirm wallcolors.py works: `python3 ~/.config/quickshell/.Ricelin/configs/hypr/scripts/wallcolors.py /path/to/wallpaper.jpg`
  - Verify: `cat ~/.cache/ricelin/colors.json | head -20`
- [x] **P1.14.2** Modify `scripts/after-wall.sh` (or create it) to call wallcolors.py on wallpaper change
- [x] **P1.14.3** Test: change wallpaper, run `after-wall.sh`, confirm `~/.cache/ricelin/colors.json` updates
- [x] **P1.14.4** Commit: `git add -A && git commit -m "feat(theme): wire wallcolors.py into wallpaper pipeline"`

## Phase 1 end-to-end verification

- [x] **P1.15.1** `grep -rn "pywal\|Pywal" --include="*.qml" ~/.config/quickshell/ | grep -v ".Ricelin" | grep -v dist/` → must return ZERO matches
- [x] **P1.15.2** `ls ~/.config/quickshell/services/Pywal.qml 2>&1` → must error
- [x] **P1.15.3** `cat ~/.config/quickshell/services/qmldir` → must NOT contain `singleton Pywal` (only commented-out version)
- [x] **P1.15.4** `qs -p ~/.config/quickshell/shell.qml` — start the shell
  - Bar should render with Ricelin theme colors (not blank, not "undefined")
  - All pills visible: workspaces, media, clock, network, bluetooth, volume, brightness, battery, tray
  - No red errors in stderr
  - Ctrl+C after a few seconds
- [x] **P1.15.5** Change wallpaper, run `after-wall.sh` (or trigger however WM does)
  - Confirm bar colors update
  - Confirm `~/.cache/ricelin/colors.json` was written
- [x] **P1.15.6** Verify light/dark: set a bright wallpaper, run wallcolors.py, confirm `light = true` in script output

## 🛑 PHASE 1 COMPLETE — All pywal refs removed, Theme singleton active

> **Do NOT start Phase 2.** Report your results to the user. Wait for the
> user to verify the theme works and unblock Phase 2.

---

# Phase 2: Broken-stuff Cleanup

> **Outcome:** AltSwitcher, SettingsWindow, dist/quickshell/, QuickShellKeybinds.conf
> removed. BUG-013 and BUG-014 fixed. Bar still works.

> **AWAITING Phase 1 completion.** Detailed tasks will be added when
> Phase 1 is verified.

---

# Phase 3: Standalone Overlay Launcher

> **Outcome:** Ricelin's `launcher/` ported in. Loaded by main `shell.qml`.
> Replaces existing `launcher` IPC. Old `LauncherPanel.qml` deleted. Bar
> launcher button works against new IPC.

> **AWAITING Phase 2 completion.** Detailed tasks will be added when
> Phase 2 is verified.

---

# Phase 4 (Future): Pill-surface Launcher

> **Outcome:** Ricelin's `pill/Launcher.qml` ported in. Needs PillSurface,
> Theme, Flags, Motion singletons + morph animation system.

> **Future work.** Not in this cycle.