# Pill Appearance Section — Niri Map

**Section:** Appearance (`modules/pill/Appearance.qml`)
**Sub-surface:** FontPicker (`modules/pill/FontPicker.qml`)
**Scripts:** `after-wall.sh`, `apply-system-theme.sh`
**Date:** 2026-08-29

---

## 1. Structure

```
Appearance.qml (SettingsSurface)
├── Processes
│   ├── colorProc        → runs after-wall.sh <mood> [wallpaper]
│   └── systemThemeProc  → runs apply-system-theme.sh <mood>  (HOST dark/light)
├── rows[] (9 settings rows)
│   ├── timeRow          → Flags.time12h (12h / 24h)
│   ├── secRow           → Flags.clockSeconds (toggle)
│   ├── paletteRow       → Flags.paletteMode ("static" / "dynamic") → applyMode()
│   ├── moodRow          → Flags.systemMood ("dark" / "light") → applyMode()
│   ├── themeRow         → Flags.themeStyle ("yemi" / "aurora")
│   ├── scaleRow         → Flags.uiScale (0.9 / 1.0 / 1.1 / 1.25)
│   ├── motionRow        → Flags.reduceMotion (toggle)
│   ├── overviewRow      → Flags.altSwitcherEnabled (toggle)
│   └── fontRow          → navigates to FontPicker surface
└── FontPicker (separate surface)
    ├── families[]       → Theme.fontFamilies, deduped, filtered
    ├── resetLabel       → writes "" to Flags.uiFont
    └── onPicked         → writes family to Flags.uiFont
```

## 2. Data flow

```
User toggles palette/mood → root.applyMode()
  → colorProc.exec(["sh", "-c", 'after-wall.sh "<mood>" "<wallPath>"'])
    → after-wall.sh reads flags.json (paletteMode), wallpaper state
      → Matugen generates colors → writes ~/.cache/yemi-shell/colors.json
        → fans out terminal.json + hypr-colors.lua
    → Niri: no special handling needed; after-wall.sh is compositor-agnostic
  → systemThemeProc.exec(["sh", "-c", 'apply-system-theme.sh "<mood>"'])
    → GNOME: gsettings color-scheme "prefer-<mood>" + gtk-theme (Adwaita/Breeze)
    → KDE: plasma-apply-colorscheme (BreezeDark/Light) / kvantummanager
    → Niri: same — desktop-env theming, not compositor IPC
```

> Note: `systemThemeProc` was originally orphaned (defined but never invoked, so
> the host theme never switched). It is now wired into `applyMode()` so the pill's
> System mood flips the entire desktop (GNOME + KDE), not just the shell palette.

## 3. Settings rows detail

| Row | Control | Flag | What it changes | Niri note |
|---|---|---|---|---|
| Time format | Seg (24H/12H) | `Flags.time12h` | Clock display | ✅ safe |
| Clock seconds | Toggle | `Flags.clockSeconds` | Clock display | ✅ safe |
| Palette | Seg (static/dynamic) | `Flags.paletteMode` | Color source | ✅ safe (triggers after-wall.sh) |
| System mood | Seg (dark/light) | `Flags.systemMood` | Color source + **host theme** | ✅ safe (applyMode → after-wall.sh + apply-system-theme.sh) |
| Theme style | Seg (yemi/aurora) | `Flags.themeStyle` | Theme variant | ✅ safe |
| UI scale | Seg (90/100/110/125%) | `Flags.uiScale` | QML scaling | ✅ safe |
| Reduce motion | Toggle | `Flags.reduceMotion` | Animation speed | ✅ safe |
| Overview | Toggle | `Flags.altSwitcherEnabled` | Alt+Tab behavior | ✅ safe |
| Font | Nav → FontPicker | `Flags.uiFont` | Font family | ✅ safe (Theme.font reads Flags.uiFont) |

## 4. Script audit

| Script | Role | Hyprland-specific? | Niri-safe? |
|---|---|---|---|
| `after-wall.sh` | Single writer of `colors.json`. Reads `flags.json` (paletteMode), wallpaper state. Uses Matugen. | No | ✅ |
| `apply-system-theme.sh` | Sets GTK theme + GNOME color-scheme via gsettings. Falls back to KDE (plasma-apply-colorscheme / kvantummanager). | No | ✅ (desktop env, not compositor) |

## 5. Niri findings

**✅ No Niri gaps found.** Appearance is entirely compositor-agnostic.

- No `hyprctl` calls
- No `Hyprland.*` API usage
- No `decoration.lua` or Hyprland config editing
- `after-wall.sh` reads/writes only state files (`flags.json`, wallpaper path, colors.json)
- `apply-system-theme.sh` uses gsettings/KDE tools, not compositor IPC
- `FontPicker` reads `Theme.fontFamilies` (Qt font database) — compositor-agnostic

**LOW — stale comment fixed:**
- `Appearance.qml` doc comment: *"rebuilds the rice colour set through after-wall.sh and reloads Hyprland and the terminal."*
- Replaced with accurate description: mood also applies the host dark/light theme via `apply-system-theme.sh`.

## 6. Verdict

Appearance is fully Niri-compatible. The System mood now switches the **whole desktop** (GNOME `color-scheme`/gtk-theme via gsettings, KDE via plasma/kvantum) through `systemThemeProc`, wired into `applyMode()`. `apply-system-theme.sh` is compositor-agnostic, so it works on Niri and Hyprland alike. No live Hyprland/Niri gaps remain.
