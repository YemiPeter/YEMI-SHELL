# RICELLIN Settings Architecture — Full Map
> Source: `/home/yemi/Ricelin/configs/quickshell/pill/`  
> Purpose: show how every settings surface connects to the pill, to each other, and to the outside world.

---

## 1. Hierarchy at a Glance

```
shell.qml  (ShellRoot — top-level window factory)
  └─ Pill.qml  (the morphing pill body)
       ├─ Settings.qml          ← category index (7 rows)
       │    ├─ Appearance.qml   ← sub-surface
       │    ├─ Look.qml         ← sub-surface
       │    ├─ Display.qml      ← sub-surface
       │    ├─ Input.qml        ← sub-surface
       │    ├─ Keybinds.qml     ← sub-surface (extends PillSurface directly)
       │    ├─ IdleLock.qml     ← sub-surface
       │    └─ Updates.qml      ← sub-surface
       ├─ FontPicker.qml        ← sub-surface of Appearance
       └─ SettingsSurface.qml   ← shared base for all sub-surfaces
```

---

## 2. The Three Pillar Files

### 2.1 `SettingsSurface.qml` — the base class every sub-surface extends

```
PillSurface  (generic morph-surface: open, s, morphCloseness, mTop/mLeft/mRight/mBottom)
  └─ SettingsSurface  (adds: row registry, keyboard nav, Ame seam)
```

**Key additions over PillSurface:**

| Property / Signal | Type | Purpose |
|---|---|---|
| `backSurface` | `string` | Name of the parent surface to return to (e.g. `"settings"`) |
| `requestSurface(string)` | signal | Bubbles up to Pill.qml to morph to a named surface |
| `focusRowItem` | `Item` | Currently hovered/focused row |
| `kbIndex` | `int` | Keyboard cursor position in the `rows` array |
| `rows` | `var[]` | Row registry — each entry describes one control |
| `rowFocused` | `bool` (readonly) | `focusRowItem !== null && active` |
| `rowPoint` | `point` (readonly) | Screen position of the focused row (for Ame seam) |
| `ameForm` | `string` | `"rowseam"` when a row is focused, `"off"` otherwise |
| `amePoint` | `point` | Position mapped into pill space for the Ame bead |

**Row entry schema** (each element of `rows[]`):

```
{
  item: <SettingsRow instance>,   // the visual row
  kind: "nav" | "seg" | "toggle", // control type
  surface: "appearance",          // (nav only) target surface name
  vals: [false, true],            // (seg only) cycle values
  get: function() { ... },        // (seg/toggle) read current value
  set: function(v) { ... }        // (seg/toggle) write new value
}
```

**Keyboard methods** (called from Pill.qml):

- `kbMove(dir)` — move focus up/down, clamp to bounds
- `kbAdjust(dir)` — step a seg or toggle a bool
- `kbActivate()` — activate: toggle flips, nav opens sub-surface, seg cycles

**Mouse methods:**

- `reportRowHover(item, hovered)` — sync `focusRowItem` and `kbIndex` on hover
- `activateRow(item)` — click handler: same logic as `kbActivate` but for pointer

**Ame integration:**  
`ameForm`/`amePoint` are bound properties. When `rowFocused` is true the seam form `"rowseam"` is sent to Ame, positioned at the focused row's centre. When no row is focused it sends `"off"`.

---

### 2.2 `Settings.qml` — the category index

Extends `SettingsSurface`. Declares the 7 rows and the two group labels ("Shell" / "Control").

**Rows declared:**

| Row id | Kanji | Name | Sub-caption | kind | surface |
|---|---|---|---|---|---|
| `appearanceRow` | — | Appearance | Clock, glyphs, accent palette | nav | `"appearance"` |
| `lookRow` | — | Look | Gaps, rounding, blur, opacity | nav | `"look"` |
| `displayRow` | — | Display | Resolution, refresh, scale | nav | `"display"` |
| `inputRow` | — | Input | Pointer, keyboard, cursor | nav | `"input"` |
| `keybindsRow` | — | Keybinds | Rebind, add, set commands | nav | `"keybinds"` |
| `idleRow` | — | Idle / Lock | Auto-lock, screen off, suspend | nav | `"idlelock"` |
| `updatesRow` | — | Updates | Version and check for updates | nav | `"updates"` |

**Group labels** are plain `Text` items with `Theme.faint` colour, `Font.AllUppercase`, `letterSpacing: 1.2 * s`.

**Back navigation:** clicking empty space on a sub-surface calls `surfaceBack()` in Pill.qml, which checks which settings-family surface is open and calls `pill.requestSurface("settings")` to return to the index.

---

### 2.3 `Pill.qml` — the orchestrator

**The `surfaces` map** (single source of truth for every morphing surface):

```qml
readonly property var surfaces: ({
  calendar:    { size: () => Qt.size(calendarW, calendarH),    ame: calendar },
  launcher:    { size: () => Qt.size(launcherW, launcherH),    ame: launcher },
  clipboard:   { size: () => Qt.size(clipboardW, clipboardH),  ame: clip },
  wallpaper:   { size: () => Qt.size(wallpaperW, wallpaperH),  ame: null },
  power:       { size: () => Qt.size(powerW, powerH),          ame: power },
  media:       { size: () => Qt.size(mediaW, mediaH),          ame: media },
  mixer:       { size: () => Qt.size(mixerW, mixerH),          ame: mixer },
  link:        { size: () => Qt.size(link.desiredW, ...),      ame: link },
  battery:     { size: () => Qt.size(batteryW, ...),          ame: battery },
  settings:    { size: () => Qt.size(settingsW, ...),         ame: settings },
  keybinds:    { size: () => Qt.size(keybindsW, ...),         ame: keybinds },
  recorder:    { size: () => Qt.size(recorderW, ...),         ame: recorder },
  sysmon:      { size: () => Qt.size(sysmonW, ...),           ame: sysmon },
  appearance:  { size: () => Qt.size(appearanceW, ...),       ame: appearance },
  updates:     { size: () => Qt.size(updatesW, ...),          ame: updates },
  display:     { size: () => Qt.size(displayW, ...),          ame: display },
  input:       { size: () => Qt.size(inputW, ...),            ame: input },
  look:        { size: () => Qt.size(lookW, ...),             ame: look },
  idlelock:    { size: () => Qt.size(idlelockW, ...),         ame: idlelock },
  fontpicker:  { size: () => Qt.size(fontpickerW, ...),       ame: fontpicker }
})
```

Each entry: `size` is a thunk (so the geometry reads register as live deps of `targetSize`), `ame` is the surface item Ame anchors to (null = Ame uses pill's own anchor).

**`mode` property** — resolves which mode the pill is in:

```qml
readonly property string mode: surfaceOpen && surfaces[surface] !== undefined ? surface
  : (quickChoosing ? "quickChoose"
  : (quickCounting ? "quickCount"
  : (osdActive && !held ? "osd"
  : (toastActive && !held ? "toast"
  : (expanded ? "hover" : "rest")))))
```

**Settings-specific navigation methods:**

| Method | Purpose |
|---|---|
| `rowNavSurface()` | Returns which settings-family surface owns keyboard nav right now (settings index, appearance, display, input, look, idlelock, updates). Returns null if none open. |
| `settingsMove(dir)` | Forward arrow-key up/down to the open settings surface's `kbMove` |
| `settingsAdjust(dir)` | Forward left/right to `kbAdjust` (step seg or toggle) |
| `settingsActivate()` | Forward Enter to `kbActivate` (toggle/nav/seg) |
| `surfaceBack()` | Back navigation: keybinds form→list→settings, fontpicker→appearance, any sub-surface→settings index, anything else→close |

**`surfaceBack()` logic chain:**

```
keybindsOpen && keybinds.formOpen  → keybinds.closeForm()
keybindsOpen                       → requestSurface("settings")
fontpickerOpen                     → requestSurface("appearance")
appearanceOpen / updatesOpen / displayOpen / inputOpen / lookOpen / idlelockOpen
                                   → requestSurface("settings")
else                               → requestClose()
```

**`onSurfaceOpenChanged`:** when any surface opens, `pinned = false` and cancels any active quick-record chooser.

---

## 3. IPC Entry Points (shell.qml)

The `IpcHandler` in `shell.qml` exposes these settings-relevant commands:

```
settings(mon)  → toggleSurface(mon, "settings")
```

`toggleSurface` is the universal open/close toggle: if the same surface is already open on the same monitor it closes; otherwise it opens.

**No separate IPC for sub-surfaces** — they are reached only through the settings index's nav rows (which call `root.requestSurface(name)`).

---

## 4. Each Sub-Surface in Detail

### 4.1 Appearance.qml (`backSurface: "settings"`)

**Rows (7):**

| # | kind | Name | Control | Bound to |
|---|---|---|---|---|
| 1 | seg | Time format | 24H / 12H | `Flags.time12h` |
| 2 | toggle | Clock seconds | on/off | `Flags.clockSeconds` |
| 3 | toggle | Japanese glyphs | on/off | `Flags.showGlyphs` |
| 4 | seg | Palette | Static / Dynamic / Manual | `Flags.paletteMode` |
| 5 | seg | UI Scale | 0.9 / 1.0 / 1.1 / 1.25 | `Flags.uiScale` |
| 6 | toggle | Reduce motion | on/off | `Flags.reduceMotion` |
| 7 | nav | Font picker | — | surface `"fontpicker"` |

**Palette modes:**
- **Static** — no background process
- **Dynamic** — runs `wallcolors.py` on the current wallpaper file, then reloads Hyprland + Ghostty
- **Manual** — reveals a hue rainbow strip + dark/light toggle + saturation; dragging the strip debounces at 260ms before running `wallcolors.py --hue <val> <mode> <sat>` + reload

**Process chain for palette apply:**
```
applyTimer (260ms debounce)
  → paletteProc: python3 wallcolors.py --hue "$1" "$2" "$3"
                 && hyprctl reload
                 && busctl ghostty reload-config
```

**Dynamic mode process:**
```
dynamicProc: reads ~/.local/state/ricelin-wallpaper
             → python3 wallcolors.py <wallpaper-path>
             → hyprctl reload
             → busctl ghostty reload-config
```

**Font picker nav row:** opens `FontPicker.qml` as a sub-surface of Appearance.

---

### 4.2 Look.qml (`backSurface: "settings"`)

**Edits:** `decoration.lua` directly, then `hyprctl reload`.

**Rows (6):**

| # | kind | Name | Control | Default |
|---|---|---|---|---|
| 1 | seg | Gaps in | −/+/value stepper | 6 |
| 2 | seg | Gaps out | −/+/value stepper | 12 |
| 3 | seg | Rounding | −/+/value stepper | 12 |
| 4 | seg | Border size | −/+/value stepper | 2 |
| 5 | toggle | Blur | on/off | true |
| 6 | toggle | Opacity | active/inactive sub-rows | 1.0 |

**Blur sub-rows** (visible when blur is on): blur size (default 8), blur passes (default 3).

**Pill-blur layer rule:** toggling blur on/off adds/removes a named rule `pill-blur` in `decoration.lua`:
```lua
hl.layer_rule({ name = "pill-blur", match = { namespace = "pill" }, blur = true, ignore_alpha = 0.05 })
```

**Opacity special path:** changing active/inactive opacity calls both `writeDeco` (reload) AND `hyprctl eval hl.config({...})` to force immediate window-state recompute (otherwise windows keep stale alpha until next focus change).

**Helper library:** `lib/setDeco.js` — `getField`, `setField`, `getBlockField`, `setBlockField`, `hasNamedRule`, `addNamedRule`, `removeNamedRule`.Created [`YEMI SHELL DOC/RICELLIN_SETTINGS_ARCHITECTURE.md`](YEMI SHELL DOC/RICELLIN_SETTINGS_ARCHITECTURE.md) — a complete read-only map of how RICELLIN connects settings to the pill module.

**What it covers:**

1. **Hierarchy** — `shell.qml → Pill.qml → Settings.qml (index) → 7 sub-surfaces`, with `SettingsSurface.qml` as the shared base and `FontPicker.qml` as a sub-surface of Appearance.

2. **SettingsSurface.qml** — the base class that adds the `rows[]` registry, keyboard nav (`kbMove`/`kbAdjust`/`kbActivate`), mouse hover sync, and the Ame seam (`ameForm`/`amePoint`) to `PillSurface`. Row entry schema documented: `{item, kind, surface, vals, get, set}`.

3. **Pill.qml orchestrator** — the `surfaces` map (single source of truth for all 20 surfaces), the `mode` resolver, settings-specific nav methods (`rowNavSurface`, `settingsMove`, `settingsAdjust`, `settingsActivate`, `surfaceBack`), and the back-navigation decision chain.

4. **Each sub-surface in detail:**
   - **Appearance** — 7 rows (time format, seconds, glyphs, palette static/dynamic/manual, UI scale, reduce motion, font picker). Palette apply chains through `wallcolors.py` + `hyprctl reload` + Ghostty reload.
   - **Look** — 6 rows editing `decoration.lua` directly (gaps, rounding, border, blur, opacity). Blur toggles a named `pill-blur` layer_rule. Opacity uses `hyprctl eval hl.config` for immediate window-state refresh.
   - **Display** — card-based UI, no row registry. Uses `display-apply.sh` with a 12-second auto-revert watchdog. Persists via `monitors.lua` rewrite.
   - **Input** — custom stepper UI, no row registry. Edits `input.lua`, `env.lua`, `autostart.lua`. Cursor changes apply live via `hyprctl setcursor`.
   - **Keybinds** — extends `PillSurface` directly (not SettingsSurface). Own ListView + form state machine. Edits `binds.lua` via `lib/binds.js`.
   - **IdleLock** — 3 seg rows. Regenerates `hypridle.conf` from current values, restarts `hypridle` systemd unit.
   - **Updates** — custom status UI. Git fetch/pull in `$HOME/.config/quickshell`.

5. **IPC entry points** — `shell.qml`'s `IpcHandler` exposes `settings(mon)` only; sub-surfaces are reached via nav rows calling `requestSurface(name)`.

6. **Flags singleton** — documented as the implicit settings store. All 14+ settings properties, which surfaces read/write them, and how side effects are triggered inline in row callbacks.

7. **Settings → outside world connection map** — ASCII diagram showing each surface's write target (Flags, decoration.lua, monitors.lua, input.lua, binds.lua, hypridle.conf, git).

8. **Key design patterns** — the `rows[]` registry pattern, `backSurface` string, `surfaces` map as single source of truth, Flags as implicit store, and the Ame seam integration.

9. **Full file inventory** — all 18 settings-related files with their roles.

---

### 4.3 Display.qml (`backSurface: "settings"`)

**Edits:** `monitors.lua` via `display-apply.sh` with a 12-second auto-revert watchdog.

**No row registry** (`rows: []`) — this surface uses its own card-based UI, not the SettingsRow system.

**Flow:**
1. On open: runs `hyprctl monitors -j`, parses with `lib/monitors.js`
2. Renders one card per output with three segmented pickers: resolution (WxH), Hz, scale
3. **Apply** → calls `display-apply.sh apply <output> <mode> <position> <scale>` which snapshots old spec, applies new one, arms 12s watchdog
4. **Keep** → calls `display-apply.sh keep <output>`, rewrites that output's block in `monitors.lua` via `lib/monitors.js:setMonitor`
5. **Revert** (watchdog fires) → restores old mode automatically

**Scale options:** 1.0, 1.25, 1.5, 2.0

**Countdown:** 12-second visual countdown while pending; clicking empty space during countdown is swallowed (can't accidentally lose the Keep button).

---

### 4.4 Input.qml (`backSurface: "settings"`)

**Edits:** `input.lua`, `env.lua`, `autostart.lua` directly, then `hyprctl reload`.

**No row registry** (`rows: []`) — custom UI with a stepper control for sensitivity.

**Fields controlled:**

| Field | File | Method |
|---|---|---|
| Sensitivity | `input.lua` | `writeInputField("sensitivity", literal)` → reload |
| Accel profile | `input.lua` | `writeInputField("accel_profile", literal)` → reload |
| Cursor size | `env.lua` | `hyprctl setcursor <theme> <size>` + rewrite env + rewrite autostart |
| Cursor theme | `env.lua` | same as above |

**Cursor theme list:** scanned at open from `~/.icons`, `~/.local/share/icons`, `/usr/share/icons`, and `$XDG_DATA_DIRS` — any folder with a `cursors/` subfolder is a candidate.

**Helper library:** `lib/setInput.js` — `getField`, `setField`, `setEnv`, `setCursorLine`.

---

### 4.5 Keybinds.qml (extends `PillSurface` directly, NOT SettingsSurface)

This is the outlier — it does NOT extend `SettingsSurface`. It extends `PillSurface` directly because it has its own full keyboard navigation (list + form), not the row-registry pattern.

**Key difference from SettingsSurface:**
- No `rows[]` registry
- Has its own `focusIndex` for the ListView
- Has `formOpen` / `formAdd` / `listening` state machine
- Emits `requestSurface(string)` directly (same signal name as SettingsSurface)

**Data flow:**
1. On open: reads `binds.lua`, parses with `lib/binds.js`
2. Renders a searchable `ListView` of binds (combo chip + name/action)
3. Tap row → opens form in EDIT mode (prefilled)
4. Bottom dashed bar → opens form in ADD mode (empty)
5. Form has: key-binding field (arms chord capture), name field, command field
6. Save → `lib/binds.js:add` / `rebind` / `editCmd` / `editName` → single write → reload
7. Command field is read-only for non-exec dispatches and env-prefixed paths

**Chord capture:** while `listening`, an invisible `Item` with focus swallows every keystroke; captured combo held in form state until Save or Escape.

**Helper libraries:** `lib/binds.js` (parse/write binds.lua), `lib/keychord.js` (chord formatting).

**Back navigation from Pill.qml:**
```
keybindsOpen && keybinds.formOpen  → keybinds.closeForm()
keybindsOpen && !formOpen          → requestSurface("settings")
```

---

### 4.6 IdleLock.qml (`backSurface: "settings"`)

**Edits:** regenerates `hypridle.conf` from current values, then `systemctl --user restart hypridle`.

**Rows (3):**

| # | kind | Name | Options | Bound to |
|---|---|---|---|---|
| 1 | seg | Auto-lock | Off/1/3/5/10/15 min | `Flags.idleLockMin` |
| 2 | seg | Screen off | Off/3/5/10/15 min | `Flags.idleSuspendMin` |
| 3 | seg | Suspend | Off/15/30/60 min | `Flags.idleSuspendMin` |

**Config generation** (`buildConf()`):
```
general {
  lock_cmd = <lock.sh>
  before_sleep_cmd = loginctl lock-session
  after_sleep_cmd = hyprctl dispatch dpms on
}
[listener { timeout = N; on-timeout = <lock.sh> }]        ← if idleLockMin > 0
[listener { timeout = N; on-timeout = hyprctl dispatch dpms off; on-resume = hyprctl dispatch dpms on }]  ← if idleScreenOffMin > 0
[listener { timeout = N; on-timeout = systemctl suspend }] ← if idleSuspendMin > 0
```

Minutes are converted to seconds in the output.

---

### 4.7 Updates.qml (`backSurface: "settings"`)

**Edits:** runs git commands in `$HOME/.config/quickshell` (the live config dir, which is a symlink to the Ricelin clone).

**No row registry** (`rows: []`) — custom status UI.

**State machine:**

| `statusKind` | Condition | UI |
|---|---|---|
| `idle` | not checked yet | "Installed" badge |
| `checking` | `checking = true` | spinning icon |
| `ok` | checked, up to date | "Up to date" + check badge |
| `behind` | checked, behind | "N updates available" + arrow-up badge |
| `updating` | `updating = true` | "Updating…" spinning |
| `updated` | pull succeeded | "Updated · restart the shell to apply" |
| `fail` | check or pull failed | "Check failed" / error text |

**Git operations:**
- **Version:** `git log -1 --format='%h %cs'` → shows short SHA + date
- **Check:** `git fetch --quiet origin main` then compare HEAD vs FETCH_HEAD by SHA
- **Update:** `git pull --ff-only` (fails safely on dirty tree or conflict)

---

### 4.8 FontPicker.qml (sub-surface of Appearance)

Reached from Appearance row 7 (`nav` → surface `"fontpicker"`).  
Back navigation: `pill.requestSurface("appearance")`.

Not read in full, but from Pill.qml's `surfaceBack()`:
```
fontpickerOpen → requestSurface("appearance")
```

---

## 5. The SettingsRow / SettingsSeg / SettingsHeader Primitives

These are the visual building blocks used inside every SettingsSurface.

### SettingsRow
- Wraps one control row: icon + name + sub-caption + control (SettingsSeg / LinkToggle)
- `captionOnFocus: true` shows the sub-caption only when focused
- Chevron icon on the right glows `Theme.cream` when focused, `Theme.iconDim` otherwise
- Reports hover to parent via `surface.reportRowRowHover(rowItem, hovered)`

### SettingsSeg
- Segmented control: shows current value label, left/right arrows to step
- `options: [{label, value}, ...]` — the cycle list
- `value: <binding>` — current value
- `onPicked: (v) => ...` — callback when user selects

### SettingsHeader
- Kanji glyph + title + optional back chevron
- `showBack: true` on sub-surfaces, absent on the index
- Back chevron calls `root.requestSurface(root.backSurface)`

---

## 6. Complete Data Flow: Opening a Settings Sub-Surface

```
User hovers pill
  → Pill.hovered = true
  → mode = "hover"
  → Pill.requestSurface("settings")  [from hover soul or IPC]
    → Pill.surface = "settings"
    → Pill.mode = "settings"
    → targetSize = surfaces["settings"].size()  [392*s × implicitHeight+29*s]
    → Pill.width/height animate to target
    → Settings.qml (surface: "settings") becomes active
      → opacity = morphCloseness^1.3 fades in
      → Ame anchor = settings (from surfaces map)
```

**Keyboard open path:**
```
Escape / Super+W [example]
  → Bar.qml or shell.qml catches key
  → Pill.surfaceBack()
    → if settings-family open: requestSurface("settings")  [back to index]
    → else: requestClose()  [dismiss to hover]
```

**Sub-surface open path (from index):**
```
User clicks "Appearance" row or presses Enter on it
  → SettingsSurface.activateRow(appearanceRow)
    → kind === "nav" → root.requestSurface("appearance")
      → Pill.surface = "appearance"
      → mode = "appearance"
      → Appearance.qml becomes active
        → onActiveChanged fires → seed() reads Flags
        → rows[] controls bind to Flags properties
```

**Back from sub-surface:**
```
User clicks back chevron or presses Escape
  → SettingsHeader calls root.requestSurface(root.backSurface)
    → root.backSurface = "settings"
    → Pill.surface = "settings"
    → Settings.qml (index) fades back in
```

---

## 7. The Flags Singleton — Central State Store

Every settings sub-surface reads from and writes to `Flags`, a singleton at `Singletons/Flags.qml`.

**Properties used by settings surfaces:**

| Property | Type | Set by | Read by |
|---|---|---|---|
| `time12h` | bool | Appearance | Clock, Appearance |
| `clockSeconds` | bool | Appearance | Clock, Appearance |
| `showGlyphs` | bool | Appearance | Pill headers |
| `paletteMode` | string | Appearance | Appearance |
| `manualHue` | real | Appearance (hue strip) | Theme |
| `manualSat` | real | Appearance (hue strip) | Theme |
| `manualDark` | bool | Appearance (dark/light toggle) | Theme |
| `uiScale` | real | Appearance | Pill.s, Bar.s |
| `reduceMotion` | bool | Appearance | Motion singleton |
| `idleLockMin` | int | IdleLock | IdleLock |
| `idleScreenOffMin` | int | IdleLock | IdleLock |
| `idleSuspendMin` | int | IdleLock | IdleLock |
| `pillBlur` | bool | Look | PillOverlay mask |

Flags is a `QtObject` with all properties defaulting to sensible values. Changes propagate via QML bindings — no explicit signal wiring needed for UI updates. The side effects (file writes, process runs) are triggered by the `onPicked` / `onToggled` callbacks in each row.

---

## 8. The Settings → Outside World Connection Map

```
SettingsSurface sub-surface
  │
  ├─ Appearance ──► Flags singleton (QML bindings)
  │     ├─ paletteMode = "dynamic" ──► dynamicProc (wallcolors.py + reload)
  │     ├─ paletteMode = "manual" ──► paletteProc (wallcolors.py --hue + reload)
  │     └─ uiScale ──────────────────► Pill.s / Bar.s (live rescale)
  │
  ├─ Look ────────► lib/setDeco.js ──► decoration.lua ──► hyprctl reload
  │     └─ opacity ──► hyprctl eval hl.config(...) (immediate refresh)
  │
  ├─ Display ─────► display-apply.sh ──► hyprctl monitor ──► 12s watchdog
  │     └─ keep ──► monitors.lua rewrite (lib/monitors.js)
  │
  ├─ Input ───────► lib/setInput.js ──► input.lua / env.lua / autostart.lua
  │     └─ cursor ──► hyprctl setcursor (live) + file writes (persist)
  │
  ├─ Keybinds ────► lib/binds.js ──────► binds.lua ──► hyprctl reload
  │
  ├─ IdleLock ────► buildConf() ────────► hypridle.conf ──► systemctl restart hypridle
  │
  └─ Updates ─────► git -C $HOME/.config/quickshell fetch/pull
```

---

## 9. Key Design Patterns

### 9.1 The `rows[]` Registry Pattern
Used by: Settings.qml, Appearance.qml, IdleLock.qml  
NOT used by: Display.qml, Input.qml, Look.qml, Updates.qml, Keybinds.qml

The registry pattern gives free keyboard navigation (kbMove/kbAdjust/kbActivate) and the Ame seam. Surfaces with complex custom UIs (cards, steppers, forms) bypass it and handle their own input.

### 9.2 The `backSurface` String
Every SettingsSurface declares `backSurface: "settings"`. The base class doesn't enforce navigation — Pill.qml's `surfaceBack()` reads `backSurface` indirectly by checking which surface is open and routing accordingly. The string is also used by `SettingsHeader`'s back chevron.

### 9.3 The `surfaces` Map as Single Source of Truth
Adding a new surface to the pill requires exactly one entry in Pill.qml's `surfaces` map. The map drives: target size, Ame anchor, mode resolution, and the `settingsLike` shortcut. No parallel ternary chains.

### 9.4 Flags as the Implicit Settings Store
There is no dedicated "settings manager" object. `Flags` (a QtObject singleton) IS the store. Each sub-surface reads/writes Flags directly. Side effects (file writes, process runs) are triggered inline in the row callbacks. This means:
- No observer pattern needed — QML bindings propagate UI changes automatically
- Side effects are colocated with the control that triggers them
- The file-on-disk is a serialization of Flags, not the source of truth

### 9.5 The Ame Seam
Every SettingsSurface sets `ameForm`/`amePoint` via the base class. When a row is focused, the seam form `"rowseam"` appears at the row's centre. This is handled entirely in SettingsSurface.qml — sub-surfaces don't need to know about Ame at all.

---

## 10. File Inventory — Settings-Related Files

```
configs/quickshell/pill/
  Settings.qml          ← category index (7 rows, 2 groups)
  SettingsSurface.qml   ← base class (row registry, kb nav, Ame seam)
  SettingsRow.qml       ← visual row primitive
  SettingsSeg.qml       ← segmented control primitive
  SettingsHeader.qml    ← header with kanji + back chevron
  Appearance.qml        ← clock, glyphs, palette, scale, motion
  Look.qml              ← gaps, rounding, border, blur, opacity
  Display.qml           ← monitor resolution/refresh/scale
  Input.qml             ← pointer sensitivity, accel, cursor
  Keybinds.qml          ← bind list + edit/add form
  IdleLock.qml          ← auto-lock, screen-off, suspend timeouts
  Updates.qml           ← git check + pull
  FontPicker.qml        ← font selection (sub-surface of Appearance)
  Pill.qml              ← orchestrator: surfaces map, nav methods, surfaceBack
  PillSurface.qml       ← generic morph-surface base
  shell.qml             ← window factory, IPC handler, fullscreen detection
  lib/
    setDeco.js          ← decoration.lua read/write helpers
    setInput.js         ← input.lua/env.lua/autostart.lua helpers
    binds.js            ← binds.lua parse/write helpers
    keychord.js         ← chord formatting
    monitors.js         ← monitor mode parsing + Lua block rewrite
  Singletons/
    Flags.qml           ← central state store (all settings values)
    Theme.qml           ← colour palette
    Motion.qml          ← animation timings
    Dyn.qml             ← dynamic palette (per-wallpaper colour generation)
```
