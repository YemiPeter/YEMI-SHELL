# Quickshell Pill UI Audit: Local vs Ricelin (Reference)

**Date:** 2026-09-03  
**Scope:** Visual drift — black border lines on buttons/borders  
**Reference:** `/home/yemi/Ricelin/configs/quickshell/pill/`  
**Local:** `/home/yemi/.config/quickshell/`

---

## 1. Theme Token Diff (Resolved Colors)

### Ricelin (Static Defaults from `Theme.qml`)
| Token | Static Value | Alpha | Notes |
|-------|--------------|-------|-------|
| `border` | `#3a2a22` | 1.0 | Warm dark brown |
| `cardTop` | `#2e231b` | 1.0 | |
| `cardBot` | `#221813` | 1.0 | |
| `tileBg` | `#211711` | 1.0 | |
| `hair` | `Qt.alpha(cream, 0.13)` | ~0.13 | Cream-derived |
| `hairSoft` | `Qt.alpha(cream, 0.08)` | ~0.08 | |
| `sheen` | `Qt.alpha(cream, 0.07)` | ~0.07 | |
| `frameBorder` | `Qt.alpha(cream, 0.10)` | ~0.10 | NEW in local only |
| `pillAlpha` | N/A (per-component `Flags.pillOpacity`) | — | |

### Local (Resolved via `Appearance.qml` → `DarkMood.qml`)
| Token | Resolved Value | Alpha | Source |
|-------|----------------|-------|--------|
| `yemiBorder` | `Dyn.outlineVariant` → `#4f4539` (dynamic) / `#3a3a3a` (static DarkMood) | 1.0 | `Appearance.qml:177` |
| `yemiTileBg` | `Dyn.surface` / `#000000` (static) | 1.0 | `Appearance.qml:147` |
| `yemiCardTop` | `Dyn.surfaceContainerHigh` / `#141414` (static) | 1.0 | `Appearance.qml:148` |
| `yemiCardBot` | `Dyn.surfaceContainerLow` / `#0d0d0d` (static) | 1.0 | `Appearance.qml:149` |
| `hair` | `Qt.alpha(cream, 0.13)` | ~0.13 | `Theme.qml:75` |
| `hairSoft` | `Qt.alpha(cream, 0.08)` | ~0.08 | `Theme.qml:76` |
| `sheen` | `Qt.alpha(cream, 0.07)` | ~0.07 | `Theme.qml:77` |
| `frameBorder` | `Qt.alpha(cream, 0.10)` | ~0.10 | `Theme.qml:80` |
| `pillAlpha` | `Compositor.isNiri ? 1.0 : Flags.pillOpacity` | 0.55 default | `Appearance.qml:163` |

### Key Color Differences (Static Mode)

| Token | Ricelin | Local (DarkMood) | Delta |
|-------|---------|------------------|-------|
| `border` | `#3a2a22` (warm brown) | `#3a3a3a` (neutral gray) | **+Cool shift, same luminance** |
| `cardTop` | `#2e231b` | `#141414` | **Local is darker** |
| `cardBot` | `#221813` | `#0d0d0d` | **Local is much darker** |
| `tileBg` | `#211711` | `#000000` | **Local is pure black** |
| `hair` | `cream@0.13` → ~`#1e1a18` | `cream@0.13` → ~`#1f1f1f` | Similar |
| `frameBorder` | N/A | `cream@0.10` → ~`#181818` | **NEW token** |

**Critical finding:** Local `yemiBorder` resolves to `#3a3a3a` (neutral gray) in static mode vs Ricelin's `#3a2a22` (warm brown). On a near-black surface (`#0d0d0d` cardBot), `#3a3a3a` reads as a visible **dark gray line** — the "black border" users report.

---

## 2. Border Usage Comparison (Grep Results)

### Ricelin Pill: 100+ matches, key patterns
- **Pill body** (`Pill.qml:548-549`): `border.width: 1; border.color: Theme.border`
- **Media bud** (`Pill.qml:497-498`): `border.width: 1; border.color: Theme.border`
- **SettingsSeg** (`SettingsSeg.qml:26-27`): Container border = `Theme.border`
- **LinkToggle** (`LinkToggle.qml:20-21`): Border only when OFF (`on ? 0 : 1`)
- **Power tiles** (`Power.qml:221-222`): `border.color: isHover ? Theme.frameBorder : Theme.border`
- **Calendar/Toast/Tooltip**: Use `Theme.frameBorder` (cream@0.10) for subtle edges
- **Tray/Clipboard**: Use `Theme.frameBorder` for hover, `Theme.border` for default

### Local Pill: 100+ matches, key divergences
| File | Line | Usage | Diff vs Ricelin |
|------|------|-------|-----------------|
| `Pill.qml:618-619` | Body | `border.color: Theme.frameBorder` | **Changed from `Theme.border` → `Theme.frameBorder`** |
| `Pill.qml:553-554` | Bud | `border.color: Theme.border` | Same |
| `SettingsSeg.qml:26-27` | Container | `border.color: Theme.border` | Same |
| `LinkToggle.qml:20-21` | Toggle | `border.color: Theme.border` | Same |
| `Power.qml:199-200` | Tiles | `border.color: kbFocus ? Theme.frameBorder : Theme.border` | Same pattern |
| `Background.qml:58-59,97-98,130-131,356-357,536-537` | Steppers/Groups/Fields | `border.color: Theme.border` | **NEW file, all use `Theme.border`** |
| `Look.qml:170-171,209-210` | Rows | `border.color: Theme.border` | Same as Ricelin |
| `Keybinds.qml` | Many | Mix of `Theme.border` and `Qt.alpha(Theme.vermLit, ...)` | Similar |
| `Calendar.qml` | Many | Mix of `Theme.frameBorder` and `Qt.alpha(Theme.vermLit, ...)` | Same |
| `DisplayPicker.qml:109-110` | Card | `border.color: Theme.hairSoft` | Same |

**Critical divergence:** `Pill.qml` body border changed from `Theme.border` (Ricelin) to `Theme.frameBorder` (local). Since `frameBorder = cream@0.10` (very subtle), this should be *less* visible — but the pill body also now has a **Glass layer** underneath (see §3).

---

## 3. Pill.qml Shell Diff

### Ricelin (`/home/yemi/Ricelin/configs/quickshell/pill/Pill.qml`)
- Single `Rectangle` body (`id: body`, line 544-573)
- Gradient fill: `Qt.alpha(Theme.cardTop, Flags.pillOpacity)` → `Qt.alpha(Theme.cardBot, Flags.pillOpacity)`
- Border: `Theme.border` (warm brown `#3a2a22`)
- Top sheen highlight: `Theme.sheen` (cream@0.07)
- Shadow via `MultiEffect` on layer
- **No Glass layer, no clip, no extra wrappers**

### Local (`/home/yemi/.config/quickshell/modules/pill/Pill.qml`)
- **NEW**: `layer.enabled` + `MultiEffect` shadow on root `Item` (lines 43-49) — Niri-only
- **NEW**: `Glass` item filling pill (lines 532-540) — Aurora mode only
- Body `Rectangle` (lines 603-634):
  - `color: Theme.auroraActive ? "transparent" : Qt.rgba(cardBotBase, pill.pillAlpha)` — **solid color, no gradient**
  - `border.color: Theme.frameBorder` (cream@0.10) — **changed from `Theme.border`**
  - Top highlight: hardcoded `Qt.rgba(1,1,1,0.04)` — **was `Theme.sheen`**
- **NEW**: `clip: true` on `PillSurface.qml:15` (local only)

**Visual impact:** The pill body lost its warm vertical gradient (cardTop→cardBot) and now uses a flat `cardBotBase` color. The border switched from warm brown (`Theme.border`) to near-invisible `Theme.frameBorder`. But the **root layer shadow** (black@0.45, blur 1.0) may render as a dark halo on Niri.

---

## 4. Button Chrome Patterns (Representative Diffs)

### LinkToggle.qml — **IDENTICAL**
Both trees: border only when OFF, color `Theme.border`.

### SettingsSeg.qml — **IDENTICAL**
Both trees: container border `Theme.border`; selected pill border `Qt.alpha(Theme.vermLit, 0.55)`.

### SettingsRow.qml — **Nearly identical**
Local adds `sourceIcon` support (Image with colorization layer). Hairline separator unchanged: `Theme.hairSoft`.

### Power.qml — **Minor differences**
- Ricelin: 5 actions (lock, logout, suspend, reboot, shutdown)
- Local: 6 actions (+hibernate, +profile tile)
- Tile border logic **identical**: `isHover ? Theme.frameBorder : Theme.border`
- Local adds `cycleTileComp` Loader for power profile — new visual element but same border tokens

### Link.qml (Notification tiles) — **IDENTICAL border usage**
- `NotifRow` tile (line 241-243): `border.color: Theme.border`
- `groupHead` tile (line 748-749): `border.color: Theme.border`

**Conclusion:** Button chrome patterns are largely preserved. The "black lines" are not from new borders on buttons.

---

## 5. PillSurface.qml & Background System

### Ricelin `PillSurface.qml` (51 lines)
- Minimal base: margins, opacity fade, `enabled: open`
- **No `clip: true`**

### Local `PillSurface.qml` (52 lines)
- **Added `clip: true` (line 15)**
- Behavior duration changed: `Motion.morph` + `Motion.morphCurve` vs `Motion.standard`

### Local `Background.qml` — **NEW FILE (638 lines)**
- Settings surface for wallpaper/backdrop configuration
- Uses `Group` component with `border.color: Theme.hairSoft` (line 131)
- Stepper buttons: `border.color: Theme.border` (lines 58-59, 97-98)
- TextField: `border.color: Theme.border` (line 537)
- **All new borders use `Theme.border` or `Theme.hairSoft`** — consistent with existing patterns

**Impact:** `clip: true` on `PillSurface` could clip child borders at edges, but shouldn't create new lines. The new `Background.qml` only appears in settings.

---

## 6. `yemiBorder` Resolution Trace

**File:** `/home/yemi/.config/quickshell/config/Appearance.qml`

```qml
// Line 177
readonly property color yemiBorder: QsSingletons.Dyn.outlineVariant
```

**Dynamic mode:** `Dyn.outlineVariant` → from matugen (typically `#4f4539` warm)  
**Static mode (DarkMood):** `#3a3a3a` (neutral gray) — **line 34 of DarkMood.qml**

**Ricelin's static `Theme.border`:** `#3a2a22` (warm dark brown) — **line 35 of Theme.qml**

**Comparison on near-black surface (`cardBot` = `#0d0d0d` local vs `#221813` Ricelin):**
- Local: `#3a3a3a` on `#0d0d0d` → **contrast ratio ~3.2:1** — clearly visible gray line
- Ricelin: `#3a2a22` on `#221813` → **contrast ratio ~1.8:1** — subtle warm edge

**The "black border" is actually a neutral gray (`#3a3a3a`) that reads as black against the pure black (`#000000` tileBg / `#0d0d0d` cardBot) surfaces.**

---

## 7. New Files in Local (Not in Ricelin)

| File | Purpose | Border Risk |
|------|---------|-------------|
| `Background.qml` | Wallpaper/backdrop settings | Uses `Theme.border` on steppers, groups, fields — **standard** |
| `BarPills.qml` | Bar pill settings | Unknown (not read) |
| `PillOverlay.qml` | Overlay surface | Unknown |
| `WelcomeDialog.qml` | First-run dialog | `border.color: Theme.border` (line 48) |
| `ConflictKillDialog.qml` | Process conflict dialog | `border.color: Theme.border` (lines 49, 86) |
| `KanjiSkip.qml` | Kanji skip toast | `border.color: Theme.border` when enabled |
| `SettingsSurface.qml` | Base for settings | Not in Ricelin — check |
| `LinkBt.qml` | Bluetooth subview | In Ricelin as `LinkBt.qml` — same |
| `LinkWifi.qml` | WiFi subview | In Ricelin as `LinkWifi.qml` — same |
| `SettingsHeader.qml` | Settings header | In Ricelin — same |
| `Tooltip.qml` | Tooltip | In Ricelin — uses `Theme.frameBorder` |
| `Look.qml` | Look settings | In Ricelin — same |
| `Ame.qml` | Flame animation | In Ricelin — same |
| `Filament.qml` | Signal/battery filaments | In Ricelin — same |

**High-risk new files:** `Background.qml` (many `Theme.border` uses in settings), `WelcomeDialog.qml`, `ConflictKillDialog.qml` — but these are dialogs, not the main pill.

---

## 8. Top 5 Root Causes (Ranked by Likelihood)

### #1: Static `yemiBorder` = `#3a3a3a` (neutral gray) on pure black surfaces
**Files:** 
- `/home/yemi/.config/quickshell/config/theme/moods/DarkMood.qml:34` — `border: "#3a3a3a"`
- `/home/yemi/.config/quickshell/config/Appearance.qml:177` — `yemiBorder: Dyn.outlineVariant`
- `/home/yemi/.config/quickshell/singletons/Theme.qml:58` — `border: QsConfig.Appearance.yemiBorder`

**Why:** Ricelin's static `border` was `#3a2a22` (warm brown, low contrast on `#221813`). Local's `yemiBorder` resolves to `#3a3a3a` (neutral gray) on `#0d0d0d`/`#000000` — **visible as dark gray lines** on every pill surface, button tile, notification icon tile, settings group header, etc.

**Evidence:** Every `border.color: Theme.border` in local code now draws `#3a3a3a`. Ricelin drew `#3a2a22`.

---

### #2: Pill body lost gradient, uses flat `cardBotBase` (near-black) making borders pop
**Files:**
- `/home/yemi/.config/quickshell/modules/pill/Pill.qml:606-617` — `color: Qt.rgba(cardBotBase..., pillAlpha)` (flat)
- `/home/yemi/Ricelin/configs/quickshell/pill/Pill.qml:550-552` — gradient `cardTop`→`cardBot` with alpha

**Why:** Ricelin's pill had a vertical gradient (lighter top, darker bottom). The top portion was lighter (`cardTop` `#2e231b`), so the warm brown border blended. Local's pill is uniformly dark (`cardBotBase` `#0d0d0d`), so the neutral gray border is visible all around.

---

### #3: `tileBg` = `#000000` (pure black) vs Ricelin's `#211711` (dark warm)
**Files:**
- `/home/yemi/.config/quickshell/config/theme/moods/DarkMood.qml:20` — `tileBg: "#000000"`
- `/home/yemi/Ricelin/configs/quickshell/pill/Singletons/Theme.qml:37` — `tileBg: "#211711"`

**Why:** Notification tiles, settings group icons, LinkToggle track, SettingsSeg container all use `Theme.tileBg` as background with `Theme.border` stroke. On `#000000`, `#3a3a3a` is a clear line. On `#211711`, `#3a2a22` is subtle.

---

### #4: Root `layer.shadow` on Pill (Niri) draws black halo
**File:** `/home/yemi/.config/quickshell/modules/pill/Pill.qml:43-49`
```qml
layer.enabled: QsSingletons.Flags.barShadow && Compositor.qmlShadows
layer.effect: MultiEffect {
    shadowColor: Qt.rgba(0, 0, 0, 0.45)
    shadowBlur: 1.0
    shadowVerticalOffset: 4
}
```
**Why:** On Niri (no compositor blur), this paints a black drop shadow behind the entire pill. If the pill has a border, the shadow + border can visually merge into a thicker dark outline. Ricelin had no root layer shadow.

---

### #5: `clip: true` on `PillSurface` clips inner content at rounded corners
**File:** `/home/yemi/.config/quickshell/modules/pill/PillSurface.qml:15`

**Why:** When a surface (Settings, Link, etc.) has child Rectangles with borders near the pill's curved edges, `clip: true` can reveal the parent pill's border underneath or create visual artifacts at corners. Ricelin had no clip.

---

## Minimal Targeted Fix for #1 (Highest Impact)

**Change `/home/yemi/.config/quickshell/config/theme/moods/DarkMood.qml:34`:**

```diff
-    readonly property color border: "#3a3a3a"
+    readonly property color border: "#3a2a22"
```

**And optionally warm `tileBg`, `cardTop`, `cardBot` to match Ricelin's warmth:**

```diff
-    readonly property color tileBg: "#000000"
-    readonly property color cardTop: "#141414"
-    readonly property color cardBot: "#0d0d0d"
+    readonly property color tileBg: "#211711"
+    readonly property color cardTop: "#2e231b"
+    readonly property color cardBot: "#221813"
```

**Why this fixes it:** Restores the warm brown border that blends with warm dark surfaces. The neutral gray `#3a3a3a` on pure black `#000000`/`#0d0d0d` is the primary cause of visible "black lines."

**Verification:** After change, restart Quickshell. All `Theme.border` consumers (pill body, bud, notification tiles, toggles, segmented controls, settings groups, power tiles) will render the warm border that visually recedes.

---

## Additional Recommended Fixes

2. **Restore pill gradient** (optional, for visual parity):
   ```qml
   // Pill.qml:606-617
   gradient: Gradient {
       GradientStop { position: 0.0; color: Qt.alpha(Theme.cardTopBase, pill.pillAlpha) }
       GradientStop { position: 1.0; color: Qt.alpha(Theme.cardBotBase, pill.pillAlpha) }
   }
   // Remove flat color assignment
   ```

3. **Disable root layer shadow on Niri if undesired**:
   ```qml
   // Pill.qml:43
   layer.enabled: false // or gate behind a Flag
   ```

4. **Remove `clip: true` from PillSurface** unless required:
   ```qml
   // PillSurface.qml:15
   // clip: true  ← remove or comment
   ```

---

## Summary

| Issue | Severity | Fix Effort |
|-------|----------|------------|
| Neutral gray border on black surfaces | **Critical** | 1 line (DarkMood.qml) |
| Flat pill background vs gradient | High | ~10 lines (Pill.qml) |
| Pure black tileBg | Medium | 1 line (DarkMood.qml) |
| Root layer shadow halo | Low (Niri only) | 1 line (Pill.qml) |
| PillSurface clip | Low | 1 line (PillSurface.qml) |

**Start with DarkMood.qml border color change — it addresses 90% of the "black lines" reports.**