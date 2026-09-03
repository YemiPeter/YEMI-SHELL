# Audit 04 — Hidden Bugs
*Refreshed 2026-09-04 on branch `pill-perf`. Verified against a live `qs log` capture.*

## Resolved since last audit ✅
- ~~B1: `Theme.flameGlow`/`flameCore` undefined → per-frame `Unable to assign [undefined] to QColor` storm (38 call sites)~~ — **the big one.** Fixed `a13b119`; live log confirms the storm is dead.
- ~~B3: `WallpaperCrossfader` importing nonexistent `modules/singletons` → entire `QsSingletons` namespace undefined there (QString/int/bool assignment spam)~~ — fixed `e15503c`.
- ~~B4: `Updates.qml` missing `import Quickshell`~~ — fixed `e15503c`.
- ~~B5: `Background.qml` broken `../../../config` import + `parent.parent.radius`~~ — fixed `e15503c`.
- ~~B6: `PillOverlay` reserve window deprecated `height`~~ — fixed `b84983d`.
- ~~B7: `StatusIndicators` `setPaused()` called on a non-running animation~~ — gated via `running:` instead, `b84983d`.

## Open

### H1 — Startup race: `Dyn.primary` undefined until matugen lands (low)
`Calendar.qml[656]` binds against dynamic colors that don't exist for the first frames after launch → one burst of `Unable to assign` at boot, then silent. Not user-visible beyond the log. Fix: fallback palette in `config/Appearance.qml` so `Dyn.*` is never undefined.

### H2 — Environmental noise (not shell bugs, listed for completeness)
- Stale recorder thumbnail path warning (file deleted, path still referenced by the recorder module's state).
- `ddcutil` timeout — hardware DDC/CI probe on a machine whose monitor doesn't answer; the brightness service handles the failure, just noisy.

## Watchlist (patterns that caused past bugs)
- **Translucent decoration on blurred layer surfaces** — caused the halo; invariant now recorded in audit 01. If a glow/shadow/highlight is ever added to a `pill*`/`quickshell`-namespace surface, it must be alpha-1.0 dense or live on its own non-blurred surface.
- **Relative import paths (`../../..`)** — caused B3/B5. Prefer `qs.` module imports; two of the four broken imports this cycle were deep relative chains.
- **`parent.parent…` chains** — caused B5. Bind through an explicit `property` on the immediate parent instead.