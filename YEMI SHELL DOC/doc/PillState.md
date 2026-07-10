# PillState

## 1. Component Overview

PillState is a singleton that tracks which monitor has which pill surface open. It is the single source of truth for pill surface state across the entire shell. All IPC calls to open, close, or toggle pill surfaces go through PillState, and PillOverlay reads from it to determine which surface to display.

## 2. Project Structure and Dependencies

- **File**: `singletons/PillState.qml`
- **Imports**: `QtQuick`
- **Instantiated by**: Any component that needs to control or observe pill surface state (e.g., `shell.qml` IPC handlers, `PillOverlay.qml`, `Pill.qml`)
- **Depends on**: No external dependencies; pure QtQuick singleton

## 3. Component Hierarchy and Role

PillState is a `Singleton` extending `QtObject`. It holds three string properties that describe the current pill state:

- `openMon` — the monitor name that has a surface open
- `openSurface` — the name of the currently open surface
- `peekMon` — the monitor name that is in peek mode

It exposes three methods to manipulate this state: `toggleSurface`, `close`, and `peek`.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| openMon | string | "" | No | Monitor name that currently has a pill surface open |
| openSurface | string | "" | No | Name of the currently open surface on that monitor |
| peekMon | string | "" | No | Monitor name in peek mode (temporary hover preview) |

## 5. Signals

PillState does not define custom signals.

## 6. Methods

#### toggleSurface(mon, surface) : void
Toggles a pill surface on the given monitor. If the same surface is already open on that monitor, it closes it. Otherwise, it opens the new surface by setting `openMon` and `openSurface`.

#### close() : void
Closes any open pill surface by clearing `openMon` and `openSurface`.

#### peek(mon) : void
Toggles peek mode for the given monitor. If the monitor is already in peek mode, it exits peek mode. Otherwise, it enters peek mode by setting `peekMon`.

## 7. Inter-Component Interactions

- **shell.qml**: The `pill` IPC handler calls `QsSingletons.PillState.toggleSurface(mon, surface)` for each surface type (launcher, mixer, calendar, etc.)
- **PillOverlay.qml**: Reads `QsSingletons.PillState.openMon` and `openSurface` to determine which surface to show on each monitor
- **Pill.qml**: Reads `QsSingletons.PillState.openMon` and `openSurface` indirectly through PillOverlay bindings

## 8. Usage Example

```qml
import "../../singletons" as QsSingletons

// Toggle the launcher surface on the focused monitor
QsSingletons.PillState.toggleSurface("eDP-1", "launcher")

// Close any open surface
QsSingletons.PillState.close()

// Toggle peek mode on a monitor
QsSingletons.PillState.peek("eDP-1")
```
