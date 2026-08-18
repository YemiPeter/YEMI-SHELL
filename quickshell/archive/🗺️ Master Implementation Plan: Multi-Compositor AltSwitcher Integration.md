# 🗺️ Master Implementation Plan: Multi-Compositor AltSwitcher Integration

## Goal
Fully integrate iNiR's AltSwitcher UI and logic into Yemi-Shell. It must work seamlessly on both Hyprland and Niri, respect Yemi-Shell's Material 3 `Theme.qml`, and handle the complex "key-held" Alt+Tab state.

## Architecture Mapping (iNiR → Yemi-Shell)

| iNiR Component | Yemi-Shell Replacement | Reason |
| :--- | :--- | :--- |
| `services/CompositorService.qml` | `singletons/CompositorService.qml` | We need a shape-shifting facade that feeds Niri-shaped data to the UI, regardless of the active backend. |
| `services/NiriService.qml` | Quickshell Native `Niri` / `Hyprland` | Yemi-Shell uses Quickshell's native modules directly via the facade. |
| `modules/common/Config.qml` | Hardcoded defaults / Future Yemi-Shell Settings | Strip iNiR's massive 2000-line config singleton. |
| `services/ThemeService.qml` | `singletons/Theme.qml` | Yemi-Shell uses its own strict Material 3 dominance engine. |
| `services/AppCatalog.qml` | Quickshell `System` or basic string mapping | Strip heavy app icon cataloging; rely on `app_id` and standard icon themes. |

---

## 📋 The Implementation Sections

### Section 1: The Compositor Facade (The Bridge)
**Objective:** Build the backend abstraction. The UI must never know if it's running on Hyprland or Niri.

**Checklist:**
- [x] Create `~/.config/quickshell/singletons/CompositorService.qml`.
- [x] Implement startup environment detection (`HYPRLAND_INSTANCE_SIGNATURE` vs `NIRI_SOCKET`).
- [x] Implement a 100ms throttled update timer to prevent UI lag during rapid window events.
- [x] Expose the **Unified Niri-Shaped API**:
  - [x] `windows`: Array of objects with `{ id, title, app_id, icon }`.
  - [x] `workspaces`: Object keyed by workspace ID.
  - [x] `mruWindowIds`: Array of window IDs in Most Recently Used order (capped at 20).
  - [x] `activeWindow`: Currently focused window object.
- [x] Implement unified methods:
  - [x] `focusWindow(id)`: Routes to `Hyprland.dispatch` or Niri IPC.
  - [x] `closeWindow(id)`: Routes to backend close commands.
- [x] Register in `singletons/qmldir`.

### Section 2: UI Extraction & Bloat Removal (The Visuals)
**Objective:** Port the QML structure but strip iNiR's heavy dependencies.

**Checklist:**
- [x] Read iNiR's `/home/yemi/iNiR/modules/altSwitcher/` directory.
- [x] Copy `AltSwitcher.qml` and its sub-components (thumbnails, list delegates) to `~/.config/quickshell/modules/altSwitcher/`.
- [x] **The Purge:** Search and destroy all references to:
  - [x] `Config.options` (replace with hardcoded sizes/booleans).
  - [x] `GlobalStates` (use local `property bool isOpen`).
  - [x] `ThemeService` / `MaterialThemeLoader` (replace with Yemi-Shell's `Theme.surface`, `Theme.primary`, etc.).
  - [x] `AppCatalog` (use standard Qt `Image` with `icon` fallback).
- [x] Wire the `ListView` or `Repeater` to read from `CompositorService.mruWindowIds` for the order.
- [x] Look up visual details in `CompositorService.windows` based on the MRU ID.

### Section 3: The Trigger Logic (The Engine)
**Objective:** Port iNiR's battle-tested IPC handler for Alt+Tab state management.

**Checklist:**
- [x] Extract iNiR's `IpcHandler` logic from their `AltSwitcher.qml`.
- [x] Implement the target `"altSwitcher"` in Yemi-Shell's `AltSwitcher.qml`.
- [x] Expose the exact methods iNiR uses:
  - [x] `show()`: Opens the UI, initializes the selection index to the *second* MRU window.
  - [x] `next()`: Cycles the selection index forward.
  - [x] `prev()`: Cycles backward.
  - [x] `select(id)`: Focuses the window, closes the UI, and updates the MRU tracker.
  - [x] `hide()`: Cancels the switch and closes the UI.
- [x] Ensure the `activeWindow` is pushed to the front of `mruWindowIds` only when `select()` is successfully executed.

### Section 4: Shell Instantiation & Keybinds (The Wiring)
**Objective:** Make the switcher exist in the shell and respond to global shortcuts.

**Checklist:**
- [x] Open `~/.config/quickshell/shell.qml`.
- [x] Instantiate the AltSwitcher component (replaced dummy `Item` stub with real `Loader`, correct path casing).
- [x] Provide the exact CLI commands to trigger the IPC (e.g., `qs ipc altSwitcher show`).
- [x] Provide the exact configuration blocks for the user to add to their compositors:
  - [x] **Hyprland (`~/.config/hypr/hyprland.conf`):** Keybinds for Alt_L+Tab (next), Alt_L+Shift+Tab (prev), and the release modifier (hide/select).
  - [x] **Niri (`~/.config/niri/config.kdl`):** Equivalent keybind blocks using Niri's spawn syntax to hit the Quickshell IPC.

### Section 5: Edge Cases & Hardening (The Polish)
**Objective:** Ensure it doesn't break in weird scenarios.

**Checklist:**
- [ ] **Empty State:** If `CompositorService.windows.length < 2`, the IPC `show()` command should do nothing (no point in switching to yourself).
- [ ] **Ghost Windows:** If a window closes while the switcher is open, the UI must reactively remove it from the list without crashing.
- [ ] **Icon Fallback:** If the `app_id` doesn't match an icon in the system theme, fall back to a generic window icon from Yemi-Shell's assets.