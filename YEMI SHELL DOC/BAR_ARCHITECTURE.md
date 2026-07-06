# Top Bar Architecture

> Reference documentation for the Quickshell bar system — a three-window architecture (Bar + Reserve + Overlay) with a morphing center pill. This document covers the top-level bar components: `BarWrapper.qml`, `Bar.qml`, `PillOverlay.qml`, and `Pill.qml`.

---

## 1. Component Overview

The Quickshell bar is a Wayland shell bar that renders one instance per monitor. It is split across three PanelWindows per screen to solve a fundamental Wayland constraint: a single window cannot simultaneously claim an exclusive zone (so tiled windows avoid the bar) and render above other windows (so the morphing pill can float over fullscreen content).

The system is composed of four key QML components:

- **BarWrapper.qml** — A `Scope` containing a `Variants` model (one entry per `Quickshell.screens`) that creates one `PanelWindow` per screen and loads `Bar.qml` inside it. Acts as the bar window factory.
- **Bar.qml** — The visual bar: a transparent `Item` containing three pill groups (left workspaces, center spacer, right connectivity/audio/power pills). Each pill is a `Rectangle` with frosted-glass styling. Loaded synchronously (`asynchronous: false`) to avoid visual flash during startup.
- **PillOverlay.qml** — An `Item` that creates two `PanelWindow`s per screen: a **Reserve** window (claims the top exclusive zone) and an **Overlay** window (holds the morphing center pill with dynamic input masking).
- **Pill.qml** — The morphing center pill. A single `Item` (1677 lines) that carries every visual state. Width and height are driven by a `mode` property that resolves to a target size. Morphing uses `Motion.morph` duration with `Motion.morphCurve` (no-overshoot bezier). Surfaces are stacked absolutely and cross-fade via `morphCloseness`.

The center pill is part of the top bar — it sits in the same horizontal position as the bar's center spacer and is vertically aligned with the bar pills. It is rendered in a separate overlay window so it can float above the bar and fullscreen content.

---

## 2. Project Structure and Dependencies

### File Layout

| File | Role |
|------|------|
| `shell.qml` | ShellRoot — loads BarWrapper and PillOverlay per screen |
| `modules/bar/BarWrapper.qml` | Bar window factory (Scope + Variants + PanelWindow) |
| `modules/bar/Bar.qml` | Visual bar content (left/center/right pills) |
| `modules/bar/components/Workspaces.qml` | Workspace indicator row (Repeater of 9 Workspace delegates) |
| `modules/bar/components/Workspace.qml` | Single workspace dot/indicator |
| `modules/bar/components/Network.qml` | WiFi icon + SSID label |
| `modules/bar/components/Bluetooth.qml` | Bluetooth icon |
| `modules/bar/components/Brightness.qml` | Brightness icon + level |
| `modules/bar/components/Volume.qml` | Volume icon + level |
| `modules/bar/components/Battery.qml` | Battery icon + percentage |
| `modules/bar/components/StatusIndicators.qml` | Caffeine + DND indicators |
| `modules/bar/components/SystemTray.qml` | System tray (disabled — source commented out) |
| `modules/pill/PillOverlay.qml` | Reserve + Overlay window factory |
| `modules/pill/Pill.qml` | Morphing center pill (21 surfaces + overlays) |
| `modules/pill/Ame.qml` | Filament animation overlay (molten-glass bead) |
| `modules/pill/*.qml` | Individual surface components (Calendar, Mixer, Launcher, etc.) |

### Imports

All bar components import from these Qt Quick and project modules:

- `QtQuick 6.10` — base QML types (Item, Rectangle, Row, Loader, etc.)
- `QtQuick.Layouts 6.10` — RowLayout for workspace content
- `QtQuick.Effects` — visual effects
- `Quickshell` — ShellRoot, Variants, IpcHandler, Process
- `Quickshell.Wayland` — PanelWindow, WlrLayershell, WlrLayer
- `Quickshell.Hyprland` — Hyprland compositor integration
- `Quickshell.Io` — IpcHandler
- `Quickshell.Services.Mpris` — Mpris media player detection
- `Quickshell.Networking` — Networking device detection
- `../../config` as `QsConfig` — Config, BarConfig, AppearanceConfig
- `../../services` as `QsServices` — Notifs, Matugen, Audio, Brightness, Network, Bluetooth, etc.
- `../../singletons` as `QsSingletons` — Theme, Flags, PillState, Dyn, Metrics
- `../../compositor` as `QsCompositor` — Compositor (Hyprland/Niri abstraction)
- `../../components/effects` — Material3Anim
- `Singletons` (local to pill) — Battery, Cliphist, Devices, Events, Motion, Notifs, ScreenRec, Sysmon, Walls, Weather, Workspacerules

### Module Registration

Components are loaded via relative `source` paths from `Bar.qml` (e.g. `source: "components/Network.qml"`). The `modules/bar/qmldir` and `modules/pill/Singletons/qmldir` files register the module structure. No CMake targets are used — Quickshell resolves imports at runtime.

---

## 3. Component Hierarchy and Role

### BarWrapper.qml

Root type: `Scope`

Contains a `Variants { model: Quickshell.screens }` block. For each screen, creates a `PanelWindow` anchored to the top, left, and right edges with `implicitHeight: config.bar.height`. The window is transparent and uses `WlrLayer.Top` with `exclusionMode: Ignore` — it does not claim an exclusive zone itself (the Reserve window handles that).

Inside each PanelWindow, a `Loader` loads `Bar.qml` and injects `screen` and `barWindow` bindings once the loader is ready via `Qt.binding()` with `restoreMode: Binding.RestoreBinding`.

### Bar.qml

Root type: `Item`

The visual bar container. Defines a scale factor `s = (screen.height / 1080) * Flags.uiScale` that all child dimensions multiply by. Contains three horizontal sections inside `barContainer`:

- **leftPills** (`Row`) — Contains the workspace pill: a `Rectangle` with frosted-glass styling that loads `Workspaces.qml` via a `Loader` (`asynchronous: false`). The workspace pill shows 9 workspace indicators (active, occupied, empty states).
- **centerContainer** (`Item`) — A fixed 160×38*s spacer that reserves horizontal space matching the pill's rest dimensions. The actual center pill lives in the overlay window.
- **rightPills** (`Row`) — Contains three pill `Rectangle`s:
  - **connectivityPill** — Network icon + SSID + separator + Bluetooth icon
  - **audioPill** — Brightness icon + separator + Volume icon
  - **powerPill** — StatusIndicators (caffeine/DND) + separator + Battery + separator + SystemTray (disabled)

Each right pill has the same visual anatomy: 28*s height, 14*s radius, `pillBg` color (cardBot @ 0.7 alpha), 1px `pillBorder` (cream @ 0.10 alpha), and a top highlight gradient (4% white → transparent). Width animations use 250ms OutCubic.

### PillOverlay.qml

Root type: `Item`

Creates two `PanelWindow`s per screen:

**Reserve Window** (`WlrLayer.Top`, `exclusionMode: Ignore`, `aboveWindows: true`):
- Anchored top, left, right. Height = `restH + topGap` where `restH = QsSingletons.Metrics.restHBase * s` and `topGap = (barHeight - restH) / 2`.
- Has a zero-size `Region` mask (`Region { width: 0; height: 0 }`) — no interactive content, purely claims the top strip so tiled windows sit below the pill's resting position.
- `s` is computed as `(modelData.height / 1080) * QsSingletons.Flags.uiScale`.

**Overlay Window** (`WlrLayer.Overlay`):
- Full-screen anchored, with `margins.top: 8 * s` (the `overlayTopOffset`).
- `keyboardFocus`: `WlrKeyboardFocus.Exclusive` when a surface is open, `WlrKeyboardFocus.OnDemand` otherwise.
- Has a dynamic `mask` property that switches between three `Region` objects:
  - `hiddenRegion` (empty) — click-through when fullscreen
  - `fullRegion` (full window) — captures all input when a surface is open
  - `pillRegion` (pill-shaped) — click-through outside the pill when resting
- `pillRegion` geometry: `baseW = max(pill.width, pill.targetW)`, `x = pill.x + (pill.width - baseW) / 2`, `y = pill.y - pill.inputPadTop`, `width = baseW + pill.inputPadRight`, `height = max(pill.height, pill.targetH) + pill.inputPadTop`.
- Detects fullscreen state via Hyprland events (`hyprctl activeworkspace -j`) or Niri IPC polling (`niri msg -j windows`, 500ms `Timer`).
- Contains the `Pill` instance and a backdrop `MouseArea` for click-outside-to-close.

**Coordinate alignment**: The overlay window has `margins.top: 8*s`, which shifts its entire coordinate system 8px lower than the Bar window. The `topGap` property compensates: `(barHeight - restH) / 2 - overlayTopOffset`, so the pill's absolute screen position lines up with the bar's centerline.

### Pill.qml

Root type: `Item` (1677 lines)

The morphing center pill. A single element that carries every visual state. Width and height are bound directly to `targetW` and `targetH` (not animated directly — `Behavior` objects handle the morph animation). The `mode` property resolves to a string that determines the target size.

**Mode state machine:**
```
surfaceOpen → surfaces[name] applied
!surfaceOpen → quickChoosing → quickCount → osdActive → toastActive → expanded → rest
```

The `mode` property is computed via a ternary chain:
```qml
surfaceOpen && surfaces[surface] !== undefined ? surface
: (quickChoosing ? "quickChoose"
: (quickCounting ? "quickCount"
: (osdActive && !held ? "osd"
: (toastActive && !held ? "toast"
: (expanded ? "hover" : "rest")))))
```

- **rest** — Shows the 時 kanji glyph + current time (HH:mm). Size: 160×restH (restH = Metrics.restHBase * s).
- **hover** — Shows workspace dots, clock with date, weather, minimized tray, system tray, DND indicator, WiFi, battery, inbox, mixer, sysmon, recorder, settings, and power icons. Size: hoverW×58*s.
- **surface** — One of 21 surface components (calendar, launcher, clipboard, wallpaper, power, media, mixer, link, bluetooth, battery, settings, keybinds, recorder, sysmon, appearance, updates, display, input, look, idlelock, fontpicker). Each surface has its own target dimensions defined in the `surfaces` descriptor.
- **overlays** — osd (brightness/volume sliders), toast (notification), quickChoose (screen/window recorder chooser), quickCount (pre-roll countdown). These morph in place without a surface entry.

**morphCloseness**: A computed property that measures how settled the pill is into its target geometry:
```qml
readonly property real morphCloseness: {
  const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH));
  return 1 - Math.min(1, d / (110 * s));
}
```
Content opacities key off this value (not their own timers), so a surface fades in as the pill reaches full size.

**hoverSoulGate**: Gates the soul bead until the hover morph has arrived (`morphCloseness > 0.55`) and its icons exist. Latched so small width changes inside hover don't flicker the bead. A 300ms grace timer (`graceTimer`) prevents flicker during morph transitions — it only clears `hoverLatch` when `morphCloseness > 0.95`.

**Media bud**: A circular `Rectangle` (id: `bud`) that appears at the pill's right edge when `mode === "hover"` and `hasMedia` (Mpris has active players). Contains a `Canvas` (id: `budBead`) drawing a radial gradient bead (flameInk → vermLit → verm → flameEmber). Clicking opens the "media" surface. `inputPadRight` extends the window mask to cover the bud's outer half.

**Body styling**: The pill body is a `Rectangle` (id: `body`) with `radius: morphRadius`, `color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.55)`, `border.width: 1`, `border.color: Qt.rgba(Theme.cream.r, Theme.cream.g, Theme.cream.b, 0.10)`. A top highlight gradient (white @ 4% → transparent) matches the bar pills.

**Ame filament**: An `Ame` instance (id: `ame`) that renders a glowing bead tracking the soul target. Bindings:
- `ame.s` = `pill.s`
- `ame.heat` = `pill.powerOpen ? power.holdProgress : 0`
- `ame.wake` = `pill.wakePoint` (rest kanji centre)
- `ame.wickDir` = `pill.powerOpen ? 1 : -1`
- `ame.form` = `pill.ameSurface.ameForm` or `"soul"` (hover) or `"off"` (rest)
- `ame.point` = `pill.ameSurface.amePoint` or `pill.soulPoint` or `pill.wakePoint`

### Ame.qml

Root type: `Item` (576 lines)

The molten-glass bead animation. Uses a `Canvas` with `FrameAnimation` for full-rate repaint during active motion, and a `Timer` at 12fps (30fps while caret blinks) for idle swirl to keep 24/7 shell cost low.

**Forms** (drawn on Canvas):
- `"rest"` — breathing bead (2.5% scale over ~8s via `canvas.breathe`)
- `"caret"` — blinking launcher capsule
- `"seam"` — media bead
- `"ring"` — calendar ring
- `"dock"` — plain bead (mixer/power/link), scales with `heatScale`
- `"tick"` — flattened bead
- `"rowseam"` — vertical capsule
- `"soul"` — hover bead with wick line
- `"off"` — hidden (opacity 0)

**Motion system**:
- `startFlight(targetForm, quick)` — full shapeshift: anticipation stretch → remnant droplet → quadratic-bezier flight with tapered streak → three-droplet landing splash → easeOutBack settle. Duration: `quick ? 460ms : Motion.shapeshift`. Flight tracks moving target live (bezier endpoint, control point, and heading recomputed per frame via `updateFlightGeo()`).
- `startMorph(targetForm)` — in-place transform: skips travel, replays only settle window (splash + easeOutBack pop) for nearby form changes.
- `startGlide(target)` — same-form target moves (hover width, seam progress, mixer focus hops) glide over `Motion.glide` ms.
- `appear()` — wake from hidden state: condenses at wake anchor, then flies or pops in place.
- `retarget()` — coalesced decision via `Qt.callLater(decide)` to avoid reading stale partner values when `form` and `point` bindings change mid-cascade.

**Flight geometry**: `updateFlightGeo()` computes `flightDist`, `flightAng`, and a perpendicular bezier control point at 22% of the distance from the midpoint. Arc side is latched in `startFlight` (`arcFlip`) to prevent mirroring when the target crosses the vertical through the origin.

**Rendering**: The `onPaint` handler draws:
- Remnant droplet at origin (if `remnant > 0`)
- Anticipation phase: bead pulled back along flight angle
- Fly phase: 15-segment tapered streak + bead at flight position
- Settle phase: 3-droplet splash + easeOutBack pop + form-specific drawing

---

## 4. Properties

### BarWrapper.qml

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `config` | `QtObject` | `QsConfig.Config` | No | Reference to the application configuration object. Read-only. |

### Bar.qml

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `screen` | `var` | `undefined` | **Yes** | The screen object this bar instance is attached to. Set by BarWrapper after loader is ready. |
| `barWindow` | `var` | `null` | **Yes** | The PanelWindow that contains this bar. Used by child components to position popups. |
| `screenName` | `string` | `""` | No | The name of the screen (e.g. "eDP-1"). Derived from `screen.name`. Read-only. |
| `s` | `real` | `1` | No | Scale factor calculated as `(screen.height / 1080) * Flags.uiScale`. Read-only. |
| `config` | `QtObject` | `QsConfig.Config` | No | Application configuration. Read-only. |
| `appearance` | `QtObject` | `QsConfig.AppearanceConfig` | No | Appearance configuration. Read-only. |
| `pillBg` | `color` | dynamic | No | Pill background color: `cardBot` at 70% opacity. Read-only. |
| `pillBorder` | `color` | dynamic | No | Pill border color: `cream` at 10% opacity. Read-only. |
| `pillSeparator` | `color` | dynamic | No | Pill separator color: `cream` at 15% opacity. Read-only. |
| `highlightTop` | `color` | `rgba(1,1,1,0.04)` | No | Top highlight gradient start color. Read-only. |

### PillOverlay.qml

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `modelData` | `var` | — | **Yes** | The screen object from the Variants model. Required property. |
| `barWindow` | `var` | `null` | No | Reference to the bar's PanelWindow, passed from shell.qml. |
| `s` | `real` | `1` | No | Scale factor: `(modelData.height / 1080) * QsSingletons.Flags.uiScale`. Read-only. |
| `restH` | `real` | `Metrics.restHBase * s` | No | Pill resting height. Read-only. |
| `barHeight` | `real` | `config.bar.height` | No | Bar height from config. Read-only. |
| `topGap` | `real` | `(barHeight - restH) / 2 - overlayTopOffset` | No | Vertical offset from overlay top to pill centerline. Read-only. |
| `overlayTopOffset` | `real` | `8 * s` | No | Overlay window's top margin. Compensated in topGap. Read-only. |
| `surface` | `string` | `""` | No | Current surface from `PillState.openMon/openSurface`. Read-only. |
| `surfaceOpen` | `bool` | `false` | No | Whether a surface is open on this monitor. Read-only. |
| `monFullscreen` | `bool` | `false` | No | Whether any window is fullscreen on this monitor. |

### Pill.qml

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `s` | `real` | `1` | No | Scale factor for DPI-aware sizing. |
| `screenName` | `string` | `""` | No | The monitor name this pill instance belongs to. |
| `barWindow` | `var` | — | No | Reference to the bar's PanelWindow for popup positioning. |
| `surface` | `string` | `""` | No | The currently open surface name (e.g. "calendar", "mixer", "settings"). Empty when no surface is open. |
| `hovered` | `bool` | `false` | No | Whether the pointer is over the pill. Set by a window-level HoverHandler. |
| `pinned` | `bool` | `false` | No | Whether the pill is pinned open by a tap. Toggled by TapHandler. |
| `forcePinned` | `bool` | `false` | No | Forces the pill into pinned state regardless of user interaction. |
| `held` | `bool` | — | No | Read-only. True when `pinned` or `forcePinned` is true. |
| `hoverLatch` | `bool` | `false` | No | Latches the hover state with a 300ms grace timer to prevent flicker during morph transitions. |
| `expanded` | `bool` | — | No | Read-only. True when `surfaceOpen`, `held`, or `hoverLatch` is true. |
| `mode` | `string` | — | No | Read-only. The current visual mode: one of `rest`, `hover`, `osd`, `toast`, `quickChoose`, `quickCount`, or a surface name. |
| `linkInitialView` | `string` | `"main"` | No | Subview the link surface should land on when next opened. Set to `"wifi"` by the WiFi icon click, `"main"` by the inbox click. Reset to `"main"` when the link surface closes. |
| `linkBtInitialView` | `string` | `"bt"` | No | Subview the bluetooth surface should land on. Always `"bt"` — the bar bluetooth pill opens straight to the device list. |
| `soulTarget` | `string` | `""` | No | The name of the last hovered icon or workspace dot. Drives the Ame bead position. Valid values: `"wifi"`, `"battery"`, `"inbox"`, `"mixer"`, `"power"`, `"settings"`, `"recorder"`, `"sysmon"`, `"ws"`. |
| `soulWsIndex` | `int` | `-1` | No | The index of the last hovered workspace dot. Used when `soulTarget` is `"ws"`. |
| `kanjiFlash` | `real` | `0` | No | Animation property for the kanji flash effect. Animates 0→1 (90ms OutCubic) → 0 (320ms OutCubic) when the soul bead first appears. |
| `morphCloseness` | `real` | — | No | Read-only. How settled the pill is into its target geometry: 0 while morphing, 1 once arrived. Content opacities key off this. |
| `hoverSoulGate` | `bool` | `false` | No | Gates the soul bead until the hover morph has arrived and its icons exist. Latched so small width changes don't flicker the bead. |
| `hoverArrived` | `bool` | — | No | Read-only. True when `mode === "hover"` and `morphCloseness > 0.55`. |
| `restW` | `real` | `160 * s` | No | Rest state width. Read-only. |
| `restH` | `real` | `QsSingletons.Metrics.restHBase * s` | No | Rest state height. Read-only. |
| `hoverPad` | `real` | `20 * s` | No | Horizontal padding added to hover row width. Read-only. |
| `hoverW` | `real` | `hoverRow.implicitWidth + 2 * hoverPad` | No | Hover state width. Read-only. |
| `hoverH` | `real` | `58 * s` | No | Hover state height. Read-only. |
| `restCorner` | `real` | `18 * s` | No | Corner radius when in rest or hover mode. Read-only. |
| `openCorner` | `real` | `22 * s` | No | Corner radius when a surface is open. Read-only. |
| `morphRadius` | `real` | — | No | Read-only. The current corner radius: `restCorner` for rest/hover, `openCorner` for surfaces. |
| `targetW` | `real` | — | No | Read-only. The target width the pill is morphing toward. |
| `targetH` | `real` | — | No | Read-only. The target height the pill is morphing toward. |
| `wakePoint` | `point` | — | No | Read-only. The rest anchor for Ame: the 時 kanji centre. |
| `soulPoint` | `point` | — | No | Read-only. The bead target while hovered. Maps `soulTarget` to the corresponding icon's position. |
| `ameSurface` | `var` | — | No | Read-only. The open surface's Ame anchor object, or null if no surface is open. |
| `inputPadRight` | `real` | — | No | Read-only. Extra input width past the pill's right edge while the media bud is visible. |
| `inputPadTop` | `real` | `2 * s` | No | Read-only. Extra input height above the pill. |
| `toastActive` | `bool` | — | No | Read-only. True when there are notification popups. |
| `osdActive` | `bool` | — | No | Read-only. True when the OSD is flashing. |
| `quickHere` | `bool` | — | No | Read-only. True when the quick-record target monitor matches this pill's screen. |
| `quickChoosing` | `bool` | — | No | Read-only. True when the quick-record source chooser is active on this monitor. |
| `quickCounting` | `bool` | — | No | Read-only. True when the pre-roll countdown is active on this monitor. |
| `hasMedia` | `bool` | — | No | Read-only. True when Mpris has active media players. |
| `keybindsListening` | `bool` | — | No | Read-only. True when the keybinds surface is open and chord capture is active. |
| `wallpaperSearching` | `bool` | — | No | Read-only. True when the wallpaper surface is open and search mode is active. |
| `surfaces` | `var` | — | No | Read-only. Descriptor object mapping surface names to their size thunks and Ame anchors. Each entry: `{ size: () => Qt.size(w, h), ame: surfaceItem }`. |
| `modeSize` | `var` | — | No | Read-only. Descriptor object for non-surface modes (osd, toast, hover, quickChoose, quickCount). Each entry: `{ modeName: () => Qt.size(w, h) }`. |

---

## 5. Signals

### Pill.qml

#### `requestSurface(string name)`

Emitted when a user clicks on a hover icon or a sub-surface navigation triggers a surface switch. The `name` parameter is the surface identifier (e.g. `"calendar"`, `"mixer"`, `"settings"`). Connected handlers call `QsSingletons.PillState.toggleSurface(monitorName, name)` to open the requested surface.

#### `requestClose()`

Emitted when the user requests to close the current surface (via Escape key, backdrop click, or surface-internal close button). Connected handlers call `QsSingletons.PillState.close()` to dismiss the surface.

---

## 6. Methods

### Pill.qml

#### `mixerStep(real deltaPct) : bool`

Forward an arrow-key nudge to the open mixer's focused fader. `deltaPct` is the percentage change (positive for up, negative for down). Returns `true` when the mixer is open and a fader consumed the step.

#### `mixerFocusMove(int dir)`

Move the open mixer's keyboard focus across the fader row. `dir` is `+1` (right) or `-1` (left). No-op unless the mixer is open.

#### `recorderStep(real deltaPct) : bool`

Forward an arrow-key nudge to the open recorder's focused audio fader. Returns `true` when the recorder is open and a revealed fader consumed it.

#### `rowNavSurface() : var`

Resolve which settings-family surface owns keyboard row navigation right now. Returns the surface item (`settings`, `appearance`) or `null` when none is open.

#### `settingsMove(int dir) : bool`

Move the focused settings row by `dir` (+1 down, -1 up), carrying the soul seam. Returns `true` when a settings-family surface is open and consumed it.

#### `settingsAdjust(int dir) : bool`

Step the focused settings row's control: a segmented choice cycles by `dir`, a toggle is set on (dir > 0) or off. Returns `true` when consumed.

#### `settingsActivate() : bool`

Activate the focused settings row: a toggle flips, a nav row opens its sub-surface. Returns `true` when a settings-family surface is open.

#### `keybindsMove(int dir)`

Slide the open keybinds list's focused row by `dir` (+1 down, -1 up). No-op unless the keybinds surface is open.

#### `keybindsActivate()`

Enter on the open keybinds surface: arm chord capture on the focused row. No-op unless the keybinds surface is open.

#### `quickChooseSource(string kind)`

A tile was picked in the standalone quick-record chooser. `kind` is `"screen"` or `"window"`. Screen with several monitors flips to the inline sub-choice; otherwise each source fires its resolver and the chooser closes.

#### `quickPickMonitor(string name)`

A monitor was picked in the quick-record multi-monitor sub-choice. Calls `ScreenRec.prepareScreen(name)` and closes the chooser.

#### `linkBack() : bool`

Pop the open link surface one subview back. Returns `true` when the step was consumed, `false` when the surface is already at its root (Escape should close the surface instead).

#### `surfaceBack()`

Step the open surface back one level when its header bar is clicked: a settings sub-surface returns to the index, the font picker to appearance, a keybinds form to its list, and any other surface dismisses to the hover pill.

#### `keybindsBack() : bool`

Pop the open keybinds editor form back to the bind list. Returns `true` when a form was open and dismissed, `false` otherwise.

#### `wallpaperMove(int dir)`

Slide the open wallpaper strip's focus by `dir` thumbs: +1 is right (older), -1 is left (newer). No-op unless the wallpaper surface is open.

#### `wallpaperActivate()`

Apply the wallpaper strip's focused thumb. The surface stays open so the pick can be iterated. No-op unless the wallpaper surface is open.

#### `wallpaperType(string ch)`

Route the first printable keystroke over the open wallpaper strip into a DuckDuckGo search seeded with that character. No-op unless the wallpaper surface is open.

#### `powerMove(int dir)`

Slide the open power surface's keyboard focus by `dir` tiles: +1 is right, -1 is left. No-op unless the power surface is open.

#### `powerPress() : bool`

Enter pressed on the open power surface's focused tile: fires a safe tile at once, latches a destructive tile's heat hold. Returns `true` when a tile consumed the key.

#### `powerRelease()`

Enter released on the open power surface: drains an unfinished destructive hold so a key let go before the fill completes never confirms.

---

## 7. Inter-Component Interactions

### Data Flow Diagram

```
Config.bar.height ──────────► PillOverlay topGap calculation
Config.bar.workspaces ──────► Workspaces count and spacing
Theme.cardBot ──────────────► pillBg color (all pills)
Theme.cream ──────────────► pillBorder, pillSeparator colors
Flags.uiScale ─────────────► s (scale factor for all dimensions)
QsSingletons.Metrics.restHBase ──► restH (pill resting height)
Compositor.activeWsId ─────► left pill workspace active state
Compositor.getOccupiedWorkspaces() ──► workspace occupied dots
PillState.openMon / openSurface ──► Pill.surface string ──► mode → target size
Mpris.players ─────────────► Pill.hasMedia ──► media bud visibility
ScreenRec.quickMon ────────► Pill.quickHere
ScreenRec.quickChoosing ───► Pill.quickChoosing
ScreenRec.counting ─────────► Pill.quickCounting
Notifs.popups ─────────────► Pill.toastActive
```

### Bar.qml → Child Components

- `screen` and `barWindow` are injected into each child `Loader` via `Binding` objects with `restoreMode: Binding.RestoreBinding`. The binding activates only when the loader status is `Loader.Ready`.
- `screenName` is injected into Network, Bluetooth, Brightness, Volume, and Battery loaders for `PillState.toggleSurface()` calls.
- Child components call `PillState.toggleSurface(screenName, surfaceName)` on click to open the center pill's surfaces.

### PillOverlay.qml → Pill.qml

- `overlay.s` is passed to `Pill.s` for consistent DPI scaling.
- `overlay.surface` (derived from `PillState.openMon` and `PillState.openSurface`) drives `Pill.surface`.
- `overlay.monFullscreen` controls `Pill.opacity` (0 when fullscreen, 200ms OutCubic) and `Pill.transform` (translate Y off-screen by `-(pill.height + overlay.topGap)`, 200ms OutCubic).
- `Pill.requestSurface()` → `PillState.toggleSurface()` → updates `PillState.openMon/openSurface` → `overlay.surface` changes → `Pill.surface` updates.
- `Pill.requestClose()` → `PillState.close()` → clears `PillState.openSurface` → pill returns to rest/hover.

### Pill.qml → Surface Components

Each surface component (Mixer, Calendar, Launcher, etc.) receives:
- `s` — scale factor
- `open` — boolean indicating whether this surface is the active one
- `morphCloseness` — for opacity/visibility gating
- `onRequestClose` — signal to close the surface

Surfaces that support sub-navigation (Settings, Appearance, Keybinds, etc.) also receive `onRequestSurface` for switching to another surface.

### Pill.qml → Ame.qml

- `ame.s` = `pill.s`
- `ame.heat` = `pill.powerOpen ? power.holdProgress : 0`
- `ame.wake` = `pill.wakePoint` (rest kanji centre)
- `ame.wickDir` = `pill.powerOpen ? 1 : -1`
- `ame.form` = `pill.ameSurface.ameForm` or `"soul"` (hover) or `"off"` (rest)
- `ame.point` = `pill.ameSurface.amePoint` or `pill.soulPoint` or `pill.wakePoint`

### Fullscreen Detection

- **Hyprland**: `Connections { target: Hyprland } onRawEvent` listens for `fullscreen`, `fullscreen1`, `fullscreen2`, `openwindow`, `closewindow`, `movewindow`, `workspace`, `workspacev2` events. Calls `overlay.updateFullscreen()` which runs `hyprctl activeworkspace -j` and checks `hasfullscreen` on the active workspace.
- **Niri**: A 500ms `Timer` polls `niri msg -j windows` and checks if the focused window's `tile_size` matches the monitor dimensions.
- When `monFullscreen` becomes `true`, `PillState.close()` is called to dismiss any open surface.
- When a surface is opened while fullscreen is already active (e.g. via keybind IPC), the `onSurfaceOpenChanged` guard immediately force-closes it via `Qt.callLater(QsSingletons.PillState.close)`.

### Popup Windows (separate from surfaces)

BarWrapper injects four popup windows into the bar components. These are **separate PanelWindows**, not morphing surfaces:

| Popup | File | Triggered By |
|-------|------|-------------|
| Bluetooth | `BluetoothPopupWindow.qml` | Bluetooth pill click |
| Network | `NetworkPopupWindow.qml` | Network pill click |
| Volume | `VolumePopupWindow.qml` | Volume pill click |
| Brightness | `BrightnessPopupWindow.qml` | Brightness pill click |

These are distinct from the Pill surfaces:
- **link surface** (Pill) → `Link.qml` / `LinkWifi.qml` — in-overlay network controls
- **bluetooth surface** (Pill) → `Link.qml` with `initialView: "bt"` — in-overlay bluetooth controls
- **mixer surface** (Pill) → `Mixer.qml` — in-overlay audio mixer

### Keyboard Navigation

| Key | Surface Open | Action |
|-----|-------------|--------|
| Escape | any | `surfaceBack()` / `linkBack()` → close |
| ↑ ↓ | mixer | `mixerStep(delta)` / `mixerFocusMove(dir)` |
| ↑ ↓ | keybinds | `keybindsMove(dir)` / `keybindsActivate()` |
| ↑ ↓ | settings/appearance | `settingsMove(dir)` / `settingsAdjust(dir)` |
| → ← | power | `powerMove(dir)` |
| Enter (down) | power | `powerPress()` → heat hold |
| Enter (up) | power | `powerRelease()` |
| → ← | wallpaper | `wallpaperMove(dir)` / `wallpaperActivate()` |
| printable | wallpaper | `wallpaperType(ch)` → search |
| Escape | link | `linkBack()` → subview pop → close |
| Escape | keybinds (form) | `keybindsBack()` → list → close |
| SUPER+D | — | `ScreenRec.quickChoosing = true` (on focused monitor) |

---

## 8. Architecture Summary

### Full Bar ASCII Map

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ QUICKSHELL TOP BAR                                                                                                                          │
│ Three-Window Architecture · one per monitor · s = (screen.height/1080) * Flags.uiScale                                                      │
│                                                                                                                                             │
│ ┌══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ │
│ ║ WINDOW #1 — BAR (WlrLayer.Top · exclusionMode: Ignore · height: config.bar.height) ║                                                 │
│ ║ PanelWindow { anchors: top|left|right; color: transparent } ║                                                                          │
│ ║ ┌─── barContainer ── margins: 1*s 9*s 9*s 1*s ─────────────────────────────────────────────────────────────────────────────────┐ ║ │
│ ║ │ │ ║ │
│ ║ │ ┌─ leftPills (Row, spacing: 8*s) ──────────────┐ ┌─ centerContainer ──────┐ ┌─ rightPills (Row, spacing: 6*s) ──────────┐ │ ║ │
│ ║ │ │ │ │ │ │ ║ │
│ ║ │ │ ┌──────────────────────────────────┐ │ │ ┌─────────────────┐ │ │ ┌────────────────┐ ┌────────────────┐ ┌─┐ │ │ ║ │
│ ║ │ │ │ WORKSPACE PILL │ │ │ │ CENTER SPACER │ │ │ │ CONNECTIVITY │ │ AUDIO │ │P│ │ ║ │
│ ║ │ │ │ ┌──────────────────────────┐ │ │ │ │ │ 160 × 38 * s │ │ │ │ │ PILL │ │ PILL │ │O│ │ ║ │
│ ║ │ │ │ │ Loader (asynch: false) │ │ │ │ │ │ │ (spacer only — │ │ │ │ │ │ │ │W│ │ ║ │
│ ║ │ │ │ │ └──► Workspaces.qml │ │ │ │ │ │ pill lives in │ │ │ │ ┌──────────┐ │ │ ┌──────────┐ │ │E│ │ ║ │
│ ║ │ │ │ │ Repeater [count=9] │ │ │ │ │ │ Overlay) │ │ │ │ Network │ │ │ │ │Brightness│ │ │R│ │ ║ │
│ ║ │ │ │ │ └── Workspace.qml │ │ │ │ └─────────────────┘ │ │ │ │ .qml │ │ │ │ │.qml │ │ │ │ ║ │
│ ║ │ │ │ │ workspaceId: N │ │ └───────────────────────┘ │ │ │ wifi glyph │ │ │ │ │bright icon│ │ │ │ ║ │
│ ║ │ │ │ │ isActive │ │ │ │ │ SSID text │ │ │ │ │level% │ │ │ │ ║ │
│ ║ │ │ │ │ isOccupied │ │ │ │ │ onTap → │ │ │ │ onTap → │ │ │ │ ║ │
│ ║ │ │ │ │ onClick → dispatch│ │ │ │ │ toggleSfc │ │ │ │ toggleSfc│ │ │ │ ║ │
│ ║ │ │ │ │ pill stats: │ │ │ │ ├──────────┤ │ │ ├──────────┤ │ │ │ ║ │
│ ║ │ │ │ │ ┌── 28*s height │ │ │ │ │ Separator│ │ │ │ Separator│ │ │ │ ║ │
│ ║ │ │ │ │ ├── 14*s radius │ │ │ │ │ 1×12*s │ │ │ │ 1×12*s │ │ │ │ ║ │
│ ║ │ │ │ │ ├── pillBg: cardBot@0.7a │ │ │ │ ├──────────┤ │ │ ├──────────┤ │ │ │ ║ │
│ ║ │ │ │ │ ├── border: 1px cream@0.1a│ │ │ │ │ Bluetooth│ │ │ │ Volume │ │ │ │ ║ │
│ ║ │ │ │ │ └── top highlight gradient │ │ │ │ │ .qml │ │ │ │ │ .qml │ │ │ │ ║ │
│ ║ │ │ │ └──────────────────────────┘ └───────────────────────┘ └──────────┘ │ │ │ │ ║ │
│ ║ │ │ │ │ │ bt glyph │ │ │ │vol glyph │ │ │ │ ║ │
│ ║ │ │ │ │ │ onTap → │ │ │ │level% │ │ │ │ ║ │
│ ║ │ │ │ │ │ toggleSfc│ │ │ │onTap → │ │ │ │ ║ │
│ ║ │ │ │ │ │("bluetooth") │ │ │ toggleSfc│ │ │ │ ║ │
│ ║ │ │ │ │ └──────────┘ │ │ │("osd") │ │ │ │ ║ │
│ ║ │ │ │ │ │ │ └──────────┘ │ │ │ ║ │
│ ║ │ │ │ │ connectivity │ │ audio │ │ │ ║ │
│ ║ │ │ │ │ pill width: │ │ pill width: │ │ │ ║ │
│ ║ │ │ │ │ content+16*s │ │ content+16*s │ │ │ ║ │
│ ║ │ │ │ │ spacing: 4*s │ │ spacing: 6*s │ │ │ ║ │
│ ║ │ │ │ └────────────────┘ └────────────────┘ │ │ │ ║ │
│ ║ │ │ │ │ │ ║ │
│ ║ │ │ ═══ rightPills continued ═══ │ ┌────────────────────────────────────┐ │ │ │ ║ │
│ ║ │ │ │ │ POWER PILL │ │ │ │ ║ │
│ ║ │ │ │ │ ┌──────────────┐ ┌──────────┐ │ │ │ │ ║ │
│ ║ │ │ │ │ │StatusIndicat │ │ Battery │ │ │ │ │ ║ │
│ ║ │ │ │ │ │.qml │ │ .qml │ │ │ │ │ ║ │
│ ║ │ │ │ │ │ caffeine icon│ │ batt icon│ │ │ │ │ ║ │
│ ║ │ │ │ │ │ DND icon │ │ pct% │ │ │ │ │ ║ │
│ ║ │ │ │ │ │ visible: │ │ onTap→ │ │ │ │ │ ║ │
│ ║ │ │ │ │ │ hasActiveInd │ │ toggleSfc│ │ │ │ │ ║ │
│ ║ │ │ │ │ └──────────────┘ │("batt") │ │ │ │ │ ║ │
│ ║ │ │ │ │ ┌──────────────┐ └──────────┘ │ │ │ │ ║ │
│ ║ │ │ │ │ │ ← separator →│ ┌──────────┐ │ │ │ │ ║ │
│ ║ │ │ │ │ │ visible only │ │SysTray │ │ │ │ │ ║ │
│ ║ │ │ │ │ │ if indicators│ │(DISABLED)│ │ │ │ │ ║ │
│ ║ │ │ │ │ └──────────────┘ │ └──────────┘ │ │ │ │ ║ │
│ ║ │ │ │ │ pill width: content+16*s │ │ │ │ ║ │
│ ║ │ │ │ │ spacing: 6*s │ │ │ │ ║ │
│ ║ │ │ └────────────────────────────────────┘ │ │ │ ║ │
│ ║ │ └──────────────────────────────────────────────────────────────────────────────────┘ │ │ │ ║ │
│ ║ └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ ║ │
│ ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ │
│ │
│ ┌══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ │
│ ║ WINDOW #2 — RESERVE (WlrLayer.Top · exclusionMode: Ignore · aboveWindows: true · height: restH + topGap) ║                                 │
│ ║ PanelWindow { anchors: top|left|right; color: transparent; mask: Region{0,0} } ║                                                          │
│ ║ ║                                                                        │
│ ║ ┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐ ║ │
│ ║ │ NO INTERACTIVE CONTENT. Zero-size input Region → claims the top strip as an exclusive zone so tiled windows │ ║ │
│ ║ │ are positioned below the pill's resting height. The Bar window itself has exclusionMode: Ignore; this Reserve │ ║ │
│ ║ │ window is the one that actually reserves the space. │ ║ │
│ ║ │ │ ║ │
│ ║ │ s = (screen.height / 1080) * Flags.uiScale ║ │
│ ║ │ restH = Metrics.restHBase * s ║ │
│ ║ │ topGap = (barHeight - restH) / 2 ║ │
│ ║ └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ ║ │
│ ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ │
│ │
│ ┌══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ │
│ ║ WINDOW #3 — OVERLAY (WlrLayer.Overlay · exclusionMode: Ignore · anchors: fullscreen · margins.top: 8*s) ║                                 │
│ ║ PanelWindow { color: transparent; keyboardFocus: Exclusive|OnDemand } ║                                                                  │
│ ║ ║                                                                        │
│ ║ ┌── DYNAMIC INPUT MASK (controls click-through based on state) ─────────────────────────────────────────────────────────────────────────┐ ║ │
│ ║ │ │ ║ │
│ ║ │ monFullscreen == true → hiddenRegion (Region{}) → 100% click-through (pill invisible) ║ │
│ ║ │ surfaceOpen == true → fullRegion (full overlay size) → captures all input (backdrop close active) ║ │
│ ║ │ resting → pillRegion (pill-shaped) → click-through everywhere EXCEPT the pill ║ │
│ ║ │ pillRegion.x = pill.x + (pill.width - baseW)/2 ║ │
│ ║ │ pillRegion.y = pill.y - pill.inputPadTop ║ │
│ ║ │ pillRegion.w = baseW + pill.inputPadRight where baseW = max(pill.width, pill.targetW) ║ │
│ ║ │ pillRegion.h = max(pill.height, pill.targetH) + pill.inputPadTop ║ │
│ ║ └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ ║ │
│ ║ ║ │
│ ║ ┌── FULLSCREEN DETECTION ────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐ ║ │
│ ║ │ │ ║ │
│ ║ │ Hyprland: Connections { target: Hyprland } onRawEvent → checks hasfullscreen on activeWorkspace via hyprctl ║ │
│ ║ │ Niri: Timer { interval: 500 } → niri msg -j windows → tile_size >= monitor dimensions ║ │
│ ║ │ │ ║ │
│ ║ │ When monFullscreen becomes true → PillState.close() (dismisses open surface) ║ │
│ ║ │ When surface opened while fullscreen active → onSurfaceOpenChanged guard → force close ║ │
│ ║ └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ ║ │
│ ║ ║ │
│ ║ ┌── CENTER MORPHING PILL (Pill.qml) ──── anchors.top: parent.top + topGap · anchors.horizontalCenter ─────────────────────────────────┐ ║ │
│ ║ │ │ ║ │
│ ║ │ Mode: rest ──────────────────────────────────────────────────────────────── 160 × restH ║ │
│ ║ │ ┌─────────────────────────────────────────────┐ │ ║ │
│ ║ │ │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ highlight gradient │ ║ │
│ ║ │ │ 時 12:34 │ kanji glyph + time │ ║ │
│ ║ │ │ └─────────────────────────────────────────────┘ │ ║ │
│ ║ │ │ ║ │
│ ║ │ Mode: hover ────────────────────────────────────────────────────────────── hoverW × 58 * s ║ │
│ ║ │ ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐ │ ║ │
│ ║ │ │ ☐☐☐☐☐☐☐☐☐ │ 12:34 │ ☀ 28° │ [tray] │ 󰅶 │ 󰤨 │ 87% │ 󰢝 │ 󰍹 │ 󰎦 │ 󰒓 │ 󰐨 │ ⏻ │ │ ║ │
│ ║ │ │ workspaces │ date │ weather │ icons │ DND │ wifi │ batt │ inbox │ mixer │ sysmon│record│settngs│power │ │ ║ │
│ ║ │ └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ │ ║ │
│ ║ │ TapHandler: pin/unpin · HoverHandler: hoverLatch (300ms grace) · soulTarget tracks last hovered icon │ ║ │
│ ║ │ │ ║ │
│ ║ │ Mode: surface (one of 21) ────────────────────────────────────────────── varies by type ║ │
│ ║ │ ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐ │ ║ │
│ ║ │ │ Each surface is a child Item stacked inside Pill, cross-faded via morphCloseness: 0→1 as pill reaches target size │ │ ║ │
│ ║ │ │ │ │ ║ │
│ ║ │ │ calendar ──► (calendar.implicitWidth>0?implicitWidth:282*s)+36*s × implicitH+32*s launcher ──► 360*s × 332*s │ │ ║ │
│ ║ │ │ clipboard ──► 360*s × 332*s wallpaper ──► 720*s × 172*s power ──► 330*s × 150*s │ │ ║ │
│ ║ │ │ mixer ──► 93*max(4,faderCount)*s × 214*s media ──► 390*s × 150*s │ │ ║ │
│ ║ │ │ link ──► desiredW × implicitH+26*s bluetooth──► desiredW × implicitH+26*s │ │ ║ │
│ ║ │ │ battery ──► 316*s × implicitH+26*s settings ──► 392*s × implicitH+29*s keybinds ──► 460*s × implicitH+29*s │ │ ║ │
│ ║ │ │ recorder ──► 384*s × implicitH+33*s sysmon ──► 392*s × implicitH+33*s appearance──► 392*s × implicitH+29*s │ │ ║ │
│ ║ │ │ updates ──► 360*s × implicitH+29*s display ──► 392*s × implicitH+29*s input ──► 392*s × implicitH+29*s │ │ ║ │
│ ║ │ │ look ──► 392*s × implicitH+29*s idlelock ──► 392*s × implicitH+29*s fontpicker──► 360*s × implicitH+29*s │ │ ║ │
│ ║ │ │ │ │ ║ │
│ ║ │ │ Overlays (morph in place, no surface entry): │ │ ║ │
│ ║ │ │ osd ──► brightness/volume sliders toast ──► notification (342*s × dynamic) │ │ ║ │
│ ║ │ │ quickChoose ──► screen/window chooser (344×76) quickCount ──► countdown (150×64) │ │ ║ │
│ ║ │ └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ │ ║ │
│ ║ │ │ ║ │
│ ║ │ Morph animations: │ ║ │
│ ║ │ Behavior on width { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } } ║ │
│ ║ │ Behavior on height { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } } ║ │
│ ║ │ Behavior on morphRadius { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } } ║ │
│ ║ │ morphCloseness = 1 - min(1, max(|w-targetW|, |h-targetH|) / (110*s)) ║ │
│ ║ │ │ ║ │
│ ║ │ Fullscreen transition: │ ║ │
│ ║ │ opacity: 0 (200ms OutCubic) │ ║ │
│ ║ │ transform: Translate { y: -(pill.height + overlay.topGap) } (200ms OutCubic) │ ║ │
│ ║ │ │ ║ │
│ ║ │ Ame filament: │ ║ │
│ ║ │ rest → form: "off" point: wakePoint (kanji centre) │ ║ │
│ ║ │ hover → form: "soul" point: soulPoint (last hovered icon) │ ║ │
│ ║ │ surface→ form: ameForm point: amePoint (anchor on open surface) │ ║ │
│ ║ │ power → heat, wickDir set from power.holdProgress │ ║ │
│ ║ └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ ║ │
│ ║ ║ │
│ ║ ┌── BACKDROP CLOSE (MouseArea { anchors.fill: parent; z: -1; enabled: surfaceOpen }) ──────────────────────────────────────────────────┐ ║ │
│ ║ │ onClicked(mouse) → if (!pill.contains(mouse)) PillState.close() ║ │
│ ║ └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ ║ │
│ ╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ │
│ │
│ ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ │ KEY TO LABELS │
│ │ ───────────── │
│ │ ☐☐☐☐☐☐☐☐☐ = workspace dots (active=red, occupied=grey, empty=dim) │
│ │ 時 = kanji glyph for "time" (rest state) │
│ │ 12:34 = current time (HH:mm or h:mm AP) │
│ │ ☀ 28° = weather temp + glyph │
│ │ 󰅶 = DND (Do Not Disturb) indicator │
│ │ 󰤨 = WiFi strength glyph (varies: 󰤟 󰤢 󰤥 󰤨) │
│ │ 87% = battery percentage │
│ │ 󰢝/󰕾/󰛨 = inbox / volume / brightness glyphs │
│ │ 󰍹/󰎦/󰒓/󰐨/⏻ = sysmon / recorder / cog / shutdown / power glyphs │
│ │ *s = scale factor = (screen.height / 1080) * Flags.uiScale │
│ │ toggleSfc = PillState.toggleSurface(screenName, surfaceName) │
│ └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Three-Window Architecture (per monitor)

```
Window #1 — BAR WINDOW (WlrLayer.Top, no exclusive zone)
PanelWindow, anchors: top|left|right, height: config.bar.height
┌─ leftPills ───┬── centerContainer ─┬── rightPills ───────────────┐
│ workspaces │ 160×38*s spacer │ connectivity | audio | power │
└───────────────┴────────────────────┴─────────────────────────────┘

Window #2 — RESERVE WINDOW (WlrLayer.Top, exclusive zone)
PanelWindow, anchors: top|left|right, height: restH + (barHeight - restH) / 2
mask: zero-size Region (no input)
Purpose: claim the top exclusive zone so tiled windows sit below

Window #3 — OVERLAY WINDOW (WlrLayer.Overlay)
PanelWindow, anchors: fullscreen, mask: dynamic
┌─ Pill (morphing center) ──────────────────────────────────────────┐
│ rest (160×restH) → hover (hoverW×58) → surface (varies) │
│ opacity=0 + translate Y when fullscreen │
└───────────────────────────────────────────────────────────────────┘
Contains: 21 surfaces (calendar, launcher, clipboard, wallpaper, power, media, mixer, link, bluetooth, battery, settings, keybinds, recorder, sysmon, appearance, updates, display, input, look, idlelock, fontpicker)
Backdrop: MouseArea on entire window for click-outside-to-close
```

### Surface Size Reference

| Surface | Width | Height | File |
|---------|-------|--------|------|
| calendar | `(calendar.implicitWidth > 0 ? implicitWidth : 282*s) + 36*s` | `implicitHeight + 32*s` | Calendar.qml |
| launcher | `360*s` | `332*s` | Launcher.qml |
| clipboard | `360*s` | `332*s` | Clipboard.qml |
| wallpaper | `720*s` | `172*s` | Wallpaper.qml |
| power | `330*s` | `150*s` | Power.qml |
| media | `390*s` | `150*s` | Media.qml |
| mixer | `93*max(4, faderCount)*s` | `214*s` | Mixer.qml |
| link | `link.desiredW` | `implicitHeight + 26*s` | Link.qml |
| bluetooth | `linkBt.desiredW` | `implicitHeight + 26*s` | Link.qml (bt) |
| battery | `316*s` | `implicitHeight + 26*s` | BatterySurface.qml |
| settings | `392*s` | `implicitHeight + 29*s` | Settings.qml |
| keybinds | `460*s` | `implicitHeight + 29*s` | Keybinds.qml |
| recorder | `384*s` | `implicitHeight + 33*s` | Recorder.qml |
| sysmon | `392*s` | `implicitHeight + 33*s` | SysmonSurface.qml |
| appearance | `392*s` | `implicitHeight + 29*s` | Appearance.qml |
| updates | `360*s` | `implicitHeight + 29*s` | Updates.qml |
| display | `392*s` | `implicitHeight + 29*s` | Display.qml |
| input | `392*s` | `implicitHeight + 29*s` | Input.qml |
| look | `392*s` | `implicitHeight + 29*s` | Look.qml |
| idlelock | `392*s` | `implicitHeight + 29*s` | IdleLock.qml |
| fontpicker | `360*s` | `implicitHeight + 29*s` | FontPicker.qml |
| osd | `osd.desiredW` | `osd.desiredH` | Osd.qml (inline) |
| toast | `342*s` | `toastLoader.item ? implicitHeight + 24*s : restH` | Toast.qml (inline) |
| quickChoose | `344*s` | `76*s` | inline in Pill.qml |
| quickCount | `150*s` | `64*s` | inline in Pill.qml |

### Bar Dimension Reference

| Measurement | Value |
|-------------|-------|
| Bar height | `config.bar.height` |
| Bar container margins | top: 1*s, left: 9*s, right: 9*s, bottom: 1*s |
| Scale factor `s` | `(screen.height / 1080) * Flags.uiScale` |
| Pill resting height | `QsSingletons.Metrics.restHBase * s` |
| Pill height | `restH` |
| Pill radius (rest/hover) | `18 * s` |
| Pill radius (surface open) | `22 * s` |
| Pill padding | `16 * s` (each side of content) |
| Pill border | 1px, cream @ 10% alpha |
| Pill background | cardBot @ 55% alpha (body), 70% alpha (bar pills) |
| Pill separator | 1×12*s, cream @ 15% alpha, radius 0.5*s |
| Right pills spacing | `6 * s` |
| Left pills spacing | `8 * s` |
| Center spacer | `160*s × 38*s` |
| Reserve window height | `restH + (barHeight - restH) / 2` |
| Overlay top margin | `8 * s` |
| Hover pad | `20 * s` (each side of hover row) |
| Hover height | `58 * s` |
| Media bud radius | `12 * s` (rest), `15 * s` (hovered) |

### Animation Timings

| Property | Duration | Easing |
|----------|----------|--------|
| Pill morph (width/height/radius) | `Motion.morph` | `Motion.easeMorph` / `Motion.morphCurve` (no-overshoot bezier) |
| Bar pill width | 250-350ms | OutCubic / same bezier |
| Pill opacity (fullscreen) | 200ms | OutCubic |
| Fullscreen translate Y | 200ms | OutCubic |
| Color transitions | 150ms | linear |
| Kanji flash | 90ms → 320ms | OutCubic |
| Soul bead (bud) | `Motion.standard` | easeStandard |
| Ame flight (quick) | 460ms | Linear |
| Ame flight (normal) | `Motion.shapeshift` | Linear |
| Ame settle | `Motion.shapeshift * (1 - pFly)` | Linear |
| Ame remnant | 350ms | OutCubic |
| Ame glide | `Motion.glide` | OutCubic |
| Ame fade (off) | `Motion.fast` | — |
| Ame budR | `Motion.fast` | easeStandard |

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Bar window uses WlrLayer.Top with no exclusive zone | Reserve window claims the exclusive zone; bar is just a visual layer |
| Reserve window has zero-size mask | Claims the top strip for input routing without capturing any input itself |
| Overlay uses WlrLayer.Overlay | Renders above everything including the bar, so the morphing pill can float above |
| Mask switches between pillRegion ↔ fullRegion ↔ hiddenRegion | Click-through when fullscreen, full capture when modal, pill-only when resting |
| Center spacer is fixed 160×38*s in Bar.qml | Prevents layout shift; actual pill is in the overlay |
| All bar pills share same highlight gradient | Consistent frosted-glass aesthetic |
| Bar components loaded synchronously (asynchronous: false) | Avoids visual flash during startup; loaders are fast enough without async |
| SystemTray source commented out in Bar.qml | Tray functionality moved to the center pill's hover row (Tray.qml) |
| Fullscreen detection monFullscreen drives pill visibility | Morphing pill hides smoothly when any window goes fullscreen on that monitor |
| Niri fullscreen via polling (Timer 500ms) | Niri lacks event-driven IPC for fullscreen state changes |
| overlayTopOffset compensates for margins.top | Overlay has 8*s top margin; topGap subtracts it so pill aligns with bar centerline |
| morphCloseness gates content opacities | Surfaces fade in as pill reaches full size, never over a half-grown pill |
| hoverSoulGate with 300ms grace timer | Prevents bead flicker during morph transitions and small width changes |
| Ame uses Canvas + FrameAnimation + Timer | Full-rate repaint only during motion; 12fps idle swirl for 24/7 shell cost |
| Qt.callLater(decide) in Ame | Coalesces form/point binding changes to avoid reading stale partner values |
| surfaces descriptor is single source of truth | Adding a surface is one entry in the descriptor + its child item; no parallel ternary chains |
| modeSize for non-surface modes | osd, toast, hover, quickChoose, quickCount have no surface item, so sizes live here |
| Bud inputPadRight extends mask | Window mask covers the media bud's outer half so clicks register correctly |
| Backdrop MouseArea z: -1 with contains(mouse) check | Click-outside-to-close only fires when click is outside the pill itself |
