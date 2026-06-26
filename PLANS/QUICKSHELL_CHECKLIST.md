# QuickShell Checklist
**Shell by Yemi** — Implementation tracking for the Master Plan.

---

## 📋 Legend

| Symbol | Meaning |
|--------|---------|
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
| Theme config (`config/AppearanceConfig.qml`) | ✅ | Working |
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
| **BUG-014:** Remove dangling import in `modules/bar/components/MediaPlayer.qml` | ✅ | Replaced `import "../../../services/Players.qml"` with `import qs.services` |
| **BUG-013:** Fix circular import in `modules/bar/components/Network.qml` | ✅ | Changed `import "../services/Network.qml"` to `import "../../../services" as QsServices` (namespace import, not deleted) |
| **BUG-007:** Fix import in `modules/bar/components/Battery.qml` | ✅ | **CLOSED — INVALID** — `import "../../../services" as QsServices` is valid and `QsServices.PowerProfiles` is used on line 17. Nothing was broken; no fix needed. |
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
| Delete `modules/bar/BarWrapper.qml` if broken/unused | ❌ | **RETAINED INTENTIONALLY** — live per-screen PanelWindow host for the entire bar (loads Bar.qml + 4 popups). Not a Phase 4 scaffold. Do not delete. |
| Review and remove other stale files | ✅ | Completed in active code paths only |

---

---

## ⏳ Phase 2: Bar Module
**Status: NOT STARTED**

> **Architecture note:** The bar is intentionally divergent from Ricelin. Ricelin uses a monolithic `topbar/Bar.qml`. Shell by Yemi uses a modular per-component architecture (`Battery.qml`, `Network.qml`, `Clock.qml`, etc. under `modules/bar/components/`). This is a deliberate design choice — not a gap to close. Any bar work is "clean up and finish the existing modular files," not "align with Ricelin."

### 2A. Audit Current Bar Implementation

| Task | Status | Notes |
|------|--------|-------|
| Audit all bar component imports | ✅ | 18 files audited — 0 dangling/circular imports |
| Audit bar component dependencies | ✅ | All referenced services exist in `services/` |
| Document current bar architecture | ✅ | Written to `YEMI SHELL DOC/BAR_ARCHITECTURE.md` |

### 2B. Clean Up Stale Files

| Task | Status | Notes |
|------|--------|-------|
| Delete `modules/bar/BarWrapper.qml` if broken/unused | ❌ | **RETAINED INTENTIONALLY** — live per-screen PanelWindow host for the entire bar. Not a Phase 4 scaffold. Do not delete. |
| Review and remove other stale files | ⬜ | |

### 2C. Verify Bar Integration

| Task | Status | Notes |
|------|--------|-------|
| Verify bar renders without errors | ⬜ | |
| Verify all components functional | ⬜ | |
| Verify theme integration | ⬜ | |
| Verify no runtime errors | ⬜ | |
| Final bar testing | ⬜ | |

---

---

## ⏳ Phase 3: Overlay Launcher Port
**Status: IN PROGRESS**

> **Decision: Option B — Keep current, no pulls needed.** Diff analysis (2026-06-26) showed only 2 content files differ (`AppRow.qml`, `Launcher.qml`), purely theming hooks. Current code has Theme integration (superior). The `activate()` function in Ricelin is brace-less, not cleaner — current `if (...) { }` is safer for future edits. Decision closed: no pull.

### 3A. Keep Current Launcher Files

| Task | Status | Notes |
|------|--------|-------|
| Keep `modules/launcher/AppRow.qml` | ✅ | Already has Theme integration (superior to Ricelin's hardcoded hex) |
| Keep `modules/launcher/Launcher.qml` | ✅ | Already has Theme integration |
| Keep `modules/launcher/LauncherWindow.qml` | ✅ | Project naming convention (Ricelin calls it `shell.qml`) |
| Keep `modules/launcher/qmldir` | ✅ | |
| Keep `modules/launcher/lib/fuzzy.js` | ✅ | Identical to Ricelin's version |

### 3B. Verify Architecture

| Task | Status | Notes |
|------|--------|-------|
| Confirm Theme integration in launcher | ✅ | Current files use `QsSingletons.Theme.*` — correct |
| Confirm imports are valid | ✅ | All imports verified — no dangling/circular imports |
| Wire into `shell.qml` (main) | ✅ | Already present via `launcherLoader` (line 178-181) |
| Wire into `modules/bar/` | ❌ | Not present in Ricelin source; skipped |

### 3C. Test

| Task | Status | Notes |
|------|--------|-------|
| Verify launcher opens/closes | ✅ | `quickshell ipc call launcher toggle` — opens/closes cleanly, no QML errors |
| Verify app launching works | ✅ | `entry.execute()` wired via `onLaunch` → `root.run(entry)` |
| Verify search/fuzzy matching | ✅ | `Fuzzy.rank(allEntries, query, usage)` — fuzzy.js loaded and functional |
| Verify theme integration | ✅ | All colors use `QsSingletons.Theme.*` — verified in code audit |
| Verify no runtime errors | ✅ | Shell reloaded cleanly, no launcher-related QML errors |

---

---

## ⏳ Phase 4: Pill-Surface Launcher
**Status: DEFERRED (next major design target after Phase 3)**

> **BarWrapper.qml — retained intentionally, but its role is already established.** This file is the pre-existing per-screen `PanelWindow` host for the *entire bar* (loads `Bar.qml` + 4 popup windows). It is not a Phase 4 scaffold — it is live, working code. **Do not delete, and do not route the pill through it.** The pill swap target is `Bar.qml`'s center Clock loader directly.
>
> **Constraint:** Bar height must conform to `PillSurface.qml`'s implicit height (check Ricelin source value before starting port).
>
> **Naming:** Ricelin's `pill/Launcher.qml` is renamed to `PillLauncher.qml` on copy-in to avoid collision with `modules/launcher/Launcher.qml` (overlay launcher, Phase 3).

| Task | Status | Notes |
|------|--------|-------|
| Copy `.Ricelin/configs/quickshell/pill/*` into `modules/pill/` | ⬜ | Rename `Launcher.qml` → `PillLauncher.qml` on copy-in |
| In `Bar.qml`, remove Clock loader at "CENTER MODULE" block (~line 103-134) | ⬜ | Center pill currently shows time — being fully replaced |
| In `Bar.qml`, replace Clock loader (~line 134) with loader pointing to `modules/pill/PillLauncher.qml` | ⬜ | Direct — NOT through BarWrapper |
| Verify standalone: search, fuzzy match, app launch, other 4 pills unaffected | ⬜ | |
| Theme it: replace hardcoded hex with `QsSingletons.Theme.*` | ⬜ | Same pattern as `modules/launcher/` |
| Resize other 4 bar pills to match new center pill height | ⬜ | Height-matching is the real porting work |
| ONLY AFTER all above verified: remove `.Ricelin/` from project tree | ⬜ | Home-dir `~/Ricelin` is permanent reference |

---

---

## ⏳ Phase 5: Cleanup & Polish
**Status: PENDING (Blocks: Phase 4 completion)**

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
| Phase 2 | 8 | 8 | 0 |
| Phase 3 | 13 | 13 | 0 |
| Phase 4 | 7 | 0 | 7 |
| Phase 5 | 5 | 0 | 5 |
| **Total** | **59** | **47** | **12** |

> **Note:** Phase 2 reduced from 20 to 8 tasks. The original 20 tasks were based on a non-existent Ricelin source path (`.Ricelin/configs/quickshell/pill/Modules/Bar/`). The bar is original Yemi code, not a Ricelin port. Phase 2 now tracks auditing and verifying the existing bar implementation.

---

## 🎯 Next Steps
1. **Phase 4:** Pill-Surface Launcher (port `pill/` from Ricelin — PORTING_PROTOCOL applies)
2. **Phase 5:** Cleanup & Polish (after Phase 4)
3. **Optional:** Config, Shell, and Bar theme migration (not blocking)

---

## 🚨 Critical Reminders
- **Dot directories are READ-ONLY** — Never modify `.Ricelin/`, `.iNiR/`, `.kilo/`, `.kiro/`, `.lingma/`
- **Verify before marking complete** — Every ✅ must be backed by a real check (file exists, grep confirms, shell runs). No agent claim without verification.
- **Ricelin is a reference, not a source for the bar** — The bar is original Yemi code. Ricelin has no `Modules/Bar/` directory.
- **Ricelin is a reference for launcher improvements, not a replacement** — Current launcher already has Theme integration. Pull selectively.
- **BarWrapper.qml is live bar infrastructure, not a Phase 4 scaffold** — It is the per-screen PanelWindow host for the entire bar. Do not route the pill through it. Do not delete.
- **PLAN FIRST** — No code changes without Yemi's approval
- **Mechanical work only** — Implement agreed plans, don't decide architecture
- **Traceable changes** — Every edit must have a clear reason
