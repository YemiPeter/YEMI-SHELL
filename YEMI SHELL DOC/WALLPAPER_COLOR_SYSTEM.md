# 🎨 Wallpaper → Color System Map

How the wallpaper's pixels become every color the pill (and bar) renders.

---

## Overview — The Pipeline in One Breath

```
Wallpaper image
    │
    ▼
┌──────────────────────────────────┐
│  wallcolors.py  (Python script)  │  ← ImageMagick histogram → dominant hue + mean lightness
│  scripts/wallcolors.py           │  → HSL math builds pill surfaces + accent + text
│                                  │  → matugen builds base16 for terminal/Hyprland
└──────────┬───────────────────────┘
           │  writes
           ▼
    ~/.cache/yemi-shell/colors.json    ← The single source of truth for pill colors
    ~/.cache/yemi-shell/hypr-colors.lua
    ~/.cache/yemi-shell/ghostty-colors
           │
           ▼  (FileView watchChanges)
┌──────────────────────────────────┐
│  Dyn.qml  (singleton)            │  ← Reads colors.json via JsonAdapter
│  singletons/Dyn.qml              │  Exposes: surface, primary, cream, bright, etc.
│  modules/pill/Singletons/Dyn.qml │  (identical copy — pill's local module scope)
└──────────┬───────────────────────┘
           │  provides dynamic hex
           ▼
┌──────────────────────────────────┐
│  Theme.qml  (singleton)          │  ← Ternary per token: dyn ? Dyn.xxx : "#fixed"
│  singletons/Theme.qml            │  Static mode = curated washi/flame hex
│  modules/pill/Singletons/Theme.qml│  Dynamic mode = wallpaper-derived from Dyn
└──────────┬───────────────────────┘
           │  every QML component reads
           ▼
    Pill.qml, Link.qml, Mixer.qml, Toast.qml, …
    Bar components (via config/Appearance.qml → QsSingletons.Theme)
    MusicPanel.qml (via QsTheme.Theme.*)
```

---

## Layer 1 — The Trigger: Wallpaper Change

**Entry points that start the pipeline:**

| Trigger | Path | What it does |
|---|---|---|
| Random keybind | `shell.qml` → `IpcHandler "wallpaper"` → `random()` | Runs `wallpaper.sh random` |
| Wallpaper picker | `modules/pill/Wallpaper.qml` → `Walls.apply(path)` | Runs `wallpaper.sh set <path>` |
| `wallpaper.sh` | `~/.config/hypr/scripts/wallpaper.sh` | Sets Hyprland wallpaper, then calls `after-wall.sh` |
| `after-wall.sh` | `scripts/after-wall.sh` | Runs `wallcolors.py "$1"` |

The chain: **user picks wallpaper → `wallpaper.sh` → `after-wall.sh` → `wallcolors.py`**

---

## Layer 2 — The Brain: `wallcolors.py`

**File:** [`scripts/wallcolors.py`](scripts/wallcolors.py)

This is where the actual color science happens. Two modes:

### Mode A: Wallpaper analysis (`wallcolors.py <image>`)

1. **ImageMagick histogram** — resizes to 200×200, quantizes to 48 colors, runs `histogram:info:-`
2. **Hue bucketing** — bins pixels into 12 hue families (30° each), weighted by saturation × area
3. **Dominant hue** — the bucket with highest weighted saturation wins
4. **Mean lightness** — area-weighted average across all pixels → decides dark vs light pill
5. **Achromatic fallback** — if <8% of pixels are chromatic, drops to neutral grey ramp

### Mode B: Manual override (`wallcolors.py --hue <degrees> <dark|light> <sat>`)

Bypasses image analysis entirely. The Appearance surface's hue strip / dark-light toggle feeds this.

### Color generation (both modes):

```
mean_l >= 0.40  →  LIGHT pill  (bright surfaces, dark text)
mean_l <  0.40  →  DARK pill   (near-black surfaces, cream text)
```

**Surface ramp** — 6 tiers from `surface` → `surface_container_highest`, stepped by lightness:

| Token | Dark step | Light step |
|---|---|---|
| `surface` | +0.000 | +0.000 |
| `surface_container_low` | +0.022 | −0.045 |
| `surface_container` | +0.038 | −0.075 |
| `surface_container_high` | +0.065 | −0.115 |
| `surface_container_highest` | +0.100 | −0.160 |
| `outline_variant` | +0.225 | −0.340 |

All tinted by the dominant hue at `surf_sat` (capped 0.26 light / 0.30–0.45 dark).

**Accent ramp:**

| Token | Dark | Light |
|---|---|---|
| `primary` | L=0.70, sat+0.12 | L=0.42, sat+0.18 |
| `primary_container` | L=0.34, sat+0.08 | L=0.30, sat+0.08 |
| `on_primary_container` | L=0.86 | L=0.55 |

**Text ramp** — 7 tokens (`cream`, `bright`, `subtle`, `dim`, `faint`, `icon_dim`, `tick_rest`), each with fixed lightness + low saturation so they always contrast the surface. Dark pill = light text, light pill = dark text.

### Output files:

| File | Consumer | Content |
|---|---|---|
| `~/.cache/yemi-shell/colors.json` | **Dyn.qml** (pill + bar) | All surface, accent, text tokens |
| `~/.cache/yemi-shell/hypr-colors.lua` | Hyprland border colors | `active` = pill primary, `inactive` = base01 |
| `~/.cache/yemi-shell/ghostty-colors` | Ghostty terminal | Full base16 palette + cursor/selection |

The `colors.json` is the critical one — it's what the live QML reads.

---

## Layer 3 — The Bridge: `Dyn.qml`

**Files (identical copies):**
- [`singletons/Dyn.qml`](singletons/Dyn.qml) — project-wide singleton (bar, music panel)
- [`modules/pill/Singletons/Dyn.qml`](modules/pill/Singletons/Dyn.qml) — pill's local singleton

```qml
FileView {
    path: "~/.cache/yemi-shell/colors.json"
    watchChanges: true        // ← auto-reloads when wallcolors.py writes
    onFileChanged: reload()

    JsonAdapter {
        // 17 properties matching the JSON keys
        property string surface: "#18120b"           // ← warm fallback defaults
        property string primary: "#f5bd6f"
        property string cream: "#e6d6cb"
        // ...
    }
}
```

**Key insight:** `Dyn` never does any color math. It's a pure **file → property** bridge. Every token is a raw hex string from the JSON, with hardcoded warm defaults if the file doesn't exist yet.

The `watchChanges: true` means the moment `wallcolors.py` finishes writing `colors.json`, every running Dyn singleton across all Quickshell daemons reloads and its properties update, which cascades through Theme to every bound color in the UI. **No restart needed.**

---

## Layer 4 — The Switch: `Theme.qml`

**Files (identical copies):**
- [`singletons/Theme.qml`](singletons/Theme.qml) — project-wide
- [`modules/pill/Singletons/Theme.qml`](modules/pill/Singletons/Theme.qml) — pill-local

This is the **only** place the static/dynamic decision lives:

```qml
readonly property bool dyn: Flags.paletteMode !== "static"
```

Every color token is a single ternary:

```qml
readonly property color cardTop: dyn ? Dyn.surfaceContainerHigh : "#2e231b"
readonly property color verm:     dyn ? Qt.darker(Dyn.primary, 1.18) : "#c0442b"
readonly property color cream:    dyn ? Dyn.cream : "#e6d6cb"
```

### What's dynamic vs what's locked:

| Category | Dynamic (wallpaper-driven) | Static (hardcoded) |
|---|---|---|
| **Surfaces** | `tileBg`, `cardTop`, `cardBot`, `border`, `ghost` | — |
| **Accent** | `onGlow`, `verm`, `vermLit`, `vermDeep`, `vermBurn`, `flameCore`, `flameGlow` | — |
| **Text** | `cream`, `bright`, `subtle`, `dim`, `faint`, `iconDim`, `tickRest` | — |
| **Outlines** | `outlineVariant` (via `border`) | — |
| **Veils** | — | `hair`, `hairSoft`, `sheen` (alpha of `cream`, always relative) |
| **Shadow** | — | `shadow` = `Qt.rgba(0,0,0,0.55)` (always fixed) |
| **Font** | — | `Inter` / `Zen Kaku Gothic New` (never wallpaper-driven) |

**Why veils and shadow stay locked:** `hair` = `Qt.alpha(cream, 0.13)`. Since `cream` itself is already dynamic, the veil automatically adapts — it's always 13% of whatever cream is. No need for a separate Dyn token. Shadow is pure black at 55% opacity regardless of wallpaper.

### Flame canvas tokens (string type, not color):

```qml
readonly property string flameInk:   dyn ? Dyn.primary : "#f0795a"
readonly property string flameEmber: dyn ? Dyn.primaryContainer : "#7e2812"
```

These are `string`, not `color`, because Canvas `addColorStop()` serializes `color` properties as `#aarrggbb` which corrupts the gradient. The dynamic branch passes matugen's raw `#rrggbb` hex through untouched.

---

## Layer 5 — The Flag: `Flags.paletteMode`

**Files (two versions, different state paths):**
- [`singletons/Flags.qml`](singletons/Flags.qml) — project-wide, reads `~/.local/state/quickshell/flags.json`, default `"dynamic"`
- [`modules/pill/Singletons/Flags.qml`](modules/pill/Singletons/Flags.qml) — pill-local, reads `~/.local/state/yemi-shell/flags.json`, default `"static"`

Three modes:

| Mode | Effect |
|---|---|
| `"static"` | `Theme.dyn = false` → all curated washi hex, zero Dyn reads |
| `"dynamic"` | `Theme.dyn = true` → every token follows wallpaper via Dyn |
| `"manual"` | `Theme.dyn = true` → same as dynamic, but `wallcolors.py --hue` regenerates colors.json from the user's hue/sat/dark choices instead of a wallpaper |

**⚠️ Divergence note:** The project-wide Flags defaults to `"dynamic"`, the pill-local Flags defaults to `"static"`. They also read from **different state files** (`quickshell/flags.json` vs `yemi-shell/flags.json`). This means the bar and pill can technically disagree on palette mode if the two files diverge. The pill's Appearance surface writes to its own Flags, so changes there only propagate within the pill's module scope.

---

## Layer 6 — The Consumers

### Pill components (use pill-local `Theme`)

Every pill surface reads `Theme.xxx` directly — the pill's `qmldir` registers its own `Theme` singleton, so `import "Singletons"` resolves to the pill's copy:

- [`modules/pill/Pill.qml`](modules/pill/Pill.qml) — `Theme.cardTop`, `Theme.cardBot`, `Theme.border`, `Theme.flameInk`, `Theme.vermLit`
- [`modules/pill/Link.qml`](modules/pill/Link.qml) — `Theme.flameGlow`, `Theme.verm`, `Theme.cream`, `Theme.hair`
- [`modules/pill/Mixer.qml`](modules/pill/Mixer.qml) — `Theme.frameBg`, `Theme.frameBorder`, `Theme.cream`
- [`modules/pill/Toast.qml`](modules/pill/Toast.qml) — `Theme.tileBg`, `Theme.vermLit`, `Theme.flameGlow`
- [`modules/pill/Wallpaper.qml`](modules/pill/Wallpaper.qml) — `Theme.ghost`, `Theme.tileBg`, `Theme.vermBurn`
- [`modules/pill/Power.qml`](modules/pill/Power.qml) — `Theme.verm`, `Theme.vermLit`, `Theme.flameCore`
- [`modules/pill/Recorder.qml`](modules/pill/Recorder.qml) — `Theme.verm`, `Theme.vermLit`, `Theme.cardBot`
- [`modules/pill/Appearance.qml`](modules/pill/Appearance.qml) — the palette mode UI itself, writes to `Flags.paletteMode`
- …and every other surface

### Bar components (use project-wide `Theme` via `Appearance`)

[`config/Appearance.qml`](config/Appearance.qml) wraps project-wide `QsSingletons.Theme` into semantic tokens:

```qml
readonly property var colors: ({
    colPrimary: QsSingletons.Theme.onGlow,
    colSecondary: QsSingletons.Theme.verm,
    colBackgroundSurfaceContainer: Qt.rgba(QsSingletons.Theme.cardBot.r, ...),
    // ...
})
```

### Music panel (uses project-wide `Theme`)

[`modules/music/MusicPanel.qml`](modules/music/MusicPanel.qml) imports `../../singletons as QsTheme` and reads `QsTheme.Theme.onGlow`, `QsTheme.Theme.cardBot`, etc.

---

## The Full Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER ACTION                               │
│  Pick wallpaper  ·  Press random  ·  Drag hue strip            │
└──────────┬──────────────────────────────────┬───────────────────┘
           │                                  │
           ▼                                  ▼
    wallpaper.sh set <path>           Appearance.qml
    wallpaper.sh random               Flags.paletteMode = "manual"
           │                                  │
           ▼                                  ▼
    after-wall.sh                     paletteProc / dynamicProc
    │  runs wallcolors.py             │  runs wallcolors.py
    │  with wallpaper path            │  with --hue <h> <mode> <sat>
    ▼                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     wallcolors.py                                │
│                                                                  │
│  1. ImageMagick histogram → dominant hue + mean lightness        │
│     (or --hue args bypass analysis)                              │
│  2. HSL math: surface ramp + accent ramp + text ramp             │
│  3. matugen → base16 for terminal/Hyprland                      │
│                                                                  │
│  OUTPUTS:                                                        │
│  → ~/.cache/yemi-shell/colors.json        (pill + bar live colors) │
│  → ~/.cache/yemi-shell/hypr-colors.lua    (Hyprland border colors)  │
│  → ~/.cache/yemi-shell/ghostty-colors     (terminal palette)        │
└──────────┬──────────────────────────────────────────────────────┘
           │
           │  file write event
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Dyn.qml (×2 copies)                                            │
│  FileView { watchChanges: true } → JsonAdapter reloads          │
│  Properties update: surface, primary, cream, bright, …          │
└──────────┬──────────────────────────────────────────────────────┘
           │
           │  property bindings
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Theme.qml (×2 copies)                                          │
│  dyn = (Flags.paletteMode !== "static")                         │
│                                                                  │
│  Each token: dyn ? Dyn.xxx : "#curated-hex"                     │
│  Veils: Qt.alpha(cream, 0.13) — always relative to cream        │
│  Shadow: fixed Qt.rgba(0,0,0,0.55)                              │
│  Font: fixed "Inter" / "Zen Kaku Gothic New"                    │
└──────────┬──────────────────────────────────────────────────────┘
           │
           │  every bound property cascades
           ▼
┌─────────────────────────────────────────────────────────────────┐
│  ALL QML COMPONENTS                                              │
│  Pill · Link · Mixer · Toast · Power · Recorder · Wallpaper    │
│  Bar · MusicPanel · OSD · Calendar · Keybinds · Clipboard · …  │
│                                                                  │
│  Colors update INSTANTLY — no restart, no reload needed          │
└─────────────────────────────────────────────────────────────────┘
```

---

## The Old Ricelin Pill (`.Ricelin/`) — What Changed

The `.Ricelin/configs/quickshell/pill/` was the original standalone pill. Key differences:

| Aspect | Old Ricelin Pill | New Unified Project |
|---|---|---|
| **Theme.qml** | Hardcoded hex only, no `Dyn` branch | Ternary: `dyn ? Dyn.xxx : "#hex"` |
| **Dyn.qml** | Didn't exist | New — file watcher bridge |
| **Flags.qml** | Reads `~/.local/state/yemi-shell/flags.json` | Pill-local: same path; Project-wide: `~/.local/state/quickshell/flags.json` |
| **paletteMode default** | `"static"` (pill), `"dynamic"` (project) | Same split still exists |
| **wallcolors.py** | Same script, same output | Identical copy in `scripts/` |
| **Look.qml** | Decoration editor (gaps, blur, opacity) | Replaced by `Appearance.qml` (palette + scale + motion) |
| **Sidebar/Topbar/Lock Theme** | Each had its own hardcoded Theme.qml | Merged into project-wide `singletons/Theme.qml` |

The old pill's sidebar, topbar, and lock each had their own `Theme.qml` with hardcoded washi hex and no dynamic path. The unified project replaced all of those with a single `Theme.qml` that conditionally reads from `Dyn`.

---

## Color Mode Toggle Script

[`scripts/toggle-colormode.sh`](scripts/toggle-colormode.sh) — cycles `auto → dark → light → auto` in `state/colormode`, then re-runs `wal` (pywal, not wallcolors.py). This is a **separate system** from the pill's `Flags.paletteMode` — it controls pywal/terminal theming, not the pill's live Dyn pipeline. The two can diverge.

---

## Key Architectural Insight

The whole system is **file-driven reactive**:

1. **Python writes a file** (`wallcolors.py` → `colors.json`)
2. **QML watches the file** (`Dyn.qml` → `FileView.watchChanges`)
3. **Bindings cascade automatically** (`Dyn` → `Theme` → every component)

No IPC, no DBus, no socket. Just `inotify` on a JSON file. This is why wallpaper changes feel instant — the moment Python finishes writing, the QML engine picks up the file change and every bound property re-evaluates in the same frame.

The trade-off: two copies of `Dyn.qml` and `Theme.qml` exist (project-wide + pill-local) because QML singleton scoping is per-module. The pill's `import "Singletons"` resolves to its own copies, while the bar and music panel import from the project-wide `singletons/`. They read the **same** `colors.json`, so they stay in sync — but if the two `Flags.qml` copies disagree on `paletteMode`, one could be static while the other is dynamic.
