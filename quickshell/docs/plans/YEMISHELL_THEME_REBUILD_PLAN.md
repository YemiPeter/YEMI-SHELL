# Yemi-Shell Theme System Rebuild Plan

Date: 2026-08-08
Status: Approved concept, implementation not started
Config: /home/yemi/.config/quickshell
Donor source: /home/yemi/iNiR
Goal: Replace the current flat Theme/Dyn pipeline with a robust iNiR-inspired architecture while keeping Yemi-shell simple.

---

## 1. Locked Decisions

| Decision | Choice |
|---|---|
| Color engine | Use iNiR-style Matugen / Material Theme Builder method |
| Old engine | Retire wallcolors.py as the main engine, keep it temporarily for rollback |
| Dark/Light mood | Generate both dark and light schemes from the wallpaper |
| Static mode | Static becomes a real mode, not just fallback |
| Static surface | Static uses solid dark/light surfaces from the active mood |
| Static accent | Static can still extract wallpaper accent |
| Static grayscale toggle | Add toggle to force hardcoded grayscale accents |
| Naming | Internal engine uses iNiR/Material naming |
| Consumer compatibility | Keep Theme.* public API through an adapter |
| Migration style | No Day 1 rewrite of all consumers |
| Performance rule | No constant polling, no heavy QML color daemons |
| External apps | Terminal and Hyprland remain part of the theme pipeline |

---

## 2. Core Concept

The new system separates two ideas that are currently tangled:

1. Surface Source
   - Dynamic: wallpaper-derived surfaces
   - Static: solid mood-derived surfaces

2. System Mood
   - Dark
   - Light

This gives four possible states:

| Source | Mood | Pill surface | Accent/text behavior |
|---|---|---|---|
| Dynamic | Dark | Wallpaper-derived dark surface | Wallpaper-derived dark-readable colors |
| Dynamic | Light | Wallpaper-derived light surface | Wallpaper-derived light-readable colors |
| Static | Dark | Solid dark mood surface | Wallpaper accent or grayscale accent |
| Static | Light | Solid light mood surface | Wallpaper accent or grayscale accent |

Mood changes must affect:

- Quickshell surfaces
- Text contrast
- Accent readability
- Terminal colors
- Hyprland border colors

---

## 3. Target Architecture

```text
Consumers
  modules/pill/*
  modules/bar/*
  modules/osd/*
  modules/music/*
        |
        v
Theme.qml
  Old public API: Theme.cream, Theme.verm, Theme.tileBg, etc.
  Maps old names to the new adapter.
        |
        v
Appearance.qml
  Adapter / gearbox.
  Exposes:
    - m3colors
    - colors
    - yemi compatibility tokens
    - static mood surfaces
    - derived readable text colors
        |
        v
ThemeService.qml
  Orchestrator.
  Applies active mood/source scheme to Appearance.
        |
        v
Dyn.qml
  File watcher for colors.json v2.
        |
        v
after-wall.sh
  Single writer.
  Runs Matugen and writes generated theme files.
        |
        v
Matugen
  Generates dark and light Material schemes from wallpaper.
```

---

## 4. Public API Strategy

### Keep this public API stable for now

Components continue reading:

```qml
Theme.tileBg
Theme.cardTop
Theme.cardBot
Theme.cream
Theme.bright
Theme.dim
Theme.subtle
Theme.faint
Theme.iconDim
Theme.verm
Theme.vermLit
Theme.vermDeep
Theme.vermDim
Theme.vermDimDeep
Theme.vermBurn
Theme.onGlow
Theme.border
Theme.hair
Theme.hairSoft
Theme.sheen
Theme.threadBg
Theme.frameBg
Theme.frameBorder
Theme.creamMenu
Theme.flameInk
Theme.flameEmber
Theme.flameBurn
Theme.flameTip
```

### Internal engine uses iNiR-style naming

Appearance will internally understand tokens like:

```qml
Appearance.m3colors.m3primary
Appearance.m3colors.m3surface
Appearance.m3colors.m3onSurface
Appearance.m3colors.m3surfaceContainer
Appearance.m3colors.m3outlineVariant
Appearance.colors.colPrimary
Appearance.colors.colLayer0
```

This gives us the robust iNiR engine without immediately breaking every Yemi-shell component.

---

## 5. Mood System

Dark and light moods become their own theme objects.

Proposed files:

```text
config/theme/moods/DarkMood.qml
config/theme/moods/LightMood.qml
```

Each mood file defines:

- Static surface palette
- Static text palette
- Shadow strength
- Highlight alpha
- Border fallbacks
- Terminal background policy
- Readability targets

Example responsibilities:

| Mood | Static surface | Static text | Shadow |
|---|---|---|---|
| Dark | Black / near-black | Near-white | Stronger |
| Light | White / near-white | Near-black | Softer |

Dynamic mode still uses Matugen dark/light schemes, but mood files provide:

- Static surfaces
- Fallback palettes
- Contrast policy
- System-wide mood behavior

---

## 6. Color Generation Pipeline

Current pipeline:

```text
after-wall.sh
  -> wallcolors.py
  -> colors.json
  -> terminal.json
  -> hypr-colors.lua
```

New pipeline:

```text
after-wall.sh
  -> Matugen
  -> colors.json v2
  -> terminal.json
  -> hypr-colors.lua
```

### Single writer rule

Only after-wall.sh writes generated theme files.

No QML file should directly write colors.json.
No random script should bypass after-wall.sh.

---

## 7. colors.json v2 Schema

The new colors.json must contain both dark and light schemes.

Proposed location:

```text
~/.cache/yemi-shell/colors.json
```

Proposed schema:

```json
{
  "version": 2,
  "generator": "matugen",
  "wallpaper": "/path/to/wallpaper",
  "seed": "#123456",
  "scheme_type": "content",
  "dark": {
    "primary": "#000000",
    "on_primary": "#000000",
    "primary_container": "#000000",
    "on_primary_container": "#000000",
    "secondary": "#000000",
    "secondary_container": "#000000",
    "tertiary": "#000000",
    "surface": "#000000",
    "surface_container_lowest": "#000000",
    "surface_container_low": "#000000",
    "surface_container": "#000000",
    "surface_container_high": "#000000",
    "surface_container_highest": "#000000",
    "on_surface": "#000000",
    "on_surface_variant": "#000000",
    "outline": "#000000",
    "outline_variant": "#000000",
    "inverse_surface": "#000000",
    "inverse_on_surface": "#000000",
    "error": "#000000",
    "on_error": "#000000",
    "error_container": "#000000",
    "on_error_container": "#000000"
  },
  "light": {
    "primary": "#000000",
    "on_primary": "#000000",
    "primary_container": "#000000",
    "on_primary_container": "#000000",
    "secondary": "#000000",
    "secondary_container": "#000000",
    "tertiary": "#000000",
    "surface": "#000000",
    "surface_container_lowest": "#000000",
    "surface_container_low": "#000000",
    "surface_container": "#000000",
    "surface_container_high": "#000000",
    "surface_container_highest": "#000000",
    "on_surface": "#000000",
    "on_surface_variant": "#000000",
    "outline": "#000000",
    "outline_variant": "#000000",
    "inverse_surface": "#000000",
    "inverse_on_surface": "#000000",
    "error": "#000000",
    "on_error": "#000000",
    "error_container": "#000000",
    "on_error_container": "#000000"
  }
}
```

The QML side selects the active scheme using:

```text
Flags.systemMood === "dark" ? colors.dark : colors.light
```

This allows mood switching without regenerating the wallpaper palette every time.

---

## 8. Dynamic Mode Behavior

Dynamic mode uses wallpaper-derived surfaces.

### Dark mood

Use:

```text
colors.dark.surface
colors.dark.surface_container_*
colors.dark.on_surface
colors.dark.primary
```

### Light mood

Use:

```text
colors.light.surface
colors.light.surface_container_*
colors.light.on_surface
colors.light.primary
```

### Readability rule

Dynamic mode must not blindly trust wallpaper colors.

Appearance will use ColorUtils to:

- Ensure text is readable on surfaces
- Adjust accent brightness if needed
- Derive dim/subtle/faint text from onSurface/onSurfaceVariant
- Prevent dark accents from disappearing on dark surfaces
- Prevent light accents from disappearing on light surfaces

---

## 9. Static Mode Behavior

Static mode no longer means fallback. It becomes a deliberate clean mode.

### Static surfaces

Static surfaces come from mood files.

Dark static:

```text
tileBg: pure black or near-black
cardTop: dark gray
cardBot: darker gray
ghost: elevated gray
border: subtle gray
```

Light static:

```text
tileBg: pure white or near-white
cardTop: light gray
cardBot: slightly darker light gray
ghost: soft gray
border: subtle gray
```

### Static text

Static text uses mood-based neutral text colors:

Dark mood:

```text
cream: near-white
bright: white
dim: medium light gray
subtle: soft light gray
faint: darker gray
```

Light mood:

```text
cream: near-black
bright: black
dim: medium dark gray
subtle: soft dark gray
faint: lighter dark gray
```

### Static accent

Default:

```text
Static mode extracts wallpaper accent using Matugen.
```

With grayscale toggle enabled:

```text
Static mode ignores wallpaper accent and uses hardcoded gray accents.
```

Proposed flag:

```text
Flags.staticGrayscaleAccents
```

Default value:

```text
false
```

---

## 10. New Flags

Add to Flags.qml:

| Flag | Type | Default | Purpose |
|---|---|---|---|
| paletteMode | string | dynamic | dynamic/static |
| systemMood | string | dark | dark/light |
| staticGrayscaleAccents | bool | false | Force grayscale accents in static mode |
| pillOpacity | real | current | Keep existing |
| pillBlur | bool | current | Keep existing |
| reduceMotion | bool | current | Keep existing |
| uiScale | real | current | Keep existing |

---

## 11. File Change Map

| File | Action | Purpose |
|---|---|---|
| scripts/after-wall.sh | Modify | Become Matugen single writer |
| scripts/wallcolors.py | Move to legacy | Rollback only |
| scripts/apply-terminal-colors.py | Modify | Read new colors.json v2 and active mood |
| singletons/Dyn.qml | Modify | Read colors.json v2 with dark/light schemes |
| singletons/Theme.qml | Modify | Map old public tokens to Appearance adapter |
| singletons/Flags.qml | Modify | Add staticGrayscaleAccents |
| config/Appearance.qml | Rebuild | Adapter, M3 facade, Yemi compatibility layer |
| config/Config.qml | Upgrade later | Use iNiR JsonAdapter pattern if needed |
| config/theme/moods/DarkMood.qml | Create | Dark static/mood definitions |
| config/theme/moods/LightMood.qml | Create | Light static/mood definitions |
| services/ThemeService.qml | Create/modify from iNiR | Orchestrator |
| services/MaterialThemeLoader.qml | Modify from iNiR | Apply colors.json to Appearance |
| services/Matugen.qml | Keep temporarily | IPC compatibility shim |
| config/functions/ColorUtils.qml | Copy from iNiR | Contrast, mix, readable text, hex conversion |

---

## 12. iNiR Donor Map

| iNiR source | Yemi-shell target | What we take |
|---|---|---|
| modules/common/functions/ColorUtils.qml | config/functions/ColorUtils.qml | Color math, contrast, readable text |
| services/MaterialThemeLoader.qml | services/MaterialThemeLoader.qml | JSON loading and Appearance mutation pattern |
| services/ThemeService.qml | services/ThemeService.qml | Orchestration, debounce, apply logic |
| modules/common/Appearance.qml | config/Appearance.qml | Facade pattern, m3colors/colors structure |
| scripts/colors/switchwall.sh | scripts/after-wall.sh or helper script | Matugen invocation pattern |
| scripts/colors/applycolor.sh | scripts/apply-terminal-colors.py / hypr apply | External app theming discipline |

### Not copying yet

| iNiR part | Reason |
|---|---|
| ThemePresets.qml | Too large, not needed for first robust rebuild |
| StylePresets.qml | Typography presets not priority |
| Angel style | Not needed |
| Aurora style | Not needed |
| Inir style | Not needed |
| GameMode | Not needed yet |
| Desaturation | Not needed yet |
| Theme scheduling | Not needed yet |
| 45+ preset library | Not needed yet |

---

## 13. Theme Facade Mapping

Theme.qml remains the public facade.

Old token names stay stable.

Example mapping concept:

| Old token | New internal source |
|---|---|
| Theme.onGlow | Appearance.colors.colPrimary or readable adjusted primary |
| Theme.verm | Darkened primary |
| Theme.vermLit | Lighter primary |
| Theme.vermDeep | Primary container |
| Theme.vermDim | Dimmed primary |
| Theme.vermDimDeep | Heavily dimmed primary |
| Theme.vermBurn | Error/destructive token |
| Theme.cream | Readable onSurface/main text |
| Theme.bright | High-emphasis text |
| Theme.dim | Dimmed text |
| Theme.subtle | onSurfaceVariant-based text |
| Theme.faint | Lower-emphasis text |
| Theme.iconDim | Dimmed icon color |
| Theme.cardTop | surfaceContainerHigh or static mood surface |
| Theme.cardBot | surfaceContainerLow or static mood surface |
| Theme.tileBg | surface or static mood surface |
| Theme.ghost | surfaceContainerHighest or static ghost |
| Theme.border | outlineVariant or static border |
| Theme.tickRest | Secondary/tertiary-derived indicator |
| Theme.flameInk | Hex string from primary |
| Theme.flameEmber | Hex string from primaryContainer |
| Theme.flameBurn | Hex string from primaryContainer variant |
| Theme.flameTip | Hex string from onPrimaryContainer |

---

## 14. Flame Canvas Rule

The flame tokens must remain strings.

Do not convert these to QML color types:

```qml
flameInk
flameEmber
flameBurn
flameTip
```

They must output:

```text
#rrggbb
```

They must not output:

```text
#aarrggbb
```

ColorUtils must include or use a safe hex converter for this.

---

## 15. External App Theming

### Terminal

Keep terminal theming.

Generated file:

```text
~/.cache/yemi-shell/terminal.json
```

apply-terminal-colors.py must be updated to:

- Read colors.json v2
- Use active mood
- Write kitty theme.conf
- Write ghostty theme
- Preserve current blur/opacity background policy
- Reload terminals

### Hyprland

Keep Hyprland border theming.

Generated file:

```text
~/.cache/yemi-shell/hypr-colors.lua
```

Hyprland colors must follow active mood:

- Dark mood: dark-friendly active/inactive borders
- Light mood: light-friendly active/inactive borders

---

## 16. after-wall.sh Behavior

### Inputs

```text
after-wall.sh <mood> [wallpaper-path]
```

### Logic

1. Read flags.json
2. Determine paletteMode
3. Determine staticGrayscaleAccents
4. Decide whether Matugen is needed
5. Generate or reuse colors.json v2
6. Write terminal.json
7. Write hypr-colors.lua
8. Apply terminal colors
9. Apply Hyprland colors
10. Call IPC reload

### Fast path

If only mood changed and colors.json v2 already exists for the current wallpaper:

```text
Do not rerun Matugen.
Reapply terminal and Hyprland colors from existing colors.json.
```

### Static grayscale fast path

If paletteMode is static and staticGrayscaleAccents is true:

```text
Do not extract wallpaper accent.
Use neutral grayscale scheme.
```

---

## 17. IPC Strategy

Keep one main IPC target:

```text
qs ipc call colors reload
```

Deprecate ambiguous targets later:

```text
matugenReload
```

The reload handler must trigger:

```text
Dyn reload -> ThemeService apply -> Appearance update -> Theme update
```

---

## 18. Performance Rules

| Rule | Reason |
|---|---|
| Matugen runs only on wallpaper change or forced regeneration | Avoid CPU spikes |
| Mood switching inside QML should be instant | Better UX |
| No file polling loops | Avoid battery/RAM waste |
| Use debounce from iNiR pattern | Prevent duplicate Matugen runs |
| ColorUtils calculations only on theme apply | Tiny cost |
| Keep adapter lightweight | No extra daemon |
| No giant preset loading at startup | Avoid memory bloat |

---

## 19. Migration Phases

### Phase 0: Safety and Ground Truth

Tasks:

- Create git branch
- Backup current scripts
- Read all files before editing
- Confirm current wallpaper path source
- Confirm current flags.json schema
- Confirm IPC reload behavior
- Move wallcolors.py to legacy location but keep it callable

Exit criteria:

- Current theme still works
- Rollback path exists
- No consumer files changed yet

---

### Phase 1: Install and Verify Matugen

Tasks:

- Check if Matugen is installed
- Install Matugen if missing
- Test Matugen against a wallpaper
- Inspect output JSON structure
- Confirm dark/light scheme generation
- Decide final Matugen CLI arguments

Exit criteria:

- Matugen can generate dark and light schemes from a wallpaper
- Output JSON is stable enough to adapt

---

### Phase 2: New colors.json v2 Generator

Tasks:

- Modify after-wall.sh
- Add Matugen generation path
- Create colors.json v2 with dark and light blocks
- Keep legacy fallback path
- Preserve terminal.json and hypr-colors.lua generation

Exit criteria:

- colors.json v2 exists
- It contains both dark and light schemes
- It is written only by after-wall.sh
- Old pipeline can still be restored if needed

---

### Phase 3: QML Loader Update

Tasks:

- Copy ColorUtils from iNiR
- Update Dyn.qml to read colors.json v2
- Expose active dark/light scheme
- Add safe fallback if JSON is missing or corrupt
- Keep old Dyn property names temporarily if useful

Exit criteria:

- QML can read both dark and light schemes
- No UI crash on missing/corrupt JSON
- IPC reload works

---

### Phase 4: Appearance Adapter

Tasks:

- Rebuild Appearance.qml as adapter
- Add m3colors structure
- Add colors structure
- Add Yemi compatibility tokens
- Add readable text derivation
- Add static mood surface selection
- Add flame string hex conversion

Exit criteria:

- Appearance can translate Matugen colors into Yemi tokens
- Static and dynamic surfaces are separated
- Dark/light mood changes update Appearance
- Old Theme tokens can be fed by Appearance

---

### Phase 5: Theme Facade Rewrite

Tasks:

- Rewrite Theme.qml internals
- Keep all old public token names
- Point tokens to Appearance adapter
- Implement four-state matrix
- Preserve flame string behavior
- Preserve derived alpha tokens

Exit criteria:

- Existing components still work without mass editing
- Dynamic dark/light works
- Static dark/light works
- Static grayscale toggle works
- No broken flame canvas gradients

---

### Phase 6: External Apps Update

Tasks:

- Update apply-terminal-colors.py
- Update Hyprland color generation
- Make terminal colors follow active mood
- Make Hyprland borders follow active mood
- Test kitty reload
- Test ghostty reload

Exit criteria:

- Terminal follows mood
- Hyprland follows mood
- No terminal reload crash
- Kitty/ghostty files are valid

---

### Phase 7: Cleanup

Tasks:

- Remove dead Matugen shim if safe
- Remove legacy colormode file usage
- Remove stale toggle-colormode.sh if unused
- Document final architecture
- Update THEME_SYSTEM_MAP_CURRENT.md
- Decide whether consumers should migrate to Appearance names later

Exit criteria:

- No stale docs describing wrong pipeline
- One clear pipeline
- One clear writer
- One clear facade

---

## 20. Acceptance Tests

### Pipeline tests

```bash
jq '.version' ~/.cache/yemi-shell/colors.json
jq '.dark.primary' ~/.cache/yemi-shell/colors.json
jq '.light.primary' ~/.cache/yemi-shell/colors.json
```

Expected:

```text
version = 2
dark.primary exists
light.primary exists
```

### Mood tests

- Toggle dark mood: pill changes surface
- Toggle light mood: pill changes surface
- Dynamic mode changes with mood
- Static mode changes with mood
- Terminal updates after mood change
- Hyprland borders update after mood change

### Static tests

- Static dark uses solid dark surface
- Static light uses solid light surface
- Static with wallpaper accent uses extracted accent
- Static with grayscale toggle uses gray accent
- Text remains readable in both moods

### Dynamic tests

- Wallpaper change regenerates colors.json
- Dark wallpaper + dark mood remains readable
- Light wallpaper + dark mood remains readable
- Dark wallpaper + light mood remains readable
- Light wallpaper + light mood remains readable

### Performance tests

- Mood toggle does not rerun Matugen if colors.json already has both schemes
- Wallpaper change runs Matugen once
- No repeated IPC spam
- No visible QML binding storm

---

## 21. Known Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Matugen output schema differs from plan | Loader breaks | Verify output before wiring QML |
| Yemi custom text tokens missing | UI looks wrong | Derive cream/bright/subtle from M3 onSurface/onSurfaceVariant |
| Static accent unreadable | Bad contrast | Use ColorUtils.ensureReadable |
| Flame canvas receives #aarrggbb | Gradient breaks | Force #rrggbb string conversion |
| Too many QML binding updates | Lag | Debounce loader and theme apply |
| Terminal light mode looks bad | Ugly terminal | Keep background policy configurable |
| Old scripts bypass new pipeline | Inconsistent colors | Keep after-wall.sh as only writer |
| iNiR code assumes missing files | Crash | Strip unused parts, adapt paths |

---

## 22. Definition of Done

The rebuild is successful when:

1. Theme.qml remains the only public API needed by current consumers.
2. Dynamic mode uses Matugen-generated dark/light wallpaper schemes.
3. Static mode uses solid mood surfaces.
4. Dark/light mood changes both source modes correctly.
5. Static mode can use wallpaper accent or forced grayscale accent.
6. Terminal colors follow the active mood.
7. Hyprland colors follow the active mood.
8. No component rewrite is required on Day 1.
9. Flame canvas colors remain valid strings.
10. The old wallcolors.py pipeline can be restored if needed.

---

## 23. Not In This Phase

These are intentionally excluded for now:

- 45+ theme presets
- Angel style
- Aurora style
- Inir style
- GameMode
- Desaturation
- Theme scheduling
- Custom theme editor UI
- Style presets
- Full consumer migration to iNiR names
- GTK theming
- Browser theming
- VS Code / Zed / Vesktop theming

---

## 24. Next Action

Wait for approval, then start with:

```text
Phase 0: Safety and Ground Truth
Phase 1: Install and Verify Matugen
```

No QML edits happen until the Matugen output format is verified.