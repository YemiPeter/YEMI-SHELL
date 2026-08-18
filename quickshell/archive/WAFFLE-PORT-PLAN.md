# YEMI-SHELL: Waffle Port & Niri Completion Plan

**Created**: August 14, 2026  
**Owner**: Yemi Peter  
**Repository**: `~/.config/quickshell`

---

## 🎯 End Goal

Port iNiR's **waffle** (Fluent-style) panel family into Yemi-Shell, achieving feature parity with Hyprland on **Niri**, with glassmorphism backgrounds and blur effects. Unify the settings UI across both panel families and compositors.

---

## 🏗️ Architecture Decisions (Locked In)

### 1. Config System: Engine Ported, Data Trimmed
- **Adopted**: iNiR's `Config.qml` engine (~2000 lines, generic JSON reader/writer)
- **Rejected**: iNiR's 60-section `config.json` (too much cruft: ai, booru, reddit, ytmusic)
- **Shipped**: Trimmed `~/.config/yemi-shell/config.json` with only waffle-critical sections:
  - `panelFamily`, `enabledPanels`, `appearance`, `background`, `waffles`

### 2. Service Strategy: Smart Combine via Adapter Pattern
- **Yemi-Shell already has**: Audio, Network, Brightness, Bluetooth, etc. (same names as iNiR)
- **Adapters created** (P1): `Notifications.qml`, `MprisController.qml`, `Battery.qml`, `DateTime.qml`, `TrayService.qml`
  - These proxy Yemi's existing singletons so waffle's hardcoded imports resolve
- **No rewrites**: We port iNiR services only where Yemi lacks them (NiriService, WindowPreviewService)

### 3. Theming: Dominance Engine Stays Sovereign
- **Single-writer rule**: Only `after-wall.sh` writes `~/.cache/yemi-shell/colors.json`
- **Waffle reads**: Dominance colors via thin shim (not iNiR's ThemeService)
- **No matugen**: Dominance engine is final

### 4. Settings: Unified UI, Compositor-Aware
- **iNiR's waffle Settings** becomes the unified settings for both waffle and Pill
- **Pill settings stay**: Your existing settings panel is preserved
- **Compositor branches**: Niri-specific settings (blur, animations) vs Hyprland-specific settings

### 5. Visual North Star: Pibble's Glass Philosophy
- **Borrow**: Layer-shell namespace → compositor blur pattern
- **Borrow**: Blurred live-wallpaper variants
- **Don't borrow**: Pibble's matugen theming or launcher-only architecture
- **Result**: Glass/glassmorphism styling on both Hyprland and Niri

---

## 📊 Current Status (August 14, 2026)

### ✅ Completed
- **Phase W1** (Wallpaper foundation): Fixed persistence bug + shell.qml paths (empirically verified)
- **Phase P0** (Port Blueprint): Full dependency map, rename table, collision check
- **Phase P1** (Waffle Substrate): ⚠️ **95% complete**
  - ✅ Ported `Config.qml`, `GlobalStates.qml`, `Directories.qml`, `FileUtils.qml`
  - ✅ Created trimmed `config.json`
  - ✅ Created service adapters (5 stubs)
  - ✅ Registered in `qmldir` files
  - ⚠️ **Issue**: Adapters not actually proxying Yemi's singletons (creating new instances instead)
    - Fix: Rewrite `Notifications.qml` and `MprisController.qml` to import and re-export `Notifs` and `Players`

### 🔄 In Progress
- None

### 📋 Upcoming
- **Phase P2**: wBackground + wBackdrop + Niri/Hyprland blur rules (glass background)
- **Phase P3**: wBar + hard services → waffle usable on Hyprland
- **Phase P4..N**: Remaining panels/services → Niri parity → Dominance theming → settings

---

## 🗺️ Phased Roadmap

### Phase 0: Cleanup & Loose Ends ✅ DONE
- [x] Delete dead AltSwitcher QML (`modules/altSwitcher/`)
- [x] Remove orphaned `CompositorService.qml`
- [x] Fix `Updates.qml` ReferenceError
- [x] Wire snappy-switcher theming + blur rules + keybinds

### Phase 1: Waffle Substrate ⚠️ 95% DONE
- [x] Port Config engine (`Config.qml`, `Directories.qml`, `FileUtils.qml`, `GlobalStates.qml`)
- [x] Patch `illogical-impulse` → `yemi-shell` in `Directories.qml`
- [x] Create trimmed `~/.config/yemi-shell/config.json`
- [x] Create service adapters (5 stubs)
- [x] Register in `qmldir` files
- [ ] **FIX**: Rewrite `Notifications.qml` and `MprisController.qml` to proxy Yemi's `Notifs` and `Players` singletons

### Phase 2: Glass Background (Priority Win) 🔜 NEXT
- [ ] Port `wBackground` + `wBackdrop` panels
- [ ] Port Niri blur rules from `defaults/niri/config.d/80-layer-rules.kdl`
- [ ] Add Hyprland layer rules for blur
- [ ] Verify glass effect renders on both compositors

### Phase 3: Core Waffle Panels
- [ ] Port `wBar` + wire hard services (Audio, Network, Brightness, Battery, DateTime, TrayService)
- [ ] Verify waffle renders and functions on Hyprland
- [ ] Test live reload with Dominance theming

### Phase 4: Niri Integration
- [ ] Port `NiriService.qml` (1545 lines - the Niri event loop)
- [ ] Port `CompositorService.qml` (407 lines - abstraction layer)
- [ ] Port `NiriKeybinds.qml` (401 lines - deferred keybind service)
- [ ] Verify waffle works on Niri with feature parity

### Phase 5: Remaining Panels
- [ ] Port remaining waffle panels one at a time:
  - wStartMenu, wActionCenter, wNotificationCenter, wNotificationPopup
  - wOnScreenDisplay, wWidgets, wTaskView, wLock, wPolkit, wSessionScreen
- [ ] Wire remaining services as needed

### Phase 6: Theming Bridge
- [ ] Create Dominance → waffle appearance shim
- [ ] Verify waffle panels react to wallpaper changes live
- [ ] Test edge cases (grayscale, bright, dark, pastels)

### Phase 7: Unified Settings
- [ ] Port iNiR's waffle Settings panel
- [ ] Add "Yemi / Dominance" section (mood, grayscale, color strength)
- [ ] Add compositor-aware sections (Niri blur/animation settings)
- [ ] Integrate Pill settings into unified UI

### Phase 8: Harden & Optimize
- [ ] Bug hunt across both compositors
- [ ] Profile startup time and RAM usage
- [ ] Defer heavy services
- [ ] Clean logs

---

## 🔧 Technical Details

### Directory Structure
```
~/.config/quickshell/
|-- modules/
|   |-- common/                    # Ported from iNiR
|   |   |-- Config.qml            # Generic JSON config engine
|   |   |-- Directories.qml       # Path resolution (patched for yemi-shell)
|   |   |-- FileUtils.qml         # File utilities
|   |   |-- GlobalStates.qml      # Global state management
|   |   |-- qmldir                # Module registry
|   |-- waffle/                   # To be ported (Phases 2-5)
|   |   |-- bar/
|   |   |-- background/
|   |   |-- backdrop/
|   |   |-- ... (18 panel directories)
|   |-- pill/                     # Existing Yemi-Shell Pill (untouched)
|-- services/
|   |-- qmldir                    # Service registry (50+ services)
|   |-- Audio.qml                 # Existing
|   |-- Network.qml               # Existing
|   |-- Notifications.qml         # Adapter (needs fix)
|   |-- MprisController.qml       # Adapter (needs fix)
|   |-- Battery.qml               # Stub
|   |-- DateTime.qml              # Stub
|   |-- TrayService.qml           # Stub
|   |-- ... (to be ported)
|-- singletons/
|   |-- qmldir
|   |-- Theme.qml                 # Existing
|   |-- Dyn.qml                   # Existing (watches colors.json)
|   |-- Flags.qml                 # Existing
|   |-- PillState.qml             # Existing
|   |-- Metrics.qml               # Existing
```

### Config File Locations
- **Yemi-Shell config**: `~/.config/yemi-shell/config.json` (trimmed, waffle-focused)
- **Theme colors**: `~/.cache/yemi-shell/colors.json` (Dominance engine, single-writer)
- **Wallpaper state**: `~/.local/state/yemi-shell/current-wallpaper` (live pipeline)

### Service Adapters (P1) - NEED FIX
```qml
// Notifications.qml - should proxy Yemi's Notifs
pragma Singleton
import QtQuick
import qs.services as YemiServices

YemiServices.Notifs { id: root }

// MprisController.qml - should proxy Yemi's Players
pragma Singleton
import QtQuick
import qs.services as YemiServices

YemiServices.Players { id: root }
```

### Rename Table
| Component | iNiR Value | Yemi-Shell Value |
|-----------|------------|------------------|
| Shell ID | `inir` | `yemishell` |
| Config dir | `illogical-impulse` | `yemi-shell` |
| IPC command | `inir ipc` | `yemi ipc` |

---

## 🎨 Design Philosophy

### Waffle = Functional Backbone
- iNiR's battle-tested panels and services
- Fluent-style UI (window-like, glass effects)
- Compositor-agnostic (works on Hyprland and Niri)

### Pibble = Visual North Star
- Glass/glassmorphism styling
- Layer-shell blur via compositor rules
- Wallpaper-first design
- Live wallpaper previews with blurred variants

### Dominance = Color Brain
- Wallpaper → 8 dominant colors → Material 3 schema
- Single-writer pattern (after-wall.sh only)
- No matugen, no pipeline rewrites
- Hue preserved, only Lightness changed

---

## 📝 Known Issues

### P1 Adapter Bug
**Issue**: `Notifications.qml` and `MprisController.qml` create new instances instead of proxying Yemi's singletons  
**Impact**: Waffle panels import these but get empty instances instead of Yemi's functional services  
**Fix**: Rewrite to import and re-export `Notifs` and `Players`

### Niri Blur (Not Started)
**Issue**: Niri blur rules not yet ported  
**Impact**: Glass background won't render on Niri  
**Fix**: Port `defaults/niri/config.d/80-layer-rules.kdl` in Phase 2

---

## 🚀 Next Steps

1. **Fix P1 adapter bug** (15 minutes)
2. **Phase P2**: Port wBackground + wBackdrop + blur rules (1-2 hours)
3. **Test glass background** on Hyprland and Niri
4. **Phase P3**: Port wBar + hard services (2-3 hours)
5. **Verify waffle renders** on Hyprland

---

## 📚 References

- **iNiR repo**: `/home/yemi/iNiR` (source for waffle port)
- **Pibble repo**: `https://github.com/kianblakley/pibble` (visual reference)
- **snappy-switcher**: `https://github.com/OpalAanan/snappy-switcher` (alt switcher)
- **Quickshell docs**: `https://quickshell.org`
- **Niri docs**: `https://github.com/YaLTeR/niri`

---

**Status**: Phase P1 95% complete. Ready for P2 after adapter fix.  
**Last Updated**: August 14, 2026