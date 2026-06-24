# QuickShell Project — Master Plan

> **Read this first.** Every agent working on this project must read this
> document and `QUICKSHELL_CHECKLIST.md` before doing any work. They define
> the project, the goal, the strategy, and the rules.

---

## 1. What is this project?

A custom Quickshell desktop shell for Hyprland (Niri secondary) at
`~/.config/quickshell/`. End goal: a clean, Ricelin-inspired overlay
launcher integrated with wallpaper-driven theming via Matugen.

The shell currently has a working top bar, music panel, control center,
notification popups, OSD overlays, and a slide-in app launcher. The color
system runs on the Theme singleton (matugen-driven via wallcolors.py).

---

## 2. Current state (project start)

| Component | Status | Action |
|---|---|---|
| Top bar | Working (with known bugs) | Keep, theme-update in Phase 1 |
| Pywal (`services/Pywal.qml`) | Removed | Done in Phase 1 |
| Matugen (`services/Matugen.qml`) | Stub | Remove in Phase 1 |
| Slide-in launcher (`modules/launcher/LauncherPanel.qml`) | Working | **Replace in Phase 3** |
| Music panel | Working | Keep |
| Control center | Working (4 undefined color props) | Fix during theme migration |
| Notification popups | Working | Keep |
| OSD overlays | Working | Keep |
| AltSwitcher | Broken (8 bugs, never loaded) | Remove in Phase 2 |
| SettingsWindow | Placeholder stub | Remove in Phase 2 |
| `dist/quickshell/` | Stale snapshot | Delete in Phase 2 |
| `QuickShellKeybinds.conf` | Orphan | Delete in Phase 2 |

---

## 3. Strategy — 4 phases, sequential

| Phase | Name | Outcome |
|---|---|---|
| 1 | **Theme System** | Matugen-driven theme with light/dark, replaces Pywal. Bar still works. |
| 2 | **Broken-stuff Cleanup** | Remove the broken (AltSwitcher, Settings, dead imports). Keep bar functional. |
| 3 | **Standalone Overlay Launcher** | Ricelin's `launcher/` (overlay) ported in. Owns `launcher` IPC. Replaces slide-in. |
| 4 (future) | **Pill-surface Launcher** | Ricelin's `pill/Launcher.qml` ported in. Needs morph animation system. |

Phases are strictly sequential. Do not start Phase N+1 until Phase N is
verified and committed.

---

## 4. Decisions made (locked in)

| Decision | Choice | Notes |
|---|---|---|
| Theme.qml location | `singletons/Theme.qml` | Matches Ricelin's Singletons/ structure |
| Theme scope | Full dynamic from day 1 | Matugen output is source of truth |
| Property names (canonical) | Ricelin-style: `onGlow`, `verm`, `cream`, `cardBot`, `cardTop`, `border`, `bright`, `dim`, etc. | ~44 properties; matches Ricelin's actual Theme.qml |
| Color pipeline | wallcolors.py → `~/.cache/ricelin/colors.json` → Dyn.qml (JsonAdapter) → Theme.qml | Follows Ricelin exactly; not matugen-direct |
| Light mode | Determined by wallcolors.py (`mean_l >= 0.40` in script), not by state file toggle |
| Singletons module | `singletons/` with Theme, Dyn, Flags | Flags is a new small singleton (paletteMode, uiFont) |
| Version control | All changes git-tracked | Commit after each task |
| Dyn singleton approach | `JsonAdapter` declarative binding, not manual `JSON.parse` | Ported verbatim from Ricelin |
| New launcher location | Loaded by main `shell.qml` | Single process, not separate `ShellRoot` |
| New launcher IPC | Replaces existing `launcher` IPC | Clean break; old `LauncherPanel.qml` deleted in Phase 3 |
| Pill launcher | Future (Phase 4) | Needs PillSurface/Theme/Flags/Motion singletons + morph animation system |

---

## 5. Rules for ALL agents

1. **Read MASTER_PLAN.md + CHECKLIST.md first.** Every time, before any work.
2. **Git everything.** Commit after each task with a scoped message.
3. **One task at a time.** Don't move on until current task is verified +
   committed.
4. **Don't deviate from the checklist.** If you need to do something not in
   the checklist, STOP and ask the user.
5. **Ask if uncertain.** Use the "STOP and ask" conditions listed in the
   checklist. When in doubt, ask.
6. **No scope creep.** Don't refactor unrelated code. Don't "improve" things
   not on the list. Don't remove code not in the task.
7. **Verify before reporting done.** Use the verification commands listed in
   the checklist. Paste the output in your report.
8. **Report back** with: what you did, what you verified, what you didn't
   touch, any anomalies, and a final `DONE` or `BLOCKED: <reason>`.
9. **Don't revert Phase 1 work to fix visible breakage.** When Pywal/
   Matugen are disabled in qmldir (task P1.5.5), the bar will look broken
   until the rewrite task (P1.7) finishes. This is expected. Reverting
   breaks the migration. Continue with the next task instead.

---

## 6. STOP and ask conditions (universal)

An agent MUST stop and ask the user before proceeding if any of these are
true:

- A file mentioned in the checklist doesn't exist
- A file exists that isn't in the checklist (might be relevant to the task)
- A property is referenced in code that isn't in the canonical property list
- A reference pattern doesn't match the mapping table in the checklist
- The agent is about to touch a file not in the task list
- The agent is about to delete code that isn't explicitly marked for removal
- The task list contradicts the actual code in the project
- The agent's work would break a working component (bar, music, control
  center, notifications, OSD)
- A git operation fails (conflict, missing remote, etc.)
- The agent encounters an error it doesn't know how to resolve
- The shell looks broken after a Phase 1 task (bar invisible, colors
  undefined) — DO NOT revert. This is expected mid-migration. Continue
  with the next task. Only revert if the user explicitly says so.

When in doubt: ask. It's faster than recovering from a mistake.

---

## 7. What NOT to do

- Don't touch `.Ricelin/` — read-only reference
- Don't delete the entire `dist/` directory — only the wal/ subfolder in
  Phase 1, the quickshell/ subfolder in Phase 2
- Don't modify data services (Audio, Brightness, Network, Bluetooth, Notifs,
  Players, IdleInhibitor, Logger, VolumeMonitor, SystemUsage, PowerProfiles,
  Hyprsunset) — only color services
- Don't change Ricelin's palette colors — use them as-is
- Don't start Phase N+1 before Phase N is verified
- Don't commit to git with vague messages like "updates" or "fix" — be scoped
- Don't run `qs -p` in a way that blocks (use `Ctrl+C` after a few seconds)
- Don't assume; verify

---

## 8. Reference files

| Document | Purpose |
|---|---|
| `PLANS/MASTER_PLAN.md` (this file) | Project context, rules, decisions |
| `PLANS/CHECKLIST.md` | Step-by-step tasks with verification |
| `PLANS/theme-system-architecture.md` | The technical design for the theme system |
| `YEMI SHELL DOC/BUG_REPORT.md` | The 20 known bugs in the current project |
| `YEMI SHELL DOC/PROJECT_REFERENCE.md` | Module/architecture reference |
| `~/.config/quickshell/.Ricelin/` | Ricelin source — read-only reference for ports |

---

## 9. Phases overview

### Phase 1 — Theme System (full dynamic with matugen)
Replace Pywal with a Matugen-driven theme. Create `singletons/Theme.qml`
and `singletons/Dyn.qml`. Static defaults for light/dark, dynamic values
from matugen. Update all `pywal.*` references to `theme.*`. Remove Pywal
infrastructure.

### Phase 2 — Broken-stuff Cleanup
Remove AltSwitcher (8 bugs, never loaded), SettingsWindow (placeholder),
Matugen service (already removed in Phase 1), `dist/quickshell/`, and
`QuickShellKeybinds.conf`. Fix BUG-013 and BUG-014. Keep bar functional.

### Phase 3 — Standalone Overlay Launcher
Port Ricelin's `launcher/` (Launcher.qml + AppRow.qml + shell.qml + fuzzy.js)
into the project. Wire as a Loader in main `shell.qml`. Replace the
existing `launcher` IPC. Delete the old slide-in `LauncherPanel.qml`. Bar's
launcher button calls the new IPC.

### Phase 4 (future) — Pill-surface Launcher
Port Ricelin's `pill/Launcher.qml` into the pill system. Requires porting
`PillSurface.qml`, `Theme.qml` (already in Phase 1), `Flags.qml`,
`Motion.qml` singletons. Build a morph animation system. This is a separate
large task and is not part of the current cycle.

---

## 10. Working mode with the user

- The user reviews each task's output
- The user verifies with the checklist
- The user unblocks the next task
- The user may adjust the plan as new questions come up
- The agents are tools — the user is the decision-maker
