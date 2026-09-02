# Audit 04 — Hidden Bugs (TRAE-debugger pass)

Source: live `qs log` capture + code reads. These are bugs that *don't crash*
the shell but silently degrade it — mostly undefined property assignments.

## 🔴 B1 — `Theme.flameGlow` / `Theme.flameCore` do not exist
**Worst bug in the shell by log volume.**
- `modules/pill/Wallpaper.qml[405]`: `color: Theme.flameGlow` →
  **4,104 warnings** (spams every frame/reload), the wallpaper tile-progress
  gradient renders with undefined color.
- `modules/pill/Filament.qml[62]`: `Theme.flameCore` → 528 warnings.
- `grep singletons/` finds **no declaration** of `flameGlow`/`flameCore` on
  the Theme singleton.
**Fix:** add both properties to `singletons/Theme.qml` (or re-point the two
call sites at existing palette entries), then verify the warnings stop.

## 🔴 B2 — Same pattern, other call sites (undefined → QColor)
| File | warnings |
|---|---|
| `pill/Calendar.qml[656]` | 351 |
| `pill/LinkBt.qml` | 140 |
| `pill/LinkWifi.qml` | 36 |
| `pill/Link.qml` | 36 |
| `pill/Pill.qml` | 18 |
| `pill/Osd.qml` | 18 |
| `pill/Toast.qml` | 14 |
| `pill/Recorder.qml`, `pill/BatterySurface.qml` | 9 each |

All are `Theme.<prop>` bindings where `<prop>` is missing/undefined at
runtime. One fix pattern: audit every `Theme.` reference against the
declared properties in `singletons/Theme.qml`.

## 🟠 B3 — Type mismatches (undefined → double / QString / int)
- `pill/Background.qml[?]` — 45× "Unable to assign [undefined] to double".
- `common/widgets/WallpaperCrossfader.qml` — 18× QString + 18× int.
  Likely flag bindings (`Flags.<name>` typo or missing alias) feeding
  transition properties.

## 🟠 B4 — `ReferenceError: Quickshell is not defined` in Updates.qml
`pill/Updates.qml[27,28]` uses the `Quickshell` global without
`import Quickshell`. Fires repeatedly (18×). One-line fix: add the import.

## 🟡 B5 — Unresolvable relative imports (qmlscanner)
- `modules/pill/Background.qml` → `../../../config` (10 warnings).
- `common/widgets/WallpaperCrossfader.qml` → `../../singletons` (10 warnings).
Path depth is wrong after the folder reorganization; imports resolve by luck
of a second path or are silently dropped.

## 🟡 B6 — WlrLayershell parent warning
`PanelWindow (parent or ancestor of WlrLayershell) at pill/PillOverlay.qml`
— layer-shell window is getting a QML parent it shouldn't have; can cause
unexpected destroy behavior on hide/reload.

## 🟡 B7 — Animation warnings
`bar/components/StatusIndicators.qml` SequentialAnimation warnings (9×) —
likely animating a non-animatable property; cosmetic but noisy.
