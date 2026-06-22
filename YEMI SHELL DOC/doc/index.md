# QuickShell QML Components Documentation

This documentation provides reference materials for the QML components that make up the QuickShell desktop shell for Wayland.

## Core Components

- [ShellRoot](ShellRoot.md) - The main application entry point and central coordinator
- [Compositor](Compositor.md) - Singleton abstraction layer for Hyprland/Niri compositors
- [AltSwitcher](AltSwitcher.md) - Window switcher component (with known issues)
- [ControlCenterWindow](ControlCenterWindow.md) - System control panel with quick access to system functions

## Project Overview

QuickShell is a custom desktop shell for Wayland that supports both Hyprland and Niri compositors through a compositor abstraction layer. The project follows a modular architecture with distinct areas for:

- **Core**: Main application logic in shell.qml
- **Compositor abstraction**: Unified API for different Wayland compositors
- **Services**: Backend integrations for system functions
- **Modules**: UI components organized by function (bar, control center, launcher, etc.)
- **Configuration**: Settings and appearance management

## Architecture Notes

- The project uses a compositor abstraction layer to support multiple Wayland compositors
- Services are organized as singletons for easy access throughout the application
- UI components follow a modular design with clear separation of concerns
- The codebase underwent significant restructuring to migrate from pywal to Matugen for theming

## Known Issues

As identified in the project audit, several components have issues that need attention:

- AltSwitcher.qml has multiple architectural problems preventing it from functioning
- Some components reference properties that don't exist in their dependencies
- Configuration files may reference non-existent IPC targets
- Some keybind configurations use incorrect binary paths or targets

For detailed information about each component, see the individual documentation files linked above.