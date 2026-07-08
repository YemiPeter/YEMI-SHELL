# System Theme Controller — Implementation Plan

## 🏗️ Architecture: Two Independent Switches

```
🎨 Color Source → Static | Dynamic   (where colors come from)
🌗 System Mood  → Dark  | Light      (how bright the result is)
```

These are **orthogonal** — like choosing a wallpaper AND separately choosing dark/light mode on a phone. Neither one turns the other off.

---

## ✅ Build Checklist — System Mood + Color Source

### 🧱 Phase 1: Data Layer (do this first — everything depends on it)

- [x] `singletons/Flags.qml` — narrow `paletteMode` to `"static" | "dynamic"` (drop `"manual"`)
- [x] `singletons/Flags.qml` — add new `systemMood: "dark" | "light"` property
- [x] Both properties persist via existing JsonAdapter (2-way bound)

### 🎨 Phase 2: UI Layer

- [x] `modules/pill/Appearance.qml` — remove old 3-way `SettingsSeg` (Static/Dynamic/Manual)
- [x] `modules/pill/Appearance.qml` — remove hue strip + debounce logic tied to Manual
- [x] `modules/pill/Appearance.qml` — add Row 1: `Static | Dynamic` segmented control
- [x] `modules/pill/Appearance.qml` — add Row 2: `Dark | Light` segmented control
- [x] Both rows call `applyMode()` on change

### 🐍 Phase 3: `scripts/wallcolors.py`

- [x] Add `--mode` and `--mood` CLI flags
- [x] `matugen(source_hex, mood="dark")` — mood now passed through, defaults to dark
- [x] `matugen(...)["base16"]` — uses `v[mood]["color"]` instead of hardcoded `v["dark"]["color"]`
- [x] Static path: `--mode static --mood <dark|light>` with explicit mood override
- [x] Dynamic path: `--mode dynamic --mood <dark|light> <wallpaper-path>`
- [ ] **Manual test required** — run from terminal:
```bash
python wallcolors.py --mode dynamic --mood light /path/to/wallpaper.png
python wallcolors.py --mode static --mood dark
```
- [ ] **Manual test required** — verify `colors.json` flips between dark/light base16 values

### 🖥️ Phase 4: `scripts/apply-system-theme.sh` (new file)

- [x] Created with GTK branch (`gsettings color-scheme` + `gtk-theme`)
- [x] Qt branch: `plasma-apply-colorscheme` with `kvantummanager` fallback
- [ ] **Manual test required** — confirm your Qt theme (stock Breeze/Adwaita or Kvantum?)
- [ ] **Manual test required** — run standalone:
```bash
~/.config/quickshell/scripts/apply-system-theme.sh dark
~/.config/quickshell/scripts/apply-system-theme.sh light
```

### 🔗 Phase 5: Wire It All Together

- [x] `applyMode()` fires `staticProc` or `dynamicProc` AND `systemThemeProc`
- [x] `systemThemeProc` calls `apply-system-theme.sh` with `Flags.systemMood`
- [ ] **Manual test required** — restart qs, test all 4 combos:
  - Static + Dark
  - Static + Light
  - Dynamic + Dark
  - Dynamic + Light
- [ ] **Manual test required** — check logs after each toggle, zero errors

---

## ⚠️ Risk Note

This plan couples **three independent systems** — the shell's glass colors, GTK's theme daemon, and KDE's color scheme tool — into one toggle. That's more moving parts than the original design.

**Recommended approach:** incremental — ship `Flags.qml` + `Appearance.qml` UI first, wire the scripts later. Small verified steps beat one big leap.
