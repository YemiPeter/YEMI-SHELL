# Shell by Yemi — Documentation

> `~/.config/quickshell/YEMI SHELL DOC/`

---

## Documents

### [BUG_REPORT.md](./BUG_REPORT.md)
Every bug found during the post-restructure audit. 20 numbered bugs, each with file, line evidence, root cause, and a concrete fix. Sections cover critical crashes, high-severity silent failures, medium visual issues, minor cleanup, keybind bugs across both Hyprland and Niri, and orphan artifacts to delete.

### [PROJECT_REFERENCE.md](./PROJECT_REFERENCE.md)
Full project reference. Covers the annotated directory map, architecture patterns (state ownership, singletons, compositor abstraction, IPC, multi-screen pattern), then a complete API reference for every module — root types, property tables with types and descriptions, method signatures, and inter-component interactions. Includes the IPC surface, color system explanation, and keybind reference.

### [BAR_MIGRATION.md](./BAR_MIGRATION.md)
Plan for copying the Shell by Yemi bar into the Ricelin project at `.Ricelin/configs/quickshell/`. Covers what files are being moved, what Ricelin already has, the full dependency diff (services, compositor abstraction, config, import paths), three options for bridging the color system difference (Pywal dynamic vs Ricelin's static Theme), recommended directory layout, shell wiring instructions, bugs to fix before migrating, and a step-by-step checklist.

### [NIRI_KEYBINDS_DOCS.md](./NIRI_KEYBINDS_DOCS.md)
Niri compositor keybind reference. Documents the `dist/niri/config.d/` config structure and all key bindings — note that the hardware key binds and most overlay binds currently call the `inir` binary instead of this project's IPC. See BUG_REPORT.md §6 for the full broken-keybind list and fixes needed.

---

## Quick Status

| Area | Status |
|------|--------|
| Bar + Workspaces | ✅ Working |
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
| Bar → Ricelin migration | 🔲 Planned — see BAR_MIGRATION.md |
