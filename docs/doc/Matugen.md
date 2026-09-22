# Matugen

## 1. Component Overview

Matugen is a service that generates color themes from wallpapers using the Matugen tool. It is responsible for reloading color schemes when the wallpaper changes and providing the shell with dynamic theme colors that match the current wallpaper.

## 2. Project Structure and Dependencies

- **File**: `services/Matugen.qml`
- **Imports**: `Quickshell`, `Quickshell.Io`
- **Instantiated by**: `shell.qml` as `QsServices.Matugen`
- **Depends on**: External `matugen` CLI tool

## 3. Component Hierarchy and Role

Matugen is a service object that wraps the Matugen color generation tool. It provides a `reload()` method that triggers color scheme regeneration, typically called after a wallpaper change.

## 4. Properties

Matugen does not expose documented public properties in the source.

## 5. Signals

Matugen does not define custom signals.

## 6. Methods

#### reload() : void
Triggers a reload of the color scheme by invoking the Matugen tool. Called by `shell.qml` after wallpaper application and via the `colors` IPC handler.

## 7. Inter-Component Interactions

- **shell.qml**: Calls `root.matugen.reload()` after wallpaper application and via the `ipcColorLoadProc` process
- **Theme singleton**: Consumes the generated color scheme

## 8. Usage Example

```qml
import "../../services" as QsServices

// Reload color scheme
QsServices.Matugen.reload()
```
