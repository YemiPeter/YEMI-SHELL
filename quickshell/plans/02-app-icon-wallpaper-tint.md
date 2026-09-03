# Plan: Wallpaper-Theme Tinted App Icons in the Bar

## Goal

Tint the **running-app icons** in the top bar's left strip (`modules/bar/components/AppIcons.qml`) so each icon is **recolored** using a color drawn from the **existing wallpaper palette** (`Dyn` / `Appearance` / `Theme`), replacing the icon's original colors with the theme color.

The recolor must be **opt-in via a flag**, **gracefully fall back to the original icon** when disabled or when the palette is unavailable, and must not break the existing focused-dot indicator, hover disc, or shadow.

---

## Findings (from exploration)

### What gets tinted
- `modules/bar/components/AppIcons.qml` — the bare running-apps strip docked next to the workspaces pill.
- Two `Image` instances in the cell delegate: the resolved app icon (lines 212-234) and the brand fallback (`fluent/app-generic.svg`, lines 238-256). Both need to be tinted.
- **Note on "pinned vs running":** the current bar strip is **running apps only** (`compositor.toplevels`). There is no pinned-apps list wired into the bar yet. This plan tints whatever `AppIcons.qml` shows today (running apps). A future pinned-apps feature should consume the same tinting helper.

### Theme color source (already exists)
- `singletons/Dyn.qml` — live wallpaper palette (M3 tokens + yemi ramp) reloaded from `~/.cache/yemi-shell/colors.json`. Already consumed via `Appearance`.
- `config/Appearance.qml` — resolves `yemiPrimary` from `Dyn.primary` / `Dyn.primaryContainer` (dynamic) or mood (static fallback).
- `singletons/Theme.qml` — facade: `Theme.onGlow` → `Appearance.yemiPrimary`, `Theme.cream` → on-surface.
- Already used by the focused dot: `AppIcons.qml:266` `color: root.theme.onGlow`.

### Precedent for recoloring
- `modules/settings/.../SettingsRow.qml:91-98` already uses `MultiEffect { colorization: 1.0; colorizationColor: ... }` to recolor a monochrome source SVG to a theme color. This is the established pattern in this codebase for "replace icon colors with theme color."

### Flag plumbing (already exists)
- `singletons/Flags.qml` — persisted JSON-backed flags (`barAppIcons`, `barShadow`, `pillOpacity`, etc.). Add a new flag here.

### Compositor
- Unaffected. `AppIcons.qml` already reads `compositor.toplevels` + `compositor.activeToplevel` through `Compositor.qml`.

---

## Design

### Behavior

1. **Default OFF.** Add `Flags.barAppIconTint: false` so the user's current bar look is unchanged until they enable it.
2. **One shared `MultiEffect`** on each `Image` instance: `colorization: 1.0` + `colorizationColor` bound to the chosen theme color. This replaces the icon's pixels with the theme color while preserving the alpha mask (so silhouette/shape stays correct).
3. **Color choice — `Theme.onGlow`** (`Appearance.yemiPrimary`):
   - Matches the focused dot below the icon, so a themed bar reads as visually consistent.
   - Derived from `Dyn.active.primary` (or `primaryContainer` if more readable against the bar background — see "Contrast safety" below), so it shifts with the wallpaper.
4. **Fallback when palette is invalid.** When `Dyn.schemeValid === false` (colors.json missing/corrupt), `Theme.onGlow` already falls back to `Appearance`'s mood-derived default (e.g. yemi gold). No extra code needed; the tint just reflects the static fallback color, which is still better than the icon's raw colors for consistency. The user can disable the flag if they don't like it.
5. **Focused-app affordance preserved.** The accent dot under the icon (`AppIcons.qml:259-269`) stays as-is. When tinting is on, the dot is `Theme.onGlow` and the icon is also `Theme.onGlow` — the dot will visually disappear into the icon. **Fix:** when tinting is on, change the focused dot color to `Theme.cream` (on-surface) so it remains a visible accent against the now-tinted icon. This mirrors the relationship used elsewhere (tint vs. text).
6. **Shadow + hover disc unchanged.** The existing `MultiEffect` shadow stays; `MultiEffect` supports combining `shadowEnabled` and `colorization` in the same effect instance. Merge into one effect per icon to avoid stacking two `MultiEffect`s.

### Color selection rule (contrast safety)

The primary container / on-surface relationship matters for legibility on the bar background:

- Use `Appearance.yemiPrimaryContainer` when it differs from `yemiPrimary` and is more readable against the bar surface.
- Concretely: pick `Appearance.yemiPrimary` if its luminance is sufficiently different from `Theme.pillSurface` luminance; otherwise pick `Appearance.yemiPrimaryContainer`. Implement as a small `ColorUtils.ensureReadable`-style helper **only if needed** — start with a single token (`yemiPrimary`) and only add the contrast branch if visual testing shows the icon disappearing into the bar.

**Decision: ship with `Appearance.yemiPrimary` only in v1.** Add the contrast helper in a follow-up if screenshots show legibility issues. This keeps the diff minimal and matches the focused-dot color today.

### Why `MultiEffect.colorization` over a `Rectangle` overlay

- A semi-transparent rectangle overlay would blend with the icon's colors and produce muddy results. The user explicitly chose "Recolor (overlay/replace)" — `MultiEffect.colorization: 1.0` is the only built-in Qt Quick effect that *replaces* the source color while preserving alpha.
- Trade-off: `colorization` works best on monochrome or near-monochrome source icons. Many real-world app icons (e.g. Firefox, Discord) are full-color PNGs. `MultiEffect.colorization` still works on those — it maps luminance → color — but the result can look less faithful than the original. The flag makes this opt-in.

---

## Implementation Steps

### 1. Add the flag

**File:** `singletons/Flags.qml`

- Add `property alias barAppIconTint: adapter.barAppIconTint` (alphabetically near `barAppIcons`, `barShadow` — keep grouping).
- In the `JsonAdapter`, add `property bool barAppIconTint: false`.
- Update the `README.md` / flag docs table if one exists (check `docs/` and `AUDIT.md`).

### 2. Extract a small tint helper (keeps `AppIcons.qml` clean)

**New file:** `modules/bar/components/AppIconTint.qml`

A tiny QML component that wraps the `MultiEffect` so the cell delegate stays readable and the effect is defined once. (Alternative: inline the `MultiEffect` in `AppIcons.qml` — slightly less DRY but one fewer file. **Decision: extract**, mirroring how `GlyphIcon.qml` and `SettingsRow.qml`'s `MultiEffect` are encapsulated.)

```qml
import QtQuick
import QtQuick.Effects

// Tint an Image source using MultiEffect.colorization. When `enabled` is
// false, the effect is bypassed and the source renders normally. Shadow is
// preserved so the icon still reads as floating over the wallpaper.
Item {
    id: root
    property Item target          // Image whose layer.effect this becomes
    property color tintColor
    property bool enabled: false
    property bool shadow: true

    function buildEffect() {
        return Qt.createQmlObject(`
            import QtQuick
            import QtQuick.Effects
            MultiEffect {
                shadowEnabled: ${root.shadow}
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.5
                shadowVerticalOffset: 1
                colorization: ${root.enabled ? 1.0 : 0.0}
                colorizationColor: ${root.enabled ? JSON.stringify({...}) : "transparent"}
            }`, root)
    }
}
```

> **Alternative (preferred, simpler):** don't extract a helper at all. Inline the `MultiEffect` in `AppIcons.qml` with three bindings: `colorization`, `colorizationColor`, `shadowEnabled`. The cell delegate already declares one `MultiEffect` per `Image`; just add two properties to it. **Decision: inline.** Less indirection, matches the current style of the file, and `MultiEffect`'s `colorization`/`shadowEnabled` are well-understood.

**Revised step 2: skip the helper file. Edit `AppIcons.qml` only.**

### 3. Update `AppIcons.qml`

**File:** `modules/bar/components/AppIcons.qml`

In the cell delegate (around lines 227-233 and 249-255), extend the existing `MultiEffect` on each `Image`:

```qml
layer.enabled: QsSingletons.Flags.barShadow || QsSingletons.Flags.barAppIconTint
layer.effect: MultiEffect {
    shadowEnabled: QsSingletons.Flags.barShadow
    shadowColor: Qt.rgba(0, 0, 0, 0.5)
    shadowBlur: 0.5
    shadowVerticalOffset: 1
    colorization: QsSingletons.Flags.barAppIconTint ? 1.0 : 0.0
    colorizationColor: root.theme.onGlow
}
```

Update the focused-dot color (line 266) so it stays visible when tinting is on:

```qml
color: QsSingletons.Flags.barAppIconTint ? root.theme.cream : root.theme.onGlow
```

That's it for the visual change. No changes to `appItems`, `iconFor`, `appIdFor`, or compositor wiring.

### 4. Surface the flag in settings (optional but expected in this codebase)

Search for `barAppIcons` and `barShadow` to find the existing "Bar appearance" settings page and add a toggle for `barAppIconTint` next to them. Use the existing `LinkToggle` / `SettingsRow` pattern.

**File to edit:** the bar-pills settings view (likely `modules/settings/.../BarPills.qml` or `Appearance.qml` — confirm during implementation).

Add a row:

```
Icon tint (wallpaper theme)
[LinkToggle bound to QsSingletons.Flags.barAppIconTint]
Sub: "Recolor running-app icons using the current wallpaper palette."
```

### 5. Document

- `AUDIT.md` — note the new flag and the recolor behavior.
- `docs/` — if there's a flags reference, add `barAppIconTint`.

---

## Files Touched

| File | Change |
|---|---|
| `singletons/Flags.qml` | Add `barAppIconTint` alias + `JsonAdapter` bool (default `false`). |
| `modules/bar/components/AppIcons.qml` | Add `colorization` + `colorizationColor` to both `MultiEffect`s; update focused-dot color when tinting is on. |
| `modules/settings/.../BarPills.qml` *(or wherever bar flags live)* | Add toggle row for the new flag. |
| `AUDIT.md` / `docs/` | One-line entry. |

No changes to: `Dyn.qml`, `Appearance.qml`, `Theme.qml`, `Compositor.qml`, `compositor/*`, `shell.qml`, `Bar.qml`.

---

## Verification

1. **Build/load:** `qs -p shell.qml` (or whatever the run script is — check `README.md`) should start without errors.
2. **Default state unchanged:** With `barAppIconTint = false`, the bar should look identical to today (icons render with their original colors, focused dot is accent color).
3. **Enabled state:**
   - Toggle `barAppIconTint = true` in `~/.local/state/quickshell/flags.json` (or via the new settings toggle).
   - All running-app icons become a single uniform color matching the focused dot.
   - Focused dot switches to `Theme.cream` and remains visible against the tinted icon.
   - Shadow still visible.
4. **Wallpaper swap:** Change the wallpaper. Run `after-wall.sh` (or whatever regenerates `colors.json`). The icon color should update alongside the focused dot on the next `Dyn` reload. Verify both light and dark moods.
5. **Edge cases:**
   - Open/close apps — tint applies to newly-resolved icons without flicker (test `asynchronous: true` is still respected; `MultiEffect.colorization` is GPU-cheap so this should be fine).
   - Fallback icon (`fluent/app-generic.svg`) also tints — it's a monochrome SVG, so it will recolor cleanly.
   - `Dyn.schemeValid === false` — color resolves to mood-derived fallback; tint still applied.
   - Hyprland *and* Niri — verify on both (the component reads only from `compositor.toplevels`, so both should work, but Niri's 500ms poll cadence means the tint applies to the icon as soon as the new top-level is observed).

---

## Out of Scope (call out for the user)

- **Pinned apps in the bar.** No pinned-apps list is wired in today. If/when pinned apps land, the same tint applies automatically because the tint lives on the cell delegate, not on the data model.
- **Per-app override.** No way to exclude specific apps from tinting (e.g. terminal emulators where the icon is meaningful). Easy follow-up: add `Flags.barAppIconTintExcludes: string[]` and a check in the delegate.
- **Contrast-safe color picking.** v1 uses `Theme.onGlow` unconditionally. If icons disappear on some wallpapers, add the `ensureReadable` helper in a follow-up.
- **Tray/system-tray icons.** This plan touches only the left-strip app icons (`AppIcons.qml`). Tray icons in the right pill are a different component.

---

## Estimated diff size

- `Flags.qml`: ~3 lines.
- `AppIcons.qml`: ~6 lines changed across 3 `MultiEffect`/dot blocks.
- Settings row: ~15 lines (boilerplate-heavy like its siblings).
- Docs: ~3 lines.

Small, low-risk feature. The flag default keeps existing users unaffected.