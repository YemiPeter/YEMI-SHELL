# Wallpaper & Theme Rearchitecture — Implementation Plan

Status: **planning checkpoint**. No rearchitect code has been written yet.
Established: 2026-08-28, after 7 diagnostic passes + 2 follow-up reviews.

## How to use this plan (gating rule)

Each phase below is a **GATE**. Do **not** start phase N+1 until phase N is
**complete AND its gate criteria pass** on the targeted compositor(s).
"Working" means verified by observation (reload + behavior/visual check), not
by reading code alone. If a gate fails, stay in that phase and fix it; do not
advance.

The checkpoint commit that accompanies this file is the restore point to fall
back to between phases.

---

## 1. Confirmed baseline (from the 7 diagnostic reports)

- **Two wallpaper daemons can run on Hyprland with no arbitration**: `awww`
  (via `hypr/scripts/wallpaper.sh`) and `skwd-daemon` (systemd-active, triggered
  by Mod+Shift+W and `shell.qml`'s random-wallpaper IPC). Niri has **zero**
  wallpaper-daemon wiring in its config; it works only because `skwd` is
  compositor-agnostic + a `RICE_HOME` env leak.
- **`compositor/Compositor.qml` exists** (env-var detection) but is **not used**
  anywhere in the wallpaper/theme path — every branch is hardcoded to
  `hypr/scripts/*.sh`.
- **Color pipeline works**: `after-wall.sh` (single writer) →
  `dominance-engine.py` → `colors.json` → `Dyn.qml` → `Appearance.qml` →
  `Theme.qml`.
- **Crossfade bug (proven)**: `wallpaper.sh:85,91` passes `transitionDuration`
  (default `800`) straight to `awww img --transition-duration`, but `awww`
  documents that flag as **seconds** (`awww img --help`). The settings UI
  (`Background.qml:688,693,695`) labels it `"ms"` and ranges 200–3000. A
  milliseconds-valued number fed to a seconds parameter ⇒ a minutes-long fade.
  `AwwwBackend.qml:42` corroborates the correct unit (`0.8` seconds).
- **`after-wall.sh:110` is broken**: `python3 after-wall.sh ...` on a bash
  script ⇒ permanent `SyntaxError`; the init/random path never re-themes.
  Only the QML picker path (`Walls.apply` → `afterWallProc`) re-themes.
- **`Variants` bug (Report 1)**: `shell.qml:272` `Variants { delegate: ... }`
  has two delegates (Wallpaper then Backdrop) fighting one non-list slot, so
  only `Backdrop.qml` instantiates; `Wallpaper.qml` never renders.
- **Two QML background layers** exist: `Wallpaper.qml` (`quickshell:yWallpaper`,
  dead) and `Backdrop.qml` (`quickshell:yBackdrop`, active). Both at
  `WlrLayer.Background`. Backdrop is the live themed overlay.
- **`backdropThemeColors` IS honored** by `after-wall.sh:47-62,81` (swaps
  extraction source to `backdropWallpaperPath`). Report 1's "read-but-ignored"
  suspicion is refuted.
- **`backdropHideWallpaper` is currently inert** — its only consumer is the dead
  `Wallpaper.qml:28`.
- **Dead services**: `AwwwBackend.qml`, `Wallpapers.qml`, `WallpaperListener.qml`
  (0 consumers; depend on nonexistent `Config.options`/`setNestedValue`). These
  were an unfinished compositor-agnostic bridge.
- **skwd dual color writer (verified this session)**: `skwd-wall/config.json`
  has `"colorSource":"magick"` and `integrations[].output:"colors.json"` — a
  second color-generation pipeline competing with `after-wall.sh`'s dominance
  writer.

---

## 2. Locked decisions

1. **Compositor model**
   - **Niri = QML *is* the wallpaper.** No `awww`/`skwd` daemon needed; the
     single QML background component renders the image from the state file and
     applies all effects. Robust, one fewer failure mode.
   - **Hyprland = `awww` *is* the wallpaper; QML overlays only.** Default QML
     overlay = **dim + vignette only**. Blur/saturation/contrast/parallax are
     disabled in the UI unless a "double-paint" opt-in forces the image visible.

2. **Collapse to ONE background component.** Delete `Wallpaper.qml`; keep
   `Backdrop.qml` as the single layer. Kills the `Variants` bug at the root
   (no second delegate to contend) and removes the double-paint.

3. **Auto-restore lives in the compositor startup hook**, never in Pill. The
   dispatcher is what `config.d/50-startup.kdl` (Niri) / `autostart.lua`
   (Hyprland) invoke directly, so a fresh login paints without opening the UI.

4. **skwd: provisionally drop**, sequenced **after** the dispatcher is proven
   working on Niri **alone** (so we're never left with nothing painting). Verified
   dual color-writer is the strongest argument for removal.

5. **Hard technical constraint — QML effects cannot touch `awww`'s pixels.**
   `Backdrop.qml:85-95` `MultiEffect { source: wallContainer }` operates on the
   QML `Image`'s own texture, not the compositor layer beneath. Therefore on
   Hyprland, where `awww` paints and the QML `Image` isn't shown, **blur /
   saturation / contrast / parallax do nothing** (only additive darkening —
   dim + vignette — survives). This is why those toggles must be disabled in the
   UI on Hyprland unless double-paint is opted in.

---

## 3. Phase 1 — Crossfade unit fix (isolated quick win)

**Goal:** make wallpaper transitions complete in <1s and make re-theming fire on
every path.

**Changes:**
- New `scripts/set-wallpaper.sh` (or patch `wallpaper.sh`) converts
  `transitionDuration` ms → seconds (`/1000`) before `--transition-duration`, so
  the UI can honestly keep saying "ms".
- Fix `wallpaper.sh:110`: `python3 after-wall.sh …` → `bash after-wall.sh "<mood>" "<path>"`.
- Fix skwd `transitionType:"random"` (`skwd-wall/config.json:114`) → a valid
  awww type (`fade`) or remove it (skwd is dropped later anyway).

**Gate (exit criteria):** setting a wallpaper via (a) the Pill picker and
(b) Mod+Shift+W produces a sub-second crossfade on Hyprland; re-theming
(`colors.json` regenerated) occurs on both paths. No `SyntaxError` in logs.

**Rollback:** `git checkout` the script + skwd config.

---

## 4. Phase 2 — Collapse to one background component

**Goal:** a single, correctly-rendering background layer; no `Variants` slot
contention; no stacked duplicate background.

**Changes:**
- Delete `modules/background/Wallpaper.qml`.
- Make `Backdrop.qml` the single component. Fix `shell.qml:272` so the one
  delegate renders reliably (replace the two-delegate `Variants` with a single
  `Repeater`/delegate or a `Component` used once).
- Bind `Image.visible` to a compositor-aware condition:
  `Compositor.isNiri || (backdropUseMainWallpaper && !backdropHideWallpaper)`.
- Re-home `backdropHideWallpaper` semantics onto the single layer (define what
  "hide" means now that there's one layer).

**Gate:** on **both** compositors the wallpaper is visible; exactly one
`WlrLayer.Background` QML layer exists for the background; effects apply; no
z-order flicker.

**Rollback:** restore `Wallpaper.qml` + revert `shell.qml`.

---

## 5. Phase 3 — Compositor-aware dispatcher + wiring

**Goal:** one script does all wallpaper-setting, branching internally by
compositor passed in from QML (never re-detected in bash).

**Changes:**
- Create `scripts/set-wallpaper.sh` taking an explicit compositor arg:
  - always writes the state file `~/.local/state/quickshell-wallpaper`;
  - always calls `after-wall.sh` correctly (`bash`);
  - calls `awww img` **only on Hyprland** (Niri QML renders);
  - gates `hyprctl reload` to Hyprland (fails on Niri today).
- Wire `compositor/Compositor.qml` into `Walls.qml` (replace hardcoded
  `$RICE_HOME/hypr/scripts/wallpaper.sh` with a `Compositor`-resolved path +
  real `RICE_HOME` fallback).
- Pass `Compositor.runningCompositor` into the dispatcher call from the QML
  background layer and picker.

**Gate:** dispatcher works on both compositors; no hardcoded `hypr` path remains
in the wallpaper path; transition fast; theming regenerates; `RICE_HOME` unset
still resolves.

**Rollback:** revert `Walls.qml` + remove dispatcher (Pill falls back to old
path, which still works post-Phase 1).

---

## 6. Phase 4 — Flag-driven Backdrop with compositor defaults + UI enforcement

**Goal:** "which few things Hyprland needs" is decided by toggles after seeing it
run, not hardcoded — but the UI must not expose lying toggles.

**Changes:**
- Backdrop feature defaults sourced from `Compositor.runningCompositor`:
  - Niri: parallax/blur/vignette/on by default (QML owns pixels ⇒ all work).
  - Hyprland: dim + theming on; blur/saturation/contrast/parallax **off + disabled
    in `Background.qml`** unless a `backdropDoublePaint` opt-in is set (which
    forces `Image.visible` true so the effects have something to act on).
- `backdropThemeColors` stays default-on both (it's data, not visuals — cheap,
  compositor-independent).
- Every flag remains user-editable in `Background.qml`.

**Gate:** Niri shows full effects; Hyprland shows only dim+vignette by default;
flipping blur on Hyprland either force-enables the image (double-paint) or the
toggle is disabled — never a silent no-op.

**Rollback:** revert `Background.qml` + `Backdrop.qml` defaults.

---

## 7. Phase 5 — Niri startup wiring

**Goal:** a fresh Niri login paints the wallpaper via the dispatcher with no Pill
dependency.

**Changes:**
- Add `config.d/50-startup.kdl` `spawn-at-startup` invoking `set-wallpaper.sh`
  (init / last-wallpaper).
- **Verify `config.kdl` actually `source`s the `config.d` dir** — Report 1 found
  orphaned Niri configs (`config.kdl.d`, `70-binds.kdl.d12d`) that weren't
  included; an un-included startup hook would silently do nothing.

**Gate:** from a clean Niri login (no Pill opened), the wallpaper appears and
themes correctly.

**Rollback:** remove the `config.d` entry.

---

## 8. Phase 6 — Drop skwd (only after Phase 3 + 5 proven)

**Goal:** remove the extra daemon and the dual color-writer now that the
dispatcher fully replaces it.

**Changes:**
- Disable/remove `skwd-daemon.service` and `skwd-wall/config.json`.
- Confirm auto-restore is covered by the compositor startup hook (Phase 5), not
  by skwd.
- Delete the dead services `AwwwBackend.qml` / `Wallpapers.qml` /
  `WallpaperListener.qml` (the unfinished bridge is now the script).

**Gate:** Niri **and** Hyprland paint correctly with skwd gone; no second
`colors.json` writer; auto-restore-on-login still works; no dual `awww`
invocation.

**Rollback:** re-enable `skwd-daemon.service`.

---

## 9. Verification matrix (fill per phase)

| Phase | Niri | Hyprland | Re-theme fires | Crossfade <1s | Notes |
|-------|------|----------|----------------|---------------|-------|
| 1 | n/a  | □        | □              | □             | |
| 2 | □    | □        | —              | —             | |
| 3 | □    | □        | □              | □             | |
| 4 | □    | □        | □              | —             | |
| 5 | □    | n/a      | □              | —             | |
| 6 | □    | □        | □              | □             | |

## 10. Open questions — resolved
- skwd `colorSource:"magick"` + `integrations` `colors.json` writer → **verified
  this session** via `jq '.colorSource, .integrations'`. Confirms dual color
  writer; supports dropping skwd at Phase 6.
- "Which few effects Hyprland needs" → answered by design: dim+vignette default,
  rest opt-in (Phase 4), because QML effects can't touch `awww` pixels.
