# Theme System Architecture Plan

## Overview

This document outlines the planned architecture for the theme system in QuickShell, based on analysis of existing skills and the Ricelin reference implementation.

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
│   ├── primaryColor: string (from Dyn.qml)
│   ├── secondaryColor: string
│   ├── backgroundColor: string
│   ├── textColor: string
│   ├── wallpaperSource: url
│   └── isLightMode: bool (default: false)
├── methods:
│   └── applyTheme(): void (calls matugen and updates system)
└── signals:
    └── themeChanged()
```

### Scope: Full Dynamic Theming from Day 1
- Matugen runs on every wallpaper change
- `singletons/Dyn.qml` reads the matugen output JSON and exposes colors
- `singletons/Theme.qml` references `Dyn` for runtime values
- Light and dark palette DEFAULTS exist in Theme.qml (so it works even if
  matugen hasn't run yet), but the live values come from Dyn

### Property Naming (Canonical)
- `primaryColor`
- `secondaryColor`
- `backgroundColor`
- `textColor`
- `wallpaperSource`

## Key Features

1. **Matugen Integration**: 
   - Calls matugen when wallpaper changes
   - Generates consistent color schemes across the system

2. **Compositor Abstraction Support**:
   - Handles both Niri and Hyprland theming
   - Different output commands based on active compositor
   - Consistent theme API regardless of backend

3. **QML Best Practices Compliance**:
   - Follows singleton guidelines from qt-qml.md
   - Proper property declarations and signal usage
   - Accessible via standard QML import mechanism

## Light Mode Support
- `isLightMode` is a bool property on Theme.qml
- Default value: `false` (dark mood)
- Toggled by a state file (suggest `state/theme-mode`, format `"light"` or `"dark"`)
- Theme.qml exposes BOTH light and dark palettes; the active one depends on `isLightMode`
- Add a `scripts/toggle-theme-mode.sh` script that flips the state file

## Version Control
All changes are committed to git; agents commit after each task; commit messages should be scoped (`feat(theme): ...`, `refactor: ...`).

## Migration Path

### From Pywal to Matugen
Build a full matugen-driven theme system that supersedes Pywal. The matugen output JSON becomes the source of truth for runtime colors. Static defaults in Theme.qml are the light/dark palette fallbacks used when matugen output is absent.

### Integration Points
- Terminal color schemes
- Window border theming
- Shell color scheme
- UI component styling

## Companion Files
What gets created in `singletons/`:
- `qmldir` — registers Theme and Dyn
- `Theme.qml` — main theme singleton, exposes the 5 properties + isLightMode
- `Dyn.qml` — reads matugen output, exposes the 5 properties

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