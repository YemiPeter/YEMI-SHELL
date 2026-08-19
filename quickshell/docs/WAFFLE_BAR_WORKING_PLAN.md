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

### 1.1 Bar sides — components & connection checklist

The bar is one `PanelWindow` whose children are laid out in three
`BarGroupRow` groups (**LEFT** `bloatRow` / **CENTER** `appsRow` / **RIGHT**
`systemRow`). For the bar to be **fully connected**, every button on a side must
open/close its backing panel correctly and have no broken dependency. Checklist
per side (maps to the B0–B12 inventory above):

 **LEFT side — `bloatRow` (`WeatherButton`)**
 - [x] `WeatherButton` → `waffleWidgetsOpen` → `WaffleWidgets`.
 - [x] `WaffleWidgets.qml` + `WidgetsContent.qml` copied into `modules/waffle/widgets/` (done 2026-08-19).
 - [x] Instantiated in `ShellWafflePanels.qml` (self-managed on `waffleWidgetsOpen`).
 - [x] `Weather` service resolves for the weather readout.
 - [x] Click Weather → widgets surface opens; click-outside / its own close closes (open confirmed live; close = verbatim iNiR catcher).
 - [x] `leftAlignApps` toggle hides LEFT weather and shows it in RIGHT `systemRow` (`FadeLoader`).

 **CENTER side — `appsRow` (`StartButton`, `SearchButton`, `TaskViewButton`, `WTaskbarSeparator`, `Tasks`)**
 - [x] `StartButton` + `SearchButton` → `searchOpen` → `WaffleStartMenu` (connected; works on Niri via verbatim iNiR; Hyprland click-swallow tracked in next item).
 - [ ] Compositor-aware launcher fix landed (Niri two-window / Hyprland single-window) so tap-outside + tap-Start close work and the bar keeps its clicks. **Niri path works; Hyprland path still the known B1/B2 gap.**
 - [x] `TaskViewButton` → `waffleTaskViewOpen` → `WaffleTaskView` (B3).
 - [x] `WaffleTaskView.qml` + content copied (done 2026-08-19); instantiated in `ShellWafflePanels.qml`; button repointed from missing `scripts/inir` to `waffleTaskViewOpen`.
 - [x] `WindowPreviewService` + `NiriService` resolve for live previews (Niri); Hyprland gap documented.
 - [x] `WTaskbarSeparator` renders (visual only, no state).
 - [x] `Tasks` → `TaskbarApps` live model (✅ works; no action).

**RIGHT side — `systemRow` (`Tray`, `TimerButton`, `UpdatesButton`, `SystemButton`, `TimeButton`, `DesktopPeekButton` + optional `WeatherButton`)**
- [ ] `Tray` → `TrayService` (✅ works).
- [ ] `TimerButton` → `waffleWidgetsOpen` (altAction) + sets `Persistent.states.sidebar.bottomGroup.tab` (verify `Persistent` exists or adapt).
- [ ] `UpdatesButton` → `Updates` (✅ works).
- [ ] `SystemButton` → `waffleActionCenterOpen` → `WaffleActionCenter` (B9). Copied (done 2026-08-19); instantiated; `Audio`/`Network`/`Brightness`/`Bluetooth`/`Battery` resolve; `common.models.quickToggles` present.
- [ ] `TimeButton` → `waffleNotificationCenterOpen` → `WaffleNotificationCenter` (B10). Copied (done 2026-08-19); instantiated; `Notifications.ensureInitialized()`; DND wiring matches `Notifs`.
- [ ] `DesktopPeekButton` → `overviewOpen` / `NiriService.toggleOverview` (✅ Niri; ⚠️ Hyprland no panel).

**Cross-side wiring**
- [ ] `ShellWafflePanels.qml` imports + instantiates all four copied panels (widgets / taskview / actionCenter / notificationCenter).
- [ ] Each ported panel's `IpcHandler` (`wwidgets`, `taskview`, `wactionCenter`, `wnotificationCenter`) registered so keybinds work (per `waffle-keybinds-plan.md`).
- [ ] `allowMultiplePanels` gating closes sibling centers when one opens (already in panel code).

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

**Fix strategy: compositor-aware launcher (mirrors the Pill pattern).**
The two working designs already exist — the fix is to *select* between them by
compositor, not to invent new code. This maps exactly to how
`modules/pill/PillOverlay.qml` branches on `Compositor.runningCompositor` while
`modules/pill/Launcher.qml` stays agnostic: `StartMenuContent.qml` must remain
compositor-agnostic, and **`WaffleStartMenu.qml` (the launcher's "overlay" /
window-manager) owns the split.**

- **Niri (and unknown compositors):** iNiR's **verbatim two-window** design —
  a separate `Top`-layer `wStartMenuBg` catcher `LazyLoader` + a self-sized
  `Overlay` menu `PanelWindow` (`Exclusive` focus, `implicitWidth/Height`,
  `leftAlignApps` anchor, no `Looks.scaledBar` margin). Works natively on Niri
  because Niri does not implement the exclusive seat/pointer grab.
- **Hyprland:** the **single-window Option B** — fullscreen `Overlay`
  `PanelWindow` with the click-catcher *inside* the exclusive surface (a
  full-size `MouseArea` behind `StartMenuContent`), centered with a
  `Looks.scaledBar(48)` lift, `Exclusive` focus kept. The only shape that closes
  on Hyprland (a separate catcher window is starved of pointer input there).

**Selection:** add `import qs.compositor`; `readonly property bool isHyprland:
Compositor.runningCompositor === "hyprland"`. The `Loader`'s `sourceComponent`
picks `hyprlandMenu` vs `niriMenu` `Component`s. Default (unknown `null`) → Niri
path (safest compatibility fallback = iNiR's native design).

**Checklist:**
- [ ] `WaffleStartMenu.qml`: add `import qs.compositor`; add `isHyprland`.
- [ ] Add `Component { id: niriMenu }` = verbatim iNiR two-window design
      (`wStartMenuBg` `Top` catcher + self-sized `Overlay` menu).
- [ ] Add `Component { id: hyprlandMenu }` = current centered single-window Option B.
- [ ] `Loader { sourceComponent: root.isHyprland ? hyprlandMenu : niriMenu }`;
      keep `allowMultiplePanels` gating, `searchOpenChanged → panelLoader.active`,
      and the `search` IpcHandler untouched.
- [ ] `StartMenuContent.qml` + sub-content: **NO changes** (compositor-agnostic).
- [ ] **Starting point (session now on Niri):** implement the split, verify the
      `niriMenu` branch first (iNiR verbatim already works on Niri), then confirm
      `hyprlandMenu` in a Hyprland session.

**Why not Option A (drop Exclusive → OnDemand):** the launcher is opened by
keybind, not a click, so `OnDemand` likely won't grant keyboard focus → the
search box could stop receiving typing (almost certainly why iNiR uses
`Exclusive`). Both the iNiR Niri path and the Hyprland Option B keep
`Exclusive`, so typing is preserved. The compositor split supersedes the
earlier "Option B everywhere" approach.

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
`qs.services` source`. Waffle is now being made a **fully-functional standalone
family**, so the iNiR-only theme singletons ARE being ported (see reversal
below) — `AppLauncher` was already present.

**THEME DIRECTION (2026-08-20):** Waffle uses iNiR's theme system **byte-for-byte**
and Dominance is **disconnected** for waffle. So `Appearance.aurora.*`,
`Appearance.angel.*`, `Appearance.inirEverywhere`, `m3colors`, `MaterialThemeLoader`,
`ThemeService`, and the `Looks.glassActive` (`auroraEverywhere && !Appearance.inirEverywhere`)
pipeline are all used verbatim. The `WaffleBarContent.qml` stubs (`auroraTransparency: 0.9`,
hardcoded `#3a88f2` border) and the `MaterialThemeLoader` guarded no-op are **temporary**
and get restored to iNiR originals once waffle's theme objects exist. Reconciling
Dominance with waffle (so they can share a theme) is **deferred** and will be done
**smartly** later — see Bible §6 THEME DIRECTION for the open crux (shared vs
waffle-scoped `Appearance`).

**Current state:**
- `modules/waffle/settings/` (16 + 12 pages) **copied but PARKED** — now that the
  5 singletons are ported, this can be un-parked as Waffle's standalone settings.
- `waffleSettings.qml` (root) **PARKED** (same — now unblocked).
- `modules/settings/WaffleConfig.qml` **exists** (registered in `modules/settings/qmldir`) — the waffle config binding point.
- Bar's settings actions: `scripts/inir settings` calls are being repointed to
  the unified settings IPC (`qs ipc call settings toggle`); left-widget
  Settings/Wallpaper quick actions already repointed.

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
| 2026-08-19 | Launcher fix re-scoped | Replaced "Option B everywhere" with **compositor-aware** design: Niri = iNiR verbatim two-window; Hyprland = single-window Option B. Select via `Compositor.runningCompositor`. Session switching to Niri → verify `niriMenu` branch first. |
| 2026-08-19 | LEFT side (Widgets) wired | `WaffleWidgets` instantiated in `ShellWafflePanels.qml`; WeatherButton → `waffleWidgetsOpen` opens the panel. Settings/Wallpaper quick actions repointed from missing `scripts/inir` to unified `settings` IPC. |
| 2026-08-19 | Theme decision reversed | Waffle made standalone: ported 5 iNiR-only singletons (`ThemeService`, `MaterialThemeLoader`, `ShellUpdates`, `Idle`, `YtMusic`) into `services/` + registered `qs.services.*`. `m3colors` guarded no-op (Dominance/Dyn pipeline). Bible §6 + this §4 updated. |
