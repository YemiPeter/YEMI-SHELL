# QuickShell Checklist
**Shell by Yemi** — Implementation tracking for the Master Plan.

---

## 📋 Legend

| Symbol | Meaning |
|--------|--------|
| ✅ | Complete |
| ⏳ | Next / In Progress |
| ⬜ | Pending |
| ❌ | Blocked / Won't Do |

---

---

## ✅ Phase 0: Theme System Foundation
**Status: COMPLETE**

| Task | Status | Notes |
|------|--------|-------|
| Theme singleton (`singletons/Theme.qml`) | ✅ | Working |
| Theme config (`config/ThemeConfig.qml`) | ✅ | Working |
| Matugen service (`services/Matugen.qml`) | ✅ | Working |
| Color mode switching (light/dark) | ✅ | Working |
| GIF theme switching | ✅ | Working |
| State files (`state/colormode`, `state/gif-index`) | ✅ | Working |

---

---

## ✅ Phase 1: Stability Pass (Room Making)
**Status: COMPLETE**

### 1A. Runtime Error Audit

| Task | Status | Notes |
|------|--------|-------|
| Run shell and capture all runtime errors | ✅ | Done - shell loads, captured all warnings |
| Categorize errors: easy vs. hard vs. upstream | ✅ | 0 critical, 6 cosmetic warnings |
| Document in `YEMI SHELL DOC/BUG_REPORT.md` | ✅ | Updated with fixes and remaining issues |

### 1B. Fix Easy Bugs (Low-Hanging Fruit)

| Task | Status | Notes |
|------|--------|-------|
| **BUG-MATUGEN:** Matugen.qml missing | ✅ | Restored from git commit d97cf491 |
| **BUG-CC-001:** SystemStats.qml syntax error | ✅ | Removed invalid syntax, file deleted at user request |
| **BUG-MUSIC-001:** MusicPanel.qml undefined colors | ✅ | Added Theme singleton import, replaced root.* → Theme.* |
| **BUG-014:** Remove dangling import in `modules/bar/components/MediaPlayer.qml` | ✅ | Deleted import, confirmed no NoneType |
| **BUG-013:** Fix circular import in `modules/bar/components/Network.qml` | ✅ | Deleted import, confirmed no NoneType |
| **BUG-007:** Fix import in `modules/bar/components/Battery.qml` | ✅ | Deleted unused PowerProfiles import |
| **BUG-011:** Check imports in `modules/bar/Bar.qml` | ✅ | AUDIT PASS - all imports valid |
| **BUG-012:** Check imports in OSD components | ✅ | AUDIT PASS - OSD imports correct |
| **OVERALL:** Bar Health | ✅ | VERY GOOD - No critical issues |

### 1C. Comment Out Hard/Unplanned Services

| Task | Status | Notes |
|------|--------|-------|
| Comment out services that error on startup | ✅ | Completed if needed |
| Add `TODO:` comments explaining each | ✅ | Documented why and re-enable conditions |

### 1D. Clean Up Dead Files & Stale Services

| Task | Status | Notes |
|------|--------|-------|
| SystemStats.qml removed | ✅ | Deleted, removed from qmldir and ControlCenterWindow |
| Delete `dist/quickshell/` if exists | ✅ | Completed |
| Delete `modules/bar/BarWrapper.qml` if broken/unused | ✅ | Completed |
| Review and remove other stale files | ✅ | Completed in active code paths only |

---

---

## ✅ Phase 2: Bar Module Port
**Status: COMPLETE**

### 2A. Remove Broken Files

| Task | Status | Notes |
|------|--------|-------|
| Delete `modules/bar/components/Battery.qml` | ✅ | |
| Delete `modules/bar/components/Bluetooth.qml` | ✅ | |
| Delete `modules/bar/components/BluetoothPopupWindow.qml` | ✅ | |
| Delete `modules/bar/components/Brightness.qml` | ✅ | |
| Delete `modules/bar/components/BrightnessPopupWindow.qml` | ✅ | |
| Delete `modules/bar/components/Clock.qml` | ✅ | |
| Delete `modules/bar/components/ControlCenterToggle.qml` | ✅ | |
| Delete `modules/bar/components/MediaPlayer.qml` | ✅ | |
| Delete `modules/bar/components/Network.qml` | ✅ | |
| Delete `modules/bar/components/NetworkPopupWindow.qml` | ✅ | |
| Delete `modules/bar/components/NotificationPopups.qml` | ✅ | |
| Delete `modules/bar/components/StatusIndicators.qml` | ✅ | |
| Delete `modules/bar/components/SystemTray.qml` | ✅ | |
| Delete `modules/bar/components/Volume.qml` | ✅ | |
| Delete `modules/bar/components/VolumePopupWindow.qml` | ✅ | |
| Delete `modules/bar/components/Workspace.qml` | ✅ | |
| Delete `modules/bar/components/Workspaces.qml` | ✅ | |
| Delete `modules/bar/Bar.qml` | ✅ | |
| Delete `modules/bar/BarWrapper.qml` | ✅ | |
| Delete `modules/bar/qmldir` | ✅ | |

### 2B. Fresh Copy from Ricelin Bar

| Task | Status | Notes |
|------|--------|-------|
| Copy `Bar.qml` from `.Ricelin/configs/quickshell/pill/Modules/Bar/` | ✅ | READ-ONLY source |
| Copy `BarWrapper.qml` from `.Ricelin/configs/quickshell/pill/Modules/Bar/` | ✅ | READ-ONLY source |
| Copy all components from `.Ricelin/configs/quickshell/pill/Modules/Bar/components/` | ✅ | READ-ONLY source |

### 2C. Adapt to QuickShell Architecture

| Task | Status | Notes |
|------|--------|-------|
| Update all import paths in bar files | ✅ | Match QuickShell structure |
| Replace Dyn singleton usage with Theme + Config | ✅ | Use QuickShell singletons |
| Replace Ricelin imports with local imports | ✅ | Update all import statements |
| Update `modules/bar/qmldir` | ✅ | Register all bar components |

### 2D. Re-integrate into shell.qml

| Task | Status | Notes |
|------|--------|-------|
| Re-add bar module import in `shell.qml` | ✅ | |
| Re-add `BarWrapper` component to main view | ✅ | |
| Verify bar renders without errors | ✅ | |
| Verify all bar components work | ✅ | |

### 2E. Test

| Task | Status | Notes |
|------|--------|-------|
| Verify bar displays correctly | ✅ | |
| Verify all components functional | ✅ | |
| Verify theme integration | ✅ | |
| Verify no runtime errors | ✅ | |
| Final bar testing | ✅ | |

---

---

## ⏳ Phase 3: Overlay Launcher Port
**Status: PENDING (Blocks: Phase 2 completion)**

### 3A. Remove Bad Copy

| Task | Status | Notes |
|------|--------|-------|
| Delete `modules/launcher/AppRow.qml` | ⬜ | |
| Delete `modules/launcher/Launcher.qml` | ⬜ | |
| Delete `modules/launcher/LauncherWindow.qml` | ⬜ | |
| Delete `modules/launcher/qmldir` | ⬜ | |
| Delete `modules/launcher/lib/` (including `fuzzy.js`) | ⬜ | |

### 3B. Fresh Copy from Source

| Task | Status | Notes |
|------|--------|-------|
| Copy `AppRow.qml` from `.Ricelin/configs/quickshell/launcher/` | ⬜ | READ-ONLY source |
| Copy `Launcher.qml` from `.Ricelin/configs/quickshell/launcher/` | ⬜ | READ-ONLY source |
| Copy `LauncherWindow.qml` from `.Ricelin/configs/quickshell/launcher/` | ⬜ | READ-ONLY source |
| Copy `lib/fuzzy.js` from `.Ricelin/configs/quickshell/launcher/` | ⬜ | READ-ONLY source |

### 3C. Adapt to Our Architecture

| Task | Status | Notes |
|------|--------|-------|
| Update imports in copied files | ⬜ | Match our project structure |
| Integrate with `singletons/Theme.qml` | ⬜ | Use our theme singleton |
| Integrate with `config/Config.qml` | ⬜ | Use our config system |
| Wire into `shell.qml` (main) | ⬜ | Register launcher module |
| Wire into `modules/bar/` | ⬜ | Bar launcher button integration |

### 3D. Test

| Task | Status | Notes |
|------|--------|-------|
| Verify launcher opens/closes | ⬜ | |
| Verify app launching works | ⬜ | |
| Verify search/fuzzy matching | ⬜ | |
| Verify theme integration | ⬜ | |
| Verify no runtime errors | ⬜ | |

---

---

## ⏳ Phase 4: Cleanup & Polish
**Status: PENDING (Blocks: Phase 3 completion)**

| Task | Status | Notes |
|------|--------|-------|
| Review all TODOs and FIXMEs | ⬜ | |
| Clean up console warnings | ⬜ | |
| Standardize code formatting | ⬜ | |
| Add documentation | ⬜ | |
| Final testing pass | ⬜ | |

---

---

## 📊 Progress Summary

| Phase | Total | Complete | Remaining |
|-------|-------|----------|-----------|
| Phase 0 | 6 | 6 | 0 |
| Phase 1 | 20 | 20 | 0 |
| Phase 2 | 20 | 20 | 0 |
| Phase 3 | 13 | 0 | 13 |
| Phase 4 | 5 | 0 | 5 |
| **Total** | **64** | **46** | **18** |

---

---

## 🎯 Next Steps
1. **Start Phase 3:** Overlay Launcher Port
2. **After Phase 3:** Phase 4 Cleanup & Polish
3. **Optional:** Config, Shell, and Bar theme migration (not blocking)

---

---

## 🚨 Critical Reminders
- **Dot directories are READ-ONLY** — Never modify `.Ricelin/`, `.iNiR/`, `.kilo/`, `.kiro/`, `.lingma/`
- **PLAN FIRST** — No code changes without Yemi's approval
- **Mechanical work only** — Implement agreed plans, don't decide architecture
- **Traceable changes** — Every edit must have a clear reason
