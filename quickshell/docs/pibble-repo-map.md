# pibble Repository Structure Map

> **Source repo:** `/home/yemi/pibble` (git: `kianblakley/pibble`, branch `dev`)
> **Purpose:** A desktop shell for wlr-layer-shell Wayland compositors (Niri, Hyprland, Sway, Wayfire, labwc)
> **Built on:** Quickshell + Qt 6.10 QML
> **Entry point:** `shell.qml`
> **IPC script:** `./pibble` (bash daemon controller)
> **Documented:** 2026-08-14

---

## Overview

pibble is a complete desktop shell replacement written in QML for the Quickshell
framework. It provides an app launcher, notification flyout, volume OSD, clipboard
history, wallpaper selection, power menu, dynamic theming (matugen), and a
custom-page system. It is **acyclic**: directories only point inward.

**Layer flow (data dependency):**

```
launcher/  +  flyouts/  →   ui/   →   services/   →   config/
                           (controls)  (data)       (stores/singletons)
```

---

## Full Directory Map (ASCII Art)

```
pibble/
├── pibble                     ◄── Bash IPC script (start/stop/toggle/replay/help)
├── shell.qml                  ◄── ShellRoot: wiring entry. 4 windows + IPC + stores
├── README.md
├── LICENSE
│
├── config/                    ◄── Persisted settings & schema (acyclic leaf)
│   ├── Settings.qml           ◄── Default settings object (what the UI edits)
│   ├── SettingsSchema.qml     ◄── Schema definition (typed keys, defaults, types)
│   ├── Defaults.qml           ◄── Factory defaults (reset target)
│   ├── SettingsStore.qml      ◄── FileView binding settings.json ←→ Settings singleton
│   ├── LaunchCountsStore.qml  ◄── FileView binding launch-counts.json ←→ app launch counts
│   └── NotifCacheStore.qml    ◄── FileView binding notif-cache.json ←→ notification history
│
├── services/                  ◄── Data sources. Everything that reads external state
│   ├── Theme.qml              ◄── Color tokens (31 tokens, Material 3), matugen integration
│   ├── Apps.qml               ◄── App list scan + .desktop parsing + icon resolution
│   ├── Clipboard.qml          ◄── cliphist history integration
│   ├── Icons.qml              ◄── Icon webfont (Material Symbols) — single font, no theme deps
│   ├── Notifier.qml           ◄── Notification proxy + replay cache
│   ├── Wallpapers.qml         ◄── Wallpaper scan + blur-variants + live-preview pools
│   ├── Weather.qml            ◄── Weather data (HTTP fetch)
│   ├── Battery.qml            ◄── UPower / battery
│   ├── Format.qml             ◄── Time/number formatting helpers
│   ├── NotifCache.qml         ◄── Notification cache read model
│   └── ActiveOutput.qml       ◄── Active output / monitor tracking
│
├── flyouts/                   ◄── Top-level wlr-layer-shell surfaces (OSDs)
│   ├── VolumeOsd.qml          ◄── Volume mute/change on-screen display
│   └── NotificationFlyout.qml ◄── Notification history flyout (grouped, expandable)
│
├── launcher/                  ◄── Launcher window (the big overlay)
│   ├── LauncherWindow.qml     ◄── The wlr-layer-shell window itself (namespaces, blur rules)
│   ├── LauncherState.qml      ◄── Pane state machine (open/close/resolve/target page)
│   ├── AppsPage.qml           ◄── App drawer
│   ├── ClipboardPage.qml      ◄── cliphist clips pane
│   ├── ClockPage.qml          ◄── Clock + weather + battery
│   ├── PowerOverlay.qml       ◄── Power/reboot menu
│   ├── WallpaperCarousel.qml  ◄── Wallpaper picker (grid + live previews)
│   ├── WallpaperGrid.qml      ◄── Wallpaper grid tiles
│   ├── WallpaperVideoPool.qml ◄── Live wallpaper preview pool (qtmultimedia)
│   ├── ClipExpandCard.qml     ◄── Expanded clipboard item card
│   ├── Settings/              ◄── In-shell settings UI (subdirectory)
│   │   ├── SettingsPane.qml    ◄── Settings container
│   │   ├── GeneralTab.qml      ◄── General settings tab
│   │   ├── FlyoutsTab.qml      ◄── Flyout settings tab
│   │   ├── NavigationTab.qml   ◄── Navigation/gesture settings tab
│   │   ├── PagesTab.qml        ◄── Custom pages management tab
│   │   └── PageList.qml        ◄── Custom page list delegate
│   └── CustomPageHost.qml     ◄── Host that loads user custom pages (main.qml per dir)
│
├── ui/                        ◄── Reusable controls (shared between launcher + settings pages)
│   ├── SettingRow.qml         ◄── Key/value settings row
│   ├── SettingLabel.qml       ◄── Label control
│   ├── SettingHint.qml        ◄── Hint text
│   ├── SettingValue.qml       ◄── Value display
│   ├── Metrics.qml            ◄── Layout metric constants
│   ├── ThemeRow.qml           ◄── Theme selector row
│   ├── ThemeRow.qml
│   ├── KeyCap.qml             ◄── Keycap glyph display
│   ├── KeyPlus.qml            ◄── "+" key composite
│   ├── StepperButton.qml      ◄── +/- stepper control
│   ├── ResetButton.qml        ◄── Reset-to-defaults button
│   ├── ColorPickerRow.qml     ◄── Color picker control
│   ├── GridSizePicker.qml     ◄── Grid size selector
│   ├── ChipRow.qml            ◄── Chip/group selector row
│   ├── PageContext.qml        ◄── Page context object (used by custom pages)
│   └── ...                    ◄── (additional small UI helpers)
│
├── custom-pages/              ◄── User custom page examples/template
│   ├── calendar.example/      ◄── Example: calendar custom page
│   │   ├── main.qml
│   │   └── Settings.qml
│   └── put_custom_pages_here  ◄── Placeholder file (instructs user)
│
├── fonts/                     ◄── Vendored icon font
│   ├── MaterialSymbolsSharp_48pt-SemiBold.ttf
│   └── MATERIAL-SYMBOLS-LICENSE
│
├── startup/                   ◄── Invisible surfaces that only exist to boot/measure
│   └── XrayScaleProbe.qml     ◄── Client-side "xray" blur probe (measures output for blur)
│
└── .git/                      ◄── Git repo (dev branch)
```

---

## Architecture Summary

### Entry Points

| File | Role |
|------|------|
| `shell.qml` | **Root.** Declares `ShellRoot`, instantiates the 3 persisted stores (`SettingsStore`, `NotifCacheStore`, `LaunchCountsStore`), puts up 4 windows (`LauncherWindow`, `VolumeOsd`, `NotificationFlyout`, `XrayScaleProbe`), and exposes the IPC handlers (`launcher.toggle`, `launcher.open`, `launcher.close`, `replay`). |
| `pibble` (bash) | **IPC wrapper script.** Commands: `start`, `stop`, `restart`, `toggle [page]`, `replay`, `help`. Reads persisted settings to export `QS_ICON_THEME` / font env vars before spawning the daemon. |
| `config/Settings.qml` | The settings object — every default and key the UI knows about lives here. |
| `config/SettingsSchema.qml` | Typed schema (key → type → default). The settings UI iterates this. |

### Layer Dependency (acyclic)

```
┌────────────┐  ┌───────────┐
│ launcher/  │  │ flyouts/  │   ← Top-level wlr-layer-shell surfaces
└──────┬─────┘  └─────┬─────┘
       │              │
       ▼              │
┌────────┴────────────┴─────┐       ┌──────────┐
│         ui/              │  ──►   │ services/ │  ──►  config/
│  (reusable controls)      │        │  (data)   │       (stores)
└──────────────────────────┘
```

- `services/` reads external state (theme, apps, clipboard, wallpaper, weather, battery)
- `ui/` provides controls used by both the launcher settings pages and custom pages
- `config/` holds the persisted stores (terminal leaves of the dependency graph)
- `launcher/` and `flyouts/` are the top-level surfaces that import down through `ui/`

### Persisted State Files

| File | Managed by | Purpose |
|------|-----------|---------|
| `settings.json` | `SettingsStore.qml` | User settings (layout, animations, theming, keybindings, etc.) |
| `launch-counts.json` | `LaunchCountsStore.qml` | App launch frequency (for sorting/frecency) |
| `notif-cache.json` | `NotifCacheStore.qml` | Cached notifications (for replay) |

### Custom Page Contract

A custom page is a directory under `custom-pages/` containing a `main.qml`.
The page is loaded by `CustomPageHost.qml`, which gives it access to shared
controls from `ui/` and data from `services/`. Settings for the page go in
`Settings.qml` within the same directory. See `calendar.example/` for a
reference implementation.

### IPC Surface Names

Each wlr-layer-shell window declares a namespace (see README.md in the repo for
the full table) so the compositor can apply per-surface rules (blur, margins,
layer, etc.) independently:

- `launcher` (LauncherWindow)
- `pibble-notif` (NotificationFlyout)
- `pibble-volume` (VolumeOsd)
- `pibble-xray` (XrayScaleProbe)

### Dependencies

**Required:**
- Wayland compositor (Niri / Hyprland / Sway / Wayfire / labwc)
- Quickshell

**Optional (full feature set):**
- matugen — wallpaper-derived color theme
- ImageMagick — static wallpaper/clipboard thumbnails
- ffmpeg — live wallpaper thumbnails
- qtmultimedia — live wallpaper previews
- awww — recommended wallpaper backend
- cliphist — clipboard history
- gsettings (GNOME) — fallback icon theme detection

---

## File Count Breakdown

```
Total tracked files: 53
├── QML:        50
├── Shell:       1  (pibble)
├── Markdown:    1  (README.md)
├── Font:        1  (MaterialSymbolsSharp)
└── License:      1  (LICENSE)
```

---

## Live Wallpaper Preview System

pibble supports three wallpaper media types, each handled differently to keep
navigation at 60fps:

### Media Types

| Type | Source file | Still frame | Animation mechanism |
|------|------------|-------------|-------------------|
| Static image | `.jpg`, `.png`, `.webp` | The file itself | None |
| GIF | `.gif` | Frame 0 (via `Image`) | `AnimatedImage` (QtQuick) — plays from source file |
| Video | `.mp4`, `.webm` | ffmpeg frame 0 → `.webp` thumb | `MediaPlayer` (`QtMultimedia`) — pooled + shared |

The scan (in `services/Wallpapers.qml`) detects `.gif` and `.video` flags per
entry and generates a static `.webp` thumbnail for every wallpaper via ffmpeg,
used as the still frame in all three views.

### The Problem (70–700ms GUI stalls)

Opening a `MediaPlayer` source on the Qt GUI thread costs:
- **~650ms** — first open in a process (backend init)
- **~80ms** — every open after that

Both selectors used to pay this cost synchronously during navigation:
- **Carousel** (`WallpaperCarousel.qml`) — built a player as the selection
  landed on a video tile and tore it down (~65ms more) as it left
- **Grid** (`WallpaperGrid.qml`) — kept one player but re-pointed its source at
  each video it reached

Result: every move on or off a video blocked the GUI thread for 70–700ms,
freezing the slide animation it landed in.

### The Solution — `WallpaperVideoPool` (pooled + shared)

`launcher/WallpaperVideoPool.qml` owns **every** video player for the lifetime
of the shell:

```
WallpaperVideoPool {               ◄── One Item, holds ALL video players
  property string current          ◄── Which video's surface is visible
  property bool live               ◄── Whether current is playing
  property bool warming            ◄── Warm-up pass (off-screen opens)
  property var openPaths: []        ◄── Append-only: paths with players
  property int openCount            ◄── Repeater model (bumps on append only)

  Timer {                          ◄── Warm pass: 1 file per 250ms tick
    running: warming && openCount < videoPaths.length
    onTriggered: root.open(next unopened path)
  }

  Repeater { model: openCount       ◄── One VideoOutput + MediaPlayer per video
    VideoOutput {                    ◄── Surface (visible only if showing==current)
      readonly property string path   ◄── Fixed at delegate creation
      readonly property bool showing  ◄── current === path
      MediaPlayer { source: "file://" + path   ◄── Never re-sourced
                    loops: Infinite; audioOutput.muted: true }
    }
  }
}
```

Key design decisions:
- **Append-only**: `openPaths` is a JS array mutated in place. A `var` property
  holding a JS array does **not** notify on mutation, so each delegate's `path`
  binding never re-evaluates and its `MediaPlayer.source` is never rewritten.
  `openCount` (an `int`) is the Repeater's model — bumping it after the push is
  what actually builds the new player.
- **Never destroyed**: Players are opened once and kept open. Navigation only
  moves `current` and toggles `live`, both of which measured as zero stall.
- **Warm pass**: While the wallpaper selector is **off-screen**, the pool opens
  one new file every 250ms. First-open cost (~650ms) lands in the warm pass,
  never in a slide. `Settings.preload` gates this — disabling it saves ~150MiB
  per held video but reintroduces the first-visit freeze.
- **Frame synchronization**: Pooled players are paused on frame 0 (the same
  frame the static thumbnail shows). `sync()` rewinds to 0 and plays when the
  surface becomes active; pauses otherwise. Seeking/pausing/starting an already-
  open player are free — only the open itself is expensive.

### How each selector uses the pool

#### Grid (`WallpaperGrid.qml`)

```
Grid {                        ◄── Paged grid of thumbnail tiles
  Repeater { model: pageSize
    Item {                      ◄── Each tile
      Image { source: thumb }    ◄── Still frame (480x270 target)
      AnimatedImage {            ◄── Only SELECTED tile plays .gif
        source: isSelected ? wall.path : "" }
    }
  }

  Item {                      ◄── One shared video surface OVER the selected tile
    x/y/w/h: derived from selSlot   ◄── Positioned to cover the selected tile
    WallpaperVideoPool {         ◄── Receives the pool
      current: selWall?.path        ◄── Points pool at selected video
      live: videoShowing              ◄── True only when selector is up + on walls pane }
  }
}
```

- Each tile shows a 480×270 static thumbnail (`Image`) at all times
- Only the **selected** tile swaps its `Image` for an `AnimatedImage` (for GIFs)
- **Video** is never played per-cell. The single shared surface is positioned
  exactly over the selected tile and overlays it, drawing from the pooled player
  that was already opened during warmup.

#### Carousel (`WallpaperCarousel.qml`)

```
Item {                        ◄── Infinite horizontal strip of parallax windows
  Repeater { model: totalSlots       ◄── Fixed count (recycled, not paged)
    Item {                          ◄── Each window (cell)
      Image { source: shownWall.thumb } ◄── Still frame, wider than bar + panned by rank
      AnimatedImage {               ◄── Center window ONLY plays .gif
        visible: gifAnimating }
    }
  }

  Item {                      ◄── One shared video surface that RIDES the center slot
    WallpaperVideoPool {            ◄── Pool configured per-selector
      current: root.videoSource      ◄── Handed off from centerWall.path
      live: root.videoShowing        ◄── True only during active navigation + on walls pane }

  Text {                      ◄── Caption (updates live during drag)
    text: wallpaperName(wallpaperMatches[carouselAnim.round()]) }
}
```

The carousel is more complex because the video surface must:
- **Ride a slide** — it takes the selected cell's placement, scale, stacking,
  and parallax so it moves with the cell through the slide animation
- **Persist through handover** — `videoSource` is "sticky": navigating off a
  video leaves the surface showing that (now paused) file while it fades out
  with its cell, rather than blanking mid-slide
- **Handle rank tracking** — `videoAbsStep` tracks which cell the player belongs
  to (not `carouselStep`, which jumps to the destination instantly on
  video-to-video handovers). Both are rebalanced mod `totalSlots` to prevent
  stale players from drifting off-screen forever and wrapping back into view.

### GIF handling

GIFs are simpler — no pool needed. `AnimatedImage` (not `MediaPlayer`) plays
them directly from the source file. Only the cell at or near center plays;
others keep the static frame. The `AnimatedImage` is sized to exactly match
the still `Image`'s box (including parallax offset) so the handover mid-slide
doesn't jump.

### Entrance synchronization

The shared video surface has no entrance spring of its own (it sits over the
tile/cell that does). To prevent it from appearing at full opacity before its
underlying cell has finished its spring-in animation:
- **Grid**: a `settle` timer waits for the selected tile's stagger + spring
  to complete before enabling `videoShowing`
- **Carousel**: an `entranceSettle` timer runs for the center cell's stagger +
  spring duration, delaying `entranceDone` and thus `videoShowing`

---

## Related: yemi-shell (this config)

This pibble repo is referenced by the local Quickshell config at
`/home/yemi/.config/quickshell`. In particular, yemi-shell's `shell.qml` has
**read-only** imports of pibble's `AltSwitcher` (lines 27-28):

```
import "root:/altSwitcher"   ◄── READS from ~/YEMI-SHELL, directory not bundled
```

The `altSwitcher/` directory does **not** exist inside the pibble repo — it is
a separate yemi-shell component that pibble consumers are expected to vendor
themselves. See `AUDIT-2026-08-13.md` §4 for details.
