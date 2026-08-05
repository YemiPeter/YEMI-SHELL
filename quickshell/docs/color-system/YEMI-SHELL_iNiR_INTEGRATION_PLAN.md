# YEMI-SHELL + iNiR Integration Plan

> **Priority rule:** No iNiR service gets ported until the color pipeline is a single source of truth. Phases 0–1 are **blocking** for everything else.

---

## Phase 0 — Unify the Color Pipeline (YEMI-SHELL fix, 1–2 days)

**Goal:** One writer, one schema, no dead code.

| Step | File | Action |
|------|------|--------|
| 0.1 | `scripts/after-wall.sh` | Make it mode/mood-aware (the single entry point). It becomes the **only** script that calls `wallcolors.py` and writes `colors.json` + `terminal.json` + `hypr-colors.lua`. |
| 0.2 | `modules/pill/Appearance.qml` | Stop calling `~/.config/hypr/scripts/wallcolors.py`. Route palette/mood toggles through `after-wall.sh`. |
| 0.3 | `~/.config/hypr/scripts/wallpaper.sh` | Remove its `wallcolors.py` invocation. It only sets the wallpaper + state file, then exits. |
| 0.4 | `services/Matugen.qml` | Delete `applyWallpaper()` and `colorsPath`. Reduce to a `reload()` shim that calls `Dyn.file.reload()`. Remove from `qmldir` if unused. |
| 0.5 | `shell.qml` | Fix IPC `colors reload` → call `Dyn.file.reload()` instead of the no-op `matugen.reload()`. |

**Acceptance:** `grep -c wallcolors.py ~/.config/hypr/scripts/wallpaper.sh` = 0. `jq 'has("primary_container")' ~/.cache/yemi-shell/colors.json` = true after any toggle.

---

## Phase 1 — Port iNiR Config Infrastructure (foundation for all services)

**Goal:** Bring in iNiR's runtime config system so future services have something to consume.

**Why now:** iNiR services expect `Config.options?.<section>` and `Config.setNestedValue()`. Without this, every ported service needs hacky shims.

| Step | Action |
|------|--------|
| 1.1 | Port `iNiR/modules/common/Config.qml` → `services/Config.qml` (or `singletons/Config.qml`). Keep its `setNestedValue()`, `_writeMirrorToDisk()`, and JsonAdapter mirror. |
| 1.2 | **Adapter layer:** On init, read YEMI-SHELL's existing `~/.local/state/quickshell/flags.json` and seed `Config.options.appearance` with `paletteMode`, `systemMood`, `pillOpacity`, `pillBlur`, etc. This gives iNiR services a config surface without breaking existing `Flags.qml`. |
| 1.3 | Register in `qmldir`. Existing YEMI-SHELL code keeps using `Flags.qml` directly; new iNiR services use `Config.options.appearance.paletteMode`. |
| 1.4 | Port `iNiR/defaults/config.json` → `defaults/config.json` in YEMI-SHELL repo. Strip sections you don't need yet (e.g., `waffles`, `dock`, `gameMode` can stay but be inactive). |

**Design decision:** `Config.qml` and `Flags.qml` coexist temporarily. A sync function mirrors `Flags` ↔ `Config.options.appearance` bidirectionally. Later phases can consolidate.

---

## Phase 2 — Port iNiR ThemeService + WallpaperListener (replace dead Matugen)

**Goal:** Replace the vestigial `Matugen.qml` with iNiR's actual theme/wallpaper services, but **adapt them to YEMI-SHELL's output schema**.

| Step | Action |
|------|--------|
| 2.1 | Port `services/ThemeService.qml` from iNiR. It consumes `Config.options.appearance` and manages theme state. |
| 2.2 | Port `services/WallpaperListener.qml` and `services/Wallpapers.qml`. These handle wallpaper change events, auto-wallpaper, and multi-monitor state. |
| 2.3 | **Adapter:** `ThemeService` does NOT generate its own `colors.json`. Instead, it triggers `after-wall.sh` (Phase 0's single writer) and then signals `Dyn.file.reload()`. It manages *when* colors change; `wallcolors.py` manages *how*. |
| 2.4 | Port `services/MaterialThemeLoader.qml` **only if** you want true Material 3 scheme adaptation later. Otherwise skip it for now — YEMI-SHELL's custom HSL ramp in `wallcolors.py` is a deliberate design choice. |
| 2.5 | Replace `modules/pill/Singletons/Walls.qml` logic: `Walls.apply()` now delegates to `WallpaperListener.setWallpaper()` → which updates state → triggers `after-wall.sh` → Dyn reloads. |

**Key constraint:** `Dyn.qml`'s snake_case `JsonAdapter` is the contract. iNiR services may expect Material 3 token names (`m3primary`, etc.) — map them in `Theme.qml` if needed, but **do not** change `colors.json` schema.

---

## Phase 3 — Complete Surface Tokenization (YEMI-SHELL cleanup)

**Goal:** Fix every surface that bypasses `Theme.*` now that the pipeline is trustworthy.

| Priority | Surface | Fix |
|----------|---------|-----|
| 3.1 | `modules/bar/components/Battery.qml` | 6 hex + 1 `Qt.rgba` → `Theme.verm`, `Theme.flameGlow`, `Theme.cream` |
| 3.2 | `modules/osd/VolumeOSD.qml` + `BrightnessOSD.qml` | Drop dead `matugen` property; bind all `Qt.rgba` to `Theme.*` tokens |
| 3.3 | `modules/pill/Osd.qml` | 3 gradient hex → `Theme.onGlow` with alpha |
| 3.4 | `modules/bar/components/*PopupWindow.qml` | `#ffffff` fallbacks → `Theme.bright` |
| 3.5 | `config/Appearance.qml` | `colSuccess: "#a6e3a1"` → `Theme.verm` (or new `Theme.success`) |
| 3.6 | `modules/pill/Pill.qml` | 2 hardcoded literals → mood-aware tokens |

Add new tokens to `Theme.qml` + `Dyn.qml` if needed:
- `Theme.success` / `Theme.error` (for battery states)
- `Theme.onSurface` (alias for `cream`/`bright`)

---

## Phase 4 — Port Selective iNiR Services (high-value, low-friction)

**Goal:** Bring in iNiR capabilities that YEMI-SHELL lacks, without touching the color system.

| Service | Value | Integration Notes |
|---------|-------|-------------------|
| `GameMode.qml` | Auto-detect games → disable animations/blur | Reads `Config.options.gameMode`. Hooks into `Flags.reduceMotion` / `Flags.pillBlur` to suppress YEMI-SHELL effects. |
| `Idle.qml` | Screen off / lock / suspend timeouts | Reads `Config.options.idle`. Triggers YEMI-SHELL's existing lock screen or a new iNiR `Lock` panel if ported later. |
| `ShellUpdates.qml` | Check for shell updates | Reads `Config.options.shellUpdates`. Can toast via YEMI-SHELL's existing `Toast.qml`. |
| `Notifications.qml` (service) | Rich notification backend | Only if YEMI-SHELL's current notification handling is thin. Keep YEMI-SHELL's popup UI, swap the backend. |
| `MemoryPressureService.qml` | Low-RAM detection | Can trigger `GameMode`-like suppression. |

**Skip for now (overkill):**
- `waffle` panel family — YEMI-SHELL's `pill` + `bar` architecture is different; this is a full UI rewrite.
- `CavaTheme`, `Booru`, `YtMusic` — cool but not foundational.
- `NiriService` — only if you switch to Niri.

---

## Phase 5 — Dark/Light & Opacity Polish (cross-cutting)

**Goal:** Make `systemMood` authoritative across both YEMI-SHELL and iNiR services.

| Step | Action |
|------|--------|
| 5.1 | `after-wall.sh` passes `--mood $systemMood` to `wallcolors.py` so static mode still flips surface lightness. |
| 5.2 | `Theme.shadow` uses `Theme.shadowOpacity` instead of hardcoded `0.55`. |
| 5.3 | Add `Flags.surfaceOpacity` / `Flags.surfaceBlur` for OSD/bar popups so they glass-match the pill. |
| 5.4 | iNiR `ThemeService` exposes `currentScheme` (light/dark) that YEMI-SHELL's `Flags.systemMood` mirrors. |

---

## Phase 6 — Consolidation (future, optional)

| Step | Action |
|------|--------|
| 6.1 | Merge `Flags.qml` into `Config.qml` fully. Deprecate `flags.json` in favor of `Config`'s mirror. |
| 6.2 | Merge the two `wallcolors.py` scripts (hypr + quickshell) into one that lives in the repo, deleting the hypr copy entirely. |
| 6.3 | Evaluate if YEMI-SHELL wants iNiR's `ii` panel family architecture (bar, dock, overview, etc.). This is a major refactor — only do it if you want to replace the pill-centric UI. |

---

## Decision Log (so we don't re-debate)

| Decision | Rationale |
|----------|-----------|
| **Keep YEMI-SHELL token names** (`cream`, `verm`, `flameGlow`) | The entire pill is built around them. iNiR's `m3primary` naming is more standard but would require rewriting 52+ `Theme.` references. |
| **Single writer rule** | `after-wall.sh` → `wallcolors.py` is the only thing that touches `colors.json`. iNiR services consume; they do not generate. |
| **Config as parallel layer** | iNiR `Config.qml` sits alongside existing `Flags.qml`/`config/*.qml` initially. Gradual migration beats big-bang replacement. |
| **Port services, not panels** | Bring in iNiR's *backend* services (Theme, Wallpaper, GameMode, Idle). Do NOT bring in `iiBar`, `waffle`, `Overview`, etc. unless you want to rebuild the UI shell. |

---

**Ready when you are.** I can start generating the actual code diffs for Phase 0 (the color pipeline fix) immediately, or we can drill into any specific phase first. What's your call?