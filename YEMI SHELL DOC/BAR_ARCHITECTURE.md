# Top Bar Architecture

## Full Component Tree

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ shell.qml  (root Quickshell scope)                                                  │
│                                                                                     │
│  └── barLoader ──────────────────────► BarWrapper.qml                               │
│                                      │                                               │
│                                      ├── bluetoothPopupLoader ──► BluetoothPopup.qml │
│                                      ├── networkPopupLoader   ──► NetworkPopup.qml   │
│                                      ├── volumePopupLoader    ──► VolumePopup.qml    │
│                                      └── brightnessPopupLoader ─► BrightnessPopup.qml │
│                                      │                                               │
│                                      └── Variants model: [Quickshell.screens]       │
│                                           │                                          │
│                                           └── PanelWindow (per screen)              │
│                                                │  top-anchored, transparent         │
│                                                │  height: 60px                       │
│                                                │  layer: Top                         │
│                                                │                                      │
│                                                └── barLoader ──► Bar.qml             │
│                                                     │                               │
│                                                     └── barContainer (Item)          │
│                                                          │  margins: 1,9,9,1         │
│                                                          │  width: parent - 18px     │
│                                                          │  scale factor: s          │
│                                                          │                           │
│             ┌──────────────────────────────────────────────┼───────────────────┐   │
│             │                                              │                   │   │
│             ▼                                              ▼                   ▼   │
│    ┌────────────────┐                          ┌─────────────────┐  ┌───────────┐ │
│    │   LEFT PILL    │                          │   CENTER        │  │ RIGHT 3x  │ │
│    │  workspace pill│                          │   160×38 spacer │  │ ROW       │ │
│    └────────────────┘                          └─────────────────┘  └───────────┘ │
│             │                                              │                   │   │
│             │                                              │                   │   │
│             ▼                                              ▼                   ▼   │
│    ┌────────────────┐                          ┌─────────────────────────────────┐ │
│    │ ☐ ☐ ☐ ☐ ☐ ☐   │                          │      [Center Pill Overlay]      │ │
│    │ Workspaces     │                          │      (PillOverlay.qml)          │ │
│    │ 9 workspaces   │                          │      PanelWindow                 │ │
│    └────────────────┘                          │      layer: Overlay (above bar)  │ │
│                                                 └─────────────────────────────────┘ │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                      RIGHT PILLS ROW (spacing: 6px)                         │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐  │  │
│  │  │ NET + BLUETOOTH  │  │ BRIGHT + VOLUME  │  │ STATUS + BATTERY + TRAY  │  │  │
│  │  │ 󰤨 WiFi 󰂯       │  │ 󰛨 Bright 󰕾    │  │ 󰛊 󰂛 󰁹 󰂄              │  │  │
│  │  │ "NetworkName"    │  │ slider + level   │  │ indicators+batt+tray     │  │  │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────────────┘  │  │
│  │    connectivityPill      audioPill              powerPill                    │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                     │
│  Each pill anatomy:                                                                 │
│  ┌──────────────────────────────┐                                                  │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │  topHighlight (gradient, 4% white → transp)   │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │  height: ~14px (half of 28px)                │
│  │                              │                                                  │
│  │   [icon] | [icon]            │  Content Row                                     │
│  │   w: 1×12 separators        │  spacing varies by pill (4-6px)               │
│  │                              │                                                  │
│  └──────────────────────────────┘                                                  │
│   border: 1px (cream @ 10%)                                                         │
│   radius: 14px                                                                      │
│   color: pillBg (cardBot @ 0.7)                                                     │
│   height: 28 * s                                                                    │
│   width: implicitWidth + 16 * s                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            DATA SOURCES → Bar.qml                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Config (QsConfig.Config)                                                        │
│  └── bar.height: 60              ──┐                                             │
│  └── bar.padding: 4               │                                             │
│  └── workspaces.count: 9          │                                             │
│  └── workspaces.spacing: 6        │                                             │
│                                   │                                             │
│  Theme (QsSingletons.Theme)     │    ┌────────────────────────────────┐        │
│  └── cardBot      ──────────────┘    │         Bar.qml                 │        │
│  └── cream        ──────────┐        │  ┌──────────────────────────┐  │        │
│  └── onGlow        ─────────┼───────►│  │  Left/Right/Center pills │  │        │
│                               │        │  └──────────────────────────┘  │        │
│  Compositor                   │        └────────────────────────────────┘        │
│  └── activeWsId      ─────────┘                                                 │
│  └── getOccupied()    ─────────┐                                                 │
│                                │                                                 │
│  Services                      │                                                 │
│  ├── IdleInhibitor ────────────┤                                                 │
│  │   └── inhibited (caffeine)   │                                                 │
│  ├── Notifs         ────────────┤                                                 │
│  │   └── dnd                    │                                                 │
│  ├── Network        ────────────┘                                                 │
│  ├── Bluetooth     ─────────────┐                                                 │
│  ├── Volume        ─────────────┤                                                 │
│  ├── Brightness    ─────────────┤                                                 │
│  ├── Battery       ─────────────┤                                                 │
│  └── SystemTray    ─────────────┘                                                 │
│                                                                                 │
│  Popups (injected from BarWrapper)                                              │
│  ├── networkPopup    ─────────────────┐                                         │
│  ├── bluetoothPopup ──────────────────┤                                         │
│  ├── volumePopup    ──────────────────┤                                         │
│  └── brightnessPopup ─────────────────┘                                         │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Binding Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Loader.asynchronous: true                                                   │
│                                                                             │
│  ┌──────────────┐                                                           │
│  │   Loader     │                                                           │
│  │   source:    │                                                           │
│  │ "Component"  │                                                           │
│  └──────┬───────┘                                                           │
│         │                                                                    │
│         │ when: status === Loader.Ready                                      │
│         │                                                                    │
│         ▼                                                                    │
│  ┌───────────────────────────────────────────────────────────┐             │
│  │  Binding {                                                 │             │
│  │      target: loader.item                                    │             │
│  │      property: "barWindow"                                  │             │
│  │      value: root.barWindow                                  │             │
│  │      restoreMode: RestoreBinding                            │             │
│  │  }                                                          │             │
│  └───────────────────────────────────────────────────────────┘             │
│                                                                             │
│  Ensures safe property injection after lazy loading completes               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Measurement Reference

```
Bar Dimensions
══════════════════════════════════════════════════════════════════════════════

Overall Bar
┌────────────────────────────────────────────────────────────────────────────┐
│  height: 60px                                                               │
│  margins: top=1*s, left=9*s, right=9*s, bottom=1*s                         │
│  scale factor s = (screen.height / 1080) * Flags.uiScale                    │
└────────────────────────────────────────────────────────────────────────────┘

Pill Specifications (all pills share these)
┌────────────────────────────────────────────────────────────────────────────┐
│  height:     28 * s                                                         │
│  radius:     14 * s                                                         │
│  border:     1px (cream color, 10% alpha)                                   │
│  padding:    width = implicitWidth + 16 * s                                 │
│  bg:         cardBot color, 70% alpha                                       │
│  highlight:  gradient, top half, 4% white → transparent                     │
└────────────────────────────────────────────────────────────────────────────┘

Spacing Matrix
┌────────────────────────────────────────────────────────────────────────────┐
│  Section              │  Spacing                                           │
│───────────────────────┼────────────────────────────────────────────────────│
│  Left pills (row)     │  8 * s                                              │
│  Right pills (row)    │  6 * s                                              │
│  Workspace items      │  6 * s (from config)                                │
│  Connectivity pill    │  4 * s internal                                     │
│  Separators           │  1×12*s, radius 0.5*s                              │
└────────────────────────────────────────────────────────────────────────────┘

Center Spacer (prevents layout shift)
┌────────────────────────────────────────────────────────────────────────────┐
│  width:  160 * s                                                            │
│  height: 38 * s                                                             │
│  Purpose: reserves space for PillOverlay.qml center pill                   │
└────────────────────────────────────────────────────────────────────────────┘

Animation Timings
┌────────────────────────────────────────────────────────────────────────────┐
│  Pill width change:    250-350ms                                            │
│  Easing:               OutCubic / BezierCurve [0.34, 1.56, 0.64, 1]       │
│  Status indicators:    200ms                                                │
│  Separator fade:       150ms                                                │
└────────────────────────────────────────────────────────────────────────────┘
```

## Keyboard Interaction Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Workspace Switches (Hyprland / Niri)                                        │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  Workspace.qml click ──► compositor.dispatch("workspace N")                 │
│                                                                             │
│  Where:                                                                     │
│  • runtime check: activeWsId !== workspaceId                                │
│  • dispatch only if switching to different workspace                        │
│  • handled by Repeater delegate in Workspaces.qml                           │
│                                                                             │
│  State Sources:                                                             │
│  • activeWsId        ← compositor.activeWsId                                │
│  • isOccupied        ← compositor.getOccupiedWorkspaces()[workspaceId]      │
│                                                                             │
│  Center Pill Keyboard Navigation (Pill.qml)                                 │
│  ─────────────────────────────────────────────────────────────────────────  │
│                                                                             │
│  arrow keys (surface open)                                                   │
│    mixerStep / mixerFocusMove    → mixer fader row                          │
│    settingsMove / settingsAdjust → settings rows                            │
│    keybindsMove / keybindsActivate → keybinds list/form                     │
│    wallpaperMove / wallpaperActivate → wallpaper strip                      │
│    powerMove / powerPress / powerRelease → power tiles                      │
│                                                                             │
│  Escape                                                                     │
│    surfaceBack() → keybinds form → settings sub-surface → hover pill        │
│    linkBack() → link subview pop                                            │
│                                                                             │
│  Quick-Record (SUPER+D)                                                     │
│    ScreenRec.prepareScreen / prepareWindow → countdown → record             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Reference

| Component | File | Lazy Loaded | Key Properties | Popup |
|-----------|------|-------------|----------------|-------|
| Workspaces | components/Workspaces.qml | Yes | count, spacing, active/occupied | None |
| Network | components/Network.qml | Yes | ssid, strength, enabled | networkPopup |
| Bluetooth | components/Bluetooth.qml | Yes | connected, device list | bluetoothPopup |
| Brightness | components/Brightness.qml | Yes | level, slider | brightnessPopup |
| Volume | components/Volume.qml | Yes | level, mute | volumePopup |
| Battery | components/Battery.qml | Yes | charge, charging, icon | None |
| StatusIndicators | components/StatusIndicators.qml | Yes | caffeine, dnd | None |
| SystemTray | components/SystemTray.qml | Yes | hasItems | None |

## Pill Anatomy (every right-side pill follows this pattern)

```
┌─────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │  ← topHighlight (gradient, 4% white → transparent)
│                             │
│   [icon] | [icon]           │  ← Row content + separators
│                             │
└─────────────────────────────┘
  radius: 14 * s
  color: pillBg  (cardBot @ 0.7 alpha)
  border: 1px pillBorder (cream @ 0.10 alpha)
  height: 28 * s
  width: implicitWidth + 16 * s
```

## Data Flow

```
Config (QsConfig.Config)
  └── bar.height, bar.padding, bar.workspaces.count, bar.workspaces.spacing

Theme (QsSingletons.Theme)
  └── cardBot, cream, onGlow  → pill colors

Compositor (QsCompositor.Compositor)
  └── activeWsId, getOccupiedWorkspaces()  → workspace state

Services
  ├── IdleInhibitor.inhibited  → caffeine state
  ├── Notifs.dnd               → DND state
  └── [Battery, Network, Bluetooth, Volume, Brightness, SystemTray]

Popups (loaded in BarWrapper, injected into Bar)
  ├── bluetoothPopup
  ├── networkPopup
  ├── volumePopup
  └── brightnessPopup
```

## BarWrapper → Bar.qml Structure (confirmed)

All 3 right pills live inside **rightPills Row** in Bar.qml (loaded by BarWrapper):

```
BarWrapper.qml
└── Variants → PanelWindow
    └── barLoader → Bar.qml
        ├── barContainer
        │   ├── leftPills → leftModule (workspaces pill)
        │   ├── centerContainer (160×38 * s spacer)
        │   └── rightPills Row (spacing: 6 * s)
        │       ├── connectivityPill (Network + Bluetooth)
        │       ├── audioPill (Brightness + Volume)
        │       └── powerPill (Status + Battery + Tray)
        └── [bindings: screen, barWindow, popups]
```

Separately: PillOverlay.qml renders the center pill in its own overlay window
```
shell.qml
└── Variants → PillOverlay (PanelWindow, layer: Overlay)
    └── Pill (morphing center pill)
```

## Popup vs Surface Architecture (critical distinction)

**BarWrapper.qml** manages 4 **separate popup WINDOWS**:
```
BarWrapper.qml
├── BluetoothPopupWindow.qml    (standalone window)
├── NetworkPopupWindow.qml      (standalone window)
├── VolumePopupWindow.qml       (standalone window)
└── BrightnessPopupWindow.qml   (standalone window)

These popups are injected into Bar.qml pills and open as separate windows.
```

**Pill.qml** (center pill) manages **in-window SURFACES** that morph within the same PillOverlay window:
```
Pill.qml surfaces (all open inside PillOverlay.qml, NOT separate windows):
├── rest / hover          → clock, workspaces, status, wifi, battery, media-bud
├── calendar              → clock + calendar
├── launcher              → app launcher grid
├── clipboard             → clipboard history
├── wallpaper             → wallpaper picker strip
├── power                 → power tiles
├── media                 → media player controls
├── mixer                 → volume mixer faders
├── link                  → network + bluetooth controls (Link.qml / LinkWifi.qml / LinkBt.qml)
├── battery               → battery details
├── settings              → settings menu (SettingsSurface.qml)
├── keybinds              → keybind editor list + form
├── recorder              → screen recorder controls
├── sysmon                → system monitor
├── appearance            → appearance settings
├── updates               → updates
├── display               → display settings
├── input                 → input settings
├── look                  → look settings
├── idlelock              → idle lock settings
├── fontpicker            → font picker
├── osd                   → brightness/volume OSD overlay
├── toast                 → notification toast
├── quickChoose           → quick-record source chooser
└── quickCount            → pre-roll countdown toast
```

**Quick-record flow (Pill.qml):**
```
SUPER+D keybind
  └── ScreenRec.quickChoosing = true  (mode="quickChoose" on focused monitor)
      ├── single monitor → prepareScreen(pill.screenName) → countdown (mode="quickCount") → record
      └── multi monitor → quickScreenChoosing = true → inline monitor strip → pick → prepareScreen(name) → ...
```

**Key difference:**
- **Popups** = separate windows (BarWrapper responsibility)
- **Surfaces** = morph within the same Pill window (Pill.qml responsibility)

The "link" surface contains network/bluetooth controls (Link.qml, LinkWifi.qml, LinkBt.qml), which is separate from the standalone NetworkPopupWindow.qml / BluetoothPopupWindow.qml.

**Ame Filament Integration:**
- Each surface that defines `ameForm` or `amePoint` becomes an Ame anchor
- Pill.qml maps `ameSurface` from the `surfaces` descriptor
- `wakePoint` = rest kanji center (pill idle anchor)
- `soulPoint` = hover target (last hovered icon or active workspace dot)

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Popups loaded in BarWrapper, not Bar.qml | Separation of concerns — window management vs. bar layout |
| Components loaded via `Loader` (async) | Lazy loading, faster startup |
| `Binding` with `restoreMode: RestoreBinding` | Safe property injection after Loader.Ready |
| Center spacer is fixed 160×38 * s | Prevents layout shift; actual center pill lives in PillOverlay.qml |
| Each pill has its own highlight gradient | Consistent frosted-glass aesthetic |
| StatusIndicators visibility drives separator | Conditional separator only shows when indicators active |
| PillOverlay uses WlrLayer.Overlay | Renders above bar's WlrLayer.Top so morphing pill floats above bar |
| Unified scale factor `s` in Bar.qml | Matches PillOverlay scaling so pills and spacer stay aligned on all DPIs |