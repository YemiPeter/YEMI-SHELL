# Theme System Architecture Plan

## Scope

The theme system provides full dynamic theming from day 1. This replaces the legacy static palette approach. The system works as follows:

- Matugen runs on every wallpaper change to generate theme colors
- `singletons/Dyn.qml` reads the matugen output JSON and exposes colors as dynamic properties
- `singletons/Theme.qml` references `Dyn` for runtime values
- Light and dark palette DEFAULTS exist in Theme.qml (so it works even if matugen hasn't run yet), but the live values come from Dyn
- The system supports both light and dark modes with dark as the default

## Property Naming (Canonical)

The theme system exposes exactly these five properties:

- `primaryColor`
- `secondaryColor`
- `backgroundColor`
- `textColor`
- `wallpaperSource`

These are the canonical property names that all components will reference. All legacy property names (like Ricelin's `cream`/`vermLit` or Pywal's `foreground`/`primary`) are deprecated and will be replaced.

## Light Mode Support

The theme system includes built-in light mode support:

- `isLightMode` is a boolean property on Theme.qml with default value `false` (dark mode)
- Light/dark mode is toggled by a state file at `state/theme-mode` with format `"light"` or `"dark"`
- Theme.qml exposes both light and dark palettes; the active one depends on `isLightMode`
- A `scripts/toggle-theme-mode.sh` script will flip the state file to switch between modes

## Version Control

All changes to the theme system are committed to git. Agents commit after each task with properly scoped commit messages such as `feat(theme): ...` or `refactor: ...`.

## Migration Path

The system builds a full matugen-driven theme system that supersedes Pywal. The matugen output JSON becomes the source of truth for runtime colors. Static defaults in Theme.qml serve as the light/dark palette fallbacks used when matugen output is absent.

## Companion Files

The following files will be created in `singletons/`:

- `qmldir` — registers Theme and Dyn
- `Theme.qml` — main theme singleton, exposes the 5 properties + isLightMode
- `Dyn.qml` — reads matugen output, exposes the 5 properties

## Implementation Notes

- Walls.qml (wallpaper management) is out of scope for Phase 1 and will be deferred
- All existing `pywal.*` references throughout the codebase will be updated to `theme.*`
- The system maintains backward compatibility during the transition period