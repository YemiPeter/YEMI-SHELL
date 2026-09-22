# Alt+Tab Switcher (altSwitcher) — Behavior & Architecture Map

This document maps every piece of the YemiShell Alt+Tab window switcher, what it
does, how it's wired, and what each option controls — so you know what you can
keep or change without breaking the feature.

---

## 1. What It Is

A **full-screen overlay** that appears when the user presses `Alt+Tab` (or
`Alt+Shift+Tab` to go backwards). It displays every open window as a frosted-glass
tile in a grid, navigable with arrow keys / Tab cycling and focusable with Enter
or a click.

- **Compositors supported:** Niri and Hyprland (gated at instantiation).
- **Feature flag:** `Flags.altSwitcherEnabled` — a master on/off toggle exposed
  in the UI under **Panels → "Overview (Alt+Tab)"**. When `false`, every public
  API function returns early and the overlay never opens.
- **Keyboard grab:** Intentionally **NOT grabbed** beyond the overlay's own
  arrow/Enter/Esc handling. Navigation is driven by compositor keybinds that call
  `qs ipc call altSwitcher next|previous`. This avoids a focus fight between the
  overlay and the compositor when cycling.

---

## 2. File Map (what every file does)

| File | Role |
|---|---|
| `modules/altswitcher/AltSwitcher.qml` | The switcher UI + logic (Scope root, PanelWindow overlay, tiles, IPC-facing methods). Sole implementation file. |
| `shell.qml` (lines 71–96) | `IpcHandler { target: "altSwitcher" }` — receives IPC calls and delegates to the loaded module. |
| `shell.qml` (lines 370–374) | `Loader { id: altSwitcherLoader }` — lazily instantiates `AltSwitcher.qml` only on Niri or Hyprland (`active: Compositor.isNiri \|\| Compositor.isHyprland`). |
| `singletons/Flags.qml` (line 53) | `property alias altSwitcherEnabled` — persisted `flags.json` flag, default `true`. |
| `singletons/Flags.qml` (flags.json) | `altSwitcherEnabled: true` — persisted state file at `$XDG_STATE_HOME/quickshell/flags.json`. |
| `compositor/Compositor.qml` | Singleton providing `runningCompositor`, `toplevels`, `workspaces`, `monitors`, and `dispatch()` — the data source and focus command channel for the switcher. |
| `modules/pill/Panels.qml` (lines 18–20, 37–49) | Settings surface toggle: `Flags.altSwitcherEnabled` on/off via `altTabRow` LinkToggle. |
| Niri keybinds: `~/.config/niri/config.d/70-binds.kdl` (lines 60–65) | `Alt+Tab` → `qs ipc call altSwitcher next`; `Alt+Shift+Tab` → `... previous`. |
| Hyprland keybinds: `~/.config/hypr/modules/binds.lua` (lines 119–121) | `bind = ALT, Tab, exec, qs ipc call altSwitcher next`; `ALT SHIFT, Tab, ... previous`. |

---

## 3. Option Map (tunables inside `AltSwitcher.qml`)

### Tunables (lines 29–38) — hardcoded, not user-configurable at runtime

| Name | Type | Default | What it controls |
|---|---|---|---|
| `scrimDim` | `real` | `0.35` | Opacity (0..1) of the black scrim rectangle drawn behind the card. Darkens everything behind the overlay. |
| `blurGlass` | `bool` | `compositor.isNiri` (true on Niri, false on Hyprland) | Whether to apply compositor-level frosted-glass blur behind the card. On Niri this uses `BackgroundEffect.blurRegion`; on Hyprland blur comes from `layerrule = blur on, match:namespace quickshell*` in Hyprland config instead. |
| `tileWidth` | `int` | `224` | Base (pre-scale) width of each window tile, in design px. |
| `tileHeight` | `int` | `116` | Base (pre-scale) height of each window tile, in design px. |
| `tileGap` | `int` | `12` | Spacing between tiles in the Flow grid, in design px. |

### Theme tokens (lines 40–45) — resolved from `QsSingletons.Theme`

| Name | Source token | Purpose |
|---|---|---|
| `cSurface` | `Theme.cardBot` | Card background color. |
| `cPrimary` | `Theme.onGlow` | Accent color — used for selected-tile border, accent rail, workspace label text, close button hover. |
| `cText` | `Theme.cream` | Primary text (app name, close icon). |
| `cSubText` | `Theme.cream` @ 60% alpha | Secondary text (window count, instructions, window title). |
| `cBorder` | `Theme.cream` @ 10% alpha | Card border + unselected-tile border. |

### Runtime state (lines 52–56)

| Name | Type | Default | What it controls |
|---|---|---|---|
| `open` | `bool` | `false` | Whether the overlay is active. Drives scrim opacity, card opacity, and PanelWindow visibility. |
| `currentIndex` | `int` | `0` | Index into `windows` of the currently-highlighted tile. Reset to 0 on open; clamped on `windows` change. |
| `s` | `real` | `Flags.uiScale` | UI scale factor applied to all size/spacing values. |

### Derived data (lines 57–94)

| Name | Type | What it controls |
|---|---|---|
| `windows` | `array` | Live-sorted array of normalized toplevels (see `normalizeWindow()` below). Sorted by workspace index, then app name. Feeds the Repeater. |
| `count` | `int` | `windows.length` — displayed in header text ("N windows" / "N window"). |

---

## 4. Public API (called by the IPC handler in `shell.qml`)

All functions check `Flags.altSwitcherEnabled` first (except `toggle`, which is the
main entry point). Calling them on an unknown compositor is a no-op.

| Function | IPC target | What it does |
|---|---|---|
| `toggle()` | `altSwitcher toggle` | Opens if closed, closes if open. Guards on `Flags.altSwitcherEnabled`. |
| `open()` → `openSwitcher()` | `altSwitcher open` | Resets `currentIndex` to 0, sets `open = true`, forces active focus to the card. No-ops if flag is off or compositor is unknown. |
| `close()` | `altSwitcher close` | Sets `open = false`. |
| `next()` | `altSwitcher next` | If not open → opens. If open → increments `currentIndex` (wraps modulo `count`). |
| `previous()` | `altSwitcher previous` | Same as `next()` but decrements (wraps). |

**Note on `open()` vs `openSwitcher()`:** In QML, a property named `open` shadows a
function named `open` on the same object. The IPC handler in `shell.qml`
explicitly calls `altSwitcherLoader.item.openSwitcher()` to avoid this shadowing.

---

## 5. Keyboard Grid Navigation (arrow keys)

| Function | Key | What it does |
|---|---|---|
| `moveLeft()` | `←` | `currentIndex = max(0, currentIndex - 1)`. |
| `moveRight()` | `→` | `currentIndex = min(count - 1, currentIndex + 1)`. |
| `moveUp()` | `↑` | `currentIndex = max(0, currentIndex - _cols)`. |
| `moveDown()` | `↓` | `currentIndex = min(count - 1, currentIndex + _cols)`. |
| `selectAndFocus(i)` | `Enter` / `Return` | Sets `currentIndex = i`, calls `focusWindow(windows[i])`, then `close()`. |
| `close()` | `Esc` | Sets `open = false`. |

`_cols` (line 141): Computed column count based on `flow.width`, `tileWidth`,
`tileHeight`, `tileGap`, and `uiScale`.

---

## 6. Window Normalization (`normalizeWindow()`)

Maps raw compositor toplevel data into a uniform shape so the delegate and focus
logic never care which compositor is running:

| Normalized field | Niri source | Hyprland source |
|---|---|---|
| `id` | `w.id` | `w.address` (string like `"0x…"`) |
| `address` | `null` | `w.address` |
| `app` | `w.app_id` | `w.lastIpcObject.class` / `.initialClass` / `w.appid` |
| `title` | `w.title` | `w.lastIpcObject.title` |
| `wsId` | `w.workspace_id` | `w.workspace.id` |

Sorting: by workspace index first (via `compositor.workspaces` lookup), then by
app name alphabetically (`localeCompare`).

---

## 7. Focus Command (`focusWindow()`)

| Compositor | How it focuses |
|---|---|
| **Hyprland** | `compositor.dispatch("focuswindow address:" + w.address)` — unified dispatch path. |
| **Niri** | `Process { command: ["niri", "msg", "action", "focus-window", "--id", String(w.id)] }` — spawned as external process. |

---

## 8. Overlay / UI Structure (QML tree)

```
Scope (root: AltSwitcher)
├── PanelWindow (id: panel)         — full-screen, Overlay layer, namespace "quickshell:altSwitcher"
│   ├── BackgroundEffect.blurRegion  — Niri-only frosted-glass behind cardHolder
│   ├── Rectangle (id: scrim)        — black, opacity=root.open, scrimDim=0.35
│   │   └── MouseArea (full)         — click → close()
│   └── Item (id: cardHolder)        — centered card container
│       ├── Rectangle (id: card)     — rounded rect, cSurface @72% alpha, cBorder 1px
│       │   ├── ColumnLayout
│       │   │   ├── RowLayout (header)
│       │   │   │   ├── Text "Overview"
│       │   │   │   ├── Text "N windows"
│       │   │   │   ├── Text "↑ ↓ ← → navigate · Enter focus · Esc close"
│       │   │   │   └── Rectangle + MouseArea (close button "✕")
│       │   │   └── Flickable + Flow (tile grid)
│       │   │       └── Repeater (model: root.windows)
│       │   │           └── Rectangle (delegate tile)
│       │   │               ├── RowLayout
│       │   │               │   ├── Rectangle (accent rail — cPrimary if selected)
│       │   │               │   └── ColumnLayout
│       │   │               │       ├── Text (app name — appLabel())
│       │   │               │       ├── Text (window title OR workspace name)
│       │   │               │       └── Text (workspace name — wsLabel())
│       │   │               └── MouseArea (hover → set currentIndex, click → selectAndFocus)
│       │   └── Text "No open windows" (visible when count === 0)
│       └── Keys.onPressed             — arrow keys, Enter, Esc
└── Animation behaviors on scrim.opacity & cardHolder.opacity
    (fade in: 300ms OutCubic, fade out: 140ms OutCubic)
```

### PanelWindow config (lines 210–235)

| Property | Value | Why |
|---|---|---|
| `visible` | `root.open \|\| scrim.opacity > 0.001 \|\| cardHolder.opacity > 0.001` | Stays mapped during the close fade animation. |
| `color` | `"transparent"` | The card provides the visible surface. |
| `exclusionMode` | `ExclusionMode.Ignore` | Excluded from screenshots/wayfire-focus. |
| `WlrLayershell.namespace` | `"quickshell:altSwitcher"` | Matches the Hyprland blur layerrule. |
| `WlrLayershell.layer` | `Overlay` | Topmost layer. |
| `WlrLayershell.keyboardFocus` | `Exclusive` when `root.open`, `None` otherwise | Grabs keyboard only when the overlay is active. |
| `BackgroundEffect.blurRegion` | `blurRegion` (Niri only) | Frosted glass behind the card. |

---

## 9. Animation Behavior

- **Fade in (open):** 300ms, `Easing.OutCubic` on both `scrim.opacity` and
  `cardHolder.opacity`.
- **Fade out (close):** 140ms, `Easing.OutCubic` — intentionally faster than open
  so rapid Alt+Tab never feels laggy.
- **No transforms:** The card fades via pure opacity, no scale/translate.
- Durations are local to this file — no shared Motion/animation settings.

---

## 10. Empty State

When `windows.length === 0`, a centered Text reads **"No open windows"** in
`cSubText`. The grid/Flickable is implicitly empty.

---

## 11. Feature Flag / Configuration

- **Flag:** `Flags.altSwitcherEnabled` (default: `true`).
- **Persisted in:** `$XDG_STATE_HOME/quickshell/flags.json` via `Flags.qml`
  `FileView` → `JsonAdapter`. Watched for external changes (hot-reload).
- **UI toggle location:** Settings → Panels surface → row labeled
  **"Overview (Alt+Tab)"** with icon `"app-window"` → toggles `Flags.altSwitcherEnabled`.

---

## 12. Data Flow (how a keystroke opens the switcher)

```
User presses Alt+Tab
  → Niri: config.d/70-binds.kdl line 64
    Alt+Tab { spawn "qs" "ipc" "call" "altSwitcher" "next"; }
  → Hyprland: hypr/modules/binds.lua line 120
    bind = ALT, Tab, exec, qs ipc call altSwitcher next
  → Quickshell IPC
    → shell.qml IpcHandler target="altSwitcher"
    → function next() { altSwitcherLoader.item.next() }
  → AltSwitcher.next()
    → if not open: openSwitcher()  (opens overlay, currentIndex = 0)
    → if open:    increment currentIndex (wrap)
  → PanelWindow becomes visible
    → scrim + cardHolder fade in (300ms)
    → grid reflects compositor.toplevels (live, sorted)
```

---

## 13. What You Can Keep vs. What's Safe to Tweak

### Safe to customize (no wiring risk)
- `scrimDim` — change the darkness level (0 removes scrim, 1 is pure black).
- `tileWidth` / `tileHeight` — change tile size (grid auto-fits).
- `tileGap` — change spacing.
- `appLabel()` / `wsLabel()` — change display formatting.
- Header text ("Overview", instructions string) — pure cosmetic.
- Animation durations (300ms in / 140ms out) — tweak easing.

### Safe to customize with caveats
- `blurGlass` — currently `compositor.isNiri` only. Setting it `true` on Hyprland
  will assign a `blurRegion` but have no effect (no `BackgroundEffect` protocol);
  Hyprland blur is handled by the layerrule. Safe but ineffective there.
- Theme tokens (`cSurface`, `cPrimary`, etc.) — safe if you update `Theme.qml`
  consistently.

### Do not touch (wiring risk)
- The `open` property name / `openSwitcher()` distinction — the IPC handler
  explicitly avoids calling `open()` due to QML property shadowing.
- `Compositor.normalizeWindow()` shape — changing the field names breaks both
  `normalizeWindow()`, `focusWindow()`, and the delegate bindings.
- `focusWindow()` — Niri uses `niri msg action focus-window --id`; Hyprland uses
  `compositor.dispatch("focuswindow address:...")`. These are compositor-specific.
- `altSwitcherLoader` active condition (`Compositor.isNiri || Compositor.isHyprland`)
  — controls instantiation.
- The `WlrLayershell.namespace` value — must match the Hyprland blur layerrule.
- The IPC target name `"altSwitcher"` — must match `shell.qml` IpcHandler and the
  keybind `spawn "qs" "ipc" "call" "altSwitcher" ...`.

---

## 14. IPC Surface Summary

| Target | Family | Functions | Description |
|---|---|---|---|
| `altSwitcher` | shared (Niri + Hyprland) | `open`, `close`, `toggle`, `next`, `previous` | Full-screen window switcher overlay. |
