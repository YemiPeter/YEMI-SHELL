# Feature Plan: GlobalActions Registry (yemishell)

Status: **Planned (not started)** — deferred from the Waffle → Pill iNiR service upgrade.
Source of truth for the action model: `/home/yemi/iNiR/services/GlobalActions.qml` (Waffle iNiR).

## 1. Goal

Add a **central, searchable action registry** to yemishell — a single `allActions`
catalog where every "thing you can do" is an object `{ id, name, description, icon,
category, keywords[], execute() }`, with:
- `runById(id, args)` — invoke an action by id,
- `fuzzyQuery(text)` — scored search over name/description/id/keywords,
- `listByCategory(cat)` — filter by category,
- an `actions` IPC (`run` / `runWithArgs` / `list` / `search`).

This is a **UX / command-palette** feature. It does **not** manage system resources
or optimize the shell — see §6 for that distinction (the resource-relevant work is
`MemoryPressureService` [done] and the open `WidgetPowerManager` item).

## 2. Scope decision

A faithful port of Waffle's `GlobalActions` would be ~62 built-in actions, many of
which depend on Waffle-only services your shell does not have (`GameMode`,
`Hyprsunset` exists, `Cliphist` exists, `Todo`, `SongRec`, `EasyEffects`, `PackageSearch`,
`AppLauncher`, `Config`, `GlobalStates`, the `inir` launcher binary, `scripts/colors/...`).
A literal port = a large registry of dead/no-op entries.

**Decision: trimmed port.** The registry holds only actions yemishell can actually
perform, mapped to its existing surfaces / services / IPC. The natural consumer is
`modules/pill/Launcher.qml` (command palette), which gets fuzzy action search.

**Out of scope (do not duplicate):** hotkey storage. That already lives in
`modules/pill/Keybinds.qml` (parses/writes Hyprland `binds.lua`). `GlobalActions`
stores no hotkeys — it stores actions keyed by id; keybinds map keys → ids elsewhere.

## 3. Action catalog (evaluation against current shell)

Legend: **HAVE** = shell already does it (map to existing surface/service/IPC);
**NEW** = needs building; **N/A** = does not apply to a pill; **OPT** = optional/edge.

### system
| id | what it is | status |
|----|------------|--------|
| `toggle-wifi` | on/off WiFi | HAVE (`Network`) |
| `toggle-bluetooth` | on/off BT | HAVE (`Bluetooth.qml`) |
| `toggle-nightlight` | blue-light filter | HAVE (`Hyprsunset.qml`) |
| `toggle-gamemode` | performance mode (kill effects for games) | NEW (no GameMode service yet) |
| `toggle-dnd` | silence notifications | HAVE (`Notifs.toggleSilent`) |
| `lock-screen` | lock session | HAVE (`IdleLock.qml` → `loginctl lock-session`) |
| `open-session` | power menu | HAVE (Power surface) |
| `open-settings` | settings panel | HAVE (settings surface) |
| `open-network-settings` | `nm-connection-editor` GUI | OPT (external) |
| `open-volume-mixer` | `pavucontrol` | OPT (external) |
| `open-task-manager` | `btop`/`htop` | OPT (external) |
| `toggle-control-panel` | quick settings | HAVE (≈ settings surface) |

### appearance
| id | what it is | status |
|----|------------|--------|
| `dark-mode` / `light-mode` | color scheme | N/A/OPT (fixed yemi dark theme) |
| `accent-color` | highlight color | OPT (Theme `yemiPrimary`, not wired as toggle) |
| `change-wallpaper` | wallpaper picker | HAVE (`Wallpaper.qml`) |
| `wallpaper-coverflow` | coverflow picker | OPT |
| `random-wallpaper` | Konachan random (needs net) | OPT |

### tools
| id | what it is | status |
|----|------------|--------|
| `screenshot` | capture region | HAVE (`Screenshot.qml`) |
| `color-picker` | `hyprpicker` eyedropper | OPT (external) |
| `screen-record` | start/stop recording | HAVE (`ScreenRec.qml` + `quickRecord`) |
| `open-clipboard` | clipboard history | HAVE (`Cliphist.qml` + Clipboard surface) |
| `open-cheatsheet` | shortcuts view | HAVE (Keybinds surface) |

### media (user omitted this category — mostly already covered)
| id | what it is | status |
|----|------------|--------|
| `media-play-pause` / `media-next` / `media-previous` | MPRIS transport | HAVE (`QsServices.Players` + `mpris` IPC) |
| `toggle-mute` / `toggle-mic-mute` | out/in mute | HAVE (`Audio`) |
| `volume-up` / `volume-down` | volume | HAVE (`Audio`) |
| `brightness-up` / `brightness-down` | brightness | HAVE (`Brightness`) |
| `toggle-easyeffects` | audio EQ | OPT |

### settings (pill-relevant subset)
| id | what it is | status |
|----|------------|--------|
| `toggle-bar-autohide` | auto-hide bar | N/A (pill, no bar) |
| `toggle-dock` | show/hide dock | N/A (no dock) |
| `toggle-animations` | reduce motion | OPT |
| `toggle-low-power` | power profile | HAVE (`PowerProfiles`) |
| `toggle-overview` | window overview | HAVE (AltSwitcher) |
| `open-sidebar-left` / `open-sidebar-right` | side panels | N/A (no sidebars) |
| `toggle-osk` | on-screen keyboard | OPT |
| `zoom-in` / `zoom-out` / `zoom-reset` | screen zoom | OPT |
| `toggle-media-controls` | fullscreen media UI | OPT |
| `toggle-tiling` | tiling picker | OPT |

**Net-new actions worth adding:** `toggle-gamemode` (+ its own GameMode service),
`color-picker`, `toggle-animations`, `toggle-osk`, `zoom-*`, `toggle-media-controls`,
`toggle-tiling`, and the external-app launchers. Everything else maps to something
already present.

## 4. Implementation plan

### Phase 1 — registry of existing (HAVE) actions
- `services/GlobalActions.qml` singleton (`pragma Singleton`, no `ComponentBehavior: Bound`).
- `allActions` array covering the HAVE actions above; each `execute()` calls the
  real target: surface toggles via `qs ipc call pill <surface> <mon>` (or a passed
  monitor), service methods (`QsServices.Hyprsunset.toggle()`, `QsSingletons.Notifs.toggleSilent()`,
  `QsServices.Audio.*`, `QsServices.Brightness.*`, `QsServices.Players`), and
  `ScreenRec` / `Screenshot` for record/shoot.
- `fuzzyQuery`, `runById`, `listByCategory` (ported scoring logic).
- `actions` IPC: `run <id>`, `runWithArgs <id> <args>`, `list [cat]`, `search <q>`.
- Register `singleton GlobalActions GlobalActions.qml` in `services/qmldir`.

### Phase 2 — genuinely new toggles (NEW/OPT, per user decision)
- `toggle-gamemode` → new `GameMode` service (separate checklist item) OR shell out to
  `hyprctl`/`niri` game-mode; decide when building.
- `color-picker` → `Quickshell.execDetached(["hyprpicker","-a"])`.
- `toggle-animations` / `toggle-osk` / `zoom-*` / `toggle-media-controls` / `toggle-tiling`
  → wire to yemishell state (`Flags`/surface) or external tools.
- External launchers (`volume-mixer`, `task-manager`, `network-settings`, `random-wallpaper`)
  → `Quickshell.execDetached(...)`.

### Phase 3 — consumer (Launcher wiring)
- `modules/pill/Launcher.qml` queries `QsServices.GlobalActions.fuzzyQuery(text)` and
  runs `runById(id)` on selection, so typing "mute"/"bright"/"shot" triggers the action.
- Keep Waffle's user/setup script auto-discovery ONLY if a yemishell equivalent path
  exists; otherwise drop (`Directories.userActions` → yemishell path or omit).

## 5. Port constraints (per repo convention)
- No `Config` / `Translation` → safe defaults + plain English names.
- No `pragma ComponentBehavior: Bound`; no `qs.modules.common` import.
- `Directories.*` / Waffle paths → replace with `Quickshell.env(...)` or yemishell paths.
- `runLauncher(["inir", ...])` → replace with yemishell IPC/surface calls.
- `pkill -9 quickshell` before editing; boot-test (no fatal load errors); tick checklist.
- `Notifications.send({...})` for any user-facing errors (same pattern as other ports).

## 6. Non-goals / clarification
- **Not** a resource optimizer. Memory/resource work = `MemoryPressureService` (done) and
  `WidgetPowerManager` (open). Do not sell this plan as performance work.
- **Not** a hotkey editor. `Keybinds.qml` owns that.

## 7. Open decisions (user)
- [ ] Which NEW/OPT actions to include (gamemode, color-picker, animations, osk, zoom, media-controls, tiling, external launchers)?
- [ ] GameMode: build a service or shell out?
- [ ] Keep user/setup script auto-discovery, or drop?
- [ ] Wire `Launcher.qml` now, or backend-only first?

## 8. Checklist linkage
- `SERVICE_CHECKLIST.md` → `GlobalActions` (Core & System) currently `[ ]`.
- When built, mark `[x]` with a note: "trimmed yemishell registry; consumer = Launcher.qml".
