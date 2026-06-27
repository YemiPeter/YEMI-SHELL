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
- `.kiro/steering/` — Technical direction and architecture principles

---

## 🗺️ Roadmap Overview

| Phase | Goal | Status |
|-------|------|--------|
| **Phase 0** | Theme System Foundation | ✅ **DONE** |
| **Phase 1** | Stability Pass (Room Making) | ✅ **DONE** |
| **Phase 2** | Bar Module (Audit & Verify) | ✅ **DONE** |
| **Phase 3** | Overlay Launcher Port | ✅ **DONE** |
| **Phase 4** | Pill-Surface Launcher | ⏳ **IN PROGRESS** |
| **Phase 5** | Cleanup & Polish | ⬜ **PENDING** |

**Progress: 56/63 tasks complete (88.9%)**

---

## ✅ Phase 0: Theme System Foundation
**Status: COMPLETE**

The Matugen-based theme system is fully implemented and working:
- `singletons/Theme.qml` — Central theme singleton (40+ color tokens, dynamic/static modes)
- `singletons/Dyn.qml` — Live wallpaper-derived palette from matugen JSON
- `singletons/Flags.qml` — Persisted session flags (25 properties, FileView-backed)
- `config/AppearanceConfig.qml` — Theme configuration
- `services/Matugen.qml` — Matugen integration service
- Color modes (light/dark) via `state/colormode`
- GIF themes via `state/gif-index`

**No changes needed here.** This is the stable foundation. Historical design: see Appendix D.

---

## ✅ Phase 1: Stability Pass (The "Room Making" Phase)
**Status: COMPLETE**

Before adding new features, we created a clean, error-free environment.

### 📋 Tasks

#### 1A. Runtime Error Audit
- [x] Run the shell and capture all runtime errors
- [x] Categorize errors: easy fixes vs. hard/unplanned vs. upstream issues
- [x] Document findings in `YEMI SHELL DOC/BUG_REPORT.md`

#### 1B. Fix Easy Bugs (The "Low-Hanging Fruit")
- [x] **BUG-MATUGEN:** Matugen.qml missing — Restored from git commit d97cf491
- [x] **BUG-CC-001:** SystemStats.qml syntax error — Removed invalid syntax, file deleted
- [x] **BUG-MUSIC-001:** MusicPanel.qml undefined colors — Added Theme singleton import
- [x] **BUG-014:** Remove dangling import in `modules/bar/components/MediaPlayer.qml`
- [x] **BUG-013:** Fix circular import in `modules/bar/components/Network.qml` — Changed to namespace import
- [x] **BUG-007:** Fix import in `modules/bar/components/Battery.qml` — **CLOSED — INVALID**
- [x] **BUG-011:** Check imports in `modules/bar/Bar.qml` — AUDIT PASS
- [x] **BUG-012:** Check imports in OSD components — AUDIT PASS
- [x] **OVERALL:** Bar Health — VERY GOOD, no critical issues

#### 1C. Comment Out Hard/Unplanned Services
- [x] Comment out services that error on startup
- [x] Add `TODO:` comments explaining each

#### 1D. Clean Up Dead Files & Stale Services
- [x] SystemStats.qml removed — Deleted, removed from qmldir and ControlCenterWindow
- [x] Delete `dist/quickshell/` if exists — Completed
- [x] Delete `modules/bar/BarWrapper.qml` if broken/unused — **RETAINED INTENTIONALLY** — live per-screen PanelWindow host for the entire bar (loads Bar.qml + 4 popups). Not a Phase 4 scaffold. Do not delete.
- [x] Review and remove other stale files — Completed in active code paths only

---

## ✅ Phase 2: Bar Module (Audit & Verify)
**Status: COMPLETE**

> **Architecture note:** The bar is intentionally divergent from Ricelin. Ricelin uses a monolithic `topbar/Bar.qml`. Shell by Yemi uses a modular per-component architecture (`Battery.qml`, `Network.qml`, `Clock.qml`, etc. under `modules/bar/components/`). This is a deliberate design choice — not a gap to close.

### 📋 Tasks

#### 2A. Audit Current Bar Implementation
- [x] Audit all bar component imports — 18 files audited, 0 dangling/circular imports
- [x] Audit bar component dependencies — All 14 referenced services exist
- [x] Document current bar architecture — Written to `YEMI SHELL DOC/BAR_ARCHITECTURE.md`

#### 2B. Clean Up Stale Files
- [x] Delete `modules/bar/BarWrapper.qml` if broken/unused — **RETAINED INTENTIONALLY**
- [x] Review and remove other stale files — None found

#### 2C. Verify Bar Integration
- [x] Verify bar renders without errors — Confirmed
- [x] Verify all components functional — Confirmed
- [x] Verify theme integration — Confirmed
- [x] Verify no runtime errors — Confirmed
- [x] Final bar testing — Confirmed

**Deliverable:** `YEMI SHELL DOC/BAR_ARCHITECTURE.md`

---

## ✅ Phase 3: Overlay Launcher Port
**Status: COMPLETE**

> **Decision: Option B — Keep current, no pulls needed.** Diff analysis showed only 2 content files differ (`AppRow.qml`, `Launcher.qml`), purely theming hooks. Current code has Theme integration (superior). Decision closed: no pull.

### 📋 Tasks

#### 3A. Keep Current Launcher Files
- [x] `modules/launcher/AppRow.qml` — already has Theme integration
- [x] `modules/launcher/Launcher.qml` — already has Theme integration
- [x] `modules/launcher/LauncherWindow.qml` — project naming convention
- [x] `modules/launcher/qmldir` — present and correct
- [x] `modules/launcher/lib/fuzzy.js` — identical to Ricelin's version

#### 3B. Verify Architecture
- [x] Theme integration confirmed — current files use `QsSingletons.Theme.*`
- [x] Confirm imports are valid — All imports verified
- [x] Wired into `shell.qml` (main) — already present via `launcherLoader`
- [ ] Wire into `modules/bar/` — not present in Ricelin source; skipped

#### 3C. Test
- [x] Verify launcher opens/closes — `quickshell ipc call launcher toggle` works
- [x] Verify app launching works — `entry.execute()` wired
- [x] Verify search/fuzzy matching — `Fuzzy.rank()` functional
- [x] Verify theme integration — All colors use `QsSingletons.Theme.*`
- [x] Verify no runtime errors — Shell reloaded cleanly

**Bugs found and fixed:** FIX-001/002 (Theme.dim2→dim), FIX-003 (qmldir versions), FIX-004 (dead import), FIX-005 (IPC handler confirmed correct). Full records: `PLANS/QUICKSHELL_FIX_LOG.md`

**Adaptation reference for future ports:** See Appendix E.

---

## ⏳ Phase 4: Pill-Surface Launcher
**Status: IN PROGRESS — raw port done, cleanup pass partially complete.**

> **BarWrapper.qml — retained intentionally, but its role is already established.** This file is the pre-existing per-screen `PanelWindow` host for the *entire bar* (loads `Bar.qml` + 4 popup windows). It is not a Phase 4 scaffold — it is live, working code. **Do not delete, and do not route the pill through it.** The pill swap target is `Bar.qml`'s center Clock loader directly.

> **Raw port confirmed:** `modules/pill/` exists with ~70 files copied from `.Ricelin/configs/quickshell/pill/`. Center pill wired into `modules/bar/Bar.qml` line 120 (`Pill.Pill { ... }`). Bar.qml is the swap target — NOT BarWrapper.qml.

> ⚠️ **Before marking any sub-task below complete:** run the verification command shown. This project has a documented history of agents claiming completion without proof. Full verification protocol: Appendix B.

### 📋 Tasks

#### 4A. Raw Port (✅ complete — 3 tasks)

| # | Task | Verification |
|---|------|-------------|
| 4A-1 | Copy `.Ricelin/configs/quickshell/pill/*` into `modules/pill/` | `ls modules/pill/ \| wc -l` → expect ~70 |
| 4A-2 | In `Bar.qml`, remove Clock loader at "CENTER MODULE" block | `grep -n "Clock\|KanjiClock\|clockLoader" modules/bar/Bar.qml` → expect 0 |
| 4A-3 | In `Bar.qml`, replace Clock loader with `Pill.Pill` loader | `grep -n "Pill\\.Pill" modules/bar/Bar.qml` → expect 1 (line 120) |

#### 4B. Cleanup Pass (✅ COMPLETE — 7/7 done, 1 deferred)

> **Pill visually matches Ricelin.** Intentional differences: blur layer removed (Yemi preference), margins set to `mTop: 12` / `mBottom: 8` for better spacing. Bar height `60` to prevent bottom clipping.

| # | Task | Detail | Status | Verification |
|---|------|--------|--------|-------------|
| 4B-1 | **Flags merge** | Project's `singletons/Flags.qml` is already the merged version (25+ properties, FileView persistence). Pill's duplicate `modules/pill/Singletons/Flags.qml` already deleted. qmldir reference already removed. | ✅ DONE | `test ! -f modules/pill/Singletons/Flags.qml && echo DELETED` |
| 4B-2 | **Theme/Dyn dedup** | Pill's duplicate `modules/pill/Singletons/Theme.qml` and `Dyn.qml` already deleted. qmldir references already removed. Pill files use project-wide `singletons/Theme.qml` and `Dyn.qml` via the `Pill.Singletons` module re-export. | ✅ DONE | `test ! -f modules/pill/Singletons/Theme.qml && echo DELETED` |
| 4B-3 | **Service stub removal** | `services/Mpris.qml`, `Pipewire.qml`, `SystemTray.qml`, `Notifications.qml` — all already deleted. `services/qmldir` entries already removed. Pill files import `Quickshell.Services.*` directly. | ✅ DONE | `grep -rn "Mpris\|Pipewire\|SystemTray\|Notifications" services/qmldir` → expect 0 |
| 4B-4 | **Pill centering (symmetrical expansion)** | Replaced `Row`+`Loader` with `Item` (`centerContainer`) + `anchors.centerIn: parent` in `Bar.qml`. Pill now expands symmetrically left/right. | ✅ DONE | `Bar.qml` uses `Item` + `anchors.centerIn: parent` |
| 4B-5 | **Blur removal** | Disabled `layer.enabled` and commented out `MultiEffect` block in `Pill.qml` (lines 554–560). Background gradient remains. | ✅ DONE | `Pill.qml` layer effect removed |
| 4B-6 | **Bottom clipping fix** | Bar height `56` → `60` (`config/BarConfig.qml`), `mBottom: 12` → `mBottom: 8` (`PillSurface.qml`). | ✅ DONE | bar height `60`, `mBottom: 8` |
| 4B-7 | **Visual match with Ricelin** | Pill margins (`mTop: 12`, `mBottom: 8`), bar height `60`, blur removed, symmetric expansion confirmed. | ✅ DONE | Confirmed by Yemi |
| 4B-8 | **Hyprland abstraction** | Deferred — pill is fully functional with Hyprland. Will be addressed in a later phase for Niri compatibility. | 🔄 DEFERRED | Moved to Phase 5 (or new Phase 6) |

> **Note:** Hyprland abstraction (4B-8) is deferred because the pill is fully functional with Hyprland. It will be addressed in a later phase for Niri compatibility.

---

## ⬜ Phase 5: Cleanup & Polish
**Status: PENDING (Blocks: Phase 4 completion)**

### 📋 Tasks
- [ ] Review all remaining TODOs and FIXMEs
- [ ] Clean up any remaining console warnings
- [ ] Standardize code formatting
- [ ] Add documentation for new systems
- [ ] Final testing pass

---

## 📊 Task Count Summary

| Phase | Total | Complete | Remaining |
|-------|-------|----------|-----------|
| Phase 0 | 6 | 6 | 0 |
| Phase 1 | 20 | 20 | 0 |
| Phase 2 | 8 | 8 | 0 |
| Phase 3 | 13 | 13 | 0 |
| Phase 4 | 11 | 7 | 4 (Hyprland abstraction deferred) |
| Phase 5 | 5 | 0 | 5 |
| **Total** | **63** | **54** | **9** |

**Overall progress:** 54/63 tasks complete (85.7%)

---

## 🚨 Critical Rules (Non-Negotiable)

1. **PLAN FIRST** — No code changes without Yemi's explicit approval on the plan
2. **Dot Directories Are READ-ONLY** — Never modify `.Ricelin/`, `.iNiR/`, `.kilo/`, `.kiro/`, `.lingma/`
3. **Mechanical Work Only** — Agents implement agreed plans, don't decide architecture
4. **Traceable Changes** — Every edit must have a clear reason Yemi can understand
5. **No Frontend Polish at Expense of Backend** — Functionality first, aesthetics second
6. **No Fluff** — Direct communication, no padding, no restating
7. **Verify before marking complete** — Every ✅ must be backed by a real check (file exists, grep confirms, shell runs). No agent claim without verification.

---

## 📚 Reference Documents

| Document | Purpose |
|----------|---------|
| `PLANS/QUICKSHELL_FIX_LOG.md` | Session fix records + executive summary |
| `PLANS/VERIFICATION_FRAMEWORK.md` | Independent verification methodology |
| `YEMI SHELL DOC/README.md` | Project reference |
| `YEMI SHELL DOC/BAR_ARCHITECTURE.md` | Bar component audit |
| `YEMI SHELL DOC/BUG_REPORT.md` | Runtime errors and bugs |
| `.lingma/rules/YemiWorkingRules.md` | Agent working rules |
| `.lingma/rules/qt-qml-review.md` | QML code review checklist |
| `.kiro/steering/tech.md` | Technical direction |

**Archived docs** (in `PLANS/archive/`, unique content merged into this file or FIX_LOG):
- `QUICKSHELL_CHECKLIST.md` — Superseded by this file
- `LAUNCHER_PHASE_3_CHECKPOINT.md` — Phase 3 historical decisions (adaptation points: Appendix E)
- `PHASE_4_PILL_PORT_PLAN.md` — Raw-port plan, executed (design spec: Appendix C)
- `THEME_SYSTEM_PLAN.md` — Theme architecture history (Appendix D)
- `PORTING_PROTOCOL (1).md` — Porting protocol (Appendix A)
- `PROMPT_VERIFY_AGENT_REPORT.md` — Agent verification protocol (Appendix B)
- `SESSION_FIX_REPORT.md` — Session fix details (in QUICKSHELL_FIX_LOG.md)
- `EXECUTIVE_SUMMARY.md` — Executive summary (in QUICKSHELL_FIX_LOG.md)
- `PHASE_4_CLEANUP_PLAN.md` — Cleanup implementation plan (executed)

---

## 🎯 Next Steps

1. **Phase 4B-4 through 4B-8:** Rewrite 5 Hyprland-coupled pill files to use Compositor abstraction
2. **Phase 4 verification:** Run `grep -rn "Quickshell\.Hyprland" modules/pill/` → expect 0
3. **Phase 5:** Cleanup & Polish (after Phase 4)
4. **Optional:** Config, Shell, and Bar theme migration (not blocking)

---

## Appendix A: Porting Protocol

> **Companion doc.** Read this alongside `MASTER_PLAN.md` before starting ANY task that ports code from a reference source (`.Ricelin/`) into the live project. Applies to Phase 3 (Overlay Launcher), Phase 4 (Pill Launcher), and any future port task.
>
> **Who does what:** You do the copying, pasting, and refactoring by hand. The AI's job is navigation — point you to the right spot, explain what's there, scaffold empty files/folders so you have somewhere to paste into. The AI never writes ported logic into your project files.

---

### 1. The core rule

The AI never edits your actual feature code. It can `mkdir` a folder or create an empty file with boilerplate (imports, `pragma Singleton`, `qmldir` registration line) — but the body of what's being ported is typed by you, by hand, every time.

---

### 2. What counts as one chunk

Same boundary logic as before:
- One file, if short (~under 80–100 lines)
- One logical section if longer — one function, one component block, one property group
- Never two unrelated files in one go

---

### 3. Navigator report format (what the AI gives you per chunk)

> 🔧 **CHUNK [n/total]: <short label>**
>
> 📍 **Source:** `<exact path in .Ricelin/>` — lines X–Y
> 📍 **Destination:** `<exact path in project>` — lines X–Y, or "new file"
>
> 🧠 **What this chunk does:** <2-3 sentences — enough that you understand it before you paste, not just transcribe it>
>
> ⚠️ **Adapt when you paste:** <e.g. "rename `Theme.qml`'s singleton import path," "swap `pywal.background` → `theme.backgroundColor`"> — described, not done for you
>
> 🛠 **Scaffolding:** if the destination file/folder doesn't exist yet, the AI creates it empty (folder + boilerplate header) so you have a place to paste into — the AI does this part, you do the rest
>
> ⏸ Over to you. Report back when it's in and tested.

---

### 4. What "scaffolding" means, precisely

| Allowed (AI does this) | Not allowed (yours to do) |
|---|---|
| `mkdir` for a new folder | Pasting the ported function/component body |
| Empty file with `pragma Singleton`, imports, `qmldir` entry | Writing the actual logic |
| Pointing out the exact line range in both files | Doing the rename/adapt for you |

---

### 5. Your loop, each chunk

1. Read the chunk explanation — make sure it actually makes sense first
2. Open source + destination side by side
3. Copy → paste, applying the flagged adaptations yourself
4. Test what's testable at this granularity (`qs -p`, or just visual check if it's not wired up yet)
5. Report back: `done, works` / `done but X broke` / `confused about Y — explain`
6. AI gives you the next chunk

If a chunk's logic doesn't click as you're pasting it — ask before moving on. That's the moment for a real explanation, not a summary.

---

### 6. STOP conditions

- The chunk depends on something not yet ported (a singleton/component from a later chunk) — AI flags this, you decide: stub it, or reorder
- The actual file on disk doesn't match what the checklist describes — don't paste against a guess, stop and check
- You've adapted something and it doesn't match the mapping table — flag the mismatch before continuing, don't silently pick one

---

### 7. Testing cadence

Test after every chunk if it's testable standalone. If a chunk only makes sense wired into something else (e.g. `AppRow.qml` needs `Launcher.qml` to render), test after the smallest group of chunks that forms one working unit — not after the whole file/feature.

---

## Appendix B: Agent Verification Protocol

> **Before marking ANY task complete in this plan:** every "done" claim needs a grep/diff shown as proof, not just stated. This project has a documented history of agent over-claiming.
>
> Full protocol text: `PLANS/archive/PROMPT_VERIFY_AGENT_REPORT.md`

---

### Why this protocol exists

A previous agent produced a report claiming mismatches between `CHECKLIST.md`'s design and Ricelin's actual implementation. Before any decision (Option A vs B) gets made, EVERY factual claim in that report must be independently checked against the real files on disk — not re-stated, not assumed, not trusted because it sounds thorough.

You are not redoing the analysis. You are auditing it.

---

### Rules — non-negotiable

1. For each claim, run the actual command and paste the **raw, unedited** output. Never paraphrase output as if it were a quote.
2. **Before** each command, explain in plain English: what the command does, and why THIS command is the right way to check THIS specific claim. This explanation is the point — the user is learning the method, not just collecting a verdict.
3. After the output, give one explicit verdict: `CONFIRMED`, `CONTRADICTED`, or `PARTIAL` (state exactly what part differs).
4. If the output contradicts the original report, say so plainly. Do not soften it, rationalize it, or assume the report meant something else.
5. Don't skip a claim because it "seems obviously true." Every claim gets a command and real output — no exceptions for confidence level.
6. If a file/path doesn't exist where expected, that's information, not a failure to paper over — show the actual error, don't substitute a guess for what probably would have been there.

---

### Output format — use exactly this per claim

> **Claim N: `<short label>`**
> 🧠 Why this command: `<plain-English reason this specific command proves or disproves this specific claim>`
> 💻 Command: `<exact command>`
> 📋 Real output:
> ```
> <paste raw output here>
> ```
> ✅/❌ Verdict: `CONFIRMED` / `CONTRADICTED` / `PARTIAL` — `<one-line why>`

---

### Minimum requirement for any ✅ claim in this plan:

1. Run the verification command listed in the task table
2. Paste the raw output
3. State the verdict: PASS or FAIL with the exact output that proves it

No claim is accepted without this three-step sequence.

---

## Appendix C: Phase 4 Design Specification

> **Source:** `PLANS/archive/PHASE_4_PILL_PORT_PLAN.md` — the detailed port plan that was executed for the raw port (4A). Retained here as the design reference for the pill system.

### Architecture

```
Bar (5 pills total)
├── LEFT: Workspaces — fixed, stays as-is
├── CENTER: Full Pill.qml — morphs between all 18 surfaces
│   ├── Launcher (search + app list)
│   ├── Calendar
│   ├── Mixer (audio)
│   ├── Media (MPRIS)
│   ├── Clipboard
│   ├── Wallpaper
│   ├── Power
│   ├── Link (network/BT)
│   ├── BatterySurface
│   ├── Settings → Appearance, Updates, Display, Input, Look, IdleLock, FontPicker
│   ├── Keybinds
│   ├── Recorder
│   ├── SysmonSurface
│   └── Toast (notification popups)
├── RIGHT-1: WiFi/BT — fixed, stays as-is
├── RIGHT-2: Brightness/Volume — fixed, stays as-is
└── RIGHT-3: Battery/charging — fixed, stays as-is
```

### File Inventory

**Core (4 files):**
| File | Lines | Role |
|------|-------|------|
| `Pill.qml` | 1,646 | Pill body — morphing container, surface gating, all state |
| `PillSurface.qml` | 52 | Base class for all surfaces |
| `shell.qml` | 399 | Top-level ShellRoot — PanelWindows, monitor management |
| `qmldir` | — | Module registration |

**Surfaces (18 files):** Launcher, Calendar, Mixer, Media, Clipboard, Wallpaper, Power, Link, BatterySurface, Settings, Appearance, Updates, Display, Input, Look, IdleLock, Keybinds, FontPicker, SysmonSurface, Recorder

**Support Components (~22 files):** SearchField, GlyphIcon, Marquee, Tooltip, Toast, Tray, MinimizedTray, WifiGlyph, Workspaces, Osd, SettingsHeader, SettingsRow, SettingsSeg, SettingsSurface, DisplayLabel, DisplayPicker, Filament, HFader, VFader, HeatHold, WheelScroller, Ame, LinkBt, LinkToggle, LinkWifi

**JS Libraries (6):** fuzzy.js, binds.js, keychord.js, monitors.js, setDeco.js, setInput.js

**Pill Singletons (14 files):** Motion, Notifs, Battery, ScreenRec, Sysmon, Weather, Workspacerules, Events, Cliphist, Devices, Walls (+ Theme/Dyn/Flags now use project-wide singletons)

### Critical Adaptation Points

1. **Theme bridging:** Pill's `Theme.*` refs now resolve to project-wide `singletons/Theme.qml` (done in 4B-2)
2. **Usage file path:** Ricelin uses `/ricelin/launcher-usage.json` → project uses `/quickshell/launcher-usage.json`
3. **Icon functions:** `Quickshell.iconPath(entry.icon, true)` — works as-is
4. **Hyprland scripts:** Many surfaces reference `.config/hypr/scripts/` — Ricelin-specific, must be checked per-surface
5. **Service access:** Pill files import `Quickshell.Services.*` directly (Mpris, SystemTray, Notifications) — no wrapper stubs needed (done in 4B-3)

---

## Appendix D: Theme System History

> **Source:** `PLANS/archive/THEME_SYSTEM_PLAN.md` — the original theme architecture plan. Phase 0 is complete; this is retained as historical context.

**Key decisions from the original plan:**
- Full dynamic theming from day 1 (not static palette)
- Matugen runs on every wallpaper change → generates color JSON
- `singletons/Dyn.qml` reads matugen output, exposes color properties
- `singletons/Theme.qml` references `Dyn` for runtime values, provides fallback defaults
- Light/dark mode via `state/colormode` + `scripts/toggle-colormode.sh`
- Compositor abstraction: handles both Niri and Hyprland theming
- Migration from Pywal to Matugen (Pywal fully removed)

**⚠️ Critical rule from migration:** When Pywal/Matugen are disabled in `services/qmldir`, the bar appears visually broken (pywal.* refs resolve to undefined). This is EXPECTED. The fix is rewriting the references, NOT re-enabling Pywal.

---

## Appendix E: Phase 3 Adaptation Reference

> **Source:** `PLANS/archive/LAUNCHER_PHASE_3_CHECKPOINT.md` — adaptation points discovered during the Phase 3 diff analysis. Useful as a template for future port tasks.

### Adaptation Points (from Ricelin → Shell by Yemi)

| # | Area | Ricelin | Shell by Yemi | Action |
|---|------|---------|---------------|--------|
| 1 | Theme colors | Hardcoded hex (`#e6d6cb`, `#fff6f0`, `#565e6a`) | `Theme.cream`, `Theme.bright`, `Theme.dim` | Replace on copy-in |
| 2 | Usage storage path | `/ricelin/launcher-usage.json` | `/quickshell/launcher-usage.json` | Change path |
| 3 | Icon functions | `Quickshell.iconPath(row.entry.icon, true)` | Same — works as-is | No change |
| 4 | Entry execution | `entry.execute()` | `Quickshell.exec(it.exec)` | Verify compatibility |
| 5 | Module structure | Various import paths | Project module paths (`../../singletons`, etc.) | Adjust imports |

**Decision record:** Option B chosen — keep current files, no Ricelin pull. Current code already has Theme integration (superior to Ricelin's hardcoded hex). The `activate()` function in Ricelin is brace-less, not cleaner — current `if (...) { }` is safer for future edits.
