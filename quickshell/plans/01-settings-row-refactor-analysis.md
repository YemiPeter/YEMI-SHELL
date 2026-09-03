# D1: Settings Row Pattern Duplication - Analysis & Plan

## Executive Summary

**Finding:** The duplication is **real but nuanced**. The current pattern has two distinct variants for row types:

1. **Toggle/Nav rows** - Simple declarative pattern used in `Appearance.qml`, `BarPills.qml`, `Settings.qml`, `IdleLock.qml`
2. **Icon + GlyphIcon rows** - More complex pattern with custom chevron controls

**Recommended Approach:** Hybrid refactor that preserves flexibility for complex rows while consolidating simple rows into a model-driven pattern.

---

## Current State Analysis

### Files Using SettingsRow Pattern

| File | Rows | Type Variety |
|------|------|--------------|
| `Appearance.qml` | 10 | Seg, Toggle, Nav |
| `BarPills.qml` | 5 | Toggle |
| `Settings.qml` | 8 | Nav only |
| `IdleLock.qml` | 3 | Seg only |

**Total SettingsRow instances:** ~26 across 4 files

### Property Patterns by Row Type

#### Type A: Simple Toggle/Seg (appears 18 times)
```qml
SettingsRow {
    id: someRow
    surface: root
    name: "Label"
    [captionOnFocus: true]
    [icon: "icon-name"]
    [sourceIcon: "..."]
    
    SettingsSeg | LinkToggle { ... }
}
```

Common properties: `surface`, `name`, `icon`/`sourceIcon`, control widget

#### Type B: Nav with GlyphIcon (appears 8 times)
```qml
SettingsRow {
    id: someRow
    surface: root
    name: "Label"
    sub: "subtitle"
    [captionOnFocus: true]
    [icon: "icon-name"]
    
    GlyphIcon { ... }  // Chevron
}
```

---

## Concrete Examples of Duplication

### Example 1: Nav Rows with Chevron
**Settings.qml lines 60-75:**
```qml
SettingsRow {
    id: appearanceRow
    surface: root
    captionOnFocus: true
    icon: "sparkles"
    name: "Appearance"
    sub: "Clock, glyphs, accent palette"

    GlyphIcon {
        width: 16 * root.s
        height: 16 * root.s
        name: "chevron-right"
        color: root.focusRowItem === appearanceRow ? Theme.cream : Theme.iconDim
        stroke: 2.2
    }
}
```
**Repeated 8 times with only `id`, `icon`, `name`, `sub` changing.**

### Example 2: Simple Toggle Rows
**BarPills.qml lines 46-59:**
```qml
SettingsRow {
    id: leftRow
    surface: root
    sourceIcon: root.icRoot + "panel-left-expand.svg"
    sourceIconColor: "#FFFFFF"
    name: "Left pill"
    sub: "Workspaces pill"

    LinkToggle {
        s: root.s
        on: Flags.barLeftVisible
        onToggled: Flags.barLeftVisible = !Flags.barLeftVisible
    }
}
```
**Only `id`, `sourceIcon`, `name`, `sub`, and toggle target differ.**

---

## Proposed Refactor Architecture

### Option 1: ListsModel + Repeater (Recommended)

```qml
// modules/pill/models/SettingsModel.qml
import QtQuick 2.15

ListModel {
    id: model
    
    // Shared roles for all rows
    // Common: id, name, icon, sourceIcon, sourceIconColor, captionOnFocus
    // Seg: valType: "seg", vals: [], get: fn, set: fn
    // Toggle: valType: "toggle", get: fn, set: fn
    // Nav: valType: "nav", surface: string
    // Custom: controlComponent: Component { ... }
}
```

```qml
// modules/pill/components/SettingsRowDelegate.qml
import QtQuick 2.15
import "Singletons"

Item {
    id: delegate
    property var model: settingsModel // assigned by Repeater
    
    height: Math.max(textCol.implicitHeight, controlSlot.childrenRect.height) + 26 * s
    width: parent.width
    
    readonly property real s: model.surface ? model.surface.s : 1
    readonly property bool focused: model.surface && model.surface.focusRowItem === delegate
    
    SettingsRow {
        surface: model.surface
        id: rowItem
        name: model.name
        captionOnFocus: model.captionOnFocus || false
        icon: model.icon || ""
        sourceIcon: model.sourceIcon || ""
        sourceIconColor: model.sourceIconColor || Theme.cream
        sub: model.sub || ""
        last: model.last || false
        
        // Control injected from model or context
        Loader {
            id: controlLoader
            sourceComponent: model.controlComponent
        }
    }
    
    MouseArea {
        onClicked: model.surface.activateRow(rowItem)
    }
    
    SettingsRow { /* actual row with all children */ }
}
```

### Option 2: SettingsRow Factory (Simpler, preserves flexibility)

Create a helper function/table that generates SettingsRow components:

```qml
// In SettingsSurface.qml or a utility file
function createRow(id, props, control) {
    return Component {
        SettingsRow {
            id: id
            surface: root
            /* props are dynamically assigned */
        }
    }
}
```

---

## Code Reduction Potential

### Before (Appearance.qml example - 155 lines of rows)
```qml
SettingsRow { id: timeRow
    surface: root; name: "Time format"; icon: "clock"
    SettingsSeg { ... }
}
SettingsRow { id: secRow
    surface: root; name: "Clock seconds"; icon: "stopwatch"
    LinkToggle { ... }
}
// ... 13 more rows = ~200 lines of boilerplate
```

### After (Model-driven)
```qml
// Model definition (15 lines)
ListModel { id: settingsRows; /* 10 ListElements */ }

// View (10 lines)
Repeater {
    model: settingsRows
    delegate: SettingsRowDelegate { }
}

// Net reduction: ~175 lines (87% reduction in row declarations)
```

---

## Pitfalls & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Dynamic component loading overhead** | Performance | QML's Loader is efficient; use `active: true` for visible rows |
| **Complex control injection** | Logic complexity | Use `Component` in model entries for full flexibility |
| **Keyboard navigation index changes** | Breaking UX | Preserve `rows[]` array as computed property from model |
| **Conditional visibility** (e.g., compositor gating) | Logic scattering | Add `visibleCondition` role to model |
| **Custom row decorations** (GlyphIcon chevron) | Pattern diversity | Support `controlComponent` role for overrides |

---

## Implementation Steps

### Phase 1: Prototype
- [ ] Create `models/SettingsModel.qml` with ListModel definition
- [ ] Create `components/SettingsRowDelegate.qml` 
- [ ] Refactor `Appearance.qml` to use model + delegate (prototype only)
- [ ] Measure code reduction and verify visual parity

### Phase 2: Core Surfaces
- [ ] Refactor `Settings.qml` (nav-heavy, good candidate)
- [ ] Refactor `BarPills.qml` (toggle-heavy, good candidate)
- [ ] Refactor `IdleLock.qml` (seg-heavy, verify Seg handling)

### Phase 3: Complex Cases
- [ ] Handle `Appearance.qml` with conditional rows (themeRow visibility gating)
- [ ] Handle `Settings.qml` with compositor-specific rows (lookRow visibility)
- [ ] Verify `SettingsSurface.rows` array population works correctly

### Phase 4: Rollout
- [ ] Audit remaining settings surfaces
- [ ] Update or deprecate old pattern
- [ ] Add documentation for new pattern

---

## Alternative: Do Nothing?

**Why proceed:**
- 26+ SettingsRow instances scattered across 4+ files
- Each row has 5-6 repeated property declarations
- Adding new settings rows requires copying/boilerplate
- Violates DRY principle

**Why hesitate:**
- Current pattern has fine-grained control over each row
- Nested components (GlyphIcon, LinkToggle, SettingsSeg) vary significantly
- Keyboard navigation logic is tied to `rows[]` array

**Verdict:** Proceed with Option 1 (ListsModel) but preserve escape hatches for complex cases.

---

## Success Metrics

- [ ] Reduce total SettingsRow boilerplate by 40%
- [ ] All existing functionality preserved (visual testing)
- [ ] New settings row can be added in <5 lines (model entry)
- [ ] No performance degradation in settings surfaces
- [ ] Keyboard navigation maintains index stability