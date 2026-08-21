# Monitor Visibility — Brain / Face Unification Plan

## Goal
Unify the Monitors (shell-surface visibility) section across the Waffle and Pill
families from a single source of logic, while each family keeps its own native UI.
No logic duplication; cross-family sync is automatic because both faces bind to
the same shared `Config` singleton.

## Architecture
- **Brain** (`modules/common/settings/MonitorVisibilityCore.qml`): pure `QtObject`,
  zero UI. Owns all logic + the shared surface list. Talks only to `Config` and
  `Quickshell.screens`.
- **Waffle Face** (`modules/waffle/settings/pages/WMonitorVisibilityPage.qml`):
  imports the Brain, renders with `WButton` / `WSettingsCard` / `Looks` (Win11).
  Keeps its 3 cards (Shell visibility, Waffle surfaces, Shared popups).
- **Pill Face** (`modules/pill/Monitors.qml`): imports the SAME Brain, renders
  with Pill's native `PillSurface` / `SettingsSurface` / `Theme` / `GlyphIcon` /
  `SettingsRow` (morphing pill). Only 2 cards (Pill has no `screenList`).

## Why sync needs no code
Both faces bind to the same `Config.options.*` paths
(`notifications.screenList`, `osd.screenList`, `background.widgets.screenList`,
`waffles.bar.screenList`, `display.primaryMonitor`). One Quickshell session → one
`Config` singleton → QML reactive bindings update the other face automatically.

## Files
| File | Action |
|------|--------|
| `modules/common/settings/MonitorVisibilityCore.qml` | NEW (Brain) |
| `modules/common/settings/qmldir` | NEW (module export) |
| `modules/waffle/settings/pages/WMonitorVisibilityPage.qml` | EDIT (strip logic, repoint to Brain) |
| `modules/pill/Monitors.qml` | NEW (Pill face) — LAST |
| `modules/pill/Settings.qml` | EDIT (add "Monitors" row) — LAST |

## Build order
### Phase 0 — Clean slate (PRE-CODING, done)
Committed pending quickshell work (`3087cc8`) as the baseline. Unrelated
`ghostty`/`hypr`/`kitty`/`niri` diffs left unstaged per commit-hygiene rule.
`.bak` of the Waffle page taken before editing.

### Phase 1 — Brain
Create `MonitorVisibilityCore.qml`. Lift the 13 functions verbatim from the
current Waffle page (connectedScreenNames, primaryScreenName, monitorOptions,
monitorResolution, configuredScreens, allScreensEnabled, surfaceEnabled,
visibilitySummary, setSurfaceAll, setSurfaceScreen [incl. `[]` sentinel &
disable-last guard], setPathsToPrimary, setPathsToAll, surfacePaths). Move
`sharedSurfaces` here. No UI imports. Export via `modules/common/settings/qmldir`.

### Phase 2 — Waffle face (surgical, UI unchanged)
Instantiate `MonitorVisibilityCore { id: core }`. Delete the 13 inline functions
+ `sharedSurfaces`. Repoint every `root.<logic>(...)` call to `core.<logic>(...)`.
Keep `waffleSurfaces` (taskbar → `waffles.bar.screenList`) local. Component tree
+ `Looks.*` styling untouched → pixel-identical UI.

### Phase 3 — Verify Waffle
`QT_QPA_PLATFORM=offscreen qs -p waffleSettings.qml` (catches binding/parse
errors). Visual diff vs `WMonitorVisibilityPage.qml.bak` in the Hyprland session.

### Phase 4 — PILL UI DESIGN STUDY  ⛔ REQUIRES EXPLICIT USER PERMISSION
STOP and obtain user go-ahead BEFORE any Pill code. Study Pill's design system
first: `PillSurface`/`SettingsSurface` morphing, `Theme` tokens, `GlyphIcon`,
`SettingsRow`/`SettingsSeg`, row-seam animations, spacing scale `s`. Confirm Pill
has no `screenList` (no family card) and decide whether Pill needs any surface
filtering at all.

### Phase 5 — Pill face (only after Phase 4 permission)
Build `modules/pill/Monitors.qml` as a native morphing `SettingsSurface`, 2 cards
only (Shell visibility + Shared popups/widgets), using the same Brain.

### Phase 6 — Wire + verify sync
Add "Monitors" row to Pill `Settings.qml` → the surface. Live-test: toggle a
surface in Pill, confirm Waffle reflects it (same session).

## Safety / rollback
- `.bak` copy before each edit; git baseline before coding.
- Waffle change is extract-only (same I/O) → low risk; verified in Phase 3.

## Open questions
- Pill `screenList` path: none exists today → Pill face has no family card.
- Does Pill want per-monitor filtering of its own surfaces, or only the shared
  ones? (Decide in Phase 4.)
