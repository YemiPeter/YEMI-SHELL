# Pill Look Section — Niri Audit

**Section:** Look (`modules/pill/Look.qml`)
**Helper:** `lib/setDeco.js` (parses/writes `decoration.lua`)
**Hyprland artifacts:** `decoration.lua`, `decoration.defaults.lua`, `hyprctl reload`, `hyprctl eval hl.config(...)`
**Date:** 2026-08-29

---

## 1. Structure

```
Look.qml (SettingsSurface, rows: [])
├── decoPath        = $RICE_HOME/hypr/modules/decoration.lua   ← Hyprland-only file
├── decoDefaultsPath= $RICE_HOME/hypr/modules/decoration.defaults.lua
├── Reads (FileView decoFile / decoDefaultsFile) → seed() parses:
│     gaps_in, gaps_out, rounding, border_size, active_opacity, inactive_opacity
│     + Flags.pillBlur (hasNamedRule "pill-blur")
├── Writes (FileView decoWriter, atomic) via setDeco.js:
│     writeDeco(name, lit)   → SetDeco.setField(decoText, name, lit) → decoWriter.setText → reloadProc
│     writeOpacity(name,lit) → writeDeco + push through hyprctl eval hl.config({ decoration = {...} })
│     resetToDefault()       → writes decoration.defaults.lua back → reloadProc
├── Processes
│     ├── reloadProc     → ["setsid","-f","sh","-c","sleep 0.4; hyprctl reload"]   ← Hyprland IPC
│     └── opacityRefresh → ["hyprctl","eval","hl.config({ decoration = {...} })"]   ← Hyprland Lua API
└── Controls (Stepper rows)
      ├── Window
      │     ├── Gaps inner   → writeDeco("gaps_in")
      │     ├── Gaps outer   → writeDeco("gaps_out")
      │     ├── Rounding     → writeDeco("rounding")
      │     └── Border size  → writeDeco("border_size")
      ├── Opacity (BLUR block commented out)
      │     ├── Active window   → writeOpacity("active_opacity")
      │     └── Inactive window → writeOpacity("inactive_opacity")
      └── Pill
            ├── Pill opacity  → Flags.pillOpacity (QML flag, no file write)
            └── Pill blur     → Flags.pillBlur + applyPillBlur() writes hl.layer_rule to decoration.lua
```

## 2. Data flow

```
User steps a Look control → writeDeco / writeOpacity
  → SetDeco.setField rewrites the in-memory decoText
  → decoWriter.setText(decoText)   → WRITES $RICE_HOME/hypr/modules/decoration.lua
  → reloadProc.running = true      → hyprctl reload            (Hyprland-only)
  (opacity only) opacityRefresh    → hyprctl eval hl.config(...) (Hyprland Lua API)

Niri reality:
  • decoration.lua is a Hyprland-Lua file Niri never reads → every write lands in a DEAD file.
  • hyprctl is not present on Niri → reloadProc errors; hl.config eval errors.
  → On Niri the page is fully live but every change is silently lost; nothing visible changes.
```

## 3. Settings rows — Niri mapping

| Row | Hyprland mechanism | Niri equivalent? | Notes |
|---|---|---|---|
| Gaps inner | `decoration.lua` `gaps_in` | ⚠️ partial | Niri `gaps` (`config.d/20:12`, scalar) or `gaps { strut, surround_strut }`. Inner gap ≈ `strut`. |
| Gaps outer | `decoration.lua` `gaps_out` | ⚠️ partial | Niri `gaps { surround_strut }` / `struts { }` block. |
| Rounding | `decoration.lua` `rounding` | ❌ none | Niri does not round window corners. No config knob. |
| Border size | `decoration.lua` `border_size` | ⚠️ coarse | Niri `border { off \| thin \| normal }` — discrete steps, not pixel size. |
| Active opacity | `decoration.lua` + `hl.config` | ❌ none (global) | Niri only does per-window-rule `opacity`; no global active_opacity. |
| Inactive opacity | `decoration.lua` + `hl.config` | ❌ none (global) | Same as above. |
| Pill opacity | `Flags.pillOpacity` (QML flag) | ✅ safe | Pure Quickshell flag; pill layer surface exists on Niri. |
| Pill blur | `hl.layer_rule` in `decoration.lua` | ⚠️ dead write | Niri ignores the Lua rule; pill blur is actually done in QML (BackgroundEffect). Toggle has no Niri effect but is harmless. |

## 4. Hyprland / Niri touchpoints

| Touchpoint | Kind | Niri-safe? |
|---|---|---|
| `decoPath` = `.../hypr/modules/decoration.lua` | file write | ❌ Niri never reads it |
| `reloadProc` → `hyprctl reload` | Hyprland IPC | ❌ `hyprctl` absent on Niri |
| `opacityRefresh` → `hyprctl eval hl.config(...)` | Hyprland Lua API | ❌ no `hl.config` on Niri |
| `setDeco.js` field rewrite | text edit of Lua | ❌ targets Hyprland file |
| `Flags.pillOpacity` | QML flag | ✅ |
| `Compositor.isHyprland` / `isNiri` guard | — | ❌ **absent in Look.qml** |

## 5. Niri findings

**❌ Architecturally Hyprland-bound.** Look edits a Hyprland Lua decoration file and drives
reloads through `hyprctl` — neither exists on Niri. Unlike Display (which has a real `niri msg
output` equivalent), Look has **no clean Niri port** for 4 of 6 live knobs:

- `rounding`, active/inactive `opacity` have **no Niri equivalent at all**.
- `gaps` and `border` have only **partial / coarse** Niri equivalents (scalar `gaps`, discrete `border` mode).

There is also **no compositor guard** in `Look.qml` — on Niri the surface renders, accepts input,
writes to a dead file, and runs `hyprctl` (fails silently). The user gets the illusion of control
with zero effect.

This matches the prior settings audit (`pill-settings-niri-audit.md §2`): Look is in the
"hide on Niri or build a from-scratch Niri path" bucket, not a normalization.

## 6. Verdict & recommendation

**Verdict:** Look is NOT Niri-compatible. It is Hyprland-only by construction.

**Fix — IMPLEMENTED (hide on Niri):** Look is now hidden on Niri via `Compositor.isHyprland`:
- `modules/pill/Settings.qml`: `lookRow.visible: Compositor.isHyprland` (visual hide) and the
  nav `rows` array filters out the `look` entry when `!Compositor.isHyprland` (keyboard nav skips it).
- `modules/pill/Pill.qml`: added `import qs.compositor`; the `surfaces` map entry `look:` is
  `Compositor.isHyprland ? {...} : undefined`, so the surface cannot be opened even via a deep link.
  `lookOpen` stays false on Niri as a result.

This is the correct call because rounding + global opacity have no Niri equivalent — a faithful
port is impossible, and a partial port (gaps + border only) would be misleading.

**Optional later:** port only `gaps` + `border` to a Niri `config.kdl` write path if desired, but
that is a separate from-scratch effort and is not needed for Niri compatibility.

`Pill opacity` (`Flags.pillOpacity`) is already Niri-safe and needs no change.
