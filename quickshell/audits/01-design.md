# Audit 01 — Design (qt-ui-design + YemiWorkingRules pass)

Scope: architecture, module design, theming consistency — not pixel-level UI.

## Architecture — what's right
- `compositor/` facade (isNiri/isHyprland, `enabled:`-gated impls, normalized
  data) is the correct abstraction. Keep it as the only place that imports
  `Quickshell.Hyprland` / niri APIs.
- White-fill asset pattern (`assets/icons/fluent-white/`) over shader
  colorization — deterministic, theme-safe.
- Flag persistence via `Flags.qml` JSON with live file-watch is a clean
  cross-daemon contract.

## Design issues

### D1 — Settings row pattern duplication (refactor candidate)
`Appearance.qml` → sub-cards (`BarPills.qml`) → `SettingsRow` +
`SettingsSurface` now hand-declare every row with 5–6 repeated properties
(`surface`, `captionOnFocus`, `sourceIcon`, `name`, `sub`, `last`). A
declarative model (`ListElement` rows + `Repeater` + `Loader`) would cut
~40% of settings-surface code and make new cards one-array changes.
Follows YemiWorkingRules Rule #2 (traceable, mechanical) — propose, get
approval before touching.

### D2 — Theme property contract is implicit
B1–B3 in 04-hidden-bugs exist because `Theme.<prop>` references are unchecked.
Design fix: keep `Theme.qml` as the single palette source and add a `qmllint`
pass (possible after the IMP-2 versioned-import sweep) so missing properties
become build-time errors instead of 4k runtime warnings.

### D3 — `modules/pill` is a monolith
~40+ files in one folder: services (Singletons/), dialogs, settings surfaces,
bar items all mixed. The reorg already started (`modules/bar`, `modules/
background`); next split: `pill/dialogs/`, `pill/settings/`, and promote
`pill/Singletons/` → `services/` (it already holds real daemons like
ScreenRec, Notifs, Weather).

### D4 — Compositor parity contract (the regression watchlist)
Every new surface must declare its compositor story at creation:
background layers → `isNiri || doublePaint` gating (Backdrop/Wallpaper
pattern); config writers → niri/hyprland pair or explicit gate. Codify this
as a one-line comment header convention on files touching compositor APIs.

## Accessibility / consistency spot checks
- Toast/Osd/Tooltip each hand-roll their fade; a shared `SurfaceFade`
  behavior would standardize timing with `Flags.reduceMotion` respect.
- `Flags.reduceMotion` exists but is not consulted by the new settings
  transitions — wire it into the shared fade (pairs with D-fix above).
