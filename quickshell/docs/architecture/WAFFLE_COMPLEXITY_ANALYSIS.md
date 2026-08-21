# Waffle Complexity Analysis

> Scope: what makes the **Waffle** panel family complex, both in its current
> port (`/home/yemi/.config/quickshell`) and in the source it was cloned from
> (`/home/yemi/iNiR`). Generated 2026-08-18.

Waffle is the Windows-11-style ("Fluent") panel family of this Quickshell shell.
It is not a single component but a **stack of panels + a full widget/control
library + heavy external integrations**. This document enumerates the parts
that make it complex and where the risk concentrates.

---

## 1. What exists where

| Layer | iNiR (source) | quickshell (port) |
|---|---:|---:|
| `modules/waffle/looks/` (control library + `Looks` skin) | ✅ ~50 files | ✅ 52 files |
| `modules/waffle/bar/` (taskbar) | ✅ | ✅ 28 files |
| `modules/waffle/background/` (glass wallpaper) | ✅ | ✅ 2 files |
| `modules/waffle/backdrop/` (solid backdrop) | ✅ | ✅ 1 file |
| `modules/waffle/settings/` (standalone settings app) | ✅ ~30 files | ✅ ported & wired (bar opens `waffleSettings.qml`; see §11) |
| `modules/settings/WaffleConfig.qml` (style page) | ✅ | ✅ ported (THEME section deferred) |
| `waffleSettings.qml` (standalone launcher) | ✅ | ✅ ported (launched/toggled by the `settings` IPC, 2026-08-20) |
| Full feature set (action center, start menu, alt-switcher, task view, clipboard, notification center, OSD, lock, polkit, session, widgets) | ✅ ~250 files / 34,375 LOC | ❌ **not ported** (bar right-cluster panels still absent; see WAFFLE_BAR_WORKING_PLAN) |

**Port total:** 70 QML files, ~6,720 LOC (just `bar`, `background`, `backdrop`, `looks`).
**Source total:** ~34,375 LOC across the full module.

Only the *visual surfaces* (bar + background + backdrop) plus the *looks library*
were carried into quickshell. The settings layer and the rest of the Waffle app
were not — which is why the standalone Waffle settings cannot exist in quickshell
today (see §6).

---

## 2. Complexity driver #1 — the `Looks` singleton (central skin)

`modules/waffle/looks/Looks.qml` (657 LOC) is the **single source of truth for
the entire Waffle visual identity**. It exposes:

- `colors` / `darkColors` / `lightColors` (palette)
- `radius`, `font`, `transition`
- transparency model: `backgroundTransparency`, `panelBackgroundTransparency`,
  `panelLayerTransparency`, `contentTransparency`
- scaling helpers: `dp()`, `scaled()`, `scaledBar()`, `screenScale()`, `barScale()`
- `auroraEverywhere`, `useMaterial`, `glassActive` flags that toggle between
  the Aurora glass pipeline and the Material ("ii") color pipeline

**Coupling:** 58 of the 70 waffle QML files reference `Looks.` directly. Changing
one property in `Looks.qml` ripples across the whole family. It also reaches
*outward* into `Appearance` (`Appearance.colors`, `Appearance.fontSizeScale`,
`Appearance.aurora.*`), so it sits at the intersection of two theming pipelines.

---

## 3. Complexity driver #2 — a hand-rolled Fluent control library

`modules/waffle/looks/` is effectively **a private reimplementation of
QtQuick.Controls.FluentWinUI3** — ~50 components: `WButton`, `WSwitch`,
`WSlider`, `WTextField`, `WMenu`, `WMenuItem`, `WStackView`, `WListView`,
`WScrollBar`, `WProgressBar`, `WToolTip`, `WPane`, `WAppIcon`, `FluentIcon`,
`AcrylicRectangle`, `AcrylicButton`, `WAmbientShadow`, `WRectangularShadow`, etc.

Complexity notes:
- `FluentIcon.qml` + `WIcons.qml` (247 LOC) convert Fluent icon names to the
  bundled Material Symbols / fluent asset set — a translation layer.
- `AcrylicRectangle.qml` / `AcrylicButton.qml` implement the Windows "acrylic"
  blur, which depends on the Aurora transparency pipeline (`auroraEverywhere`).
- Mix of styling strategies: most use `qs.modules.common`, but a few reach for
  `org.kde.kirigami` (`AppButton`, `SearchButton`, `TaskViewButton`,
  `FluentIcon`, `WAppIcon`) and one uses `QtQuick.Controls.FluentWinUI3`
  (`WTextField.qml:4`). Inconsistent base controls add review overhead.
- `WPane.qml:42` explicitly avoids importing the sibling `ii`-family rounding,
  documenting a deliberate boundary between the two panel families — fragile if
  the `ii` and waffle families are ever merged.

---

## 4. Complexity driver #3 — Wayland / live window integration

The taskbar's **live window previews** are the hardest integration surface.

Files involved: `bar/tasks/Tasks.qml`, `TaskAppButton.qml`,
`TaskPreview.qml` (142 LOC), `WindowPreview.qml` (167 LOC),
`bar/tray/Tray.qml`, `bar/StartButton.qml`, `bar/SystemButton.qml`,
`bar/TaskViewButton.qml`, `bar/tray/WaffleTrayMenu*.qml`, `BarPopup.qml`.

Key external services used (from `import qs.services`):
- `NiriService` — **18 references**, the largest external dependency
- `CompositorService` — 8 references
- `WindowPreviewService` — 11 references
- `TrayService` — 9 references
- `TimerService` — 15 references

These pull in `Quickshell.Wayland`, `WindowThumbnail`, `Toplevel`, and persistent
window-state tracking. Live thumbnail rendering is compositor-specific and is the
most likely source of runtime breakage.

---

## 5. Complexity driver #4 — the taskbar feature surface

The bar is a full Windows taskbar clone, not a clock+launcher:

- `StartButton`, `SearchButton`, `TaskViewButton`, `DesktopPeekButton`
- `Tasks` (running-window list with live previews, grouping)
- `Tray` + `TrayButton` + `TrayOverflowMenu` + `WaffleTrayMenu` (system tray)
- `SystemButton` (242 LOC — power/volume/network quick actions)
- `WeatherButton`, `WidgetsButton`, `TimerButton`, `UpdatesButton`
- `BarPopup`, `BarMenu`, `BarToolTip`, `BarIconButton` (popup scaffolding)

Each button is its own component file with its own panel/popup lifecycle, adding
linear but wide maintenance surface.

---

## 6. Complexity driver #5 — the missing settings layer

In iNiR the standalone settings app (`waffleSettings.qml` →
`modules/waffle/settings/WSettingsContent.qml` + 12 pages) is **1,979+ LOC just
for the framework**, plus heavy pages:

- `WThemesPage.qml` 1,094 LOC
- `WGowallPage.qml` 1,114 LOC
- `WBackgroundPage.qml` 1,478 LOC
- `WQuickPage.qml` 1,135 LOC
- `WInterfacePage.qml` 731 LOC
- `WWaffleStylePage.qml` 517 LOC + `modules/settings/WaffleConfig.qml`

**This layer is now *present* in quickshell (2026-08-20), but gated on two
still-missing pieces:**
- The standalone `waffleSettings.qml` launcher is **live**: the bar's "Unified
  Settings" action (`qs ipc call settings toggle`) probe-launches it as a
  standalone `qs` process; clicking opens it, a second click toggles it closed via
  the `waffleSettings` IPC target. Dead `scripts/inir`/`Persistent` references
  were removed from the bar and shared services; `GlobalActions`/`Idle`/`Session`
  /`ScreenSnip` are ported.
- `modules/waffle/settings/` reaches for `ThemeService`, `MaterialThemeLoader`,
  `AppLauncher`, `ShellUpdates`, `Idle` inside the deeper pages (themes / gowall /
  updates). Those iNiR-app singletons are **already ported** into `qs.services`
  (registered in `services/qmldir`, per WAFFLE_BAR_WORKING_PLAN §4) — so the page
  imports resolve and the launcher opens — but they are guarded/stubbed where the
  iNiR host-only behavior is unavailable (e.g. `m3colors` no-op; `ThemeService`
  facade without a live Aurora pipeline), hence the `WThemesPage` theme-bridge is
  deferred (see §11).
- `services/Wallpapers.qml` is a **9-line stub** → the wallpaper picker pages
  (`WQuickPage` left column, `WBackgroundPage` "Pick/Change") are non-functional
  (dead calls) until it is implemented. **Deferred, not dead.**

**Consequence:** Waffle is configured through the `waffles.*` Config keys
(e.g. `Config.setNestedValue("waffles.background.widgets.clock.x", …)` in
`WaffleBackground.qml`) for the areas whose service backing exists; the dedicated
Waffle settings pages exist and the launcher opens, but only the pages whose
singletons/services resolve are fully functional today.

---

## 7. Complexity driver #6 — theming-pipeline entanglement

Waffle sits on top of **two** color systems at once:
1. The **Aurora/ii** pipeline (`Appearance.colors`, `Appearance.aurora.*`,
   `useMaterial` flag in `Looks.qml:26`).
2. The **waffle-local** palette in `Looks.qml` (`darkColors`/`lightColors`).

`Looks.glassActive` = `auroraEverywhere && !Appearance.inirEverywhere` shows the
two pipelines must be kept in sync. The `WAFFLE_NIRI_DEPENDENCY_AUDIT.md` in this
folder covers the Niri-specific half of this entanglement; the color half is
covered by `docs/color-system/THEME_SYSTEM_MAP_CURRENT.md`.

---

## 8. Loading model (mitigates, but adds indirection)

`ShellWafflePanels.qml` (46 LOC) is loaded by `shell.qml` only via
`LazyLoader` when `panelFamily === "waffle"`, and each panel (`wBackground`,
`wBackdrop`, `wBar`) is gated by `Config.options.enabledPanels`. This keeps an
inactive waffle family from being compiled — good for safety, but means the
family is a **separate compilation unit** and errors only surface when the
family is actually selected.

---

## 9. Risk summary (where to look first when something breaks)

1. **`Looks.qml`** — central skin; 58 files depend on it.
2. **`NiriService` / `CompositorService` / `WindowPreviewService`** — Wayland
   live previews; compositor-coupled, highest runtime-failure risk.
3. **`WaffleBackground.qml` (403 LOC)** + `WaffleBackdrop.qml` — Aurora glass /
   transparency layering; entangled with the theming pipelines.
4. **`WaffleBar.qml` + `WaffleBarContent.qml` + `SystemButton.qml`** — widest
   feature surface, most external service calls.
5. **Missing settings layer** — any Waffle config change must go through raw
   `Config` keys; no UI safety net in quickshell.

---

## 10. Service → compositor coupling

Waffle references five services. **Not all are Niri-specific** — only two are
tied to iNiR (the Niri-based source shell):

| Service | Tied to iNiR / Niri? | Works on Hyprland? | Notes |
|---|---|---|---|
| `NiriService` | ✅ **Niri-only** | ❌ No | Reads `NIRI_SOCKET` (env), client to the Niri IPC socket. Non-functional on Hyprland. (`services/NiriService.qml`) |
| `WindowPreviewService` | ✅ **Niri-tied** | ❌ No | Live thumbnail capture keyed on Niri window IDs; caches under `~/.cache/inir/window-previews`. **NOT ported to quickshell** — Waffle references an undefined singleton there. (exists in iNiR `services/WindowPreviewService.qml`, exported in `qmldir`) |
| `CompositorService` | ❌ Bridge (both) | ✅ Yes | Detects `isHyprland` / `isNiri` / `isGnome` via `HYPRLAND_INSTANCE_SIGNATURE`, `NIRI_SOCKET`, `XDG_CURRENT_DESKTOP`; uses both `Quickshell.Hyprland` and `Quickshell.Wayland`. The multi-compositor adapter, not tied to one. (`services/CompositorService.qml`) |
| `TrayService` | ❌ Agnostic | ✅ Yes | `Quickshell.Services.SystemTray` (DBus) + Wayland. Any compliant compositor. (`services/TrayService.qml`) |
| `TimerService` | ❌ Agnostic | ✅ Yes | Stub in quickshell (pomodoro/countdown no-ops); no compositor dependency. (`services/TimerService.qml`) |

**Conclusion:** only `NiriService` and `WindowPreviewService` are iNiR/Niri-bound.
The remaining three are compositor-agnostic or explicitly multi-compositor.
The live-preview path (`WindowPreviewService` + `NiriService`) is therefore the
part that breaks when Waffle is run outside a Niri session, and
`WindowPreviewService` is additionally missing from the quickshell port.

## 11. Port status (2026-08-20)

Both original gaps were copied from `/home/yemi/iNiR` into quickshell on 2026-08-18, and the
settings launcher wiring was completed on 2026-08-20:

**Gap B — live previews (done):**
- `services/WindowPreviewService.qml` (copied; registered `singleton WindowPreviewService 1.0` in `services/qmldir`)
- `scripts/capture-windows.fish`, `scripts/capture-windows.sh` (copied)
- Its deps (`Cliphist`, `ShellExec`, `Directories`, `FileUtils`, `NiriService`) were already present.

**Gap A — Waffle settings UI (done, wired):**
- `modules/waffle/settings/` (entire folder incl. `WSettingsContent.qml` + 12 pages) copied.
- `waffleSettings.qml` (standalone launcher) copied to repo root; now **live** — the
  `settings` IPC in `shell.qml` probe-launches it (toggle via the `waffleSettings` IPC
  target, else `execDetached`).
- `modules/settings/WaffleConfig.qml` copied; `modules/settings/qmldir` exports it.
- The 5 iNiR-only singletons the settings pages import (`ThemeService`,
  `MaterialThemeLoader`, `AppLauncher`, `ShellUpdates`, `Idle`) were **ported into
  `qs.services`** and registered (see WAFFLE_BAR_WORKING_PLAN §4) — so page imports
  resolve and the launcher opens.

**Remaining blockers (none are dead links — all are *absent dependencies*, deferred):**
- `services/Wallpapers.qml` is a **9-line stub** → `WQuickPage`/`WBackgroundPage`
  wallpaper picker pages are non-functional until implemented. (The bar's
  "Unified Settings" *opens* fine; only the wallpaper sub-pages don't work yet.)
- `WThemesPage` / the `WaffleConfig.qml` THEME section — deferred per Bible §6
  (theme-bridge built later; Dominance disconnected for Waffle).
- The deeper iNiR host-only singletons are guarded no-ops where the host pipeline is
  absent (e.g. `m3colors`), so themes/gowall/updates pages may load but not fully run.

The Waffle bar/background/backdrop code and `WindowPreviewService` are unaffected by these gaps.

## 12. Cross-reference

- Source of clone: `/home/yemi/iNiR` (full Waffle app, 34,375 LOC).
- Companion audits in this repo:
  - `docs/architecture/WAFFLE_NIRI_DEPENDENCY_AUDIT.md` (Niri coupling).
  - `docs/color-system/THEME_SYSTEM_MAP_CURRENT.md` (color pipeline).
- Archived (superseded) Waffle notes: `archive/WAFFLE-*.md`.
