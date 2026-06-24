# Shell by Yemi — Documentation

> `~/.config/quickshell/YEMI SHELL DOC/`

---

## Quick Status

| Area | Status |
|------|--------|
| Bar + Workspaces | ✅ Working — Launcher pill removed, now 6 pills (Workspaces, MediaPlayer, Clock, Connectivity, Audio, Power) |
| Overlay Launcher | 🟡 In progress — Porting Ricelin's standalone overlay launcher with fuzzy search and usage ranking, adapted to Yemi's Pywal color system |
| Pill-Surface Launcher | 🔲 Planned — Ricelin's morphing pill-surface launcher will be ported later. Reservation made. Depends on building a morphing animation system for the bar pills first |
| App Launcher | ✅ Working (remove dead Qt5Compat import — BUG-013) |
| Wallpaper Browser | ✅ Working |
| Music Panel | ✅ Working |
| OSD Overlays | ✅ Working |
| Control Center | ✅ Working (4 undefined color props — BUG-015) |
| Notification Popups | ✅ Working |
| Alt+Tab Switcher | ❌ Disabled — 8 bugs, needs PanelWindow conversion (BUG-001 to BUG-011) |
| Screenshots | ❌ Region/window capture broken, clipboard copy broken (BUG-008, BUG-009) |
| Matugen Colors | ❌ Stub only — Pywal is the active color system (BUG-007, BUG-012) |
| Niri Hardware Keys | ❌ All 16 call `inir` binary instead of this shell (BUG_REPORT §6) |
| Settings Window | 🟡 Placeholder stub only (BUG-019) |

## Design Direction

The Yemi bar is the primary shell surface. Ricelin is treated as a component source — individual features are ported into Yemi's architecture (service singletons, Pywal colors, multi-screen Scope pattern, Material 3 animations).

### Launcher — Two-Phase Plan

**Phase 1 (current): Overlay Launcher**
- Port Ricelin's standalone overlay launcher (`launcher/shell.qml` + `Launcher.qml` + `AppRow.qml` + `fuzzy.js`)
- Runs as a full-screen `PanelWindow` on `WlrLayer.Overlay`, controlled via IPC
- Uses Quickshell's built-in `DesktopEntries` instead of manual .desktop parsing
- Fuzzy search with usage-frequency ranking, shared across all monitors via `Variants`
- All Ricelin hardcoded colors replaced with `QsServices.Pywal` equivalents

**Phase 2 (future): Pill-Surface Launcher**
- Port Ricelin's pill-surface launcher (`pill/Launcher.qml` + `SearchField.qml`)
- Requires building a morphing animation system for Yemi's bar pills first
- The pill would physically expand to contain the search field and results
- Reservation is made — no work starts until the morph system exists

---

## Documents

### [BUG_REPORT.md](./BUG_REPORT.md)
Every bug found during the post-restructure audit. 20 numbered bugs, each with file, line evidence, root cause, and a concrete fix. Sections cover critical crashes, high-severity silent failures, medium visual issues, minor cleanup, keybind bugs across both Hyprland and Niri, and orphan artifacts to delete.

### [PROJECT_REFERENCE.md](./PROJECT_REFERENCE.md)
Full project reference. Covers the annotated directory map, architecture patterns (state ownership, singletons, compositor abstraction, IPC, multi-screen pattern), then a complete API reference for every module — root types, property tables with types and descriptions, method signatures, and inter-component interactions. Includes the IPC surface, color system explanation, and keybind reference.

### [BAR_MIGRATION.md](./BAR_MIGRATION.md)
Legacy migration reference. Kept for the dependency diff and color bridging notes. Does not represent the active plan — see Design Direction above.

### [NIRI_KEYBINDS_DOCS.md](./NIRI_KEYBINDS_DOCS.md)
Niri compositor keybind reference. Documents the `dist/niri/config.d/` config structure and all key bindings — note that the hardware key binds and most overlay binds currently call the `inir` binary instead of this project's IPC. See BUG_REPORT.md §6 for the full broken-keybind list and fixes needed.