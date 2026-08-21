# Waffle Bar — ASCII Layout & Component Map

> Generated from `modules/waffle/bar/WaffleBarContent.qml` (live source of truth).
> Shows the rendered taskbar strip, every component, its backing panel, the
> `GlobalStates` flag it toggles, and its current port status.

---

## 1. The rendered bar (default — `bar.leftAlignApps = false`)

```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│  WaffleBar (PanelWindow · WlrLayershell · namespace "quickshell:bar" · ExclusionMode.Ignore)   │
│                                                                                               │
│  ┌─LEFT─┐            ┌───────────────CENTER───────────────┐   ┌──────────────────RIGHT──────────┐
│  │      │            │                                    │   │                                  │
│  [WEA]  │  [START] [SEARCH] [TASKVIEW] │ [TASKS ······]   │   │ [TRAY][TIM][UPD][SYS][TIME][PEEK]│
│        │            │          (WTaskbarSeparator)        │   │                                  │
│  └──────┘            └────────────────────────────────────┘   └──────────────────────────────────┘
│                                                                                               │
│  ▔▔▔▔▔▔▔▔▔▔▔▔▔ bottom border (1px, #3a88f2 when glassActive / bg0Border) ▔▔▔▔▔▔▔▔▔▔▔▔▔             │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
   ▲                                  ▲                                         ▲
   │                                  │                                         │
 GlassBackground (aurora, screenX/Y)  Right-click MouseArea (z:-1) →       DesktopPeekButton
   (radius:0, fills bar)              BarMenu (Task Manager / Settings)
```

### When `bar.leftAlignApps = true`
The `WeatherButton` moves from the LEFT group (`bloatRow`, opacity→0/hidden) into
the RIGHT group (`systemRow.FadeLoader`, `shown: leftAlignApps`):
```
[CENTER: START SEARCH TASKVIEW │ TASKS]   [RIGHT: WEA TRAY TIM UPD SYS TIME PEEK]
```

---

## 2. Component inventory (row-order, per file)

| Zone | Component (file) | GlobalStates flag | Backing panel | Status |
|------|------------------|-------------------|---------------|--------|
| LEFT | `WeatherButton.qml` | `waffleWidgetsOpen` | `WaffleWidgets` | ❌ panel not ported → now copied |
| CTR | `StartButton.qml` | `searchOpen` (query `""`) | `WaffleStartMenu` | 🐞 ported, buggy |
| CTR | `SearchButton.qml` | `searchOpen` (query `!=""`) | `WaffleStartMenu` | 🐞 ported, buggy |
| CTR | `TaskViewButton.qml` | `waffleTaskViewOpen` + `inir taskview toggle` | `WaffleTaskView` | ❌ panel not ported → now copied |
| CTR | `WTaskbarSeparator` (tasks) | — | — | ✅ visual |
| CTR | `Tasks` (`tasks/Tasks.qml`) | — (live model) | `TaskbarApps` | ✅ works |
| RIGHT | `Tray` (`tray/Tray.qml`) | — | `TrayService` | ✅ works |
| RIGHT | `TimerButton.qml` | `waffleWidgetsOpen` (altAction) | `WaffleWidgets` | ❌ panel not ported → now copied |
| RIGHT | `UpdatesButton.qml` | — | `Updates` | ✅ works |
| RIGHT | `SystemButton.qml` | `waffleActionCenterOpen` | `WaffleActionCenter` | ❌ panel not ported → now copied |
| RIGHT | `TimeButton.qml` | `waffleNotificationCenterOpen` | `WaffleNotificationCenter` | ❌ panel not ported → now copied |
| RIGHT | `DesktopPeekButton.qml` | `overviewOpen` / `NiriService.toggleOverview` | compositor overview | ✅ Niri; ⚠️ no Hyprland panel |

Legend: ✅ works · ❌ missing panel (now copied) · 🐞 buggy

---

## 3. Right-click context menu (`BarMenu`)
Anchored to an invisible `contextMenuAnchor` (right-click MouseArea, `z:-1`):
```
┌─ Taskbar context menu ───────┐
│ 🔘 Task Manager              │ → Session.launchTaskManager()
│ ───────────────────────────  │
│ ⚙ Taskbar settings           │ → qs ipc call settings toggle (launches/toggles waffleSettings.qml)
└──────────────────────────────┘
```

---

## 4. Panel tree (what each button opens)

```
WaffleBar.qml  (Scope · barLoader: LazyLoader active: GlobalStates.barOpen)
└─ Variants over screens (screenList filter)
   └─ PanelWindow (barRoot)  →  WaffleBarContent.qml
        ├─ GlassBackground            (aurora, glassActive)
        ├─ border                     (1px)
        ├─ RIGHTCLICK → BarMenu        (Task Manager / Settings)
        ├─ bloatRow      → WeatherButton      → WaffleWidgets   (waffleWidgetsOpen)
        ├─ appsRow       → StartButton        → WaffleStartMenu (searchOpen, query=="")
        │                → SearchButton       → WaffleStartMenu (searchOpen, query!="")
        │                → TaskViewButton     → WaffleTaskView  (waffleTaskViewOpen)
        │                → WTaskbarSeparator
        │                → Tasks               → TaskbarApps     (live)
        └─ systemRow     → WeatherButton*     → WaffleWidgets   (leftAlignApps only)
                         → Tray               → TrayService     (live)
                         → TimerButton        → WaffleWidgets   (waffleWidgetsOpen, alt)
                         → UpdatesButton      → Updates         (live)
                         → SystemButton       → WaffleActionCenter (waffleActionCenterOpen)
                         → TimeButton         → WaffleNotificationCenter (waffleNotificationCenterOpen)
                         → DesktopPeekButton  → compositor overview (overviewOpen)
```

---

## 5. Port status of the four dead panels (copied 2026-08-19)

| Panel | Files copied into `modules/waffle/` | Entry component | Next step |
|-------|-------------------------------------|----------------|-----------|
| widgets | `widgets/` (2) | `WaffleWidgets.qml` | instantiate in `ShellWafflePanels.qml` |
| notificationCenter | `notificationCenter/` (13) | `WaffleNotificationCenter.qml` | instantiate + `Notifications.ensureInitialized()` |
| actionCenter | `actionCenter/` (24 + submodules) | `WaffleActionCenter.qml` | instantiate; verify service deps |
| taskview | `taskview/` (4) | `WaffleTaskView.qml` | Niri-coupled (`WindowPreviewService`) |

All four entry components already bind to their exact `GlobalStates` flags and
ship their own `IpcHandler` + click-outside catcher, so the remaining work in
`ShellWafflePanels.qml` is **import + instantiate**.

---

## 6. Cross-references
- Functional plan & fix sequence: `docs/WAFFLE_BAR_WORKING_PLAN.md`
- Service/settings inventory: `docs/architecture/WAFFLE_SETTINGS_AND_SERVICES.md`
- Bar window hygiene (B0): `WaffleBar.qml` (add `WlrLayershell.layer: WlrLayer.Top`)
- Launcher bug (B1/B2): `startMenu/WaffleStartMenu.qml` (`WlrKeyboardFocus.Exclusive` seat grab)
