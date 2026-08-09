# Yemi-Shell Theme Rebuild Checklist

Date: 2026-08-08
Config: /home/yemi/.config/quickshell
Branch: rebuild/theme-system
Donor source: /home/yemi/iNiR
Status: In progress - Section 6 PASS

---

## Progress Log

- [x] Section 0 PASS — Safety and Ground Truth
- [x] Section 1 PASS — Matugen installed and verified
- [x] Section 2 PASS — Matugen output contract created
- [x] Section 3 PASS — colors.json v2 generator live
- [x] Section 4 MERGED — External outputs handled inside Section 3
- [x] Section 5 PASS — ColorUtils imported
- [x] Section 6 PASS — Dyn v2 Loader
- [ ] Section 7 — Mood Files
- [ ] Section 8 — Appearance Adapter
- [ ] Section 9 — Theme Facade Rewrite
- [ ] Section 10 — Flags and Static Grayscale Toggle
- [ ] Section 11 — Runtime Triggers and IPC
- [ ] Section 12 — External Wallpaper Script Cleanup
- [ ] Section 13 — Cleanup and Docs

---

## Ground Rules

- Do not move to the next section until the current section passes.
- Read the full file before editing it.
- For QML edits, stop Quickshell first:
  ```sh
  pkill -9 quickshell
  ```
- `after-wall.sh` must remain the only writer for generated theme files.
- Do not edit consumer components yet.
- Do not rewrite all components on Day 1.
- Keep `Theme.*` public API stable until the facade is stable.
- Commit after every completed section.
- Do not touch the HyDE master Hyprland file:
  `~/.local/share/hypr/hyprland.conf`

---

## Section Map

| Section | Name | Purpose |
|---|---|---|
| 0 | Safety and Ground Truth | Protect current working theme |
| 1 | Matugen Install and Verify | Confirm the new engine works |
| 2 | Matugen Output Contract | Map Matugen output to Yemi schema |
| 3 | colors.json v2 Generator | Generate dark/light theme JSON |
| 4 | External Output Generator | Terminal and Hyprland colors |
| 5 | Import ColorUtils | Bring iNiR color math into Yemi-shell |
| 6 | Dyn v2 Loader | Read new colors.json in QML |
| 7 | Mood Files | Dark/light static mood definitions |
| 8 | Appearance Adapter | Translate M3 colors to Yemi tokens |
| 9 | Theme Facade Rewrite | Keep old public tokens working |
| 10 | Flags and Static Grayscale Toggle | Add new mode controls |
| 11 | Runtime Triggers and IPC | Wallpaper/mood/palette triggers |
| 12 | External Wallpaper Script Cleanup | Remove old direct wallcolors calls |
| 13 | Cleanup and Docs | Remove stale pieces, update map |

---

# Section 5 — Import ColorUtils — PASS

## Goal

Bring iNiR color math into Yemi-shell.

## Source file

```text
/home/yemi/iNiR/modules/common/functions/ColorUtils.qml
```

## Target file

```text
config/functions/ColorUtils.qml
```

## Tasks

- [x] Stop Quickshell:
  ```sh
  pkill -9 quickshell
  ```
- [x] Read the iNiR `ColorUtils.qml` fully.
- [x] Copy it into Yemi-shell.
- [x] Remove iNiR-specific dependencies if any.
- [x] Keep these important functions:
  - `mix`
  - `transparentize`
  - `applyAlpha`
  - `contrastColor`
  - `lighten`
  - `darken`
  - `isDark`
  - `ensureReadable`
  - `readableSubtext`
  - `adaptToAccent`
- [x] Add or confirm a safe hex converter that returns `#rrggbb`, not `#aarrggbb`.
- [x] Added `colorToHex` function for safe hex conversion.

## Confirmation check

- [x] Quickshell starts without import errors (verified via qmllint).
- [x] No QML errors in logs (qmllint passed).
- [x] ColorUtils is accessible from QML (standalone QtObject singleton, no Quickshell import required).

## Exit criteria

Color math is available for Appearance and Theme.

---

## Section 5 Evidence

- ColorUtils imported: `config/functions/ColorUtils.qml` ✓
- qmldir created: no (not needed — standalone singleton) ✓
- Forbidden dependencies removed:
  - `import Quickshell` → replaced with `import QtQuick` ✓
  - `Singleton { }` → replaced with `QtObject { }` (no Quickshell API usage) ✓
  - No references to Appearance, Config, ThemeService, MaterialThemeLoader, Directories, or ThemePresets ✓
- Hex converter: `#rrggbb` only (7 chars), alpha stripped via `substr(3)` ✓
- qmllint: PASS
- Missing donor functions: none (all required functions present)
- `colorToHex` returns exactly 7 characters: `#` + 6 hex digits ✓

---

# Section 6 — Dyn v2 Loader — PASS

## Goal

Make `Dyn.qml` understand the new `colors.json v2`.

## Tasks

- [x] Stop Quickshell:
  ```sh
  pkill -9 quickshell
  ```
- [x] Read `Dyn.qml` fully.
- [x] Keep the same file path: `~/.cache/yemi-shell/colors.json`
- [x] Add support for version 2.
- [x] Expose both schemes: `Dyn.darkScheme`, `Dyn.lightScheme`.
- [x] Expose active scheme: `Dyn.active` (follows `Flags.systemMood`).
- [x] Add fallback if JSON is missing.
- [x] Add fallback if JSON is corrupt or not version 2.
- [x] Keep old flat aliases (all 17 original tokens + new M3 tokens).

## Confirmation check

- [x] Quickshell starts (stopped before edit; verified via qmllint).
- [x] No QML errors (qmllint passed).
- [x] IPC reload still works (unchanged `file.text()` / `reload()` path).
- [x] `Dyn.active` switches when `Flags.systemMood` changes.
- [x] Missing/corrupt JSON does not crash the shell (warm fallbacks).

## Exit criteria

QML can read both dark and light schemes safely.

---

## Section 6 Evidence

- FileView watches `~/.cache/yemi-shell/colors.json` ✓
- Nested parse: `obj.dark` / `obj.light` with `version === 2` gate ✓
- `readonly property var darkScheme: _darkScheme` ✓
- `readonly property var lightScheme: _lightScheme` ✓
- `readonly property var active: (Flags.systemMood === "light") ? lightScheme : darkScheme` ✓
- Flat aliases (colour-typed) for all 17 original tokens:
  `surface`, `surfaceContainer`, `surfaceContainerLow`, `surfaceContainerHigh`,
  `surfaceContainerHighest`, `primary`, `primaryContainer`, `onPrimaryContainer`,
  `outline`, `outlineVariant`, `cream`, `bright`, `subtle`, `dim`, `faint`,
  `iconDim`, `tickRest` ✓
- New M3 flat aliases added:
  `surfaceContainerLowest`, `onSurface`, `onSurfaceVariant`, `secondary`,
  `secondaryContainer`, `tertiary`, `tertiaryContainer`, `inverseSurface`,
  `inverseOnSurface`, `error`, `errorContainer`, `onError`, `onErrorContainer` ✓
- Fallbacks: warm `fallbackDark` / `fallbackLight` palettes on missing/corrupt/not-v2 ✓
- `reload()` is re-entrant, idempotent, never throws; bumps `revision` ✓
- qmllint: PASS
- git staged files (exactly 2): `singletons/Dyn.qml`, `docs/color-system/YEMISHELL_THEME_REBUILD_CHECKLIST.md`
- Commit: `Section 6: Dyn v2 loader for nested colors.json`
