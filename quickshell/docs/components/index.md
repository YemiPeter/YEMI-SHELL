# Yemi Shell Documentation

Developer reference for the Yemi QuickShell desktop environment. This index links to per-component documentation generated from the QML source.

## Core

- [ShellRoot](ShellRoot.md) — top-level shell entry point, IPC handlers, wallpaper pipeline, and service wiring
- [Config](Config.md) — singleton configuration aggregator for bar, appearance, notifications, popups, and dashboard toggles
- [Compositor](Compositor.md) — compositor abstraction layer supporting Hyprland and Niri backends

## Bar

- [Bar](Bar.md) — per-screen status bar with workspace, connectivity, volume, battery, and tray modules
- [BarWrapper](BarWrapper.md) — window wrapper that instantiates Bar per screen

## Pill System

- [PillOverlay](PillOverlay.md) — two-window architecture managing reserve spacer and overlay surface with fullscreen masking
- [Pill](Pill.md) — morphing pill body with state-driven surfaces, hover/pin interactions, and Ame transitions
- [PillState](PillState.md) — singleton tracking which monitor has which surface open

## Services

- [Notifs](Notifs.md) — notification service with DND, grouping, history, and cleanup
- [Matugen](Matugen.md) — color theme generation service
- [Audio](Audio.md) — audio volume and sink management
- [Brightness](Brightness.md) — display brightness control
- [Bluetooth](Bluetooth.md) — Bluetooth device management
- [Network](Network.md) — network connectivity and Wi-Fi management
- [VolumeMonitor](VolumeMonitor.md) — audio volume monitoring
- [Players](Players.md) — media player MPRIS integration
- [PowerProfiles](PowerProfiles.md) — power profile management
- [SystemUsage](SystemUsage.md) — system resource monitoring
- [Screenshot](Screenshot.md) — screenshot capture service
- [Logger](Logger.md) — logging service
- [IdleInhibitor](IdleInhibitor.md) — idle inhibition service
- [Hyprsunset](Hyprsunset.md) — Hyprland-specific sunset/blue-light filter

## Singletons

- [Theme](Theme.md) — theme color definitions
- [Flags](Flags.md) — feature flags and UI scale
- [Metrics](Metrics.md) — layout metrics and sizing constants
- [Dyn](Dyn.md) — dynamic values
- [PillState](PillState.md) — pill surface state tracker
