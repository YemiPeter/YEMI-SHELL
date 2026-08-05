# YEMI-SHELL Color & Wallpaper System Audit

> **Repo:** `/home/yemi/.config/quickshell` (≡ `~/YEMI-SHELL`)  
> **Date:** 2026-08-05  
> **Framework:** Quickshell / Qt 6.10 QML  
> **Purpose:** Trace the exact color pipeline, identify the dual-wallpaper-path conflict, and locate every surface that fails to resolve colors through tokens.

---

## 0. Current System Snapshot

### 0.1 Component / role inventory

| File / Component | Role in Color System | Status |
|------------------|---------------------|--------|
| `scripts/wallcolors.py` (quickshell copy) | Color extraction from wallpaper → `colors.json` + `terminal.json` + `hypr-colors.lua` (snake_case schema) | ✅ Active, **but duplicated** |
| `~/.config/hypr/scripts/wallcolors.py` (hypr copy) | Color extraction from wallpaper → `colors.json` + `terminal.json` + `hypr-colors.lua` (camelCase schema) | ✅ Active, **conflicts with quickshell copy** |
| `services/Matugen.qml` | Matugen service wrapper. `applyWallpaper()` runs `matugen image … -c config.toml`; `reload()` only `console.log`s | ⚠️ `applyWallpaper` **never called**; writes `colors.qml` (wrong ext/path) never consumed by Dyn.qml |
| `singletons/Theme.qml` | Static fallback tokens + live `dyn ? Dyn.X : "#hex"` ternary gate | ✅ Core token façade |
| `singletons/Dyn.qml` | `FileView` watching `~/.cache/yemi-shell/colors.json` → `JsonAdapter` (17 snake_case keys) | ✅ Core dynamic source — **schema-bound** |
| `singletons/Flags.qml` | Persists `flags.json`; holds `paletteMode`, `systemMood`, `pillOpacity`, `pillBlur` | ✅ Works |
| `scripts/after-wall.sh` | Post-wallpaper hook: runs quickshell `wallcolors.py` → `apply-terminal-colors.py` → `qs ipc call matugenReload` | ✅ Active (quickshell schema writer) |
| `scripts/apply-terminal-colors.py` | Fan-out `terminal.json` → kitty `theme.conf` + ghostty `yemi-auto` | ✅ Active |
| `scripts/toggle-colormode.sh` | Cycles auto/dark/light; reads `~/.cache/wal/colors.json` (pywal) for the wallpaper path | ⚠️ Reads a **3rd, unrelated colors.json** |
| `modules/pill/Singletons/Walls.qml` | Wallpaper bridge: picker → `wallpaper.sh set` → `after-wall.sh` on exit | ✅ Active picker path |
| `modules/pill/Appearance.qml` | Palette/mood toggle UI — calls **hypr copy** of `wallcolors.py` directly | ❌ **Calls the wrong script** (writes wrong schema) |
| `modules/pill/Pill.qml` | Pill body — the reference surface; 52 `Theme.*` refs, 0 hex literals | ✅ Properly themed |
| `modules/osd/{Wrapper,VolumeOSD,BrightnessOSD}.qml` | OSD surfaces — `required property var matugen` **declared but never read** | ❌ Hardcoded Qt.rgba fallbacks only |
| `modules/bar/components/Battery.qml` | Bar battery — 6 hardcoded hex colors | ❌ Partially themed |
| `modules/bar/Bar.qml` | Bar top-level pills — themed via `Qt.rgba(Theme.*)` | ✅ Themed |
| `~/.config/skwd-wall/config.json` | skwd-wall config: `externalWallpaperCommand → wallpaper.sh`, `matugen:false`, integration writes `colors.json` (dormant) | See §1.3 |

### 0.2 Discovery evidence

```bash
$ ls ~/.config/hypr/scripts/wallcolors.py ~/.config/hypr/scripts/wallpaper.sh \
>    ~/.cache/yemi-shell/colors.json ~/.cache/yemi-shell/terminal.json \
>    ~/.cache/wal/colors.json
-rw-r--r-- 1 yemi yemi 11779 Jul 20  ~/.config/hypr/scripts/wallcolors.py   # ─┐
-rw-r--r-- 1 yemi yemi  3052 Aug  4  ~/.config/hypr/scripts/wallpaper.sh     #  │ hypr path
-rw-r--r-- 1 yemi yemi   492 Aug  5  ~/.cache/yemi-shell/colors.json          # ├─ both write HERE
-rw-r--r-- 1 yemi yemi   385 Aug  5  ~/.cache/yemi-shell/terminal.json        # └─ and HERE
-rw-r--r-- 1 yemi yemi   723 Jul 20  ~/.cache/wal/colors.json                # ─ pywal path (3rd)
-rwxr-xr-x 1 yemi yemi  186  scripts/wallcolors.py                           # ─┐ repo (quickshell) copy
```

The repo's own `scripts/wallcolors.py` is **186 lines**; the hypr copy is **247 lines** with a completely **different schema** and color logic. Both write `CACHE = Path.home()/".cache"/"yemi-shell"`.

---

## 1. The Dual Wallpaper Path Problem

### 1.1 The two active wallpaper triggers (plus a dead third)

**Path A — Picker / `skwd wall apply` (the LIVE change path)**
```
Wallpaper.qml:127  Walls.apply(entry.path)            # picker tile click
shell.qml:336      applyWallpaper(wallpaper)          # random keybind / bar
  └─ Walls.qml:59  applyProc → wallpaper.sh set <path>        (or skwd wall apply → externalWallpaperCommand)
      └─ wallpaper.sh (hypr) ────────────────────────┐
          │  awww img <pic>            (sets wallpaper)      │
          │  (XDG_STATE_HOME)/quickshell-wallpaper   (state) │
          │  jq flags.json .paletteMode                (mode)│
          │  python3 ~/.config/hypr/scripts/wallcolors.py <pic>   ◀── HYPR copy (camelCase schema)
          │  hyprctl reload; ghostty reload             │
          └─ on Walls.applyProc exit 0 ─────────────────┘
      └─ Walls.qml:131 afterWallProc → after-wall.sh <wallPath>
          ├─ python3 scripts/wallcolors.py <WALL_PATH>    ◀── QUICKSSELL copy (snake_case schema) — **OVERWRITES** colors.json
          ├─ python3 apply-terminal-colors.py   (terminal fan-out)
          └─ qs ipc call matugenReload          (no-op, see §1.4)
```

**Path B — Appearance toggle (palette / mood switch)**
```
modules/pill/Appearance.qml  (paletteRow / moodRow SettingsSeg → applyMode())
  ├─ staticProc  → python3 "$HOME/.config/hypr/scripts/wallcolors.py --mode static  --mood <mood>"   ◀── HYPR copy ONLY
  ├─ dynamicProc → python3 "$HOME/.config/hypr/scripts/wallcolors.py --mode dynamic --mood <mood>" <pic>  ◀── HYPR copy ONLY
  ├─ systemThemeProc → apply-system-theme.sh <mood>
  ├─ hyprctl reload; ghostty reload
  └─ **does NOT run after-wall.sh, does NOT run quickshell wallcolors.py, does NOT signal quickshell Dyn**
```
After Path B, `colors.json` is left with the **camelCase schema** and stays that way — there is no follow-up writer to fix it.

**Path C — Matugen.qml (DEAD CODE)**
`services/Matugen.qml:24` `applyWallpaper()` runs `matugen image <path> -c dist/matugen/config.toml` → writes `$RICE_HOME/quickshell/state/colors.qml`.  
- `dist/` does **not exist** in the repo (no `quickshell/dist/matugen/config.toml`).  
- `colors.qml` ≠ `colors.json` → **never read by Dyn.qml**.  
- `applyWallpaper()` is **never invoked** anywhere (only `reload()` is, and that just `console.log`s).  
Verdict: vestigial; zero runtime effect.

### 1.2 The exact schema mismatch (the root of the conflict)

Both scripts do `CACHE = Path.home() / ".cache" / "yemi-shell"` and `write_text(... colors.json ...)`, but emit **different keys**:

| Token concept | Quickshell `wallcolors.py` (186-line) key | Hypr `wallcolors.py` (247-line) key | Dyn.qml `JsonAdapter` reads |
|---------------|-------------------------------------------|-------------------------------------|----------------------------|
| surface | `surface` | `surface` | ✅ `surface` |
| surface-low | `surface_container_low` | `surfaceLow` | ✅ `surface_container_low` |
| surface-high | `surface_container_high` | `surfaceHigh` | ✅ `surface_container_high` |
| surface-highest | `surface_container_highest` | `surfaceHighest` | ✅ `surface_container_highest` |
| primary / accent | `primary` | `accent` | ✅ `primary` (**accent ≠ primary**) |
| primary container | `primary_container` | `accentSoft`/`accentHover` | ✅ `primary_container` |
| on-primary container | `on_primary_container` | (none) | ✅ `on_primary_container` |
| outline | `outline` | `border` | ✅ `outline` (**border ≠ outline**) |
| outline variant | `outline_variant` | (none) | ✅ `outline_variant` |
| cream | `cream` | `content` | ✅ `cream` (**content ≠ cream**) |
| bright | `bright` | (none — `content` is the bright one) | ✅ `bright` |
| subtle | `subtle` | `contentMuted` | ✅ `subtle` |
| dim | `dim` | `contentDim` | ✅ `dim` |
| faint | `faint` | `contentFaint` | ✅ `faint` |
| icon dim | `icon_dim` | `icon` | ✅ `icon_dim` |
| tick rest | `tick_rest` | `tick` | ✅ `tick_rest` |

**Net effect:** when `colors.json` is written by the **hypr copy** (which is exactly what Path B leaves behind permanently), every `JsonAdapter` property that Dyn.qml consumes is missing → it silently falls back to its **baked-in warm teal defaults** (`#18120b`, `#f5bd6f`, `#e6d6cb`, etc.). The wallpaper's colors therefore **never reach the pill** — the pill always renders the same static-looking warm fallback, indistinguishable from `Flags.paletteMode === "static"`.

`terminal.json` is written twice too, with two different ANSI mappings (quickshell: matugen `base16`; hypr: `build_ansi16` family-based). Whichever runs last wins — so the terminal colors are a coin-flip race.

### 1.3 The skwd-wall angle (why Path A sometimes "wins")

`~/.config/skwd-wall/config.json` reveals:
- `"features": { "matugen": false }` — skwd's own matugen engine is OFF, so its `quickshell-colors.json` integration (output `colors.json`) is **dormant**. Good — skwd does not write a 3rd schema directly.
- `"externalWallpaperCommand": "~/.config/hypr/scripts/wallpaper.sh set %path%"` — skwd **delegates** wallpaper setting (and thus color extraction) to `wallpaper.sh`, which runs the **hypr copy**.
- `skwd-wall/skwd-wall/scripts/sync-colors.sh:11` calls `after-wall.sh` — this is skwd's hook that re-runs the **quickshell copy** and saves it via `apply-terminal-colors.py`.

So under skwd, both copies run in sequence: **hypr copy first (wrong schema), quickshell copy last (correct schema)**. When skwd's `sync-colors.sh` fires, the quickshell copy wins and colors are right. **When it does NOT fire** (e.g. `wallpaper.sh` invoked directly, or after a `hyprctl reload` without skwd's hook), the hypr copy's wrong schema is left in place.

The Appearance toggle (Path B) **bypasses skwd entirely** and calls the hypr copy directly with no recovery writer — this is the most reliable way to corrupt `colors.json`.

### 1.4 Why `qs ipc call colors reload` and `matugenReload` are no-ops

- `shell.qml:53-60`: `colors` IPC handler → `ipcColorLoadProc` (`echo reload`) → on exit `root.matugen.reload()`.
- `services/Matugen.qml:14-17`: `reload()` only does `if (Flags.debug) console.log(...)`. **It does not touch `colors.json`.**
- **`scripts/after-wall.sh:25`** calls `qs ipc call matugenReload` (note: `target: "matugenReload"` is **not a registered IpcHandler** in `shell.qml` — the registered one is `target: "colors"` with `reload()`). So `matugenReload` is a silent no-op.

Real dynamic reload works **only** because `Dyn.qml` uses `FileView { watchChanges: true; onFileChanged: reload() }` — the OS file event reparses `colors.json`. The IPC reload is cosmetic.

### 1.5 The `manual` mode mismatch

`wallpaper.sh:92-93` reads `flags.json .paletteMode` and checks `if [ "$pmode" = "manual" ]`. But `Flags.qml:73` defines `paletteMode: "dynamic"` and the UI (`Appearance.qml:119`) only offers `["static","dynamic"]`. There is no `manual` value — **the manual/hue branch of `wallpaper.sh` can never fire.** Static mode is therefore unreachable from a wallpaper change and is only reachable via the Appearance toggle (Path B), which uses the wrong script.

---

## 2. Color Coverage Audit — Where Colors Are vs. Aren't

### 2.1 The pill (the "good" reference)

`modules/pill/Pill.qml` is the reference surface. It resolves **every** color through `Theme.*` (52 references, 0 hex literals). Highlights:

- **Body** (`Pill.qml:549-576`): `color: Qt.rgba(Theme.cardBot.r, .g, .b, Flags.pillOpacity)` + `border.color: Qt.rgba(Theme.cream.r,.g,.b, 0.10)` + top highlight gradient `#572 Qt.rgba(1, 1, 1, 0.04)` (hardcoded, see §2.3).
- **Rest text**: `Theme.cream` (700); date `Theme.dim` (765).
- **Hover icons**: `Theme.cream` on hover else `Theme.iconDim` (816-1154).
- **Hover separators**: `Theme.hair` (741, 788, 845).
- **DND glyph**: `Theme.vermLit` (879, 894, 902).
- **Battery text**: `Theme.vermLit` / `Theme.flameGlow` / `Theme.subtle` (957).
- **Recording dot**: `Theme.verm` (1087); quick-choose tiles `Theme.tileBg` / `Theme.vermLit` / `Theme.border` (1455-1512).
- **Countdown**: `Theme.flameGlow` / `Theme.dim` (1599, 1608).
- **Static/dynamic + dark/light**: handled entirely by `Theme.qml`'s `readonly bool dyn: Flags.paletteMode !== "static"`, which gates every token to `Dyn.*` (dynamic) or a fixed hex (static). Dark/light is folded into `wallcolors.py` (it chooses `mood` and the surface/text lightness ladders). `Flags.systemMood` is the user switch; `wallcolors.py` derives `light = mean_l >= 0.40`.
- **Opacity/blur**: `Flags.pillOpacity` (alpha on body), `Flags.pillBlur` (consumed in `PillOverlay`/`Bar.qml`).

It is **not** perfectly clean — see §2.3 for two hardcoded literals inside it.

### 2.2 Per-surface color audit (all modules)

Compiled via per-file `grep` for hex literals, `Dyn.`, `Theme.`, `Flags.`. `Dyn:` column is 0 everywhere that matters — **no surface reads `Dyn` directly; they all go through `Theme.*`** (the intended façade). This is correct by design.

| Surface file | hex literals | `Theme.` | `Flags.` | Named/`Qt.rgba` literals | Status |
|---|---|---|---|---|---|
| `modules/pill/Pill.qml` | 0 | 52 | 8 | `Qt.rgba(1,1,1,0.04)` L570; `"rgba(255,246,240,0.6)"` L531 | ✅ Themed (2 minor literals, §2.3) |
| `modules/pill/Ame.qml` | 0 | 17 | 0 | — | ✅ Themed |
| `modules/pill/BatterySurface.qml` | 0 | 14 | 0 | — | ✅ Themed |
| `modules/pill/Calendar.qml` | 0 | 88 | 3 | — | ✅ Themed |
| `modules/pill/Clipboard.qml` | 0 | 19 | 0 | — | ✅ Themed |
| `modules/pill/Display.qml` | 0 | 17 | 1 | — | ✅ Themed |
| `modules/pill/DisplayLabel.qml` | 0 | 4 | 0 | — | ✅ Themed |
| `modules/pill/DisplayPicker.qml` | 0 | 11 | 0 | — | ✅ Themed |
| `modules/pill/Filament.qml` | 0 | 7 | 0 | — | ✅ Themed |
| `modules/pill/Launcher.qml` | 0 | 12 | 0 | — | ✅ Themed |
| `modules/pill/Mixer.qml` | 0 | 8 | 4 | — | ✅ Themed |
| `modules/pill/Power.qml` | 0 | 16 | 0 | — | ✅ Themed |
| `modules/pill/Wallpaper.qml` | 0 | 23 | 0 | — | ✅ Themed |
| `modules/pill/Media.qml` | 0 | 22 | 0 | — | ✅ Themed |
| `modules/pill/Recorder.qml` | 0 | 90 | 5 | — | ✅ Themed |
| `modules/pill/SysmonSurface.qml` | 0 | 27 | 0 | — | ✅ Themed |
| `modules/pill/Settings.qml` | 0 | 11 | 0 | — | ✅ Themed |
| `modules/pill/Settings*.qml` (4 files) | 0 | — | — | — | ✅ Themed |
| `modules/pill/Look.qml`, `IdleLock.qml`, `Input.qml`, `Keybinds.qml` (69 Theme) | 0 | mixed | — | — | ✅ Themed |
| `modules/pill/Toast.qml` / `Tooltip.qml` / `Tray.qml` / `Updates.qml` / `WifiGlyph.qml` / `Workspaces.qml` | 0 | mixed | — | — | ✅ Themed |
| `modules/pill/Osd.qml` | **3** (#00ffffff, #55ffe6d6 L416-418) | 25 | 0 | — | ⚠️ Partial — 3 hardcoded gradient hex |
| `modules/pill/Appearance.qml` | 0 | 1 | 23 | — | ✅ Themed |
| `modules/bar/Bar.qml` | 0 | 3 | 1 | `pillBg/pillBorder/pillSeparator` via `Qt.rgba(Theme.*)` | ✅ Themed |
| `modules/bar/components/Battery.qml` | **6** (#ef4444,#f59e0b,#2dd4bf,#5eead4,#000000,#ffffff) | 4 | 0 | `Qt.rgba(0.1,0.12,1)` L234; `#000000/#ffffff` L186,304 | ❌ Not themed |
| `modules/bar/components/BluetoothPopupWindow.qml` | **1** (#ffffff L209) | 7 | 0 | — | ❌ Hardcoded |
| `modules/bar/components/NetworkPopupWindow.qml` | **2** (#ffffff L209,603) | 7 | 0 | — | ❌ Hardcoded |
| `modules/bar/components/BrightnessPopupWindow.qml` | **1** (#f9e2af fallback L20) | 15 | 0 | — | ⚠️ Partial (fallback only) |
| `modules/bar/components/VolumePopupWindow.qml` | **1** (#a6e3a1 fallback L25) | 24 | 0 | — | ⚠️ Partial (fallback only) |
| `modules/bar/components/Network.qml/Brightness/Volume/Bluetooth/Workspace/StatusIndicators` | 0 | 4-7 | 0-4 | — | ✅ Themed |
| `modules/osd/Wrapper.qml` | 0 | 0 | 0 | passes `matugen` property | ❌ Unthemed (see §2.4) |
| `modules/osd/VolumeOSD.qml` | 0 | 0 | 0 | `Qt.rgba(0.1,0.1,0.1,0.4)`, `Qt.rgba(0.2,0.6,1.0)`, `Qt.rgba(0.8,0.8,0.8)` | ❌ Hardcoded (matugen unused) |
| `modules/osd/BrightnessOSD.qml` | 0 | 0 | 0 | `Qt.rgba(0.1,0.1,0.1,0.1)`, `Qt.rgba(1,1,1,0.06)` | ❌ Hardcoded (matugen unused) |
| `modules/music/MusicPanel.qml` | 0 | 33 | 0 | — | ✅ Themed |
| `compositor/Compositor.qml` | 0 | 0 | 0 | — | N/A (logic only) |
| `compositor/Hyprland.qml` / `Niri.qml` | 0 | 0 | 0 | — | N/A (logic only) |
| `config/Appearance.qml` | 1 (#a6e3a1 L44) | 10 | 0 | Rest via `Theme.*`/`Qt.alpha` | ⚠️ Partial (single success fallback) |
| `config/BarConfig.qml` | **7** (#BE5052,…,#0a0908 L22-28) | 0 | 0 | — | ⚠️ Config defaults (acceptable) |
| `config/Config.qml` | 0 | 0 | 0 | — | N/A |

### 2.3 Hardcoded literals inside the "properly themed" pill

`Pill.qml` is almost fully tokenized, but has two literals that bypass the palette:

| Line | Code | Purpose | Problem | Suggested token |
|------|------|---------|---------|-----------------|
| 531 | `ctx.fillStyle = "rgba(255,246,240,0.6)";` | Ame soul-bead inner highlight glow | Hardcoded pearl-white; ignores wallpaper hue | `Theme.flameGlow` with opacity, or a `Theme.bright`-derived color |
| 570 | `GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }` | Pill top glossy highlight | Fixed white, doesn't dim in light mode | `Qt.rgba(1,1,1, Flags.systemMood==="light"?0.02:0.04)` or a `Theme` token |

These are low-severity (subtle highlights) but break the "no hardcoded colors" contract.

### 2.4 The OSD family — thematically orphaned

`modules/osd/Wrapper.qml` declares `required property var matugen` and forwards it to both `VolumeOSD` and `BrightnessOSD`, which also `required property var matugen`. **The property is never read.** Every color is a hardcoded `Qt.rgba`:

- `VolumeOSD.qml:78` `color: Qt.rgba(0.1, 0.1, 0.1, 0.4)` — body bg (comment: *"fallback until matugen colors are loaded"* — they never are)
- `VolumeOSD.qml:83` `border.color: Qt.rgba(1, 1, 1, 0.06)`
- `VolumeOSD.qml:113` `color: Qt.rgba(0.2, 0.6, 1.0, 1.0)` — icon (a fixed Azure blue, not the wallpaper accent)
- `VolumeOSD.qml:122,128,146` volume bar / text — fixed greys and azure
- `BrightnessOSD.qml:116-121` same hardcoded pattern

The OSD is injected from `shell.qml:25 root.matugen` (the dead `Matugen.qml` singleton). Because `Matugen.reload()` is a no-op, the OSD never receives real colors. **Fix: read `Theme.*` (or `Dyn.*`) directly and drop the dead `matugen` property.**

---

## 3. The Token System

### 3.1 `singletons/Flags.qml`

Persisted via `JsonAdapter` ↔ `flags.json` (`XDG_STATE_HOME/quickshell/flags.json`), `watchChanges: true`. Relevant color keys:

| Property | Default | Purpose |
|----------|---------|---------|
| `paletteMode` | `"dynamic"` | `"dynamic"` → `Theme.dyn` true → `Dyn.*`; `"static"` → fixed hex |
| `systemMood` | `"dark"` | dark/light; consumed by `wallcolors.py --mood` |
| `pillOpacity` | `0.55` | alpha on pill body surface |
| `pillBlur` | `false` | blur toggle |
| `uiScale` | `1.0` | global scale |
| `uiFont` | `""` | font override |
| `manualHue`/`manualSat`/`manualDark` | 30/0.5/true | hue-rotate override (dormant — see §1.5) |
| `reduceMotion` | `false` | motion reduction |

### 3.2 `singletons/Dyn.qml`

- **`FileView`** path: `$XDG_CACHE_HOME/yemi-shell/colors.json` (fallback `$HOME/.cache/yemi-shell/colors.json`) — **line 37**.
- `blockLoading: true`, **`watchChanges: true`**, `onFileChanged: reload()` — so a correct `colors.json` rewrites auto-propagate. ✅ (the watch mechanism is sound).
- **`JsonAdapter`** provides **17 defaults** matching the quickshell schema exactly (snake_case): `surface`, `surface_container`, `surface_container_low`, `surface_container_high`, `surface_container_highest`, `primary`, `primary_container`, `on_primary_container`, `outline`, `outline_variant`, `cream`, `bright`, `subtle`, `dim`, `faint`, `icon_dim`, `tick_rest`.
- Exposes **17 readonly aliases** (`adapter.X` → `Dyn.X`).
- **No** `reload()` function of its own — `onFileChanged: reload()` calls `FileView.reload()`, which re-reads + reparses the watched file.
- **Does not** compute light/dark variants — `wallcolors.py` emits a complete palette for the detected mood in one shot.

### 3.3 `singletons/Theme.qml`

- `readonly bool dyn: Flags.paletteMode !== "static"` — the single gate.
- Every color token is a ternary: `dyn ? Dyn.X : "#fixedHex"`. This is the "only the colors that should breathe do" philosophy (per its docstring).
- **Token list (31 color tokens):**
  - Surfaces/containers: `cardTop`←`Dyn.surfaceContainerHigh`, `cardBot`←`Dyn.surfaceContainerLow`, `tileBg`←`Dyn.surface`, `ghost`←`Dyn.surfaceContainerHighest`, `border`←`Dyn.outlineVariant`
  - Accent/primary: `onGlow`←`Dyn.primary`, `verm`←`Qt.darker(Dyn.primary,1.18)`, `vermLit`/`vermDeep`←`Dyn.primary`/`Dyn.primaryContainer`, `vermDim`←`Qt.darker(Dyn.primary,1.5)`, `vermDimDeep`←`Qt.darker(Dyn.primary,2.2)`, `vermBurn`←`Qt.darker(Dyn.primaryContainer,1.1)`, `flameCore`←`Qt.lighter(onGlow,1.03)`, `flameGlow`←`onGlow`
  - Text: `cream`, `bright`, `dim`, `subtle`, `faint`, `iconDim`, `tickRest` (all `Dyn.*` in dyn mode)
  - Flavor (flame ramp, string-typed for Canvas): `flameInk`, `flameEmber`, `flameBurn`, `flameTip`←`Dyn.primary`/`Dyn.primaryContainer`/`Dyn.onPrimaryContainer`
  - Veils/opacity: `hair`←`Qt.alpha(cream,0.13)`, `hairSoft`←0.08, `sheen`←0.07, `frameBg`←0.055, `frameBorder`←0.10, `creamMenu`←0.82, `threadBg`←`Qt.alpha(cream,0.13)`, `shadow`←`Qt.rgba(0,0,0,0.55)` (hardcoded black), `shadowOpacity`←0.5
  - Typography: `font`, `fontJp`, `fontFamilies`

**Gap:** there is no `Dyn.error`/`Dyn.success`/`Dyn.onSurface`/`Dyn.surfaceContainerLowest` — surfaces that need an error (power menu, toast) or success (success badge) color derive them from `Theme.verm`/`Theme.vermLit` or hardcode. `Theme` also lacks semantic `onPrimary`/`onSurface` text tokens; the text family is named `cream/bright/subtle/dim/faint/iconDim/tickRest` rather than Material `onSurfaceVariant` etc. — a custom naming scheme, internally consistent but not Material-3 standard.

### 3.4 How the two singletons interlock

```
wallcolors.py → colors.json (snake_case) ──FileView.watch──▶ Dyn.JsonAdapter ──▶ Theme.* ternaries ──▶ Pill.qml (52 refs, 0 hex)
                             ▲
                             │ writes SAME file
                          hypr wallcolors.py (camelCase) ──writes──▶ (corrupts schema)
```
`Theme.qml` imports nothing but references `Dyn` and `Flags` as global singletons (the `qmldir` / `pragma Singleton` makes them visible project-wide). When the schema is wrong, `Dyn.*` returns the `JsonAdapter` baked-in defaults — which happen to be very close to the `Theme.qml` static fallbacks, so **the UI keeps looking warm-and-correct even though the wallpaper colors are completely ignored.** This is why the breakage is subtle.

---

## 4. The Fix Plan — Incremental Improvements

### 4.1 Phase 1 — Unify the wallpaper path (foundation)

**Decision — make *one* script authoritative for the quickshell UI schema.** The quickshell `wallcolors.py` (186-line) is the one Dyn.qml can read, so it must be the single source of truth for `colors.json`. The hypr copy is the legacy generator for the hyprland decorations (`hypr-colors.lua`) and should delegate to the quickshell copy rather than duplicate it.

**Proposed unified pipeline:**
```
[Wallpaper change]            (picker tile OR skwd OR keybind)
  ├─→ wallpaper.sh set <path>        # sets wallpaper via awww, writes state file
  │     └─→ single wallcolors.py <path>   # quickshell copy — ONE schema, ONE writer
  │           ├─ colors.json      → Dyn.qml FileView auto-reloads (watchChanges)
  │           ├─ terminal.json    → apply-terminal-colors.py → kitty/ghostty
  │           └─ hypr-colors.lua  → hyprctl reload
  └─→ after-wall.sh <path>           # terminal fan-out + qs ipc colors reload
        ├─ (idempotent) re-run wallcolors.py if wallpaper.sh didn't
        └─ qs ipc call colors reload   → shell.qml → Dyn re-reads colors.json
```

**Specific edits (Phase 1):**

| File | Change | Why |
|------|--------|-----|
| `modules/pill/Appearance.qml` (L40, 48) | Replace `"$HOME/.config/hypr/scripts/wallcolors.py"` with `"$QCONFIG/quickshell/scripts/wallcolors.py"` (and call `after-wall.sh`) | Stops Path B from writing the wrong schema; routes through the single writer so Dyn sees the right keys |
| `scripts/after-wall.sh` (L19) | Add `--mood`/`--mode` passthrough from `flags.json` so it can serve the static/mode toggle too | Lets after-wall.sh be the single color entry point for all triggers |
| `modules/pill/Singletons/Walls.qml` (L91-99 comment) | `wallpaper.sh`'s `manual` branch is dead; either implement `manual` palette mode in `Flags.qml`/UI or remove the dead branch | Closes the `manual` vs `static`/`dynamic` mismatch |
| `services/Matugen.qml` | Delete `applyWallpaper()` + `colorsPath`/config; keep `reload()` but make it actually **repaint** (`Qt.callLater` not needed — FileView auto-watches) OR replace with a `Dyn.reload()` no-op; remove from `qmldir` registration | Eliminates the colors.qml dead path and the phantom IPC |
| `shell.qml` (L53-60, L458) | `colors reload` IPC → call `Dyn` reload instead of `root.matugen.reload()`; OR leave as a no-op since FileView auto-watches | Makes the IPC honest (or removes a misleading no-op) |
| `config/Appearance.qml` (L44) | `colSuccess: QsSingletons.Theme.verm` instead of `"#a6e3a1"` (see Phase 2) | Removes last config hex |

**Out of scope for Phase 1:** merging the two wallcolors.py files, migrating the hypr copy's terminal palette. Constrain to "make the quickshell copy the only writer of `colors.json`."

### 4.2 Phase 2 — Extend token coverage to all surfaces (priority order)

> All pill overlay surfaces are **already** on `Theme.*` tokens (0 hex) — they will auto-fix once Phase 1 makes `Dyn.*` return real colors. Phase 2 targets the surfaces that bypass tokens entirely.

1. **`modules/bar/components/Battery.qml`** — highest visibility; 6 hex literals.
   - L57 `#ef4444`, L58 `#f59e0b` → `Theme.vermLit` / `Theme.verm` (low/battery states)
   - L62 `#2dd4bf`, L64 `#5eead4` → derive from `Theme` (charging liquid). Add `Dyn.primary`/a dedicated token, or map to `Theme.flameGlow`.
   - L186 `#000000`/`#ffffff`, L304 `#ffffff` → `Theme.cream`/`Theme.bright` (text/plug).
   - L234 `Qt.rgba(0.1,0.12,1)` → drop-in favor of a surface token.
2. **`modules/osd/VolumeOSD.qml` + `BrightnessOSD.qml`** — fully hardcoded `Qt.rgba`.
   - Replace all `Qt.rgba(…)` with `Theme.*` tokens: body `Qt.alpha(Theme.tileBg, 0.4)`, border `Theme.hair`, icon/mute `Theme.cream`, accent fill `Theme.onGlow`, text `Theme.cream`/`Theme.dim`. Delete `required property var matugen`.
3. **`modules/pill/Osd.qml`** — 3 gradient hex (`Osd.qml:416-418`). Replace with a tokenized `Material3Anim` color-stop set or `Theme` opacities.
4. **`modules/pill/Pill.qml`** — L531 pearl highlight → `Theme.flameGlow`-derived; L570 white highlight → mood-aware.
5. **`config/Appearance.qml`** — L44 `colSuccess: "#a6e3a1"` → `Theme.verm` (or a new `Theme.success`).
6. **Bar popup fallbacks** — `BrightnessPopupWindow.qml:20`/`VolumePopupWindow.qml:25` `m3Primary: … ?? "#f9e2af"`/`"#a6e3a1"` are already `??` fallbacks over nothing; point them at `Theme.onGlow`/`Theme.verm`.
7. **`config/BarConfig.qml`** — 7 hex defaults are *configuration defaults* (intentional, user-tunable); leave as-is but document that surface colors should still resolve through `Theme.*` at render time.

### 4.3 Phase 3 — Improve the token system

| Proposed token | Type | Purpose | Surfaces that need it |
|----------------|------|---------|----------------------|
| `Theme.success` | color | success state (charging, updates ready) | `Battery.qml`, `Updates.qml` |
| `Theme.error` | color | error/destructive (low battery, power) | `Battery.qml`, `Power.qml` |
| `Dyn.onSurface` | color | primary text on surface | (replaces `cream`/`bright` ambiguity) |
| `Dyn.surfaceContainerLowest` | color | lowest surface tier | popup backgrounds |
| `Dyn.scrim` | color | modal backdrop overlay | `PillOverlay.qml` backdrop (uses `Qt.rgba(0,0,0,0.55)` in Theme.shadow today) |

**Design decision:** keep `Theme` (static fallbacks) and `Dyn` (live) **separate** — that is the user's stated philosophy and it works. Do **not** merge them. Instead, add the two missing semantic tokens (`success`, `error`) to `Theme.qml` (with `dyn ? … : "#hex"`), and teach `wallcolors.py` to emit them so `Dyn.qml` gains `success`/`error` keys too.

### 4.4 Phase 4 — Dark/light & opacity polish

- `Flags.systemMood` ("dark"/"light") is currently a *user label*; `wallcolors.py` derives light/dark from wallpaper `mean_l` when dynamic. Make the toggle authoritative: when the user forces "light" in the Appearance surface, write `systemMood` and re-run `after-wall.sh --mood light` so surface tones flip (not just terminal color-scheme).
- `pillOpacity` / `pillBlur` are pill-only. Add a matching `surfaceOpacity` + `surfaceBlur` flag pair if popup/OSD surfaces are meant to match the pill's glass look (currently OSDs hardcode their own alpha).
- `Theme.shadow` is hardcoded `Qt.rgba(0,0,0,0.55)` (L36); make it `Qt.rgba(0,0,0, Flags.systemMood==="light"?0.45:0.55)` and expose `Theme.shadowOpacity` (already a property at L67 — wire it in).

---

## 5. Code-Quality Issues in the Color System

| File | Line | Issue | Severity | Fix |
|------|------|-------|----------|-----|
| `modules/pill/Appearance.qml` | 40, 48 | Calls `~/.config/hypr/scripts/wallcolors.py` (wrong copy/schema) instead of the quickshell copy | **CRITICAL** | Route through `after-wall.sh` / quickshell `wallcolors.py` |
| `services/Matugen.qml` | 11, 19-28 | `colorsPath` → `state/colors.qml` (wrong ext/dir); `applyWallpaper()` dead; `dist/matugen/config.toml` missing | High | Delete `applyWallpaper`/`colorsPath` or re-point; remove from qmldir |
| `services/Matugen.qml` | 14-17 | `reload()` is a no-op (only console.log) | Medium | Make it trigger a real reload or remove the call site |
| `shell.qml` | 53-60, 455-461 | `colors` IPC → `matugenReload` (unregistered target) → `root.matugen.reload()` no-op | Medium | Point IPC at `Dyn`/flags reload; drop phantom target |
| `modules/pill/Singletons/Walls.qml` | 32-33 | `setScript`/`thumbScript` point at `$RICE_HOME/hypr/scripts/…` (outside repo) | Low | Acceptable (external tool), but documents the split responsibility |
| `modules/osd/{Volume,Brightness}OSD.qml` | 14, 78-128 | `required property var matugen` declared & forwarded but **never read**; hardcoded `Qt.rgba` fallbacks | High | Drop property; bind to `Theme.*` |
| `modules/osd/VolumeOSD.qml` | 113, 122, 128, 146 | Fixed azure/grey palette ignores wallpaper | High | Tokenize via `Theme.*` |
| `modules/pill/Osd.qml` | 416-418 | 3 hardcoded hex gradient colors | Medium | Tokenize / use `Theme` opacities |
| `modules/pill/Pill.qml` | 531, 570 | 2 hardcoded literals in otherwise-clean surface | Low | Route through `Theme.*` |
| `modules/bar/components/Battery.qml` | 57,58,62,64,186,304,234 | 6 hex + 1 `Qt.rgba` hardcoded (critical/red/low/liquid/plug) | High | Tokenize |
| `modules/bar/components/BluetoothPopupWindow.qml` | 209 | `#ffffff` hardcoded | Low | `Theme.bright` |
| `modules/bar/components/NetworkPopupWindow.qml` | 209, 603 | `#ffffff` hardcoded (x2) | Low | `Theme.bright` |
| `config/Appearance.qml` | 44 | `colSuccess: "#a6e3a1"` | Low | `Theme.verm` / add `Theme.success` |
| `wallpaper.sh` (hypr) | 91-99 | Checks `paletteMode == "manual"` but Flags only emits `static`/`dynamic` → dead branch | Medium | Align values or remove branch |
| `scripts/toggle-colormode.sh` | 6, 23-35 | Reads `~/.cache/wal/colors.json` (pywal schema, 3rd source) for wallpaper path | Medium | Read `Walls.current` or the quickshell state file instead |
| `singletons/Dyn.qml` | 37 | `FileView` reads correctly but has **no error fallback** if `colors.json` is missing/malformed beyond the JsonAdapter defaults — relies on defaults silently | Low | Add `printErrors: true` during dev, or a load-status flag |
| `scripts/after-wall.sh` | 19 | `wallcolors.py` run once; if `wallpaper.sh` ALSO ran it (hypr copy) there's a transient double-write — terminal.json race | Medium | Make `after-wall.sh` the *only* writer, or add a guard/temp file |
| `wallcolors.py` (both copies) | 31 | Both write `terminal.json` with **different** ANSI mappings → race | Medium | Consolidate terminal mapping into the single script |
| Docs (`doc/Dyn.md`, `doc/Theme.md`, `doc/Matugen.md`) | — | Auto-generated and **inaccurate**: `Dyn.md` says it handles "time and date"; `Theme.md` says it "depends on Matugen service"; `Matugen.md` claims `reload()` regenerates the scheme | Low | Update docs to reflect the FileView/colors.json pipeline |

---

## 6. Verified Discovery Commands

```bash
cd ~/.config/quickshell

# === The two conflicting writers ===
ls -la ~/.config/hypr/scripts/wallcolors.py ~/.config/quickshell/scripts/wallcolors.py
wc -l  ~/.config/hypr/scripts/wallcolors.py ~/.config/quickshell/scripts/wallcolors.py
grep -n "CACHE =\|colors.json\|terminal.json\|write_text" ~/.config/hypr/scripts/wallcolors.py ~/.config/quickshell/scripts/wallcolors.py

# === Which script the UI actually calls ===
grep -rn "wallcolors.py\|wallpaper.sh\|after-wall\|skwd\|matugen" --include="*.qml" --include="*.sh" \
  modules/pill/Singletons/Walls.qml modules/pill/Appearance.qml shell.qml scripts/after-wall.sh

# === Dyn.qml reads colors.json, NOT colors.qml ===
grep -n "colors" singletons/Dyn.qml        # line 37 → ~/.cache/yemi-shell/colors.json
grep -n "colors" services/Matugen.qml      # line 11 → state/colors.qml  (DEAD)

# === Token gate ===
grep -n "paletteMode\|bool dyn" singletons/Flags.qml singletons/Theme.qml

# === Per-surface color hygiene ===
for f in $(find modules -name "*.qml" | sort); do
  printf "%-55s hex:%s Theme:%s Dyn:%s Flags:%s\n" "$f" \
    "$(grep -cE '#[0-9a-fA-F]{3,8}' "$f")" \
    "$(grep -c 'Theme\.' "$f")" \
    "$(grep -c 'Dyn\.' "$f")" \
    "$(grep -c 'Flags\.' "$f")"
done
```

---

## 7. Deliverables produced

1. **This document** — `YEMI_COLOR_WALLPAPER_AUDIT.md` (filled audit).
2. **`COLOR_FIX_PLAN.md`** — the incremental Phase 1-4 plan with file-by-file diffs.
3. **`UNIFIED_PIPELINE.md`** — the proposed single-source-of-truth architecture.
