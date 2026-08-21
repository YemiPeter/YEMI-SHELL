# Waffle Keybinds — Component Coverage Plan

> Status: **Phase 1 (2026-08-20):** Launcher (`Mod+Space → qs ipc call search toggle`)
> is wired and toggles. The bar's "Unified Settings" action targets the `settings`
> IPC (probe-launches `waffleSettings.qml`), not a keybind target. Non-launcher
> waffle IPC targets below (`wactionCenter`, `wnotificationCenter`, `wwidgets`,
> `taskview`, `overview`) are still **PENDING** — their bar panels haven't been
> ported yet. The in-panel keybinds nav (cheatsheet → Shortcuts via
> `navigateRequested(9)`) is wired inside `WQuickPage`, not an IPC target.
> File: `binds-waffle.lua` (Hyprland) / `71-binds-waffle.kdl` (Niri)

## IPC Registry Reference

The IPC registry (`modules/waffle/...`) defines these waffle-family targets.
Targets marked **[DONE]** already have an `IpcHandler` and a keybind.
Targets marked **[PENDING]** still need an `IpcHandler` added to their QML
component before a keybind can be assigned.

| IPC Target | Component | Function(s) | Status |
|---|---|---|---|
| `search` | `WaffleStartMenu.qml` | toggle / open / close | **DONE** |
| `wbar` | `WaffleBar.qml` | toggle / open / close | **DONE** |
| `wactionCenter` | `SystemButton.qml` | toggle / open / close | **PENDING** |
| `wnotificationCenter` | `TimeButton.qml` | toggle / open / close | **PENDING** |
| `wwidgets` | `WidgetsButton.qml` | toggle / open / close | **PENDING** |
| `taskview` | `TaskViewButton.qml` | toggle / open / close | **PENDING** |
| `overview` | `DesktopPeekButton.qml` | toggle / open / close | **PENDING** |

## Pending Work

When ready to add keybinds for the remaining components, follow this pattern:

### 1. Add `IpcHandler` to the bar button QML

Each bar button should get an `IpcHandler` block guarded by
`enabled: Config.options?.panelFamily === "waffle"` so it only fires in
waffle mode:

```qml
IpcHandler {
    target: "wactionCenter"
    enabled: Config.options?.panelFamily === "waffle"
    function toggle(): void {
        GlobalStates.waffleActionCenterOpen = !GlobalStates.waffleActionCenterOpen;
    }
    function open(): void {
        GlobalStates.waffleActionCenterOpen = true;
    }
    function close(): void {
        GlobalStates.waffleActionCenterOpen = false;
    }
}
```

Apply the same pattern to:
- **`TimeButton.qml`** → target `wnotificationCenter` → `waffleNotificationCenterOpen`
- **`WidgetsButton.qml`** → target `wwidgets` → `waffleWidgetsOpen`
- **`TaskViewButton.qml`** → target `taskview` → delegates to `inir taskview toggle`
- **`DesktopPeekButton.qml`** → target `overview` → `overviewOpen`

> **Note:** Bar buttons live inside `WaffleBar.qml`'s `LazyLoader`
> (`active: GlobalStates.barOpen`). IPC handlers inside those buttons are
> only registered when the bar is visible. If you need keybinds that work
> even when the bar is hidden, move the `IpcHandler` blocks to the `Scope`
> level in `WaffleBar.qml` (next to the existing `wbar` handler).

### 2. Add keybind lines to the waffle binds file

**Hyprland** (`hypr/modules/binds-waffle.lua`):
```
bind = $mod, A, exec, qs ipc call wactionCenter toggle   # Action center
bind = $mod, N, exec, qs ipc call wnotificationCenter toggle  # Notification center
```

**Niri** (`niri/config.d/71-binds-waffle.kdl`):
```
Mod+A { spawn "qs" "ipc" "call" "wactionCenter" "toggle"; }
Mod+N { spawn "qs" "ipc" "call" "wnotificationCenter" "toggle"; }
```

### 3. Suggested key assignments

Use the same key for the same function in both families where possible.

| Component | Suggested Key | IPC Target |
|---|---|---|
| Start menu / search | Mod+Space | `search` |
| Action center | Mod+A | `wactionCenter` |
| Notification center | Mod+N | `wnotificationCenter` |
| Widgets | Mod+Z | `wwidgets` |
| Task view | Mod+Tab | `taskview` |
| Desktop peek / overview | Mod+O | `overview` |
| Bar toggle | Mod+B | `wbar` |
