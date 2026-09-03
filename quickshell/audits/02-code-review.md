# Audit 02 — Code Review
*Refreshed 2026-09-04 on branch `pill-perf`.*

## Resolved since last audit ✅
- ~~`Updates.qml` missing `import Quickshell`~~ (B4) — fixed `e15503c`.
- ~~`Background.qml` / `WallpaperCrossfader.qml` broken relative import paths~~ (B3/B5) — fixed `e15503c`.
- ~~`Background.qml` `parent.parent.radius` fragile chain~~ — fixed `e15503c`.
- ~~`Network.qml` used-before-declared handler vars~~ — hoisted, `b84983d`.
- ~~`MusicPanel.qml` deprecated Connections syntax~~ — `b84983d`.
- ~~`PillOverlay.qml` reserve window `height` → `implicitHeight`~~ (B6) — `b84983d`.
- ~~Glass `saturationEnabled`~~ — property doesn't exist in this Qt build; saturation auto-enables. Correct final form shipped in `b84983d`.

## Open findings

### C1 — Load-transient `Calendar[656]` warnings (low)
`Dyn.primary` is undefined until matugen's `colors.json` lands at startup; Calendar binds against it eagerly. Fix: startup fallback palette in `config/Appearance.qml`. Cosmetic — one burst at boot, then silent.

### C2 — `qmllint` unqualified-member-access infos (info-level)
`qmllint` reports many `unqualified` member accesses across the pill modules (e.g. ids referenced from nested delegates). They run fine, but each one is a lookup that walks the scope chain and a future name-collision hazard. Worth a gradual cleanup when touching a file anyway; not a dedicated pass.

### C3 — `Glass.screenPos` alignment assumption (documented, keep in mind)
Glass aligns to the wallpaper via `screenPos` math that assumes the window is top-anchored at the screen origin with no margins. True for the bar and pill overlay today. If a future surface uses margins/offsets, its Glass frost will sample the wrong wallpaper region silently. Consider an assertion or a comment at the next Glass call site.

### C4 — Duplicated pill-cluster markup in `Bar.qml` (maintainability)
The four side-pill clusters repeat the same Glass + highlight + border block four times with only content differing. A `BarPill.qml` component would collapse ~120 lines into one definition and make the next theme-wide change a single edit. Low priority, good hygiene.