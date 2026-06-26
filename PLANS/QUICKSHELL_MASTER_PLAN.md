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
| **Phase 1** | Stability Pass (Room Making) | ✅ **DONE** |
| **Phase 2** | Bar Module (Audit & Verify) | ✅ **DONE** |
| **Phase 3** | Overlay Launcher Port | ✅ **DONE** |
| **Phase 4** | Pill-Surface Launcher | ⬜ **NEXT** |

---

---

## ✅ Phase 0: Theme System Foundation
**Status: COMPLETE**

The Matugen-based theme system is fully implemented and working:
- `singletons/Theme.qml` — Central theme singleton
- `config/AppearanceConfig.qml` — Theme configuration
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

## ⏳ Phase 2: Bar Module (Audit & Verify)
**Status: NOT STARTED**

> **Note:** The bar components in `modules/bar/` are original Yemi code, not copied from Ricelin. Ricelin has no `Modules/Bar/` directory. This phase tracks auditing and verifying the existing bar implementation.

### 🎯 Goal
Audit the current bar implementation, clean up stale files, and verify the bar is fully functional.

### 📋 Tasks

#### 2A. Audit Current Bar Implementation
- [ ] Audit all bar component imports (verify no dangling/circular imports)
- [ ] Audit bar component dependencies (confirm all referenced services exist)
- [ ] Document current bar architecture (map component hierarchy and data flow)

#### 2B. Clean Up Stale Files
- [ ] Delete `modules/bar/BarWrapper.qml` if broken/unused
- [ ] Review and remove any other stale files

#### 2C. Verify Bar Integration
- [ ] Verify bar renders without errors
- [ ] Verify all components functional
- [ ] Verify theme integration
- [ ] Verify no runtime errors
- [ ] Final bar testing

---

---

## ✅ Phase 3: Overlay Launcher Port
**Status: COMPLETE**

> **Decision: Option B — Keep current, no pulls needed.** Diff analysis (2026-06-26) showed only 2 content files differ (`AppRow.qml`, `Launcher.qml`), purely theming hooks. Current code has Theme integration (superior). The `activate()` function in Ricelin is brace-less, not cleaner — current `if (...) { }` is safer for future edits. Decision closed: no pull.

### 🎯 Goal
Finish and verify the existing launcher implementation. No Ricelin pulls needed.

### 📋 Tasks

#### 3A. Keep Current Launcher Files
- [x] `modules/launcher/AppRow.qml` — already has Theme integration (superior to Ricelin's hardcoded hex)
- [x] `modules/launcher/Launcher.qml` — already has Theme integration
- [x] `modules/launcher/LauncherWindow.qml` — project naming convention (Ricelin calls it `shell.qml`)
- [x] `modules/launcher/qmldir` — present and correct
- [x] `modules/launcher/lib/fuzzy.js` — identical to Ricelin's version

#### 3B. Verify Architecture
- [x] Theme integration confirmed — current files use `QsSingletons.Theme.*`
- [ ] Verify no dangling/circular imports
- [x] Wired into `shell.qml` (main) — already present via `launcherLoader`
- [ ] Wire into `modules/bar/` — not present in Ricelin source; skipped

#### 3C. Test
- [ ] Verify launcher opens/closes correctly
- [ ] Verify app launching works
- [ ] Verify search/fuzzy matching works
- [ ] Verify theme integration works

---

## ⏳ Phase 4: Pill-Surface Launcher (Future)
**Status: DEFERRED**

> **BarWrapper.qml — retained intentionally, but its role is already established.** This file is the pre-existing per-screen `PanelWindow` host for the *entire bar* (it loads `Bar.qml` + 4 popup windows). It is not a Phase 4 scaffold — it is live, working code. **Do not delete, and do not route the pill through it.** The pill swap target is `Bar.qml`'s center Clock loader directly.
>
> **Constraint for Phase 4:** Bar height must conform to `PillSurface.qml`'s implicit height (check Ricelin source value before starting port).
>
> **Naming:** Ricelin's `pill/Launcher.qml` is renamed to `PillLauncher.qml` on copy-in to avoid collision with `modules/launcher/Launcher.qml` (overlay launcher, Phase 3).

### 📋 Tasks
- [ ] Copy `.Ricelin/configs/quickshell/pill/*` into `modules/pill/` (rename `Launcher.qml` → `PillLauncher.qml`)
- [ ] In `Bar.qml`, remove Clock loader at "CENTER MODULE" block (~line 103-134)
- [ ] In `Bar.qml`, replace Clock loader (~line 134) with loader pointing to `modules/pill/PillLauncher.qml` (direct — NOT through BarWrapper)
- [ ] Verify standalone: search, fuzzy match, app launch, other 4 pills unaffected
- [ ] Theme it: replace hardcoded hex with `QsSingletons.Theme.*` (same pattern as `modules/launcher/`)
- [ ] Resize other 4 bar pills to match new center pill height
- [ ] ONLY AFTER all above verified: remove `.Ricelin/` from project tree (`~/Ricelin` is permanent reference)

---

## ⏳ Phase 5: Cleanup & Polish
**Status: PENDING (Blocks: Phase 4 completion)**

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

## 🎯 Next Steps

1. **Phase 2:** Audit current bar implementation (imports, dependencies, architecture)
2. **Phase 3:** Overlay Launcher Port (source exists at `.Ricelin/configs/quickshell/launcher/`)
3. **After Phase 3:** Phase 4 Pill-Surface Launcher
4. **After Phase 4:** Phase 5 Cleanup & Polish
5. **Optional:** Config, Shell, and Bar theme migration (not blocking)

---

## 🚨 Critical Rules (Non-Negotiable)

1. **PLAN FIRST** — No code changes without Yemi's explicit approval on the plan
2. **Dot Directories Are READ-ONLY** — Never modify `.Ricelin/`, `.iNiR/`, `.kilo/`, `.kiro/`, `.lingma/`
3. **Mechanical Work Only** — Agents implement agreed plans, don't decide architecture
4. **Traceable Changes** — Every edit must have a clear reason Yemi can understand
5. **No Frontend Polish at Expense of Backend** — Functionality first, aesthetics second
6. **No Fluff** — Direct communication, no padding, no restating
7. **Verify before marking complete** — Every ✅ must be backed by a real check. No agent claim without verification.

---