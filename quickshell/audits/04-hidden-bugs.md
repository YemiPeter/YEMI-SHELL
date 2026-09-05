# Audit 04 — Hidden Bugs
*Refreshed 2026-09-05 on branch `pill-perf`. Verified against a live `qs log` capture.*

## Resolved since last audit ✅
- ~~B1: `Theme.flameGlow`/`flameCore` undefined → per-frame `Unable to assign [undefined] to QColor` storm (38 call sites)~~ — **the big one.** Fixed `a13b119`; live log confirms the storm is dead.
- ~~B3: `WallpaperCrossfader` importing nonexistent `modules/singletons` → entire `QsSingletons` namespace undefined there (QString/int/bool assignment spam)~~ — fixed `e15503c`.
- ~~B4: `Updates.qml` missing `import Quickshell`~~ — fixed `e15503c`.
- ~~B5: `Background.qml` broken `../../../config` import + `parent.parent.radius`~~ — fixed `e15503c`.
- ~~B6: `PillOverlay` reserve window deprecated `height`~~ — fixed `b84983d`.
- ~~B7: `StatusIndicators` `setPaused()` called on a non-running animation~~ — gated via `running:` instead, `b84983d`.
- ~~**H1 — Startup race: `Dyn.primary` undefined until matugen lands**~~ — `Calendar.qml` bound against dynamic colors that didn't exist for the first frames after launch. Fixed by the `schemeValid` guards in `config/Appearance.qml` (every `Dyn.*` token falls back to `activeMood.<x>` while the scheme is invalid). Zero burst at boot now.

## New bugs found and fixed this session ✅
Surfaced during D1–D4 and IPC work; not part of the original audit.
- **Power.qml phantom `kbFocus`/`pressed` error on every surface close** — `reset()` assigned to properties on a `Repeater` id (the properties live on delegates, one on an uninstantiated Component). Deleted, dead code, zero functional impact (`0d98472`).
- **Background.qml height self-clamp silently NaN** — `maxSurfaceH: settings.implicitHeight` referenced an id that only exists in `Pill.qml`'s scope; evaluated to `undefined` → NaN into `implicitHeight`. Fixed by passing `maxSurfaceH` in from `Pill.qml` where the id is in scope (`4bd2797`).
- **Two `IpcHandler`s both claiming `target: "pill"`** — one fully dead (`modules/pill/shell.qml`, deleted `6555425`); the live handler was missing 8 functions. 7 ported and verified — system/recorder/screenrec/record/quickRecord (`456b200`) + bluetooth/battery (`ec07661`). Live pill IPC target now exposes all 20 functions.
- **Wallpaper reverting to a stale pick on Niri reload** — frozen "awww memory" file diverged from the live state file. Fixed by making `restoreProc` read the live state file directly (`209625b`).
- **Backdrop blur-before-image-ready race** (solid color until blur radius manually touched) — fixed with a `hasLoadedOnce` latch on the crossfader's `Image.Ready` signal (`278b981`).
- **Toast width→height re-target loop** — wrapped body text rewrapped every morph frame, re-targeting `implicitHeight`. Fixed to measure against the settled width (`27dab71`).

## Open

### H2 — Environmental noise (not shell bugs, listed for completeness)
- Stale recorder thumbnail path warning (file deleted, path still referenced by the recorder module's state).
- `ddcutil` timeout — hardware DDC/CI probe on a machine whose monitor doesn't answer; the brightness service handles the failure, just noisy.

## Watchlist (patterns that caused past bugs)
- **Translucent decoration on blurred layer surfaces** — caused the halo; invariant now recorded in audit 01. If a glow/shadow/highlight is ever added to a `pill*`/`quickshell`-namespace surface, it must be alpha-1.0 dense or live on its own non-blurred surface.
- **Relative import paths (`../../..`)** — caused B3/B5. Prefer `qs.` module imports; two of the four broken imports this cycle were deep relative chains.
- **`parent.parent…` chains** — caused B5. Bind through an explicit `property` on the immediate parent instead.