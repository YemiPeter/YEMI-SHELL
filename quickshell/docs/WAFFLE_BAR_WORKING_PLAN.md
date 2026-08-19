# Waffle Bar & Settings — Working Plan

> **Purpose:** Track every piece that makes the **waffle bar** function, fix them
> **one at a time**, and for each give a checklist of what must be fixed to make it
> *complete* (coherent / not dead). Also lays the groundwork for the **unified
> settings** so that, as panels come online, settings is placed where it belongs
> in the architecture (per `Yemi-Shell Project Bible §9` + `WAFFLE_SETTINGS_AND_SERVICES.md`).
>
> **Scope:** `panelFamily === "waffle"`. Pill family is untouched. iNiR is
> **read-only** (Rule 8) — we copy from `/home/yemi/iNiR`, never modify it.
>
> **Primary sources:**
> - `archive/WAFFLE-PORT-PLAN.md` (Phase 5 = port waffle panels)
> - `docs/waffle-keybinds-plan.md` (IPC registry + PENDING targets)
> - `docs/architecture/WAFFLE_COMPLEXITY_ANALYSIS.md`
> - `docs/architecture/WAFFLE_SETTINGS_AND_SERVICES.md`
> - `plans/Yemi-Shell Project Bible (CONTEXT.md)`

---

## 0. Definition of "bar works"

The bar is **working** when every visible control either:
1. Opens its real waffle surface (panel) when clicked, **and** that surface can
   close by click-outside / its own close affordance / re-clicking the button,
   **without** stealing clicks from the rest of the bar; **or**
2. Performs its direct action (launch app, toggle mute, etc.) with no missing
   dependency.

Today the bar renders, but the **right cluster is dead** because the panels
behind those buttons were never ported from iNiR.

---

## 1. Bar component inventory

| # | Bar control | Toggle state | Backing panel | Status in waffle | Source in iNiR |
|---|-------------|--------------|---------------|------------------|----------------|
| B0 | **Bar window** (`WaffleBar.qml`) | `GlobalStates.barOpen` | — | ⚠️ No `WlrLayershell.layer` (defaults `Top`) — hygiene only; **not** the launcher bug (see B1/B2) | — |
| B1 | **StartButton** | `searchOpen` (`&& query===""`) | `WaffleStartMenu` | 🐞 Ported, buggy | `startMenu/` |
| B2 | **SearchButton** | `searchOpen` (`&& query!==""`) | `WaffleStartMenu` | 🐞 Ported, buggy | `startMenu/` |
| B3 | **TaskViewButton** | `waffleTaskViewOpen` + `inir taskview toggle` | `WaffleTaskView` | ❌ Panel not ported | `taskview/` |
| B4 | **Tasks** | — (live model) | `TaskbarApps` | ✅ Works | (already in quickshell) |
| B5 | **Tray** | — | `TrayService` | ✅ Works | (already in quickshell) |
| B6 | **UpdatesButton** | — | `Updates` | ✅ Works | (already in quickshell) |
| B7 | **WeatherButton** | `waffleWidgetsOpen` | `WaffleWidgets` | ❌ Panel not ported | `widgets/` |
| B8 | **TimerButton** | `waffleWidgetsOpen` (altAction) | `WaffleWidgets` | ❌ Panel not ported | `widgets/` |
| B9 | **SystemButton** | `waffleActionCenterOpen` | `WaffleActionCenter` | ❌ Panel not ported | `actionCenter/` |
| B10 | **TimeButton** | `waffleNotificationCenterOpen` | `WaffleNotificationCenter` | ❌ Panel not ported | `notificationCenter/` |
| B11 | **DesktopPeekButton** | `overviewOpen` / `NiriService.toggleOverview` | compositor overview | ✅ Works on Niri; ⚠️ no waffle overview panel on Hyprland | (compositor) |
| B12 | **Right-click context menu** | — | `BarMenu` (Task Manager / Settings) | ✅ Works | (already in quickshell) |

Legend: ✅ works · ❌ missing panel · 🐞 buggy · ⚠️ caveat

**Key finding:** the buttons already set the **correct** `GlobalStates` flags
(`B3,B7,B8,B9,B10`). They are dead only because the four panels
(`taskview`, `widgets`, `actionCenter`, `notificationCenter`) were never copied
into `modules/waffle/`. iNiR's entry components (`WaffleTaskView.qml`,
`WaffleWidgets.qml`, `WaffleActionCenter.qml`, `WaffleNotificationCenter.qml`)
already bind to those exact flags and ship their own `IpcHandler` + click-outside
catcher — so porting is mostly a **copy + import-resolution** job.

---

## 2. Fix sequence (one at a time)

Order is chosen so each step unblocks the next and the bar gets more "complete"
progressively:

1. **B0 — Bar window layer** (foundation; fixes the launcher overlap at the root)
2. **B1/B2 — Launcher** (already ported; fix click-swallowing)
3. **B7/B8 — Widgets** (smallest port: 2 files)
4. **B10 — NotificationCenter** (13 files; needs `Notifications` service — present)
5. **B9 — ActionCenter** (24 files; needs Audio/Network/Brightness/Bluetooth — present)
6. **B3 — TaskView** (4 files; Niri-coupled via `WindowPreviewService`/`NiriService`)
7. **B11 — DesktopPeek** (verify/refine; Hyprland path)
8. **Settings track** (parallel, see §4) — begins as soon as B7 lands

---

## 3. Per-item checklists

### B0 — Bar window layer (`modules/waffle/bar/WaffleBar.qml`)
**Goal:** pin the bar to `WlrLayer.Top` explicitly and ensure the launcher's
full-screen catcher cannot sit above it / steal its clicks.

- [ ] Add `WlrLayershell.layer: WlrLayer.Top` to the `PanelWindow` (currently only `namespace` is set).
- [ ] Confirm `exclusionMode: ExclusionMode.Ignore` + `exclusiveZone` still reserves bar strip correctly.
- [ ] **Does NOT fix the launcher bug** — that is caused by `WlrKeyboardFocus.Exclusive` on Hyprland (see B1/B2), not by the bar's layer. B0 is independent hygiene.
- [ ] Re-check multi-monitor (`screenList` filter) still behaves.

### B1/B2 — Launcher (`modules/waffle/startMenu/WaffleStartMenu.qml`)
**Symptom:** tap-outside-to-close and tap-Start-to-close both fail while the
menu is open; the bar's Start/Search button is also starved of clicks.

**Root cause (investigated 2026-08-19, all reverted):** the menu `PanelWindow`
uses `WlrKeyboardFocus.Exclusive`. On **Hyprland** this grants an exclusive
seat/pointer grab that starves **every other surface** (the `wStartMenuBg`
catcher **and** the bar) of pointer input — regardless of layer, z-order, or
geometry. iNiR targets **Niri**, which does not implement this grab, so the bug
is Hyprland-specific. Evidence: full layer dump clean; catcher renders correctly
and works perfectly when the menu is *closed*; goes deaf only while the menu is
open; a catcher on the same `Overlay` layer stacked *above* the menu is still
starved → only a seat-level grab explains it. `WlrKeyboardFocus.Exclusive`
appears exactly once in the waffle tree (the start menu).

**Chosen fix: Option B — merge the catcher into the menu window.**
- [ ] Make `wStartMenu` PanelWindow fullscreen (transparent) on `Overlay`; keep `WlrKeyboardFocus.Exclusive`.
- [ ] Add a full-size transparent `MouseArea` **behind** the visible panel; `onClicked` → `searchOpen = false` (tap-outside AND tap-at-the-Start-location both land here, because the fullscreen exclusive surface geometrically covers the bar rect).
- [ ] Keep the panel content above that MouseArea (z-order) so panel clicks still work and typing is preserved.
- [ ] Remove the separate `wStartMenuBg` catcher window (now redundant).
- [ ] Smoke: open via keybind → type in search (must still work) → tap outside closes → tap Start-button location closes.

**Why not Option A (drop Exclusive → OnDemand):** the launcher is opened by
keybind, not a click, so `OnDemand` likely won't grant keyboard focus → the
search box could stop receiving typing (almost certainly why iNiR uses
`Exclusive`). A cheap 60s probe (flip to `OnDemand`, click-test, revert) is fine
to *confirm* the hypothesis, but **B is the committed fix** because it can't
break typing.

**Note:** B0 (pin bar layer) is unrelated hygiene — it does **not** fix this.

### B7/B8 — Widgets (`modules/waffle/widgets/`)
**Goal:** WeatherButton / TimerButton open the waffle widgets surface.

- [ ] Copy `widgets/` (2 files: `WaffleWidgets.qml`, `WidgetsContent.qml`) + `qmldir` from iNiR.
- [ ] Instantiate `WaffleWidgets {}` in `ShellWafflePanels.qml` (self-managed on `waffleWidgetsOpen`, like `WaffleStartMenu`).
- [ ] Audit `qs.modules.*` imports vs quickshell's existing modules (`common`, `common.widgets`, `common.functions`, `waffle.looks`). Add any missing.
- [ ] Confirm `Weather` service resolves for the weather readout.
- [ ] TimerButton altAction opens `waffleWidgetsOpen` + sets `Persistent.states.sidebar.bottomGroup.tab` — verify `Persistent` exists in quickshell or adapt.
- [ ] Smoke: click Weather → widgets surface opens/closes.

### B10 — NotificationCenter (`modules/waffle/notificationCenter/`)
**Goal:** TimeButton opens the waffle notification center.

- [ ] Copy `notificationCenter/` (13 files) + `qmldir` from iNiR.
- [ ] Instantiate in `ShellWafflePanels.qml`.
- [ ] `Component.onCompleted: Notifications.ensureInitialized()` — confirm `Notifications` singleton is the unified one (quickshell `services/Notifications.qml` adapter).
- [ ] Audit imports (uses `waffle.actionCenter`? `common.models.quickToggles`? ensure present).
- [ ] Verify `Notifications.list` / DND wiring matches quickshell's `Notifs`.
- [ ] Smoke: TimeButton toggles center; click-outside closes.

### B9 — ActionCenter (`modules/waffle/actionCenter/`)
**Goal:** SystemButton opens the waffle action center (volume/network/brightness/bluetooth/toggles).

- [ ] Copy `actionCenter/` (24 files) + `qmldir` from iNiR.
- [ ] Instantiate in `ShellWafflePanels.qml`.
- [ ] Audit imports: `waffle.actionCenter.{wifi,volumeControl,nightLight,hotspot,mainPage,bluetooth,toggles,screenTime}` sub-modules — each needs its qmldir (copy them too).
- [ ] Verify service deps resolve: `Audio`, `Network`, `Brightness`, `Bluetooth`, `Battery` (all in unified `services/`).
- [ ] `common.models.quickToggles` — confirm exists in quickshell; if not, port or adapt.
- [ ] Smoke: SystemButton toggles center; sub-pages (wifi/bt/volume) render.

### B3 — TaskView (`modules/waffle/taskview/`)
**Goal:** TaskViewButton opens the waffle task view with live window previews.

- [ ] Copy `taskview/` (4 files) + `qmldir` from iNiR.
- [ ] Instantiate in `ShellWafflePanels.qml`.
- [ ] **Niri dependency:** needs `WindowPreviewService` (ported per `WAFFLE_COMPLEXITY_ANALYSIS §11`) + `NiriService`/`CompositorService` (present). Confirm live-preview path works on Niri; document Hyprland limitation.
- [ ] Keep the `inir taskview toggle` IPC path OR switch to the ported panel's `waffleTaskViewOpen` toggle (decide during port).
- [ ] Smoke on Niri: TaskViewButton opens previews; closes correctly.

### B11 — DesktopPeek (`modules/waffle/bar/DesktopPeekButton.qml`)
**Goal:** show-desktop works on both compositors.

- [ ] Niri: `NiriService.toggleOverview()` — verify.
- [ ] Hyprland: `overviewOpen` has **no waffle overview panel** today. Decide: reuse `CompositorService` overview, or defer (mark as ⚠️ known gap).
- [ ] Click vs hover-peek states don't double-toggle.

---

## 4. Settings track (unified — placed where it belongs)

**Principle (Bible §9 + `WAFFLE_SETTINGS_AND_SERVICES.md`):**
yemishell-owned QML Settings for **both** families, built on the **unified
`qs.services` source**, **not** iNiR's app architecture. iNiR-only singletons
(`ThemeService`, `MaterialThemeLoader`, `AppLauncher`, `ShellUpdates`, `Idle`)
are **NOT** being ported.

**Current state:**
- `modules/waffle/settings/` (16 + 12 pages) **copied but PARKED** — needs the
  iNiR-only singletons above → will not run standalone.
- `waffleSettings.qml` (root) **PARKED** (same reason).
- `modules/settings/WaffleConfig.qml` **exists** (registered in `modules/settings/qmldir`) — the waffle config binding point.
- Bar's settings actions currently call `scripts/inir settings` (external).

**Placement plan (evolves as panels land):**
- [ ] Each ported panel's config lives under `Config.options.waffles.*` (already the schema: `actionCenter`, `bar`, `background`, `notifications`, `taskView`, `widgetsPanel`, `theming`, …).
- [ ] As each panel (B7–B10) is ported, note its config keys and confirm they map to `WaffleConfig.qml` / `Config.qml` (no new iNiR-only singletons).
- [ ] Decide the **unified settings host**: a single settings window (under `modules/settings/`) with a Waffle section + a Pill section, both reading unified services. The parked `modules/waffle/settings/` pages become reference, not the runtime.
- [ ] Replace bar's `scripts/inir settings` calls with the unified settings toggle (reuse `shell.qml` `settings` IPC → `SettingsWindow.qml`).
- [ ] When the unified settings is stood up, wire `WaffleConfig.qml` as the waffle binding layer and retire the parked standalone launcher.
- [ ] Update `WAFFLE_SETTINGS_AND_SERVICES.md` "PARKED" notes as items graduate.

**Settings checklist (to fill in as we reach each area):**

| Area | Panel landed? | Config keys confirmed | Unified-settings page planned |
|------|---------------|----------------------|-------------------------------|
| Widgets | after B7 | ☐ | ☐ |
| NotificationCenter | after B10 | ☐ | ☐ |
| ActionCenter | after B9 | ☐ | ☐ |
| TaskView | after B3 | ☐ | ☐ |
| Bar | B0/B1 | ☐ | ☐ |
| Background/Backdrop | (ported earlier) | ☐ | ☐ |

---

## 5. Cross-references
- Bar tree + service map: `docs/architecture/WAFFLE_SETTINGS_AND_SERVICES.md`
- Port phases: `archive/WAFFLE-PORT-PLAN.md` (Phase 5)
- IPC registry / PENDING targets: `docs/waffle-keybinds-plan.md`
- Complexity & risk: `docs/architecture/WAFFLE_COMPLEXITY_ANALYSIS.md`
- Niri coupling: `docs/architecture/WAFFLE_NIRI_DEPENDENCY_AUDIT.md`
- Pill safety guard (related, deferred): see `YEMI SHELL DOC/doc/PillOverlay.md` §9

## 6. Status log
| Date | Item | State |
|------|------|-------|
| 2026-08-19 | Inventory + plan created | B0–B12 mapped; sequence set; settings track scaffolded |
| 2026-08-19 | Launcher root cause found | B1/B2 caused by `WlrKeyboardFocus.Exclusive` seat grab on Hyprland (not B0). Chosen fix = Option B (merge catcher into menu window). B0 demoted to hygiene-only. |
