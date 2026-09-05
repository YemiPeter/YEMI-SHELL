# Audit 02 — Code Review
*Refreshed 2026-09-05 on branch `pill-perf`.*

## Resolved since last audit ✅
- ~~`Updates.qml` missing `import Quickshell`~~ (B4) — fixed `e15503c`.
- ~~`Background.qml` / `modules/common/widgets/WallpaperCrossfader.qml` broken relative import paths~~ (B3/B5) — fixed `e15503c`.
- ~~`Background.qml` `parent.parent.radius` fragile chain~~ — fixed `e15503c`.
- ~~`Network.qml` used-before-declared handler vars~~ — hoisted, `b84983d`.
- ~~`MusicPanel.qml` deprecated Connections syntax~~ — `b84983d`.
- ~~`PillOverlay.qml` reserve window `height` → `implicitHeight`~~ (B6) — `b84983d`.
- ~~Glass `saturationEnabled`~~ — property doesn't exist in this Qt build; saturation auto-enables. Correct final form shipped in `b84983d`.

## Resolved since last audit ✅
- ~~**C1 — Load-transient `Calendar[656]` warnings**~~ — `Dyn.primary` was undefined until matugen's `colors.json` landed at startup. Fixed by the `schemeValid` guards added to `config/Appearance.qml` (every `Dyn.*` token now falls back to `activeMoot.<x>` while the scheme is invalid). Zero burst at boot now.

## Open findings

### C2 — `qmllint` unqualified-member-access infos (info-level)
`qmllint` reports many `unqualified` member accesses across the pill modules (e.g. ids referenced from nested delegates). They run fine, but each one is a lookup that walks the scope chain and a future name-collision hazard. Worth a gradual cleanup when touching a file anyway; not a dedicated pass.

### C3 — `Glass` is tint-only (alignment assumption moot)
~~Glass aligns to the wallpaper via `screenPos` math…~~ Glass was stripped to tint-only in `5d64483` (D1 double-blur fix) — the `screenPos` wallpaper-sampling machinery was removed entirely because its source Image sampled a permanently-empty `WallpaperState.current`. Hyprland's native layerrule blur is now the sole frost source. This finding is closed by the architectural change; if a future surface reintroduces wallpaper-sampling, the top-anchor/no-margin assumption will need re-documenting at that call site.

### C4 — Duplicated pill-cluster markup in `Bar.qml` (maintainability)
The four side-pill clusters repeat the same Glass + highlight + border block four times with only content differing. A `BarPill.qml` component would collapse ~120 lines into one definition and make the next theme-wide change a single edit. Low priority, good hygiene.

### C5 — Niri-API reachability on Hyprland (folded from old root `AUDIT.md` §1.3)
Most files go through `Compositor.impl` (safe), but the old audit never completed the per-file confirmation that no direct niri call is reachable when the backend is Hyprland. You now run Hyprland daily, so any miss would be live. The config-writer part is done (Input/Keybinds carry guards); this is only about direct `Niri.*` API references in the §1.3 file list.