# QuickShell Master Plan
**Shell by Yemi** — Custom Wayland shell built on QuickShell, supporting Hyprland & Niri.

---

## 🎯 Project Identity & Philosophy

This is **Shell by Yemi** — a personal desktop shell project. It borrows concepts and components from multiple upstream sources (including `.Ricelin/`, `.iNiR/`, and others), but it is **its own project** with its own evolution path. We are not "Ricelin-inspired" or a fork; we are building a shell that works for Yemi's workflow.

**Core Philosophy:**
- **Yemi does the thinking, agents do the mechanical work**
- **PLAN FIRST, ALWAYS** — No code changes without agreed architecture
- **Understandability over cleverness** — Yemi must be able to read and understand every change
- **Backend correctness > frontend polish** — This is a shell, not a UI showcase
- **Traceable changes** — Every edit must have a clear "why"

**Reference Guidelines:**
- `.lingma/rules/` — QML/Qt best practices and review checklists
- `.kilo/agents/` — Agent workflow and clean implementation guidelines
- `.kiro/steering/` — Technical direction and architecture principles

---

---

## 🗺️ Roadmap Overview

| Phase | Goal | Status |
|-------|------|--------|
| **Phase 0** | Theme System Foundation | ✅ **DONE** |
| **Phase 1** | Stability Pass (Room Making) | ⏳ **NEXT** |
| **Phase 2** | Overlay Launcher Port | ⏳ PENDING |
| **Phase 3** | Cleanup & Polish | ⏳ PENDING |

---

---

## ✅ Phase 0: Theme System Foundation
**Status: COMPLETE**

The Matugen-based theme system is fully implemented and working:
- `singletons/Theme.qml` — Central theme singleton
- `config/ThemeConfig.qml` — Theme configuration
- `services/Matugen.qml` — Matugen integration service
- Color modes (light/dark) via `state/colormode`
- GIF themes via `state/gif-index`

**No changes needed here.** This is the stable foundation.

---

---

## ⏳ Phase 1: Stability Pass (The "Room Making" Phase)
**Status: NEXT PRIORITY**

Before adding new features, we must create a stable base. The current codebase has broken services, stale files, and runtime errors that make development painful.

### 🎯 Goal
Create a clean, error-free environment where we can work without constant crashes or console spam.

### 📋 Tasks

#### 1A. Runtime Error Audit
- [ ] Run the shell and capture all runtime errors
- [ ] Categorize errors: easy fixes vs. hard/unplanned vs. upstream issues
- [ ] Document findings in `YEMI SHELL DOC/BUG_REPORT.md`

#### 1B. Fix Easy Bugs (The "Low-Hanging Fruit")
Bugs that are simple, localized fixes that don't require architectural changes:

- [ ] **BUG-014: MediaPlayer.qml** — Remove dangling `import "../services/Players.qml"` (service doesn't exist)
- [ ] **BUG-013: Network.qml** — Remove dangling `import "../services/Network.qml"` (circular import)
- [ ] **BUG-007: Battery.qml** — Remove `import "../services/PowerProfiles.qml"` if service is unused
- [ ] **BUG-011: Bar.qml** — Fix any broken imports in the bar components
- [ ] **BUG-012: OSD components** — Verify all OSD imports are valid

#### 1C. Comment Out Hard/Unplanned Services
Services that throw errors but aren't critical for basic shell operation:

- [ ] Comment out problematic services in `shell.qml`:
  - `services/PowerProfiles.qml` (if it depends on missing `powerprofiles-daemon`)
  - `services/IdleInhibitor.qml` (if it errors on startup)
  - Any other service that crashes but isn't needed for core functionality
- [ ] Document each commented service with a `TODO:` comment explaining why and what's needed to re-enable

#### 1D. Clean Up Dead Files & Stale Services
Remove files that are:
- Duplicates
- From old versions
- Empty or placeholder
- In the wrong location

- [ ] Delete `dist/quickshell/` if it exists (stale build artifacts)
- [ ] Delete `modules/bar/BarWrapper.qml` if it's a broken wrapper (check if it's actually used)
- [ ] Review and remove any other stale files in active code paths

**⚠️ IMPORTANT:** Only touch files in the main project directories. **NEVER** modify anything in dot directories (`.Ricelin/`, `.iNiR/`, `.kilo/`, `.kiro/`, `.lingma/`). These are READ-ONLY reference directories.

---

---

## ⏳ Phase 2: Overlay Launcher Port
**Status: PENDING (Blocks: Phase 1 completion)**

The current `modules/launcher/` is a **badly copied, non-functional version** of Ricelin's launcher. It needs to be completely replaced.

### 🎯 Goal
Port Ricelin's overlay launcher into our shell, properly integrated.

### 📋 Tasks

#### 2A. Remove Bad Copy
- [ ] Delete entire `modules/launcher/` directory (AppRow.qml, Launcher.qml, LauncherWindow.qml, qmldir, lib/)

#### 2B. Fresh Copy from Source
- [ ] Copy from `.Ricelin/configs/quickshell/launcher/`:
  - `AppRow.qml`
  - `Launcher.qml`
  - `shell.qml` (Ricelin's shell integration)
  - `lib/fuzzy.js`

#### 2C. Adapt to Our Architecture
- [ ] Update imports to match our project structure
- [ ] Integrate with our `singletons/Theme.qml`
- [ ] Integrate with our `config/Config.qml`
- [ ] Wire into `shell.qml` (main shell file)
- [ ] Wire into `modules/bar/` (bar integration)

#### 2D. Test
- [ ] Verify launcher opens/closes correctly
- [ ] Verify app launching works
- [ ] Verify search/fuzzy matching works
- [ ] Verify theme integration works

---

---

## ⏳ Phase 3: Cleanup & Polish
**Status: PENDING (Blocks: Phase 2 completion)**

### 📋 Tasks
- [ ] Review all remaining TODOs and FIXMEs
- [ ] Clean up any remaining console warnings
- [ ] Standardize code formatting
- [ ] Add documentation for new systems
- [ ] Final testing pass

---

---

## 🚨 Critical Rules (Non-Negotiable)

1. **PLAN FIRST** — No code changes without Yemi's explicit approval on the plan
2. **Dot Directories Are READ-ONLY** — Never modify `.Ricelin/`, `.iNiR/`, `.kilo/`, `.kiro/`, `.lingma/`
3. **Mechanical Work Only** — Agents implement agreed plans, don't decide architecture
4. **Traceable Changes** — Every edit must have a clear reason Yemi can understand
5. **No Frontend Polish at Expense of Backend** — Functionality first, aesthetics second
6. **No Fluff** — Direct communication, no padding, no restating

---

---

## 📚 Reference Documents

| Document | Purpose |
|----------|---------|
| `PLANS/QUICKSHELL_CHECKLIST.md` | Detailed task checklist |
| `PLANS/THEME_SYSTEM_PLAN.md` | Theme system architecture |
| `YEMI SHELL DOC/README.md` | Project reference |
| `YEMI SHELL DOC/BAR_AUDIT.md` | Bar component audit |
| `YEMI SHELL DOC/BUG_REPORT.md` | Runtime errors and bugs |
| `.lingma/rules/YemiWorkingRules.md` | Agent working rules |
| `.lingma/rules/qt-qml-review.md` | QML code review checklist |
| `.kilo/agents/` | Agent workflow guidelines |
| `.kiro/steering/tech.md` | Technical direction |

---

---

## 🎯 Next Step

**Phase 1: Stability Pass is the immediate priority.**

The next concrete step is to:
1. Run the shell and capture runtime errors
2. Fix the easy bugs (BUG-014, BUG-013, etc.)
3. Comment out hard/unplanned services
4. Clean up dead files

This will create a stable base for the launcher port in Phase 2.

**The next step is: Execute Phase 1 - Stability Pass (Runtime Error Audit first).**

---