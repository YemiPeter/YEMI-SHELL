# Theme System Architecture Plan

## Overview

This document outlines the planned architecture for the theme system in QuickShell, based on analysis of existing skills and the Ricelin reference implementation.

## Scope

The theme system implements full dynamic theming from day 1, not a static palette approach. Matugen runs on every wallpaper change to generate color schemes. The `singletons/Dyn.qml` component reads the matugen output JSON and exposes color properties. The `singletons/Theme.qml` component references `Dyn` for runtime values while providing light and dark palette defaults in Theme.qml (so the system works even before matugen runs), with live values coming from Dyn.

## Analysis Sources

### Skills from .kilo/agents
- Specialized agent profiles for guidance (architect, frontend-specialist, etc.)
- These provide methodology rather than direct code implementation

### Skills from .lingma/rules
- **YemiWorkingRules.md**: Defines workflow and project context
- **qt-qml.md**: QML best practices for component development

### Original Implementation Reference (RICELLIN/Ricelin.md)
- Uses **wallust** for palette extraction from wallpapers
- Dedicated `configs/quickshell/` directory for UI components
- Theming integrates with terminal, window borders, and shell color schemes
- Follows singleton pattern for global state management

## Proposed Architecture

### Placement: `singletons/Theme.qml`
- **Rationale**: Follows Qt Quick singleton pattern for app-wide state
- **Alignment**: Matches Ricelin's approach to theming as core service
- **Benefits**: 
  - Centralized theme management
  - Consistent access across all components
  - Separation from UI and compositor logic

### Component Structure

```
singletons/Theme.qml
├── imports: QtQuick, Qt.labs.platform (for file dialogs)
├── properties: 
│   ├── primaryColor: string
│   ├── secondaryColor: string
│   ├── backgroundColor: string
│   ├── textColor: string
│   ├── wallpaperSource: url
│   └── isLightMode: bool
├── methods:
│   ├── applyTheme(): void (calls matugen and updates system)
│   └── loadWallpaper(): void (selects wallpaper via dialog)
└── signals:
    └── themeChanged()

singletons/Dyn.qml
├── imports: QtQuick
├── properties: 
│   ├── primaryColor: string (from matugen output)
│   ├── secondaryColor: string
│   ├── backgroundColor: string
│   ├── textColor: string
│   └── wallpaperSource: url
└── methods:
    └── updateFromMatugen(): void (parses matugen JSON and updates properties)
```

### Key Features

1. **Full Dynamic Theming**:
    - Matugen runs on every wallpaper change to generate fresh color schemes
    - `singletons/Dyn.qml` reads matugen output JSON and exposes color properties
    - `singletons/Theme.qml` references `Dyn` for runtime values while providing light/dark palette fallbacks
    - System works immediately with fallback colors, then updates dynamically when matugen provides new values

2. **Light Mode Support**:
    - `isLightMode` boolean property on Theme.qml (default: false for dark mode)
    - Toggled via state file (`state/theme-mode` containing "light" or "dark")
    - Theme.qml exposes both light and dark palettes; active palette depends on `isLightMode`
    - Companion script `scripts/toggle-theme-mode.sh` flips the state file to switch modes

3. **Compositor Abstraction Support**:
    - Handles both Niri and Hyprland theming
    - Different output commands based on active compositor
    - Consistent theme API regardless of backend

4. **QML Best Practices Compliance**:
    - Follows singleton guidelines from qt-qml.md
    - Proper property declarations and signal usage
    - Accessible via standard QML import mechanism

## Migration Path

### From Pywal to Matugen
Build a full matugen-driven theme system that supersedes Pywal. The matugen output JSON becomes the source of truth for runtime colors. Static defaults in Theme.qml are the light/dark palette fallbacks used when matugen output is absent.

### Integration Points
- Terminal color schemes
- Window border theming
- Shell color scheme
- UI component styling

## Important Migration Considerations

> ### ⚠️ CRITICAL RULE — DO NOT REVERT PYWAL DISABLING
>
> During migration from Pywal to Matugen, when Pywal/Matugen are disabled in services/qmldir (task P1.5.5), the bar will appear visually broken (pywal.* references resolve to undefined because Pywal is no longer a singleton). This is EXPECTED behavior. The fix comes in the rewrite task (P1.7), NOT by reverting the disable step.
>
> **If tempted to "fix" the visible breakage by uncommenting the Pywal/Matugen lines in services/qmldir, STOP.** That is the wrong fix and defeats the migration. Continue with the change list building (P1.6) and reference rewrite (P1.7). The bar will be restored when P1.7 completes.
>
> **Only revert Pywal/Matugen disabling if explicitly instructed by the user.**

## Companion Files

The following files will be created in `singletons/`:
- `qmldir` — registers Theme and Dyn components
- `Theme.qml` — main theme singleton exposing the 5 properties + isLightMode
- `Dyn.qml` — reads matugen output JSON and exposes the 5 properties

(Note: Walls.qml from earlier considerations is out of scope for Phase 1 and will be deferred.)

## Version Control

All changes to the theme system are committed to git after each implementation task. Commit messages should be scoped to the theme subsystem using conventions like `feat(theme): ...` for new features and `refactor(theme): ...` for structural improvements.

## Implementation Steps

1. Create `singletons/Theme.qml` with basic singleton structure
2. Implement matugen integration methods
3. Connect themeChanged signal to UI components
4. Update compositor abstraction layer to use new theme system
5. Test with both Niri and Hyprland configurations

## Benefits of This Approach

- **Maintains consistency** with Ricelin reference implementation
- **Follows Qt/QML best practices** for singleton usage
- **Provides clean separation** between theme logic and UI components
- **Supports both compositor backends** through abstraction layer
- **Enables future extensibility** for additional theming features