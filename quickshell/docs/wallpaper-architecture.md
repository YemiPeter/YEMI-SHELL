# Wallpaper System Architecture (Niri) — YemiShell

> **Status:** fact-checked against the code — commit `c658eae` (branch `pill-perf`), 2026-09-15
> **Scope:** the Niri wallpaper path only — from compositor painting up to the **Background** section of Pill settings.
> **Style guide:** every claim below was verified by reading the file it points to. Stale/dead code is explicitly marked.

## Table of contents

1. [High-level stack (bottom-up)](#1-high-level-stack-bottom-up)
2. [Layer-by-layer detail](#2-layer-by-layer-detail)
3. [Architecture map (ASCII)](#3-architecture-map-ascii)
4. [Data flows](#4-data-flows)
5. [Component registry (live / dormant / dead)](#5-component-registry-live--dormant--dead)
6. [Fact-check log — corrections](#6-fact-check-log--corrections)
7. [Stale / dead code inventory](#7-stale--dead-code-inventory)
8. [The Background section (Pill settings)](#layer-9--the-background-section-pill-settings)

---

## 1. High-level stack (bottom-up)

| Layer | Component | File(s) | Status |
|---|---|---|---|
| 0 · Compositor | Niri layer rules, startup, keybind | `niri/config.d/80-layer-rules.kdl`, `50-startup.kdl`, `70-binds.kdl` | live |
| 1 · Renderer | Backdrop layer window + crossfader + parallax | `quickshell/modules/background/Backdrop.qml`, `WallpaperCrossfader.qml`, `BackdropParallax.qml` | live |
| 2 · State | state-file watcher | `quickshell/singletons/WallpaperState.qml` | live |
| 3 · Setter | single dispatch script | `quickshell/scripts/set-wallpaper.sh` | live |
| 4 · Colors | single color writer + engine | `quickshell/scripts/after-wall.sh`, `dominance-engine.py` | live |
| 5 · Bridge | QML↔shell bridge + awww lifecycle | `quickshell/modules/pill/Singletons/Walls.qml` | live |
| 6 · Services | auto-shuffle / per-monitor / awww client | `quickshell/services/{Wallpapers,WallpaperListener,AwwwBackend}.qml` | **dormant** (not in `services/qmldir`) |
| 7 · IPC | `wallpaper.*`, `colors.reload` handlers | `quickshell/shell.qml` | live |
| 8 · Pill UI | picker + surface routing | `quickshell/modules/pill/Wallpaper.qml`, `Pill.qml`, `PillOverlay.qml`, `singletons/PillState.qml` | live |
| 9 · Pill UI | Background settings section | `quickshell/modules/pill/Background.qml` | live |

## 2. Layer-by-layer detail

### Layer 0 · Niri compositor

- **Niri has no native wallpaper.** On Niri the wallpaper is painted by QuickShell on a `PanelWindow` layer surface: `WlrLayershell.layer: WlrLayer.Background`, namespace `quickshell:yBackdrop` (`Backdrop.qml`).
- `niri/config.d/80-layer-rules.kdl` → `layer-rule { match namespace="quickshell:yBackdrop"; place-within-backdrop true; opacity 1.0 }` — renders behind all windows, above the compositor's solid background. The file defines the same rule for **three** namespaces: `quickshell:iiBackdrop` (iNiR), `quickshell:wBackdrop` (waffle), `quickshell:yBackdrop` (YemiShell).
- `niri/config.d/50-startup.kdl` spawns `quickshell -p $HOME/.config/quickshell/shell.qml`. It deliberately does **not** spawn `set-wallpaper.sh` (a previous `niri init` spawn flashed the real wallpaper before the shell could hide it). Startup restore is driven in-QML instead: `Walls.qml` `Component.onCompleted { syncAwww(Flags.backdropHideWallpaper) }`.
- `niri/config.d/70-binds.kdl` → `Mod+W { spawn "qs" "ipc" "call" "wallpaper" "toggle" "eDP-1"; }`.
- `quickshell/config.d/50-startup.kdl` → one-shot `scripts/boot-wallpaper-debug.sh` (boot diagnostics only).

### Layer 1 · The QML backdrop renderer (`modules/background/`)

`Backdrop.qml` (`PanelWindow`, one per screen via `Variants { model: Quickshell.screens }` in `shell.qml`):

- `visible: Flags.backdropEnable && Compositor.isNiri` — the layer is **Niri-only**.
- `effectiveWallpaper`: if `!Flags.backdropUseMainWallpaper && Flags.backdropWallpaperPath !== ""` use `backdropWallpaperPath`, else `WallpaperState.current`.
- `showImageLayer: Compositor.isNiri && !Flags.backdropHideWallpaper` — whether the QML image is actually drawn.
- Render stack (inside `BackdropParallax`, a Niri-only `Loader` that also drives `containerX`/`parallaxScale`):
  1. `WallpaperCrossfader` — two-slot image engine; visible when `showImageLayer && !isGif`; source = state path prefixed with `file://`.
  2. `AnimatedImage` — GIF path; `playing` gated by `Flags.backdropEnableAnimation`.
  3. `MultiEffect wallFx` — blur/saturation/contrast; `visible` gated `backdropEnable && isNiri` with an explicit `hasLoadedOnce` latch so it doesn't sample the crossfader mid-startup-decode.
  4. Dim `Rectangle` — `Flags.backdropDim`, gated by `backdropEnable && backdropEffects`.
  5. 4-piece vignette gradient — `Flags.backdropVignette` × `backdropVignetteEnable` × `backdropVignetteRadius` (also gated by `backdropEffects`).
- `Connections` block forwards three change sources into `wall.source` explicitly (singleton change signals were flaky across files): `WallpaperState.current`, `Flags.backdropWallpaperPath`, `Flags.backdropUseMainWallpaper`.

`WallpaperCrossfader.qml` — two `Image` slots; reads `Flags.transitionEnable.Type.Direction.Duration`; `hasLoadedOnce` latch.

`BackdropParallax.qml` — Niri-only: workspace-relative x-shift/scale via `parallaxEnable/Zoom/Strength`.

### Layer 2 · State file (single source of truth)

- **`${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper`** — current wallpaper path.
- **`${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper-bag`** — shuffle bag for random picks (flock-guarded, refilled by `set-wallpaper.sh`, never repeats the current pick).
- `singletons/WallpaperState.qml` — `FileView` watcher exposing reactive `current`. Read-only by design; never triggers a theme reload.
- The path is consistently used by: `set-wallpaper.sh:43`, `WallpaperState.qml:17`, `Walls.qml:39`, `after-wall.sh:32`, `hypr/scripts/wallpaper.sh:5`.
- Transition flags live in `${XDG_STATE_HOME}/quickshell/flags.json` (same file `Flags.qml`'s `FileView` watches).

### Layer 3 · Setter dispatcher — `scripts/set-wallpaper.sh`

Usage: `set-wallpaper.sh <compositor> <action> [path]` — compositor passed in from QML, never re-detected.

Actions:
- `set` / `init` / any non-`restore` → pick (`$1` → state file → `pop_bag` random), then **always**: write `quickshell-wallpaper` → `ensure_daemon` → `awww img` (paints on **every** compositor, Niri included) → `after-wall.sh "dynamic" <pic>`; plus `hyprctl reload` on Hyprland only.
- `restore` → **paint-only subset**: `awww img` from the live state pick, with *no* state write, *no* after-wall, *no* reload. Used by `Walls.syncAwww` when "hide main wallpaper" is turned off / at startup.

Transition flags are read via `jq` from `flags.json`; `--transition-duration` is the **ms→seconds** conversion point (`200–3000` ms UI ↔ seconds for awww). Wipe/wave translate `transitionDirection` to `--transition-angle`.

> ⚠️ **Header/code contradiction (stale docblock):** lines 27–29 claim "On Niri … no external daemon is invoked", but lines 179–186 paint `awww img` on every compositor — *"the desktop wallpaper goes stale on Niri while the QML backdrop changes."* Live behavior = awww **and** the QML Backdrop both paint (two painters), unless `backdropHideWallpaper` is ON (which bypasses this script entirely).

### Layer 4 · Color pipeline — `scripts/after-wall.sh`

- **Single writer** of `~/.cache/yemi-shell/colors.json`.
- Resolves wallpaper from an explicit arg, else the state file (and honors the backdrop image when the separate-backdrop + `backdropThemeColors` path is used).
- Runs `scripts/dominance-engine.py` (dominant-color → full token set both moods) writing `colors.json` v2, plus fans out `terminal.json` + `hypr-colors.lua`, then applies terminal themes and finishes with `qs ipc call colors reload`.
- Legacy path behind `YEMI_LEGACY_COLORS=1` → `scripts/wallcolors.py` (old schema).
- `qs ipc call colors reload` → `shell.qml` `IpcHandler "colors"` → `QsSingletons.Dyn.reload()`.

### Layer 5 · QML↔shell bridge — `modules/pill/Singletons/Walls.qml`

- Snapshot of `~/Pictures/Wallpapers`: `thumbProc` (`hypr/scripts/wallpaper-thumbs.sh`) → `listProc` (`find -printf '%T@' | sort -rn`, newest first) → `stateProc` reads state file. Refresh is single-flight with a `pending` retry.
- **`apply(path)`** — Niri split:
  - `backdropHideWallpaper && isNiri` → in-memory `current`, write state file via `stateWriteProc`, run `afterWallProc` (**no awww paint** — the QML backdrop is the sole renderer).
  - else → `applyProc` = `set-wallpaper.sh <compositor> set <path>`.
  - `queuedApply` replays the newest pick when a transition is still running; `lastAppliedPath` guards replays.
- **`syncAwww(hide)`** — Niri-only lifecycle: hide ON → `killProc` (`pkill -x awww-daemon`); hide OFF → `restoreProc` (`set-wallpaper.sh <comp> restore <state pick>`). Called on startup and when `backdropHideWallpaper` flips.
- `trash(path)` via `gio trash`, keeps `entries` in sync; re-snapshot on failure.

### Layer 6 · Services — `services/` (mostly dormant)

- `WallpaperListener.qml` — computes a per-monitor effective wallpaper + media-type classification. **Zero references anywhere in QML and not registered in `services/qmldir` → dead.**
- `AwwwBackend.qml` — awww probe + `apply()`/`clear()` wrappers, `supportsMainWallpaper()` (refuses gif/mp4/webm/mkv/avi/mov), transition-type normalization to awww's vocabulary. **Not in `services/qmldir`; only mention in the tree is a comment in `modules/common/Glass.qml` → dormant.**
- `Wallpapers.qml` — `autoWallpaperTimer` (reads `Flags.autoWallpaperEnable/Interval`), `currentMainWallpaperPath`, `apply/applySelectionTarget/select/randomFromCurrentFolder`, per-monitor config helpers. **Not in `services/qmldir`; no active import → dormant.** Consequence: the "Shuffle wallpapers" settings rows currently drive dormant code; the only *live* random is `shell.qml`'s `randomWallProc`.

### Layer 7 · IPC — `shell.qml`

- `IpcHandler "wallpaper"`:
  - `random()` → `randomWallProc` (`find … jpg/jpeg/png/webp | shuf -n1`) → `applyWallpaper()` → `applyWallProc` = `set-wallpaper.sh <compositor> set <path>`.
  - `toggle(mon)` → `PillState.toggleSurface(mon || focusedMonitor.name, "wallpaper")` — opens the picker surface.
- `IpcHandler "colors"` → `reload()` → `QsSingletons.Dyn.reload()` (this is the tail of `after-wall.sh`).

### Layer 8 · Pill surfaces & the picker

- `Pill.qml` owns the `surfaces` registry (`wallpaper: { size: () => Qt.size(wallpaperW, wallpaperH), ame: null }`) and the `wallLoader` (`Loader`, active while `wallpaperOpen || closingGraceSurface === "wallpaper"`, hosts `modules/pill/Wallpaper.qml`).
- `Pill.requestSurface` is a signal; `PillOverlay.qml` connects it → `QsSingletons.PillState.toggleSurface(mon, name)`; `PillState` holds `openMon`/`openSurface` and emits `surfaceOpened`.
- **`Wallpaper.qml`** (the picker filmstrip):
  - Model = `Walls.entries` (newest-first), plus a DuckDuckGo search mode (`hypr/scripts/wallpaper-search.sh` → `query`/`download`).
  - `activate()`: if `Flags.wallpaperSelectionTarget === "backdrop"` → `Flags.backdropWallpaperPath = entry.path`, clear the target, and if `Flags.backdropThemeColors` rerun `after-wall.sh`; else `Walls.apply(path)` (with a download branch for DDG images via `dlProc`).
  - Hold-to-trash via long-press → `Walls.trash`; `centerOnCurrent()` re-centres the strip when the current wallpaper changes.

### Layer 9 · The Background section (Pill settings)

`SettingsSurface` with header `BACKGROUND`, back-surface `"settings"`; reached from `Settings.qml` (`backgroundRow`, label "Background"). Groups (flags they drive):

| Group | Controls → Flags |
|---|---|
| **Backdrop** (Niri-only visible) | master `backdropEnable`; *Hide main wallpaper* `backdropHideWallpaper` (→ `syncAwww`); *Animated wallpapers* `backdropEnableAnimation`; *Blur animated wallpapers* `backdropEnableAnimatedBlur`; *Use separate wallpaper* `backdropUseMainWallpaper`; **Backdrop wallpaper → Change** button (`Flags.wallpaperSelectionTarget = "backdrop"` + `pill.requestSurface("wallpaper")`); *Theme from backdrop* `backdropThemeColors` (→ `regenColors()` → `after-wall.sh`); *Blur / Saturation / Contrast* steppers (`wallFx`) |
| **Wallpaper transitions** | `transitionEnable`, `transitionType`, `transitionDirection`, `transitionDuration` (ms UI) — shared vocab for both the crossfader (QML) and `set-wallpaper.sh` → awww |
| **Wallpapers folder** | directory TextField → `Flags.wallpapersDirectory` (+ config mirror) |
| **Shuffle wallpapers** | `autoWallpaperEnable` toggle + interval stepper → currently drives *dormant* `services/Wallpapers.qml` |
| **Parallax** (Niri-only) | `parallaxEnable`, `parallaxZoom`, `parallaxStrength` → `BackdropParallax` |

> ⚠️ **Missing UI:** the Settings row caption still reads *"Wallpaper dim & vignette"*, but `backgroundDim`/`backdropVignette`/`backdropVignetteRadius`/`backdropVignetteEnable`/`backdropEffects` have **no UI rows anywhere in the pill module** (verified by grep). The flags still exist and `Backdrop.qml` still renders them — the controls were dropped from this surface.

## 3. Architecture map (ASCII)

```
                    ┌────────────────────────────────────────────────────────────┐
   ENTRY POINTS     │  Mod+W → qs ipc call wallpaper toggle eDP-1  (70-binds.kdl)│
                    │  qs ipc call wallpaper random                              │
                    └───────────────┬───────────────────────────┬───────────────┘
                                    ▼                           ▼
                       shell.qml IpcHandler "wallpaper" │ "colors"
                       toggle() → PillState.toggleSurface│ reload() → Dyn.reload()
                       random()  → randomWallProc ───────┘ (tail of after-wall.sh)
                                    │ find|shuf -n1
                                    ▼
                        applyWallpaper() → set-wallpaper.sh <comp> set <path>
                                                              │
                                                              ▼
┌─────────────────────────────── shell.qml (surface host) ────────────────────────────────┐
│   PillOverlay ── Pill ── surfaces.wallpaper ── wallLoader ── modules/pill/Wallpaper.qml │
│       │  requestSurface("wallpaper") → PillState.toggleSurface   ▲  (picker filmstrip)  │
│   PillState { openMon, openSurface }  ──────────────────────────┤                       │
│       │                                                         │ activate():          │
│       ▼                                                         │  • target=="backdrop"│
│   modules/pill/Background.qml ──── "Change" button ─────────────┤    → Flags.          │
│   (BACKGROUND sub-surface)                                      │      backdropWallpaper│
│     Backdrop: enable/hide-main/gif/anim/separate/blur/sat/      │      Path (+ after-   │
│               contrast  [dim + vignette UI removed]             │      wall if themeOn) │
│     Transitions · Folder · Shuffle(→dormant svc) · Parallax     │  • else → Walls.apply │
└─────────────────────────────────────────────────────────────────┴──────────────────────┘
                                        │                │
                    ┌───────────────────▼──────┐   ┌─────▼────────────────────────────┐
   BRIDGE           │  Walls.qml (LIVE)         │   │  Dormant / dead:                 │
                    │  • entries (thumbs+find)  │   │  services/Wallpapers.qml (timer),│
                    │  • apply():               │   │  services/WallpaperListener.qml, │
                    │    hide-wallpaper+isNiri ▸│   │  services/AwwwBackend.qml,       │
                    │      state write+afterWall│   │  shell.qml wallpaperList/thumbs  │
                    │      (NO awww)            │   │  block, hypr/scripts/wallpaper.sh│
                    │    else ▸ set-wallpaper.sh│   └──────────────────────────────────┘
                    │  • trash · queuedApply    │
                    │  • syncAwww(hide) [startup]│
                    └─────────────┬──────────────┘
                                  │  set / restore
                                  ▼
```
```
┌────────────────────────────── scripts/set-wallpaper.sh (SINGLE DISPATCHER) ────────────────────────┐
│  pick: $1 | state file | pop_bag (flock, no-repeat current)                                          │
│  flags.json → transition ms→s, fade / wipe / wave → --transition-angle                                │
│  non-restore: write quickshell-wallpaper → ensure_daemon → awww img (ALL compositors!)              │
│               → after-wall.sh "dynamic" <pic> → hyprctl reload (Hyprland only)                       │
│  restore:     awww img from live state only   (no writes · no colors · no reload)                    │
└──────────────┬────────────────────────────┬───────────────────────────────────────────────────────────┘
               ▼                            ▼
   ~/.local/state/quickshell-wallpaper      scripts/after-wall.sh  (SINGLE COLOR WRITER)
   + quickshell-wallpaper-bag               dominance-engine.py → ~/.cache/yemi-shell/colors.json
                                            (+ terminal.json · hypr-colors.lua)
                                            → terminal apply → qs ipc call colors reload
               │
               ▼                              ┌──────────────────────────────────────────────────────────┐
   WallpaperState.qml (FileView watch) ──────►│  modules/background/Backdrop.qml (PanelWindow yBackdrop) │
                                             │  WlrLayer.Background · namespace quickshell:yBackdrop     │
                                             │  visible: backdropEnable && isNiri                       │
                                             │  effectiveWallpaper = backdropWallpaperPath (if separate) │
                                             │                        ?: WallpaperState.current        │
                                             │  showImageLayer = isNiri && !backdropHideWallpaper        │
                                             │  BackdropParallax (Niri Loader)                           │
                                             │    ├─ WallpaperCrossfader (two-slot, Flags transitions)   │
                                             │    └─ AnimatedImage (gif + backdropEnableAnimation)       │
                                             │  MultiEffect blur/sat/contrast (gated, hasLoadedOnce)     │
                                             │  dim rect (backdropEffects) · vignette gradient          │
                                             │  Connections: current/path/useMain → wall.source          │
                                             └───────────────────────────┬────────────────────────────────┘
                                                                         │
                                                                         ▼
                                                              niri/config.d/80-layer-rules.kdl
                                                              place-within-backdrop true
                                                              (iiBackdrop · wBackdrop · yBackdrop)
```

## 4. Data flows

### 4a. Picking a wallpaper (main path)

```
[Wallpaper.qml activate] ──▶ Walls.apply(path)
                                 ├─ backdropHideWallpaper && isNiri:
                                 │     current = path · stateWriteProc → STATE file · afterWallProc (NO awww)
                                 └─ else: set-wallpaper.sh <comp> set <path>
                                            ├─ STATE ← path
                                            ├─ awww img            (external daemon repaint — two painters!)
                                            └─ after-wall.sh → dominance-engine → colors.json → IPC reload
STATE ──▶ WallpaperState.current ──▶ Backdrop Connections ──▶ crossfader.fadeTo(path)
```

### 4b. Picking a *separate backdrop* wallpaper

```
[Wallpaper.qml activate] target=="backdrop"
   → Flags.backdropWallpaperPath = path (clear wallSelectedIndex target)
   → if backdropThemeColors: after-wall.sh backdrop <path>
Backdrop.effectiveWallpaper = backdropWallpaperPath (backdropUseMainWallpaper == false)
   → Connections → wall.source        (WaitTransition.run() drives the switch immediately)
```

### 4c. Startup restore (Niri)

```
niri 50-startup.kdl: quickshell -p shell.qml
   → Walls.qml Component.onCompleted → syncAwww(Flags.backdropHideWallpaper)
        hide=false: set-wallpaper.sh <comp> restore <state pick> → awww img from live state only
        hide=true : pkill -x awww-daemon   (state already matches, theme already loaded)
   → Backdrop reads WallpaperState.current → crossfader (Image slots decode on create)
```

### 4d. Random wallpaper (IPC)

```
qs ipc call wallpaper random
   → shell.qml IpcHandler.random → randomWallProc (find | shuf -n1) → applyWallpaper(path)
   → applyWallProc = set-wallpaper.sh <comp> set <path>
```

### 4e. Colors refresh (from after-wall.sh)

```
after-wall.sh → dominance-engine.py → ~/.cache/yemi-shell/colors.json (v2)
   → kitty/ghostty via apply-terminal-colors.py
   → qs ipc call colors reload → Dyn.reload()  (no wallpaper repaint here)
```

## 5. Component registry (live / dormant / dead)

| File | Role | Status | Notes |
|---|---|---|---|
| `quickshell/scripts/set-wallpaper.sh` | single dispatcher: state + awww paint + colors chain | **live** | paints awww on Niri too (header docblock stale) |
| `quickshell/scripts/after-wall.sh` | single `colors.json` writer (`dominance-engine.py`, atomic tmp→cat) | **live** | `YEMI_LEGACY_COLORS` → `wallcolors.py` |
| `modules/pill/Singletons/Walls.qml` | QML↔shell bridge, `apply`/`syncAwww`/`trash`, startup restore | **live** | state write via temp+rename + flock |
| `singletons/WallpaperState.qml` | state-file `FileView` watcher → reactive `current` | **live** | read-only, never reloads themes |
| `modules/background/Backdrop.qml` | Niri renderer (layer window) | **live** | visible only under `backdropEnable && isNiri` |
| `modules/background/WallpaperCrossfader.qml` | two-slot image crossfader | **live** | ms→s conversion for tween duration |
| `modules/background/BackdropParallax.qml` | Niri-only parallax loader | **live** | |
| `modules/pill/Wallpaper.qml` | picker surface (folder + DDG search + trash) | **live** | |
| `modules/pill/Background.qml` | Pill **Background** settings section | **live** | dim/vignette rows removed |
| `singletons/PillState.qml` / `Pill.qml` / `PillOverlay.qml` | surface registry + routing | **live** | |
| `shell.qml` (IPC + `randomWallProc`) | remote `wallpaper.*`, `colors.reload` | **live** | rest of wallpaper block is dead |
| `hypr/scripts/wallpaper-search.sh` | DDG wallpaper search | **live** (helper) | |
| `hypr/scripts/wallpaper-thumbs.sh` | thumbnail generation | **live** (helper) | |
| `hypr/scripts/wallpaper.sh` | legacy setter (same STATE+BAG) | **legacy** | only stale comments reference it |
| `services/Wallpapers.qml` | auto-shuffle timer, per-monitor helpers | **dormant** | not in `services/qmldir` |
| `services/WallpaperListener.qml` | per-monitor wallpaper + media-type | **dead** | zero references anywhere |
| `services/AwwwBackend.qml` | awww apply/clear wrappers | **dormant** | only a comment inside `Glass.qml` |
| `shell.qml:365–517` | `wallpaperList`, `thumbGenProc`, `hashAllProc`, `currentWallProc`, `loadWallpapers` | **mostly dead** | only `randomWallProc/applyWallProc` alive |

## 6. Fact-check log — corrections

Issues found while fact-checking the original map against the code:

1. **Script locations.** `wallpaper-search.sh` / `wallpaper-thumbs.sh` live in **`hypr/scripts/`**, not `quickshell/scripts/`. `quickshell/scripts/` holds `set-wallpaper.sh`, `after-wall.sh`, `dominance-engine.py`, `dominance-extract.py`, `wallcolors.py`, `apply-terminal-colors.py`, `apply-system-theme.sh`, `boot-wallpaper-debug.sh`, `start-quickshell.sh`, `check-update.sh`, `reset-app-usage.sh`.
2. **The "core services" trio is mostly dormant** (biggest correction). None are registered in `services/qmldir` (the module's `qs.services` lists 22 singletons — none of the trio). The earlier claimed chain *Niri → WallpaperListener → WallpaperState → Walls → Pill Background* is wrong; the real chain is *picker → Walls.apply → set-wallpaper.sh → state file → WallpaperState (FileView) → Backdrop Connections → crossfader*. The "Shuffle wallpapers" settings rows drive dormant code; the only live random is `shell.qml`'s `randomWallProc`.
3. **`set-wallpaper.sh` header contradicts behavior.** Docblock lines 27–29 claim "On Niri … no external daemon is invoked", but lines 179–186 paint `awww img` on every compositor ("Paint — every compositor…"). Live behavior: on Niri **both awww and the QML Backdrop paint** (two painters), unless `backdropHideWallpaper` is ON (bypasses the script; Walls does an in-memory + state-write path and kills awww).
4. **`hypr/scripts/wallpaper.sh` is legacy.** It still writes the same STATE + BAG, but only stale comments reference it ("applies it via `wallpaper.sh`" in `Wallpaper.qml:16`, `Pill.qml:433`, `Walls.qml:17/50`). All live code routes through `set-wallpaper.sh`.
5. **Two "current" properties.** `Walls.current` (in-memory; set on hide-wallpaper picks; centering/pending) vs `WallpaperState.current` (state-file-backed; *what Backdrop actually binds*). State file is the true source of truth.
6. **`shell.qml` legacy wallpaper block** (`:365–517`): `wallpaperList`, `filteredWallpapers`, `wallSelectedIndex`, `wallpaperHashes`, `loadWallpapers`, `thumbGenProc`, `hashAllProc`, `currentWallProc` (reads a `~/Pictures/Wallpapers/current` **symlink no longer maintained** → stays `""`). Only `randomWallProc` → `applyWallpaper` → `applyWallProc` is alive.
7. **`shell.qml:338` comment** ("Wallpaper.qml was collapsed into it") is stale — the picker `modules/pill/Wallpaper.qml` very much still exists.
8. **State model is two files**, not one: `quickshell-wallpaper` (current) **+** `quickshell-wallpaper-bag` (shuffle bag; flock-guarded; refilled without repeating current pick — `set-wallpaper.sh:44, 52–80`).

## 7. Stale / dead code inventory

If any future task should clean these up:

| Item | Where | Verdict |
|---|---|---|
| `services/WallpaperListener.qml` | `services/` (unregistered) | delete |
| `services/AwwwBackend.qml` | `services/` (unregistered, comment-only ref) | delete or re-home into `Walls.qml`/`set-wallpaper.sh` |
| `services/Wallpapers.qml` | `services/` (unregistered) | delete, or wire the Shuffle rows to it and register it |
| `withWallpapers` service / "Shuffle wallpapers" UI | `modules/pill/Background.qml` + `Flags.autoWallpaper*` | decide: kill rows or revive service |
| `shell.qml` legacy wallpaper block | `shell.qml:365–517` (except `randomWallProc`/`applyWallProc`/`random()` IPC) | prune |
| `hypr/scripts/wallpaper.sh` | `hypr/scripts/` (stale comments in 3 QML files) | delete + fix comments, or update it as canonical |
| `set-wallpaper.sh` header docblock | `set-wallpaper.sh:27–29` | rewrite to match actual dual-painter behavior |
| stale "via wallpaper.sh" comments | `Wallpaper.qml:16`, `Pill.qml:433`, `Walls.qml:17/50`, `shell.qml:338` | fix |
| dim/vignette UI rows | `modules/pill/Background.qml` vs settings caption | re-add controls or fix caption |

---

*End of document.*