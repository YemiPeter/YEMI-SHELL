# Yemi-Shell Theme Rebuild Checklist

Date: 2026-08-08
Config: /home/yemi/.config/quickshell
Donor source: /home/yemi/iNiR
Status: Planning checklist, implementation not started

---

## Ground Rules

- Do not move to the next section until the current section passes.
- Read the full file before editing it.
- For QML edits, stop Quickshell first:

      pkill -9 quickshell

- `after-wall.sh` must remain the only writer for generated theme files.
- Do not edit consumer components yet.
- Do not rewrite all components on Day 1.
- Keep `Theme.*` public API stable until the facade is stable.
- Commit after every completed section.
- Do not touch the HyDE master Hyprland file:

      ~/.local/share/hypr/hyprland.conf

---

## Section Map

| Section | Name | Purpose |
|---|---|---|
| 0 | Safety and Ground Truth | Protect current working theme |
| 1 | Matugen Install and Verify | Confirm the new engine works |
| 2 | Matugen Output Contract | Map Matugen output to Yemi schema |
| 3 | colors.json v2 Generator | Generate dark/light theme JSON |
| 4 | External Output Generator | Terminal and Hyprland colors |
| 5 | Import ColorUtils | Bring iNiR color math into Yemi-shell |
| 6 | Dyn v2 Loader | Read new colors.json in QML |
| 7 | Mood Files | Dark/light static mood definitions |
| 8 | Appearance Adapter | Translate M3 colors to Yemi tokens |
| 9 | Theme Facade Rewrite | Keep old public tokens working |
| 10 | Flags and Static Grayscale Toggle | Add new mode controls |
| 11 | Runtime Triggers and IPC | Wallpaper/mood/palette triggers |
| 12 | External Wallpaper Script Cleanup | Remove old direct wallcolors calls |
| 13 | Cleanup and Docs | Remove stale pieces, update map |

---

# Section 0 — Safety and Ground Truth

## Goal

Make sure the current theme still works and can be restored.

## Files involved

    scripts/after-wall.sh
    scripts/wallcolors.py
    scripts/apply-terminal-colors.py
    singletons/Dyn.qml
    singletons/Theme.qml
    singletons/Flags.qml
    config/Appearance.qml
    shell.qml
    modules/pill/Singletons/Walls.qml
    modules/pill/Appearance.qml

## Tasks

- [ ] Commit or stash current uncommitted changes.
- [ ] Create a new branch for the rebuild.
- [ ] Make a backup copy of the current scripts.
- [ ] Copy `scripts/wallcolors.py` to `scripts/legacy/wallcolors.py`.
- [ ] Do not delete or move the original `wallcolors.py` yet.
- [ ] Read `after-wall.sh` fully.
- [ ] Read `wallcolors.py` fully.
- [ ] Read `Dyn.qml`, `Theme.qml`, `Flags.qml`, and `Appearance.qml`.
- [ ] Confirm current `flags.json` location and schema.
- [ ] Confirm current wallpaper path source.
- [ ] Confirm current IPC reload works.

## Confirmation check

- [ ] Current git branch is correct:

      git branch --show-current

- [ ] There is a clean checkpoint commit:

      git log -1 --oneline

- [ ] Original engine still exists:

      test -f scripts/wallcolors.py && echo "original wallcolors.py intact"

- [ ] Legacy backup copy exists:

      test -f scripts/legacy/wallcolors.py && echo "legacy backup exists"

- [ ] Flags file is readable:

      jq '.paletteMode, .systemMood' ~/.local/state/quickshell/flags.json

- [ ] Current IPC reload works:

      qs ipc call colors reload

- [ ] The shell still looks normal after reload.

## Exit criteria

- Current theme works.
- Rollback path exists.
- No consumer files changed.
- No pipeline files broken.

---

# Section 1 — Matugen Install and Verify

## Goal

Confirm Matugen can generate usable dark/light schemes from a wallpaper.

## Tasks

- [ ] Check if Matugen is installed:

      command -v matugen

- [ ] If missing, install Matugen using your preferred Arch/CachyOS method.
- [ ] Confirm version:

      matugen --version

- [ ] Read Matugen help:

      matugen --help

- [ ] Save the useful CLI arguments into:

      docs/color-system/MATUGEN_CLI_NOTES.md

- [ ] Pick one test wallpaper.
- [ ] Generate a dark scheme sample.
- [ ] Generate a light scheme sample.
- [ ] Save both raw outputs into:

      docs/color-system/matugen-samples/

- [ ] Check whether Matugen can output both dark and light in one run.
- [ ] If not, confirm the two-command method works.
- [ ] Choose the default scheme type. Likely:

      content

## Confirmation check

- [ ] Matugen runs without error.
- [ ] Dark sample file exists.
- [ ] Light sample file exists.
- [ ] Sample output contains primary/surface/text colors.
- [ ] Colors are valid hex strings.

Example check:

    grep -E '#[0-9a-fA-F]{6}' docs/color-system/matugen-samples/*

## Exit criteria

- Matugen is installed.
- We know the exact command needed for dark/light generation.
- Raw output samples are saved.
- No QML changes yet.

---

# Section 2 — Matugen Output Contract

## Goal

Create a stable mapping between Matugen output and Yemi-shell `colors.json v2`.

## Why this matters

Matugen may not output the exact field names we want. We need a contract before writing the generator.

## Tasks

- [ ] Create:

      docs/color-system/MATUGEN_OUTPUT_CONTRACT.md

- [ ] List every Matugen field we need.
- [ ] Map each Matugen field to the Yemi `colors.json v2` key.
- [ ] Decide what happens if a field is missing.
- [ ] Decide where the seed color comes from.
- [ ] Decide where the wallpaper path is stored.
- [ ] Decide how dark/light schemes are selected.
- [ ] Confirm all required keys from the rebuild plan are covered.

## Required keys to map

    primary
    on_primary
    primary_container
    on_primary_container
    secondary
    secondary_container
    tertiary
    surface
    surface_container_lowest
    surface_container_low
    surface_container
    surface_container_high
    surface_container_highest
    on_surface
    on_surface_variant
    outline
    outline_variant
    inverse_surface
    inverse_on_surface
    error
    on_error
    error_container
    on_error_container

## Confirmation check

- [ ] Every required key has a Matugen source.
- [ ] Missing fields have fallback rules.
- [ ] Dark and light schemes are both mapped.
- [ ] The contract document is saved.

## Exit criteria

We can write the generator without guessing.

---

# Section 3 — colors.json v2 Generator

## Goal

Make `after-wall.sh` generate the new `colors.json` with both dark and light schemes.

## Files involved

    scripts/after-wall.sh
    scripts/legacy/wallcolors.py
    ~/.cache/yemi-shell/colors.json

## Tasks

- [ ] Read `after-wall.sh` fully.
- [ ] Add a new Matugen path.
- [ ] Keep the old `wallcolors.py` path available as fallback.
- [ ] Use the mapping from Section 2.
- [ ] Generate:

      ~/.cache/yemi-shell/colors.json

- [ ] Ensure the new file has:

      {
        "version": 2,
        "generator": "matugen",
        "wallpaper": "...",
        "seed": "...",
        "scheme_type": "...",
        "dark": {},
        "light": {}
      }

- [ ] Write the file atomically if possible.
- [ ] Do not let QML write this file.
- [ ] Do not let other scripts write this file.

## Confirmation check

- [ ] Run the new generator manually.
- [ ] Check version:

      jq '.version' ~/.cache/yemi-shell/colors.json

Expected:

    2

- [ ] Check dark primary:

      jq '.dark.primary' ~/.cache/yemi-shell/colors.json

- [ ] Check light primary:

      jq '.light.primary' ~/.cache/yemi-shell/colors.json

- [ ] Check wallpaper path:

      jq '.wallpaper' ~/.cache/yemi-shell/colors.json

- [ ] Check seed:

      jq '.seed' ~/.cache/yemi-shell/colors.json

- [ ] Old legacy path still works if forced.

## Exit criteria

- `colors.json v2` exists.
- It contains both dark and light schemes.
- The old pipeline can still be restored.
- No QML changes yet.

---

# Section 4 — External Output Generator

## Goal

Update terminal and Hyprland color generation to use the new theme source.

## Files involved

    scripts/after-wall.sh
    scripts/apply-terminal-colors.py
    ~/.cache/yemi-shell/terminal.json
    ~/.cache/yemi-shell/hypr-colors.lua
    ~/.config/kitty/theme.conf
    ~/.config/ghostty/themes/yemi-auto

## Tasks

- [ ] Decide how terminal colors follow mood.
- [ ] Update `terminal.json` generation to use active mood.
- [ ] Update `hypr-colors.lua` generation to use active mood.
- [ ] Preserve current kitty background policy.
- [ ] Preserve ghostty theme file location.
- [ ] Keep terminal reload signals.
- [ ] Ensure Hyprland border colors are valid.
- [ ] Do not touch the HyDE master Hyprland file.

## Confirmation check

- [ ] `terminal.json` exists:

      test -f ~/.cache/yemi-shell/terminal.json && echo ok

- [ ] `hypr-colors.lua` exists:

      test -f ~/.cache/yemi-shell/hypr-colors.lua && echo ok

- [ ] Kitty theme file updated:

      test -f ~/.config/kitty/theme.conf && echo ok

- [ ] Ghostty theme file updated:

      test -f ~/.config/ghostty/themes/yemi-auto && echo ok

- [ ] Terminal colors visually change.
- [ ] Hyprland border colors visually change.
- [ ] No terminal reload errors.

## Exit criteria

- Terminal follows the active mood.
- Hyprland follows the active mood.
- External files are generated from the new pipeline.

---

# Section 5 — Import ColorUtils

## Goal

Bring iNiR color math into Yemi-shell.

## Source file

    /home/yemi/iNiR/modules/common/functions/ColorUtils.qml

## Target file

    config/functions/ColorUtils.qml

## Tasks

- [ ] Stop Quickshell:

      pkill -9 quickshell

- [ ] Read the iNiR `ColorUtils.qml` fully.
- [ ] Copy it into Yemi-shell.
- [ ] Remove iNiR-specific dependencies if any.
- [ ] Keep these important functions:
  - `mix`
  - `transparentize`
  - `applyAlpha`
  - `contrastColor`
  - `lighten`
  - `darken`
  - `isDark`
  - `ensureReadable`
  - `readableSubtext`
  - `adaptToAccent`
- [ ] Add or confirm a safe hex converter that returns:

      #rrggbb

  not:

      #aarrggbb

## Confirmation check

- [ ] Quickshell starts without import errors.
- [ ] No QML errors in logs.
- [ ] ColorUtils is accessible from QML.

## Exit criteria

Color math is available for Appearance and Theme.

---

# Section 6 — Dyn v2 Loader

## Goal

Make `Dyn.qml` understand the new `colors.json v2`.

## Files involved

    singletons/Dyn.qml
    ~/.cache/yemi-shell/colors.json

## Tasks

- [ ] Stop Quickshell:

      pkill -9 quickshell

- [ ] Read `Dyn.qml` fully.
- [ ] Keep the same file path:

      ~/.cache/yemi-shell/colors.json

- [ ] Add support for version 2.
- [ ] Expose both schemes:

      Dyn.dark
      Dyn.light

- [ ] Expose active scheme:

      Dyn.active

- [ ] Active scheme must follow:

      Flags.systemMood

- [ ] Add fallback if JSON is missing.
- [ ] Add fallback if JSON is corrupt.
- [ ] Keep old property aliases temporarily if useful.

## Confirmation check

- [ ] Quickshell starts.
- [ ] No QML errors.
- [ ] IPC reload works:

      qs ipc call colors reload

- [ ] `Dyn.active` changes when `Flags.systemMood` changes.
- [ ] Missing/corrupt JSON does not crash the shell.

## Exit criteria

QML can read both dark and light schemes safely.

---

# Section 7 — Mood Files

## Goal

Make dark and light moods their own objects.

## Target files

    config/theme/moods/DarkMood.qml
    config/theme/moods/LightMood.qml

## Tasks

- [ ] Stop Quickshell:

      pkill -9 quickshell

- [ ] Create `DarkMood.qml`.
- [ ] Create `LightMood.qml`.
- [ ] Define static surfaces.
- [ ] Define static text colors.
- [ ] Define border fallbacks.
- [ ] Define shadow strength.
- [ ] Define highlight alpha.
- [ ] Do not put wallpaper-derived colors inside mood files.
- [ ] Mood files must be pure mood definitions.

## Dark mood should define

    tileBg
    cardTop
    cardBot
    ghost
    border
    cream
    bright
    dim
    subtle
    faint
    iconDim
    shadow strength

## Light mood should define

    tileBg
    cardTop
    cardBot
    ghost
    border
    cream
    bright
    dim
    subtle
    faint
    iconDim
    shadow strength

## Confirmation check

- [ ] Quickshell starts.
- [ ] Both mood files load.
- [ ] Active mood can be selected using `Flags.systemMood`.
- [ ] No wallpaper logic inside mood files.

## Exit criteria

Static surfaces and text are now owned by mood files.

---

# Section 8 — Appearance Adapter

## Goal

Turn `Appearance.qml` into the gearbox between Matugen colors and Yemi tokens.

## Files involved

    config/Appearance.qml
    singletons/Dyn.qml
    singletons/Flags.qml
    config/functions/ColorUtils.qml
    config/theme/moods/DarkMood.qml
    config/theme/moods/LightMood.qml

## Tasks

- [ ] Stop Quickshell:

      pkill -9 quickshell

- [ ] Read current `Appearance.qml` fully.
- [ ] Keep the existing iNiR compatibility layer if anything uses it.
- [ ] Add `m3colors` structure.
- [ ] Add `colors` structure.
- [ ] Add Yemi compatibility tokens.
- [ ] Feed `m3colors` from `Dyn.active`.
- [ ] Use mood files for static surfaces.
- [ ] Derive readable text tokens:
  - `cream`
  - `bright`
  - `dim`
  - `subtle`
  - `faint`
  - `iconDim`
- [ ] Adjust unreadable accents using ColorUtils.
- [ ] Generate flame strings as `#rrggbb`.

## Confirmation check

- [ ] Quickshell starts.
- [ ] No QML binding errors.
- [ ] Existing Appearance consumers still work.
- [ ] Dynamic mode colors come from `Dyn.active`.
- [ ] Static mode surfaces come from mood files.
- [ ] Flame tokens are strings, not QML colors.
- [ ] Flame tokens do not contain alpha hex.

## Exit criteria

Appearance can translate the new engine into Yemi-shell tokens.

---

# Section 9 — Theme Facade Rewrite

## Goal

Rewrite `Theme.qml` internals without breaking old consumers.

## Files involved

    singletons/Theme.qml
    config/Appearance.qml

## Tasks

- [ ] Stop Quickshell:

      pkill -9 quickshell

- [ ] Read `Theme.qml` fully.
- [ ] Keep every existing public token.
- [ ] Point tokens to Appearance adapter.
- [ ] Implement the four-state matrix:
  - Dynamic + Dark
  - Dynamic + Light
  - Static + Dark
  - Static + Light
- [ ] Preserve derived alpha tokens:
  - `hair`
  - `hairSoft`
  - `sheen`
  - `threadBg`
  - `frameBg`
  - `frameBorder`
  - `creamMenu`
- [ ] Preserve flame string tokens:
  - `flameInk`
  - `flameEmber`
  - `flameBurn`
  - `flameTip`
- [ ] Do not edit consumer files yet.

## Confirmation check

- [ ] Quickshell starts.
- [ ] Pill still renders.
- [ ] Bar still renders.
- [ ] OSD still renders.
- [ ] Music panel still renders.
- [ ] Flame canvas renders correctly.
- [ ] Dynamic mode works.
- [ ] Static mode works.
- [ ] Dark mood works.
- [ ] Light mood works.
- [ ] No consumer file was edited.

## Exit criteria

Old components work on top of the new engine.

---

# Section 10 — Flags and Static Grayscale Toggle

## Goal

Add the new static accent toggle.

## Files involved

    singletons/Flags.qml
    ~/.local/state/quickshell/flags.json
    scripts/after-wall.sh
    config/Appearance.qml
    singletons/Theme.qml

## Tasks

- [ ] Stop Quickshell:

      pkill -9 quickshell

- [ ] Read `Flags.qml` fully.
- [ ] Add:

      staticGrayscaleAccents

- [ ] Default value:

      false

- [ ] Wire the flag into Appearance/Theme.
- [ ] Wire the flag into `after-wall.sh` if pipeline should skip wallpaper accent extraction.
- [ ] When enabled:
  - Static mode uses gray accents.
  - Dynamic mode should remain unaffected.
- [ ] When disabled:
  - Static mode can still use wallpaper accent.

## Confirmation check

- [ ] Flag exists:

      jq '.staticGrayscaleAccents' ~/.local/state/quickshell/flags.json

- [ ] Toggle changes static accent visually.
- [ ] Dynamic mode is not broken.
- [ ] Static surfaces remain solid.
- [ ] Text remains readable.

## Exit criteria

Static mode has a working grayscale accent option.

---

# Section 11 — Runtime Triggers and IPC

## Goal

Make sure all real-life triggers use the new pipeline correctly.

## Files involved

    modules/pill/Singletons/Walls.qml
    modules/pill/Appearance.qml
    shell.qml
    scripts/after-wall.sh
    services/Matugen.qml

## Tasks

- [x] Confirm wallpaper change still triggers:

      after-wall.sh <mood> <wallpaper-path>

- [x] Confirm `modules/pill/Appearance.qml` only calls `after-wall.sh`.
- [x] Confirm no QML file calls `wallcolors.py` directly.
- [x] Confirm IPC handler:

      colors reload

still triggers Dyn reload.
- [x] Decide whether `matugenReload` should stay as a shim or be deprecated. (Kept as shim)
- [x] Confirm mood toggle updates QML instantly.
- [x] Confirm mood toggle updates terminal/Hyprland through pipeline.

## Confirmation check

- [x] Wallpaper change updates shell colors.
- [x] Wallpaper change updates terminal colors.
- [x] Wallpaper change updates Hyprland colors.
- [x] Mood toggle updates shell colors.
- [x] Mood toggle updates terminal/Hyprland colors.
- [x] Palette toggle updates shell colors.
- [x] No direct `wallcolors.py` call from active QML.
- [x] IPC reload works:

      qs ipc call colors reload

## Exit criteria

The new pipeline is the only live pipeline.

---

# Section 12 — External Wallpaper Script Cleanup

## Goal

Remove old direct `wallcolors.py` calls outside Quickshell.

## Known target

    ~/.config/hypr/scripts/wallpaper.sh

## Tasks

- [ ] Read the external wallpaper script fully.
- [ ] Check for direct `wallcolors.py` calls:

      grep -n "wallcolors.py" ~/.config/hypr/scripts/wallpaper.sh

- [ ] Remove or replace direct color generation.
- [ ] Ensure the script only sets wallpaper or hands off to `after-wall.sh`.
- [ ] Do not create double color generation.
- [ ] Do not edit the HyDE master Hyprland file.

## Confirmation check

- [ ] No active direct `wallcolors.py` call remains:

      grep -n "wallcolors.py" ~/.config/hypr/scripts/wallpaper.sh

Expected: no active call.

- [ ] Wallpaper change still works.
- [ ] Theme still updates after wallpaper change.
- [ ] Terminal/Hyprland still update.

## Exit criteria

No external script bypasses the single writer rule.

---

# Section 13 — Cleanup and Docs

## Goal

Remove dead pieces and make documentation match reality.

## Tasks

- [ ] Check if `scripts/toggle-colormode.sh` is used anywhere.
- [ ] If unused, move it to legacy or delete it.
- [ ] Check references to:

      state/colormode

- [ ] Remove stale `state/colormode` references if safe.
- [ ] Decide if `services/Matugen.qml` shim can be removed.
- [ ] Move original `wallcolors.py` to legacy only after all sections pass.
- [ ] Update:

      docs/color-system/THEME_SYSTEM_MAP_CURRENT.md

- [ ] Update:

      docs/color-system/YEMISHELL_THEME_REBUILD_PLAN.md

  if any decision changed.
- [ ] Commit the cleanup.

## Confirmation check

- [ ] No stale `wallcolors.py` calls remain in active scripts.
- [ ] No stale `state/colormode` references remain.
- [ ] No stale `toggle-colormode.sh` references remain.
- [ ] Docs describe the new pipeline.
- [ ] Git tree is clean.

## Exit criteria

The repo has one clear theme pipeline.

---

# Final Confirmation Matrix

Do this after all sections pass.

## Mode matrix

| Test | Expected |
|---|---|
| Dynamic + Dark | Wallpaper-derived dark surface, readable text |
| Dynamic + Light | Wallpaper-derived light surface, readable text |
| Static + Dark | Solid dark surface, wallpaper or gray accent |
| Static + Light | Solid light surface, wallpaper or gray accent |
| Static grayscale toggle on | Gray accents in static mode |
| Static grayscale toggle off | Wallpaper accent in static mode |
| Wallpaper change | Shell, terminal, Hyprland update |
| Mood toggle | Shell updates instantly, external apps update |
| IPC reload | Dyn/Theme refresh without crash |
| Flame canvas | Renders correctly, no broken gradient |
| Missing colors.json | Shell falls back safely |
| Corrupt colors.json | Shell does not crash |

---

# Completion Reply Format

When you finish a section, reply like this:

    Section 0 PASS

or:

    Section 1 FAIL: matugen output does not include light scheme

Then we fix the failed section before moving forward.