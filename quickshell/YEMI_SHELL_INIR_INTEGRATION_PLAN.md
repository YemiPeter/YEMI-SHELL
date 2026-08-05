# YEMI-SHELL + iNiR Integration Master Plan

> **Date:** 2026-08-05  
> **Priority:** Fix the color/wallpaper pipeline BEFORE any iNiR service merging.  
> **Philosophy:** Incremental, reversible, single-source-of-truth.  
> **Constraint:** `Theme.qml` token façade (`cream`, `verm`, `flameGlow`, etc.) stays. iNiR services adapt to YEMI-SHELL's snake_case schema, not the other way around.

---

## Table of Contents

1. [Phase 0 — Unify the Color Pipeline](#phase-0--unify-the-color-pipeline)
2. [Phase 1 — Port iNiR Config Infrastructure](#phase-1--port-inir-config-infrastructure)
3. [Phase 2 — Port iNiR ThemeService + WallpaperListener](#phase-2--port-inir-themeservice--wallpaperlistener)
4. [Phase 3 — Complete Surface Tokenization](#phase-3--complete-surface-tokenization)
5. [Phase 4 — Port Selective iNiR Services](#phase-4--port-selective-inir-services)
6. [Phase 5 — Dark/Light & Opacity Polish](#phase-5--darklight--opacity-polish)
7. [Phase 6 — Consolidation (Future)](#phase-6--consolidation-future)
8. [Decision Log](#decision-log)
9. [Verification Matrix](#verification-matrix)

---

## Phase 0 — Unify the Color Pipeline

**Goal:** One writer, one schema, no dead code. `colors.json` is written exclusively by the quickshell `wallcolors.py` (snake_case) and consumed exclusively by `Dyn.qml`.

### 0.1 `scripts/after-wall.sh` — Single Entry Point

Make `after-wall.sh` the **sole orchestrator** for all color generation. It handles mode/mood passthrough and becomes the single script that invokes `wallcolors.py`.

**Changes:**
- Accept `<mood>` and optional `<wallpaper-path>` args.
- Read `flags.json` for `paletteMode`.
- If `static`: run `wallcolors.py --mode static --mood <mood>`.
- If `dynamic`: require wallpaper path, run `wallcolors.py <wallpaper-path>`.
- Always run `apply-terminal-colors.py` after.
- Signal quickshell with `qs ipc call colors reload` (registered target).
- Remove the old `matugenReload` call (unregistered, no-op).

### 0.2 `modules/pill/Appearance.qml` — Route Toggle Through Single Writer

**Current bug:** Calls `~/.config/hypr/scripts/wallcolors.py` (camelCase schema) directly.

**Fix:** Replace direct `wallcolors.py` invocation with a call to `after-wall.sh`.

```diff
- command: ["sh", "-c",
-     "python3 "$HOME/.config/hypr/scripts/wallcolors.py" --mode static --mood "$1" ...",
+ command: ["sh", "-c",
+     "WALL="$(cat ${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper 2>/dev/null || true)"; "
+   + "python3 "$HOME/.config/quickshell/scripts/after-wall.sh" "$1" "${WALL:-}" >/dev/null 2>&1; "
+   + "hyprctl reload >/dev/null 2>&1; "
+   + "busctl --user call com.mitchellh.ghostty ... reload-config ...",
      "sh", mood]
```

### 0.3 `~/.config/hypr/scripts/wallpaper.sh` — Stop Writing Wrong Schema

**Current bug:** Runs the hypr copy of `wallcolors.py`, which writes camelCase keys that `Dyn.qml` cannot read.

**Fix:** Remove all `wallcolors.py` invocation from `wallpaper.sh`. It should only:
1. Set wallpaper via `awww img <pic>`.
2. Write state file `$(XDG_STATE_HOME)/quickshell-wallpaper`.
3. Run `hyprctl reload`.

Color generation is delegated to `after-wall.sh`, which is triggered by `Walls.qml`'s `afterWallProc` on `applyProc` exit.

### 0.4 `services/Matugen.qml` — Remove Dead Code

**Current state:** `applyWallpaper()` writes `state/colors.qml` (wrong ext, wrong dir, never read). `reload()` is a no-op (`console.log` only).

**Fix:**
- Delete `applyWallpaper()`, `colorsPath`, and the `matugen image ...` command.
- Reduce `reload()` to a shim: `QsSingletons.Dyn.file.reload()`.
- Remove from `services/qmldir` if nothing else references it.

### 0.5 `shell.qml` — Fix IPC Handler

**Current bug:** `colors reload` IPC → `root.matugen.reload()` → no-op.

**Fix:** Point the `colors` IPC handler at `Dyn.file.reload()` (or keep it as a no-op since `FileView.watchChanges` handles auto-reload).

```diff
- root.matugen.reload()
+ QsSingletons.Dyn.file.reload()
```

### Phase 0 Acceptance Criteria

```bash
# 1. hypr wallpaper.sh no longer calls wallcolors.py
grep -c "wallcolors.py" ~/.config/hypr/scripts/wallpaper.sh   # expect 0

# 2. colors.json always has snake_case keys after any trigger
jq 'has("primary_container")' ~/.cache/yemi-shell/colors.json  # expect true
jq 'has("accent")' ~/.cache/yemi-shell/colors.json             # expect false

# 3. Toggle palette/mood does not break the schema
# (run Appearance toggle, then check keys)

# 4. qs ipc call colors reload is honest (triggers Dyn re-read)
```

---

## Phase 1 — Port iNiR Config Infrastructure

**Goal:** Bring in iNiR's `Config.qml` (~2000 lines) so future services have a runtime config surface to consume.

### 1.1 Port `iNiR/modules/common/Config.qml`

**Target:** `services/Config.qml` (or `singletons/Config.qml` if you prefer).

**Keep:**
- `setNestedValue(key, value)` — dot-path config writes.
- `_writeMirrorToDisk()` — persists to `~/.config/illogical-impulse/config.json`.
- `Config.options` — runtime config object.

**Adapt:**
- On init, seed `Config.options.appearance` from YEMI-SHELL's existing `~/.local/state/quickshell/flags.json`.
- Map: `paletteMode` → `appearance.paletteMode`, `systemMood` → `appearance.systemMood`, etc.

### 1.2 Bidirectional Sync Layer (temporary)

`Flags.qml` and `Config.qml` coexist. A sync function mirrors values:

```qml
// In Config.qml or a bridge singleton
function syncFromFlags(): void {
    setNestedValue("appearance.paletteMode", Flags.paletteMode)
    setNestedValue("appearance.systemMood", Flags.systemMood)
    setNestedValue("appearance.pillOpacity", Flags.pillOpacity)
    setNestedValue("appearance.pillBlur", Flags.pillBlur)
}
```

Existing YEMI-SHELL code keeps using `Flags.paletteMode` directly. New iNiR services use `Config.options.appearance.paletteMode`.

### 1.3 Port `iNiR/defaults/config.json`

**Target:** `defaults/config.json` in YEMI-SHELL repo.

**Strip inactive sections** (keep structure, zero out values):
- `waffles` — not used until you decide to adopt Fluent panels.
- `dock` — YEMI-SHELL has no dock yet.
- `gameMode` — keep structure, will be wired in Phase 4.

**Keep active sections:**
- `appearance`, `bar`, `background`, `notifications`, `osd`, `modules`, `enabledPanels`, `panelFamily`.

### Phase 1 Acceptance Criteria

- `Config.setNestedValue("appearance.systemMood", "light")` writes to disk.
- `Config.options.appearance.paletteMode` reflects `Flags.paletteMode` at startup.
- Existing `Flags.qml` consumers still work unchanged.

---

## Phase 2 — Port iNiR ThemeService + WallpaperListener

**Goal:** Replace the dead `Matugen.qml` with iNiR's actual theme/wallpaper services, adapted to YEMI-SHELL's single-writer pipeline.

### 2.1 Port `services/ThemeService.qml`

**Role:** Manages theme state, reacts to config changes, signals consumers.

**Adaptation:**
- Does NOT generate `colors.json`. It triggers `after-wall.sh` and then signals `Dyn.file.reload()`.
- Consumes `Config.options.appearance` for mode/mood.
- Exposes `currentScheme` (light/dark) that YEMI-SHELL's `Flags.systemMood` can mirror.

### 2.2 Port `services/WallpaperListener.qml` + `services/Wallpapers.qml`

**Role:** Handle wallpaper change events, auto-wallpaper cycling, multi-monitor state.

**Integration:**
- `WallpaperListener` detects wallpaper changes (file watch or IPC).
- On change, it does NOT run its own color extractor. It calls `after-wall.sh <mood> <path>`.
- `Walls.qml` (YEMI-SHELL) delegates `apply()` to `WallpaperListener.setWallpaper()`.

### 2.3 Skip `MaterialThemeLoader.qml` (for now)

YEMI-SHELL's `wallcolors.py` uses a custom HSL ramp, not raw Material 3. This is a deliberate design choice. Only port `MaterialThemeLoader` if you later decide to replace the HSL ramp with true Material 3 scheme adaptation.

### 2.4 Update `modules/pill/Singletons/Walls.qml`

Replace the direct `wallpaper.sh` + `after-wall.sh` orchestration with calls to `WallpaperListener`:

```qml
// Walls.qml
function apply(path: string): void {
    WallpaperListener.setWallpaper(path)  // iNiR service
    // WallpaperListener internally triggers after-wall.sh
}
```

### Phase 2 Acceptance Criteria

- Wallpaper picker still works (via `Walls.apply()` → `WallpaperListener`).
- Auto-wallpaper (if enabled) cycles and colors update.
- `ThemeService.currentScheme` reflects the active mood.

---

## Phase 3 — Complete Surface Tokenization

**Goal:** Fix every surface that bypasses `Theme.*` now that the pipeline is trustworthy.

### 3.1 `modules/bar/components/Battery.qml` (6 hex + 1 Qt.rgba)

| Line | Current | Replacement |
|------|---------|-------------|
| 57 | `#ef4444` | `QsSingletons.Theme.verm` |
| 58 | `#f59e0b` | `QsSingletons.Theme.vermLit` |
| 62 | `#2dd4bf` | `QsSingletons.Theme.flameGlow` |
| 64 | `#5eead4` | `Qt.lighter(QsSingletons.Theme.flameGlow, 1.2)` |
| 186 | `#000000` / `#ffffff` | `QsSingletons.Theme.cream` |
| 234 | `Qt.rgba(0.1,0.1,0.12,1)` | `Qt.alpha(QsSingletons.Theme.tileBg, 0.9)` |
| 304 | `#ffffff` | `QsSingletons.Theme.bright` |

### 3.2 `modules/osd/VolumeOSD.qml` + `BrightnessOSD.qml`

- **Delete** `required property var matugen` (unused).
- Replace all hardcoded `Qt.rgba` with `Theme.*` tokens:

| Current | Replacement |
|---------|-------------|
| `Qt.rgba(0.1, 0.1, 0.1, 0.4)` | `Qt.alpha(QsSingletons.Theme.tileBg, 0.40)` |
| `Qt.rgba(1, 1, 1, 0.06)` | `QsSingletons.Theme.hair` |
| `Qt.rgba(0.2, 0.6, 1.0, 1.0)` | `QsSingletons.Theme.onGlow` |
| `Qt.rgba(0.8, 0.8, 0.8, 0.15)` | `Qt.alpha(QsSingletons.Theme.dim, 0.15)` |
| `Qt.rgba(0.9, 0.9, 0.9, 1.0)` | `QsSingletons.Theme.cream` |

### 3.3 `modules/pill/Osd.qml` (3 gradient hex)

```diff
- GradientStop { position: 0.0; color: "#00ffffff" }
- GradientStop { position: 0.5; color: "#55ffe6d6" }
- GradientStop { position: 1.0; color: "#00ffffff" }
+ GradientStop { position: 0.0; color: "transparent" }
+ GradientStop { position: 0.5; color: Qt.alpha(QsSingletons.Theme.onGlow, 0.33) }
+ GradientStop { position: 1.0; color: "transparent" }
```

### 3.4 Bar Popup Fallbacks

| File | Line | Current | Replacement |
|------|------|---------|-------------|
| `BrightnessPopupWindow.qml` | 20 | `?? "#f9e2af"` | `?? QsSingletons.Theme.onGlow` |
| `VolumePopupWindow.qml` | 25 | `?? "#a6e3a1"` | `?? QsSingletons.Theme.onGlow` |
| `BluetoothPopupWindow.qml` | 209 | `#ffffff` | `QsSingletons.Theme.bright` |
| `NetworkPopupWindow.qml` | 209, 603 | `#ffffff` | `QsSingletons.Theme.bright` |

### 3.5 `config/Appearance.qml`

```diff
- colSuccess: "#a6e3a1"
+ colSuccess: QsSingletons.Theme.verm
```

### 3.6 `modules/pill/Pill.qml` (2 literals in "good" surface)

- **L531** `"rgba(255,246,240,0.6)"` → `Qt.alpha(QsSingletons.Theme.bright, 0.6)` (Canvas context).
- **L570** `Qt.rgba(1, 1, 1, 0.04)` → mood-aware: `Qt.rgba(1, 1, 1, Flags.systemMood === "light" ? 0.02 : 0.04)`.

### 3.7 Add Missing Tokens (optional but recommended)

Add to `Theme.qml` + `Dyn.qml` + `wallcolors.py`:

| Token | Theme Definition | Dyn Source | Surfaces |
|-------|-----------------|------------|----------|
| `Theme.success` | `dyn ? Dyn.success : "#5ac85a"` | `Dyn.success` | Battery charging, Updates ready |
| `Theme.error` | `dyn ? Dyn.error : "#ef4444"` | `Dyn.error` | Low battery, Power menu destructive |
| `Theme.onSurface` | `dyn ? Dyn.bright : "#fff6f0"` | `Dyn.bright` | Primary text alias |

### Phase 3 Acceptance Criteria

```bash
# Zero hardcoded hex in these surfaces
grep -rnE "#[0-9a-fA-F]{6}" modules/osd/ modules/bar/components/Battery.qml   modules/bar/components/*PopupWindow.qml modules/pill/Pill.qml
# expect no matches (except config/BarConfig.qml which is intentional)
```

---

## Phase 4 — Port Selective iNiR Services

**Goal:** Bring in iNiR backend services that YEMI-SHELL lacks. **Do NOT port panels** (bar, dock, overview, etc.) — those are UI shells that conflict with YEMI-SHELL's pill architecture.

### 4.1 `GameMode.qml`

**Value:** Auto-detects fullscreen games → disables animations/blur.

**Integration:**
- Reads `Config.options.gameMode`.
- On enter: sets `Flags.reduceMotion = true`, `Flags.pillBlur = false`.
- On exit: restores previous values.
- Hooks into existing YEMI-SHELL effects (no new UI needed).

### 4.2 `Idle.qml`

**Value:** Screen off / lock / suspend timeouts.

**Integration:**
- Reads `Config.options.idle`.
- Triggers YEMI-SHELL's existing lock screen (or port `Lock.qml` later if you want iNiR's lock UI).
- Uses `SystemService.exec()` for `loginctl lock-session` or `systemctl suspend`.

### 4.3 `ShellUpdates.qml`

**Value:** Checks for shell updates on a timer.

**Integration:**
- Reads `Config.options.shellUpdates`.
- Toasts via YEMI-SHELL's existing `Toast.qml`.
- No new UI needed.

### 4.4 `Notifications.qml` (service backend)

**Value:** Rich notification backend with history, grouping, do-not-disturb.

**Integration:**
- Only port if YEMI-SHELL's current notification handling is thin.
- Keep YEMI-SHELL's popup UI (`modules/pill/Toast.qml`, etc.).
- Swap the backend service that feeds them.

### 4.5 `MemoryPressureService.qml`

**Value:** Low-RAM detection.

**Integration:**
- Can trigger `GameMode`-like suppression (disable blur, reduce animations).
- Reads `Config.options.resources`.

### Skip For Now

| Service | Reason |
|---------|--------|
| `CavaTheme` | Audio visualizer theming — cool but not foundational. |
| `Booru` / `YtMusic` / `RedditService` | Content widgets — add later as sidebar modules. |
| `NiriService` | Only if you switch compositor to Niri. |
| `waffle` panel family | Full UI rewrite — only if you abandon the pill architecture. |
| `iiBar`, `iiDock`, `iiOverview` | Same — these are alternative UI shells. |

### Phase 4 Acceptance Criteria

- `GameMode` triggers when a fullscreen app launches (test with a game or `mpv --fs`).
- `Idle` locks screen after configured timeout.
- No regressions in existing YEMI-SHELL UI.

---

## Phase 5 — Dark/Light & Opacity Polish

**Goal:** Make `systemMood` authoritative across both YEMI-SHELL and iNiR services.

### 5.1 Authoritative Mood in `after-wall.sh`

`after-wall.sh` must pass `--mood $systemMood` to `wallcolors.py` so static mode still flips surface lightness:

```bash
MOOD="${1:-$(jq -r '.systemMood // "dark"' "$FLAGS_FILE")}"
```

### 5.2 Wire `Theme.shadowOpacity`

`Theme.qml` L36 hardcodes `Qt.rgba(0,0,0,0.55)` but `shadowOpacity` exists at L67.

```diff
- readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)
+ readonly property color shadow: Qt.rgba(0, 0, 0, shadowOpacity)
```

### 5.3 Add Surface Opacity/Blur Flags

Add to `Flags.qml`:

```qml
readonly property real surfaceOpacity: 0.45
readonly property bool surfaceBlur: false
```

Bind OSD body and bar popups to these instead of hardcoded `0.4`:

```qml
// VolumeOSD.qml
Qt.alpha(QsSingletons.Theme.tileBg, QsSingletons.Flags.surfaceOpacity)
```

### 5.4 iNiR `ThemeService` ↔ YEMI-SHELL `Flags` Sync

`ThemeService.currentScheme` (light/dark) mirrors `Flags.systemMood` bidirectionally:

```qml
// When user toggles mood in Appearance.qml
Flags.systemMood = newMood
Config.setNestedValue("appearance.systemMood", newMood)
ThemeService.refresh()  // triggers after-wall.sh
```

### Phase 5 Acceptance Criteria

- Toggle light mode → pill surfaces lighten, OSD surfaces lighten.
- `Theme.shadow` alpha equals `Theme.shadowOpacity`.
- OSD body opacity equals `Flags.surfaceOpacity`.

---

## Phase 6 — Consolidation (Future)

These are **optional** post-stabilization tasks. Do not attempt until Phases 0–5 are solid.

### 6.1 Merge `Flags.qml` into `Config.qml`

Deprecate `flags.json` in favor of `Config`'s persistent mirror. All consumers migrate from `Flags.paletteMode` to `Config.options.appearance.paletteMode`.

### 6.2 Merge the Two `wallcolors.py` Scripts

Delete `~/.config/hypr/scripts/wallcolors.py`. Move its unique responsibilities (if any — e.g., `hypr-colors.lua` generation) into the single quickshell `scripts/wallcolors.py`.

### 6.3 Evaluate Panel Family Adoption

Decide if YEMI-SHELL wants iNiR's `ii` or `waffle` panel architecture:
- **Keep pill:** No action. YEMI-SHELL's pill + bar is the identity.
- **Adopt `ii`:** Major refactor. Replace `modules/pill/` and `modules/bar/` with `modules/ii/overlay/`, `modules/ii/bar/`, etc.
- **Adopt `waffle`:** Same, but Fluent-style.

**Recommendation:** Keep the pill. Port services, not panels.

---

## Decision Log

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | **Keep YEMI-SHELL token names** (`cream`, `verm`, `flameGlow`) | 52+ references in the pill. Renaming to `m3primary` etc. would be a massive, error-prone refactor with zero functional gain. |
| 2 | **Single writer rule** | `after-wall.sh` → `wallcolors.py` is the only thing that touches `colors.json`. iNiR services consume; they do not generate. |
| 3 | **Config as parallel layer** | iNiR `Config.qml` sits alongside existing `Flags.qml` initially. Gradual migration beats big-bang replacement. |
| 4 | **Port services, not panels** | Bring in iNiR's backend services (Theme, Wallpaper, GameMode, Idle). Do NOT bring in `iiBar`, `waffle`, `Overview`, etc. unless rebuilding the UI shell. |
| 5 | **Skip `MaterialThemeLoader`** | YEMI-SHELL's custom HSL ramp in `wallcolors.py` is intentional. True Material 3 scheme adaptation is a future opt-in, not a requirement. |
| 6 | **snake_case schema is the contract** | `Dyn.qml` reads snake_case. All writers must emit snake_case. iNiR services that expect camelCase must map at consumption time. |
| 7 | **Phase 0 is blocking** | No iNiR service gets ported until the color pipeline is a single source of truth. A broken pipeline means all dynamic theming in ported services is meaningless. |

---

## Verification Matrix

| After Phase | Test | Expected Result |
|-------------|------|-----------------|
| 0 | `grep -c wallcolors.py ~/.config/hypr/scripts/wallpaper.sh` | `0` |
| 0 | `jq 'has("primary_container")' ~/.cache/yemi-shell/colors.json` | `true` |
| 0 | `jq 'has("accent")' ~/.cache/yemi-shell/colors.json` | `false` |
| 0 | Toggle palette/mood in Appearance | Colors update, schema stays snake_case |
| 1 | `Config.setNestedValue("appearance.test", "value")` | Writes to `~/.config/illogical-impulse/config.json` |
| 1 | `Config.options.appearance.paletteMode` | Matches `Flags.paletteMode` at startup |
| 2 | Wallpaper picker → apply | `WallpaperListener` triggers, colors update |
| 2 | Auto-wallpaper cycle | Colors update automatically |
| 3 | `grep -rnE "#[0-9a-fA-F]{6}" modules/osd/` | `0` matches |
| 3 | `grep -rnE "#[0-9a-fA-F]{6}" modules/bar/components/Battery.qml` | `0` matches |
| 3 | `qmlscene` / `quickshell --dry-run` | No `required property var matugen` binding errors |
| 4 | Launch fullscreen game | `GameMode` activates, blur/animations suppressed |
| 4 | Wait for idle timeout | Screen locks / suspends per `Idle` config |
| 5 | Toggle `systemMood` to `light` | Pill + OSD surfaces lighten |
| 5 | `Theme.shadow` alpha | Equals `Theme.shadowOpacity` |
| 5 | OSD body alpha | Equals `Flags.surfaceOpacity` |

---

## Quick Reference: File Mapping

| iNiR File | YEMI-SHELL Target | Phase | Notes |
|-----------|-------------------|-------|-------|
| `modules/common/Config.qml` | `services/Config.qml` | 1 | Seed from `flags.json` |
| `defaults/config.json` | `defaults/config.json` | 1 | Strip inactive sections |
| `services/ThemeService.qml` | `services/ThemeService.qml` | 2 | Does not generate colors.json |
| `services/WallpaperListener.qml` | `services/WallpaperListener.qml` | 2 | Delegates to `after-wall.sh` |
| `services/Wallpapers.qml` | `services/Wallpapers.qml` | 2 | Multi-monitor state |
| `services/GameMode.qml` | `services/GameMode.qml` | 4 | Hooks into Flags |
| `services/Idle.qml` | `services/Idle.qml` | 4 | Triggers lock/suspend |
| `services/ShellUpdates.qml` | `services/ShellUpdates.qml` | 4 | Toasts via existing UI |
| `services/MemoryPressureService.qml` | `services/MemoryPressureService.qml` | 4 | Optional |
| `services/Notifications.qml` | `services/Notifications.qml` | 4 | Backend only, keep YEMI UI |
| `modules/ii/bar/Bar.qml` | — | Skip | UI shell conflict |
| `modules/waffle/bar/WaffleBar.qml` | — | Skip | UI shell conflict |
| `services/MaterialThemeLoader.qml` | — | Skip | Optional future opt-in |

---

*Plan generated 2026-08-05. Phases 0–1 are blocking for all subsequent work.*
