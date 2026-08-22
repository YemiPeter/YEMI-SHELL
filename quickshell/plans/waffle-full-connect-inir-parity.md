# Waffle — Full Connect to iNiR Parity ("copy for copy")

> **Goal:** make `panelFamily === "waffle"` in `~/.config/quickshell` behave the
> same way iNiR's waffle family does, with nothing missing: every waffle panel
> ported, instantiated, IPC-registered, keybound, and layer-ruled.
>
> **Reference (read-only):** `/home/yemi/iNiR`
> **Target:** `/home/yemi/.config/quickshell` + `/home/yemi/.config/niri/config.d`
>
> **Ground rule from Yemi:** *anything that touches the pill side must be
> approved first.* Those items are collected in **§1 GATES** and are blocking.

---

## 0. Where we actually are (measured, not assumed)

### 0.1 Waffle module tree

| | iNiR | local | delta |
|---|---|---|---|
| files under `modules/waffle` | 209 | 183 | **-30 missing / +4 local-only** |
| byte-identical ported files | — | 152 | |
| intentionally adapted files | — | 27 | (`import qs.config`, `module …` qmldir headers, `Persistent` removal) |

**Missing subtrees (7):**

| dir | files | lines | provides | IPC target |
|---|---|---|---|---|
| `onScreenDisplay/` | 7 | 601 | volume / brightness / media / kbd-layout OSD | `osd` |
| `notificationPopup/` | 5 | 825 | toast notifications | — |
| `clipboard/` | 4 | 614 | waffle clipboard picker | `clipboard` |
| `sessionScreen/` | 5 | 344 | power/logout screen | `session` |
| `polkit/` | 3 | 226 | auth dialog | — |
| `regionSelector/` | 2 | 210 | waffle screenshot toolbar | — |
| `lock/` | 3 | 3501 | waffle lock surface (+ "Safe" Niri variant) | — |

**Local-only files (leave as-is):** `qmldir`, `looks/Looks.stub.qml`,
`ICON_CUSTOMIZATION_PLAN.md`, `settings/pages/WMonitorVisibilityPage.qml.bak`.

### 0.2 Panels ported but **never instantiated** (the biggest live bug)

`ShellWafflePanels.qml` currently loads only:
`wBackground`, `wBackdrop`, `wBar`, `WaffleStartMenu`, `WaffleWidgets`,
`WaffleTaskView`, `WaffleAltSwitcher`.

It **does not** instantiate `WaffleActionCenter` or `WaffleNotificationCenter`,
even though both are fully ported. Result: in waffle mode,
`SystemButton` (`GlobalStates.waffleActionCenterOpen`) and
`TimeButton` (`GlobalStates.waffleNotificationCenterOpen`) flip a flag that
nothing is listening to — the whole right cluster of the taskbar is dead.

### 0.3 Broken imports in already-ported waffle files

`qs.services.network` does **not exist** locally, but is imported by 6 files:

```
modules/waffle/actionCenter/ExpandableChoiceButton.qml
modules/waffle/actionCenter/bluetooth/BluetoothControl.qml
modules/waffle/actionCenter/bluetooth/BluetoothDeviceItem.qml
modules/waffle/actionCenter/nightLight/NightLightControl.qml
modules/waffle/actionCenter/wifi/WWifiNetworkItem.qml
modules/waffle/actionCenter/wifi/WifiControl.qml
```

iNiR's `services/network/` is only 2 files (`qmldir`, `WifiAccessPoint.qml`).

### 0.4 Dangling singletons referenced by already-ported waffle files

| symbol | refs | iNiR source | lines | consumer |
|---|---|---|---|---|
| `ThemePresets` | 7 | `modules/common/ThemePresets.qml` | 3879 | `WThemesPage`, `WQuickPage`, **and shared `services/ThemeService.qml` (7 call sites)** |
| `Events` (qs.services) | 6 | `services/Events.qml` | 256 | `notificationCenter/CalendarWidget.qml` |
| `CalendarSync` | 5 | `services/CalendarSync.qml` | 350 | `notificationCenter/CalendarWidget.qml` |
| `MinimizedWindows` | 4 | `services/MinimizedWindows.qml` | 164 | `bar/tasks/TaskAppButton.qml` (minimize/restore) |
| `Images` | 1 | `modules/common/Images.qml` | 42 | + shared `DirectoryIcon.qml`, `ThumbnailImage.qml` |

Note: pill's `Events` is a *different* API at `modules/pill/Singletons/Events.qml`
(imported as `"Singletons"`), so adding `qs.services` `Events` does not collide.

### 0.5 Missing services needed by the 7 new subtrees

| need | iNiR source | lines | required by |
|---|---|---|---|
| `PolkitService` + `PolkitServiceImpl` | `services/` | 98 + 38 | `waffle/polkit` (and the already-present-but-dead `modules/common/widgets/FullscreenPolkitWindow.qml`) |
| `services/network/` | `services/network/` | 2 files | `waffle/actionCenter` (§0.3) |
| `Persistent` | `modules/common/Persistent.qml` | 230 | `modules/lock/Lock.qml` |
| `HyprlandData` | `services/HyprlandData.qml` | 177 | `modules/lock/Lock.qml` (Hyprland-only path) |

### 0.6 Missing shared (non-waffle) modules the new subtrees import

| module | files | why |
|---|---|---|
| `modules/lock/` | 7 (`LockContext`, `LockKeyboard`, `LockMediaWidget`, `Lock`, `LockSurface`, `PasswordChars`, `pam/fprintd.conf`) | `waffle/lock` needs `LockContext`; `Lock.qml` is the `WlSessionLock` host that chooses waffle vs ii surface |
| `modules/regionSelector/` | 8 (`RegionSelection`, `RegionSelector`, `AnnotationEditor`, …) | `waffle/regionSelector/WOptionsToolbar.qml` needs the `RegionSelection` enums; conversely `modules/regionSelector` imports `qs.modules.waffle.regionSelector` — two-way |
| `modules/background/widgets/clock/` | 19 (`CookieClock`, hands, marks, …) | `waffle/lock` renders `BackgroundClock.CookieClock` |
| `scripts/keyring/` | 3 (`unlock.sh`, `is_unlocked.sh`, `try_lookup.sh`) | `Lock.qml` keyring unlock (`KeyringStorage` already present locally) |

Good news found while measuring:
- `LockSurface.qml` imports `qs.modules.bar as Bar` but **never uses `Bar.`** —
  the import can be dropped, so iNiR's `modules/bar` does **not** need porting.
- Local `services/Icons.qml` stub already exposes `getWeatherIcon(...)`, the only
  `Icons.` call in `modules/lock`.
- `PolkitDialog` / `PolkitDialogHeader` are inline `component`s inside
  `WPolkitContent.qml` — nothing extra to port.
- `modules/common/widgets/FullscreenPolkitWindow.qml` and `StyledImage.qml` are
  already present and byte-identical to iNiR.

### 0.7 Config coverage — already complete

All 28 `Config.options.*` paths used by the 7 missing subtrees resolve today,
both in `modules/common/Config.qml` and in the live
`~/.config/yemi-shell/config.json`:

```
background.{wallpaperPath,thumbnailPath}
lock.{blur.*,clock.*,dim.*,enableAnimation,notifications.*,security.requirePasswordToPower,status.enable,widgets.*}
notifications.{position,screenList}
osd.{mediaEnabled,screenList,timeout}
panelFamily
waffles.{background,background.thumbnailPath,bar.bottom}
```

The `waffles` JsonObject is also effectively in sync with iNiR (only 9 keys of the
local `altSwitcher` block were trimmed vs iNiR: `monochromeIcons`,
`enableAnimation`, `animationDurationMs`, `backgroundOpacity`, `blurAmount`,
`scrimDim`, `compactStyle`, `panelAlignment`, `useM3Layout`).

**The one real config gap is `enabledPanels`** — see GATE-1.

### 0.8 Compositor-side gaps

`niri/config.d/80-layer-rules.kdl` covers only `quickshell:iiBackdrop` and
`quickshell:wBackdrop`. The 4 new waffle namespaces have no rules:
`quickshell:wOnScreenDisplay`, `quickshell:wNotificationPopup`,
`quickshell:wClipboard`, `quickshell:wSession` (+ `quickshell:lock` for blur).

`71-binds-waffle.kdl` binds only `app launcher`, `desktop toggle`,
`waffleAltSwitcher next/previous`. Unbound waffle targets:
`wactionCenter`, `wnotificationCenter`, `wwidgets`, `taskview`, `wbar`,
`clipboard`, `session`, `osd`, `lock`, `panelFamily`.

Pre-existing dead binds in `70-binds.kdl` (pill file):
`Alt+Tab → altSwitcher next` (no such target exists locally — only
`waffleAltSwitcher`), and `Ctrl+S → pill screenshot full` (the `pill` handler in
`shell.qml` has no `screenshot` function).

### 0.9 Top-level wiring gaps vs iNiR

| iNiR | local |
|---|---|
| `FamilyTransitionOverlay.qml` | **missing** (yet `GlobalStates.familyTransition{Active,Direction}` and `Config.options.familyTransitionAnimation: true` both exist and are unused) |
| `shell.qml` IPC target `panelFamily` (`cycle`, `set`) | only `desktop.toggle()` |
| staged transition (`_pendingFamily` → overlay `exitComplete` → write config → `enterComplete`) | instant config write |
| `waffleSettings.qml` | **byte-identical ✅** |

Also: `services/GlobalActions.qml:722` writes `panelFamily = "ii"` — a wrong
value for this fork (must be `"pill"`), so that action currently strands the shell
between families.

Orphan noted, not touched: `modules/pill/shell.qml` is loaded by nothing but
declares a second `pill` IPC target.

---

## 1. GATES — blocking, needs Yemi's call before any file is touched

Each gate lists the file(s), the pill-side consequence, and my recommendation.

### GATE-1 — `modules/common/Config.qml` → `enabledPanels`
Shared config file. Today the default is the stale iNiR `ii*` list and the live
`config.json` has been reduced to `["wBar"]`, which is why `wBackground` /
`wBackdrop` never load. Every new waffle panel is gated on this list.

- Pill impact: `ShellPillPanels.qml` **does not read `enabledPanels` at all**, so
  functionally none. But `services/ShellUpdates.qml` appends `"iiShellUpdate"`
  to it, and `modules/settings/WaffleConfig.qml` + `WModulesPage` read it.
- Options: **(a)** rename the `ii*` entries to `pill*` and add all `w*` entries;
  **(b)** leave `ii*` alone, only append the `w*` entries; **(c)** don't touch
  Config.qml, only extend the live `config.json`.
- Recommend **(b)** — minimum blast radius, unblocks everything.

### GATE-2 — `shell.qml`
The root file that owns every pill IPC handler. Needed edits are additive:
add the `panelFamily` target (`cycle`/`set`) alongside `desktop.toggle`, and add
the staged `FamilyTransitionOverlay` handshake.

- Pill impact: no pill handler changes, but it is *the* pill file. Any typo takes
  the whole shell down.
- Recommend: allow additive-only edits; keep `desktop.toggle` untouched for
  backwards compat with the existing `Mod+P` bind.

### GATE-3 — `modules/lock/` + the real lock screen
`waffle/lock` cannot work without `modules/lock/LockContext.qml`, and `Lock.qml`
is the `WlSessionLock` host. This shell currently has **no lock screen at all**
(`modules/pill/IdleLock.qml` is only a hypridle settings surface).

- Pill impact: `Lock.qml` registers a global `lock` IPC target and a real
  `WlSessionLock`. It also ships `LockSurface.qml` (the ii/Material surface) which
  would become the pill family's lock screen.
- Options: **(a)** full copy — pill gains iNiR's Material lock screen;
  **(b)** copy `modules/lock` but hard-pin `useWaffleLock: true` so only the
  waffle surface is ever built (pill keeps having no lock);
  **(c)** skip lock entirely for now.
- Recommend **(a)** for true parity — but this is the single biggest pill-visible
  change in the whole job, so it's your call.

### GATE-4 — `modules/regionSelector/`
`waffle/regionSelector/WOptionsToolbar.qml` needs `RegionSelection`'s enums, and
in iNiR the region selector is loaded in **both** families (`iiRegionSelector`).

- Pill impact: pill currently screenshots via `services/Screenshot.qml` +
  `qs ipc call pill screenshot` (which is itself broken, see §0.8). Adding the
  region selector introduces a second, overlapping screenshot path.
- Options: **(a)** port it and enable in both families (iNiR parity);
  **(b)** port it and gate `enabledPanels` so it only activates under waffle;
  **(c)** skip — waffle's Widgets "snip" button (`GlobalStates.regionSelectorOpen`)
  stays a no-op, as it is today.
- Recommend **(b)**.

### GATE-5 — `modules/common/ThemePresets.qml` (3879 lines)
Currently missing, but **shared `services/ThemeService.qml` already calls
`ThemePresets.applyPreset(...)` in 7 places** — so manual (non-`auto`) themes are
broken for *both* families right now.

- Pill impact: adding it changes theme behavior for the pill side too (manual
  presets would start actually applying).
- Options: **(a)** port it — fixes a shared bug, changes pill theming;
  **(b)** port it but keep `ThemeService` behavior pinned to `auto`;
  **(c)** skip and instead stub `ThemePresets` so `WThemesPage` degrades quietly.
- Recommend **(a)**, but flagging because it will visibly change pill theming.

### GATE-6 — `services/PolkitService.qml`
Adding it "wakes up" the already-present-but-inert
`modules/common/widgets/FullscreenPolkitWindow.qml` (`active: PolkitService.active`).

- Pill impact: I verified nothing currently instantiates
  `FullscreenPolkitWindow`, so the risk is theoretical. But once a polkit agent is
  registered by the shell, the `50-startup.kdl` mate-polkit agent becomes a
  **duplicate authority** and one of the two must go.
- Options: **(a)** port `PolkitService` and remove the mate-polkit
  `spawn-at-startup`; **(b)** port it and leave mate-polkit (expect double
  prompts / one agent losing the D-Bus name); **(c)** skip waffle polkit.
- Recommend **(a)**.

### GATE-7 — `services/GlobalActions.qml:722` (`panelFamily = "ii"` → `"pill"`)
One-word fix to a shared service.

- Pill impact: that action currently sets an invalid family. Fixing it makes the
  "switch to pill" global action actually reach the pill family.
- Recommend: fix it.

### GATE-8 — `niri/config.d/70-binds.kdl`
I'd rather **not** touch it: `71-binds-waffle.kdl` is already sourced after it and
overrides matching keys. But three things live in `70` that matter:
`Alt+Tab → altSwitcher` (dead target), `Mod+C → pill clipboard`, and
`Ctrl+S → pill screenshot` (dead function).

- Options: **(a)** leave `70` untouched, add every waffle bind to `71`
  (waffle wins while waffle is active, pill keeps its binds);
  **(b)** also clean the two dead binds in `70`.
- Recommend **(a)** for the port, **(b)** as a separate follow-up.

---

## 2. Phased execution

Nothing in Phase A–C touches the pill side. Phases D+ are gate-dependent.

### Phase A — unbreak what's already ported *(no pill impact)*

**A1.** Copy `iNiR/services/network/` → `services/network/`
(`qmldir` + `WifiAccessPoint.qml`). Add `module qs.services.network` header if
absent, matching the local qmldir convention. → fixes the 6 broken
`actionCenter` imports (§0.3).

**A2.** Port the 5 dangling singletons (§0.4) into the local registries:
- `services/Events.qml`, `services/CalendarSync.qml`,
  `services/MinimizedWindows.qml` → register in `services/qmldir`.
- `modules/common/Images.qml` → register in `modules/common/qmldir`.
- `modules/common/ThemePresets.qml` → **GATE-5**.

**A3.** Instantiate the two dead panels in `ShellWafflePanels.qml`:
`WaffleActionCenter` and `WaffleNotificationCenter` (§0.2). This alone revives
the taskbar's right cluster.

**A4.** Fill in `modules/waffle/qmldir` submodules — it currently lists only
`bar looks backdrop background startMenu`; add `actionCenter notificationCenter
taskview widgets altSwitcher settings` plus the new dirs from Phase B.

**Verify A:** restart shell in waffle mode; click `SystemButton` and `TimeButton`
— both centers must open, close on click-outside, and close each other
(`allowMultiplePanels === false`). Wifi/Bluetooth/NightLight tiles must render.

### Phase B — copy the standalone waffle subtrees *(no pill impact)*

For each dir, the adaptation recipe is exactly what the 27 already-adapted files
did:
1. `cp -r` from iNiR.
2. Prepend `module qs.modules.waffle.<dir>` to the copied `qmldir` if missing.
3. Add `import qs.config` wherever `Appearance` is referenced (local `Appearance`
   lives in `qs.config`, iNiR's in `qs.modules.common`).
4. Strip `Persistent.*` references unless GATE-3 lands `Persistent`.

Order (cheapest / most independent first):

**B1.** `regionSelector/` (2 files) — **GATE-4**; toolbar only, harmless to copy
even if the shared module is deferred.

**B2.** `sessionScreen/` (5 files, 344 lines) — self-contained, uses
`GlobalStates.sessionOpen` + `Session` (present) and registers `session`
(already gated `enabled: panelFamily === "waffle"`). Wire as
`DeferredPanelLoader { identifier: "wSessionScreen" }`.

**B3.** `onScreenDisplay/` (7 files, 601 lines) — needs
`Audio`/`Brightness`/`MprisController`/`KeyboardIndicators`/`CompositorService`/
`NiriService`, all present. Registers `osd`. Wire as
`PanelLoader { identifier: "wOnScreenDisplay" }` (immediate — must catch early
volume/brightness events).

**B4.** `notificationPopup/` (5 files, 825 lines) — needs `Notifications`
(present) and `WNotificationAppIcon` from the already-ported
`waffle/notificationCenter`, plus `DragManager` (present). Wire as
`PanelLoader { identifier: "wNotificationPopup" }`.

**B5.** `clipboard/` (4 files, 614 lines) — needs `Cliphist` (present in
`services/deferred`). Registers `clipboard` (already family-gated). Wire as a
`LazyLoader` gated on `panelFamily === "waffle"` exactly like iNiR does, so the
target is only claimed in waffle mode.

**B6.** `polkit/` (3 files, 226 lines) — **GATE-6** (needs `PolkitService`).
Wire as `DeferredPanelLoader { identifier: "wPolkit" }`.

**Verify B:** per panel — volume/brightness keys show the waffle OSD; a
`notify-send` shows a waffle toast; `qs ipc call clipboard toggle` opens the
picker; `qs ipc call session toggle` opens the power screen; `pkexec true`
raises the waffle auth dialog.

### Phase C — compositor wiring *(no pill impact)*

**C1.** `71-binds-waffle.kdl` — add the unbound waffle targets. Proposed set
(from `docs/waffle-keybinds-plan.md` §3, unchanged where a pill bind already
uses the same key so muscle memory carries over):

| key | call |
|---|---|
| `Mod+A` | `wactionCenter toggle` |
| `Mod+N` | `wnotificationCenter toggle` |
| `Mod+Z` | `wwidgets toggle` |
| `Mod+Tab` | `taskview toggle` |
| `Mod+B` | `wbar toggle` |
| `Mod+C` *(overrides pill's `pill clipboard`)* | `clipboard toggle` |
| `Mod+Shift+Q` | `session toggle` |
| `Mod+Alt+L` `allow-when-locked=true` | `lock activate` — GATE-3 |
| `Mod+Ctrl+Shift+L` `allow-when-locked=true` | `lock focus` — GATE-3 |
| `Mod+Shift+S` | `region screenshot` — GATE-4 |
| `Mod+Shift+W` | `panelFamily cycle` — GATE-2 |

**C2.** `80-layer-rules.kdl` — add rules for `quickshell:wOnScreenDisplay`,
`quickshell:wNotificationPopup`, `quickshell:wClipboard`, `quickshell:wSession`,
and (GATE-3) blur for `quickshell:lock`. Namespaces are waffle-only, so pill is
unaffected even though the file is shared.

**Verify C:** `niri validate`; then each new bind fires in waffle mode and the
pill binds still fire after `qs ipc call desktop toggle`.

### Phase D — lock screen *(GATE-3)*

**D1.** Copy `iNiR/modules/lock/` → `modules/lock/`, add
`module qs.modules.lock` qmldir (iNiR has none; local convention requires it).
**D2.** Drop the unused `import qs.modules.bar as Bar` from `LockSurface.qml`
(verified: zero `Bar.` usages) — avoids porting iNiR's whole `modules/bar`.
**D3.** Copy `modules/background/widgets/clock/` (19 files) for `CookieClock`.
**D4.** Copy `modules/waffle/lock/` (3 files, 3501 lines).
**D5.** Port `modules/common/Persistent.qml` + `services/HyprlandData.qml`
(`Lock.qml` needs both; `HyprlandData` only on the Hyprland branch).
**D6.** Copy `scripts/keyring/{unlock,is_unlocked,try_lookup}.sh`, `chmod +x`.
**D7.** Wire `DeferredPanelLoader { identifier: "wLock"; component: Lock {} }`.
Niri picks `WaffleLockSurfaceSafe` automatically via `CompositorService.isNiri`.

**Verify D:** `qs ipc call lock activate` → waffle lock appears, keyboard focus
works, password unlocks, the 2s swaylock/hyprlock fallback does **not** fire.
Test after a suspend/resume for the focus-heartbeat path.

### Phase E — region selector *(GATE-4)*

**E1.** Copy `iNiR/modules/regionSelector/` (8 files) + `module` qmldir header.
**E2.** Wire per GATE-4's chosen option.
**Verify E:** `Mod+Shift+S` → selection overlay with the *waffle* toolbar
(`WOptionsToolbar`) in waffle mode; the Widgets snip button opens it too.

### Phase F — family transition + `panelFamily` IPC *(GATE-2)*

**F1.** Copy `iNiR/FamilyTransitionOverlay.qml` to the shell root.
**F2.** In `shell.qml`: add `property string _pendingFamily`,
`cyclePanelFamily()`, `setPanelFamily(family)`, `_ensureFamilyPanels(family)`,
the `LazyLoader { source: "FamilyTransitionOverlay.qml" }`, and the
`IpcHandler { target: "panelFamily" }` with `cycle()`/`set()`. Keep the existing
`desktop.toggle()` so `Mod+P` keeps working.
**F3.** Fix `services/GlobalActions.qml:722` `"ii"` → `"pill"` *(GATE-7)*.

**Verify F:** `qs ipc call panelFamily cycle` animates pill→waffle→pill with no
frame where both families are mounted; `Config.options.familyTransitionAnimation
= false` falls back to the instant switch.

### Phase G — final parity sweep

**G1.** Re-run the tree diff; expect only the 4 known local-only files:
```bash
diff <(cd /home/yemi/iNiR/modules/waffle && find . -type f | sort) \
     <(cd ~/.config/quickshell/modules/waffle && find . -type f | sort)
```
**G2.** Re-run the IPC target diff; the waffle set must be
`clipboard osd search session taskview wactionCenter waffleAltSwitcher wbar
wnotificationCenter wwidgets` (+ `panelFamily`, `lock` if GATE-2/3 land).
**G3.** Grep for any remaining unresolved singleton/import in `modules/waffle`.
**G4.** Toggle families 5× in a row and confirm no leaked layer surfaces
(`niri msg layers` / compositor layer list).

---

## 3. Deliberately out of scope

These exist in iNiR's waffle-family panel list but have no local counterpart and
are **not** waffle-specific, so they are not part of "connect waffle":
`iiBootGreeting`, `iiCheatsheet`, `iiOnScreenKeyboard`, `iiOverlay`,
`iiOverview`, `iiScreenCorners`, `iiWallpaperSelector`, `iiCoverflowSelector`,
`iiRecordingOsd`, `iiShellUpdate`. Flag separately if you want them.

Also out of scope: the orphan `modules/pill/shell.qml`, and the 9 trimmed
`waffles.altSwitcher` config keys (cosmetic-only, `WWaffleStylePage` doesn't
expose them).

---

## 4. Rollback

`~/.config` is a git repo (HEAD `2ed4a59`) with a clean-ish tree
(6 modified files pre-existing). Each phase should be one commit so any single
phase can be reverted with `git revert`. `/home/yemi/iNiR` is never written to.
