# Shell by Yemi — Audit Report

**Date:** 2026-09-02 · **Branch:** `niri-fix-cleanup` · **Scope:** performance & Niri/Hyprland isolation

Goal: polish the shell so it runs smoothly on any hardware, and enforce strict
compositor separation — Niri keeps Niri behavior, Hyprland keeps Hyprland
behavior. Recent Niri work regressed a previously-fine Hyprland wallpaper stack
(now fixed — see §1), so this audit exists to find every remaining spot of that
bug class before polishing.

---

## 0. Architecture (healthy baseline)

- `compositor/Compositor.qml` is a clean facade:
  - `runningCompositor` detection, `isNiri` / `isHyprland` convenience flags.
  - `Hyprland.qml` / `Niri.qml` impls gated with `enabled:`
  - Normalized data (`_toArray`) so consumers never touch backend shapes.
- 16 files currently branch on compositor conditionals:

  | File | conditionals |
  |---|---|
  | `modules/pill/Input.qml` | 10 |
  | `modules/pill/Background.qml` | 8 |
  | `modules/bar/components/AppIcons.qml` | 8 |
  | `modules/pill/Keybinds.qml` | 5 |
  | `modules/pill/Workspaces.qml` | 4 |
  | `modules/pill/Singletons/Walls.qml` | 4 |
  | `modules/pill/Display.qml` | 4 |
  | `modules/bar/components/Workspaces.qml` | 3 |
  | `modules/pill/Settings.qml` | 2 |
  | `modules/pill/Appearance.qml` | 2 |
  | `modules/background/Backdrop.qml` | 2 |
  | `modules/altswitcher/AltSwitcher.qml` | 2 |
  | `shell.qml`, `Pill.qml`, `PillOverlay.qml`, `background/Wallpaper.qml` | 1 each |

---

## 1. Compositor isolation — findings

### 1.1 Wallpaper / Backdrop stacking on Hyprland — ✅ FIXED
**Was:** the regression that motivated this audit.
- `modules/background/Wallpaper.qml` had **no compositor check**: with
  `wallpaperEnableBlur` on it painted a blurred QML wallpaper **on top of awww**
  on Hyprland.
- `modules/background/Backdrop.qml` hid its image layer on Hyprland correctly,
  but the window itself (dim/vignette overlay) still sat above awww.
- Bonus: `transformOrigin: Transform.Center` (`Transform` doesn't exist →
  `ReferenceError: Transform is not defined` in logs, silently breaking the
  parallax transform). Fixed to `Item.Center`.

**Now:**
- `Wallpaper.qml` paints only on Niri, or when the user opts into
  `backdropDoublePaint`.
- `Backdrop.qml` `visible` requires `isNiri || backdropDoublePaint` →
  Hyprland = pure awww wallpaper by default.
- Reload verified clean.

### 1.2 Niri-config writers without runtime guards — 🔴 OPEN (Hyprland risk)
These parse and rewrite **niri config files**; on Hyprland they would write
niri-style blocks or no-op confusingly:

- `modules/pill/Input.qml` — `lib/setInputNiri.js` (`setField`,
  `upsertMouseBlock`, `upsertCursorBlock`) against `niriInputText`.
- `modules/pill/Keybinds.qml` — `BindsNiri.parse(bindsFile.text())`, add/delete
  keybinds on Niri only.

**Fix plan:** gate every writer on `Compositor.isNiri` (hide/disable rows on
Hyprland), and later (post-niri phase) add Hyprland equivalents
(`hyprctl` / `hyprland.conf` sections).### 1.3 Niri-API references needing a per-file guard pass — 🟡 VERIFY
Files referencing niri APIs: `AltSwitcher`, `bar/Bar.qml`, `bar/components/*`,
`Pill`, `PillOverlay`, `pill/shell.qml`, `Singletons/{Notifs,ScreenRec,
Workspacerules}.qml`, `services/ScreenTime.qml`, `Appearance`, `Display`,
`Keybinds`, `Input`, `Background`. Most go through `Compositor.impl` (safe);
each needs a quick confirmation that no direct niri call is reachable when the
backend is Hyprland.

---

## 2. Performance — findings

### 2.1 Effects (biggest GPU cost)
**43 `MultiEffect` / `layer.enabled` / `ShaderEffectSource` usages in 19 files.**
Per-file: Bluetooth/Brightness/Network/Volume popups, `Glass.qml`, `Tooltip`,
`SettingsRow`, `Pill`, `Tray`, `MusicPanel`, `AltSwitcher`, `AppIcons`,
`ConflictKillDialog`, `WelcomeDialog`, `pill/Wallpaper`, `background/{Wallpaper,
Backdrop}`, `WallpaperCrossfader`.

**Risks / wins:**
- Effects keep compositing while their window is hidden unless the *effect* is
  `visible: false` (not just the window) — gate on visibility.
- `SettingsRow` colorization via `layer.effect` per row — note: the fluent SVGs
  ship baked black, so shader colorization is unreliable; the white-fill SVG
  copy approach (`assets/icons/fluent-white/`) is the working pattern. Prefer
  pre-colored assets over shader colorization for static icons.
- `WallpaperCrossfader` + Backdrop `MultiEffect` (blur/saturation/contrast) run
  per-frame when enabled — fine on Niri where QML *is* the wallpaper, but keep
  radius/flags conservative defaults.

### 2.2 Timers (~40 total)
- ✅ The two `interval: 1` timers (`services/SystemInfo.qml`,
  `services/Updates.qml`) are one-shot startup kicks — fine.
- 🟡 8× `1000ms`, 6× `2000ms`, 5× `500ms` pollers — several can become
  event-driven or `running: visible && …` (clock, system info, network state,
  battery).
- Debounces (`Mixer` 160ms ×3, `WallpaperListener` 80ms) are fine.

### 2.3 Processes
- **47 `Process {}` objects.** Some are poll-based where a `FileView` watcher
  or a signal would do. FileView watchers already used well in `AppIcons`,
  `Events`, `Weather`, `Display`, etc.

---

## 3. Plan of execution

Ordered so Niri behavior is preserved and nothing Hyprland-visible changes
accidentally:

1. **Perf pass A — visibility gating:** effects & timers only active when their
   surface is visible. Zero behavior change.
2. **Perf pass B — event-driven conversion:** replace polling timers with
   FileView watchers / signals where the data source allows.
3. **Isolation pass:** add missing `Compositor.isNiri` guards around the
   niri-config writers (Input, Keybinds) and verify all §1.3 files.
4. **Hyprland parity phase (later, user-driven):** Hyprland equivalents for
   Input/Keybinds/etc., plus re-testing awww interplay.

## 4. Regression watchlist (bug class that started this)

Whenever a Niri feature is added, ask: *what does this do on Hyprland?*
Concretely: any new `PanelWindow` layered on the background, any new config
writer, any new compositor dispatch — must be gated on
`Compositor.isNiri` / `Compositor.isHyprland` from day one.
