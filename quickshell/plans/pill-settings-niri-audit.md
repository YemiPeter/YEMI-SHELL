# Pill Settings Section — Niri Inconsistency Audit

**Scope:** The 8 settings sub-surfaces reachable from the pill Settings index, plus
the `Display` helper pipeline. Hyprland works; Niri gaps vary from "already fine"
to "architecturally Hyprland-bound."
**Date:** 2026-08-29

---

## 1. Section map

| # | Page | File | Niri status | Mechanism |
|---|---|---|---|---|
| 1 | Appearance | `Appearance.qml` | ✅ safe | `after-wall.sh`, `apply-system-theme.sh` — compositor-agnostic |
| 2 | Look | `Look.qml` | ❌ Hyprland-only | edits `decoration.lua`, `hyprctl reload`, `hyprctl eval hl.config(...)` |
| 3 | Display | `Display.qml` + `display-apply.sh` + `lib/monitors.js` | ⚠️ half-aware | reads `Compositor.monitors` on Niri, but **apply/keep are Hyprland-only** |
| 4 | Input | `Input.qml` | ❌ Hyprland-only | edits `input.lua`/`env.lua`/`autostart.lua`, `hyprctl setcursor`, `hyprctl reload` |
| 5 | Keybinds | `Keybinds.qml` | ❌ Hyprland-only | edits `binds.js`, `hyprctl reload` |
| 6 | Idle / Lock | `IdleLock.qml` | ❌ Hyprland-only | builds `hypridle.conf`, restarts `hypridle`, `hyprctl dispatch dpms` |
| 7 | Background | `Background.qml` | ✅ safe | already guarded (`!Compositor.isNiri` / `Compositor.isHyprland`), `after-wall.sh` |
| 8 | Updates | `Updates.qml` | ✅ safe | git operations + `qs ipc call reload` — compositor-agnostic |

---

## 2. Page-by-page findings

### 1. Appearance — ✅ safe
No change needed. Drives color/mood through `after-wall.sh` (the single color writer)
and `apply-system-theme.sh`. Comment line 16 still says "reloads Hyprland" but the code
doesn't — stale comment only. Worth fixing the comment, not a Niri bug.

### 2. Look — ❌ architecturally Hyprland-bound
Writes `decoration.lua` (`gaps_in/out`, `rounding`, `border_size`, `active/inactive_opacity`),
then `hyprctl reload`. The opacity path even calls `hyprctl eval "hl.config({...})"`.
Niri has no `decoration.lua` and no `hl.config` — this whole surface edits files Niri never
reads. On Niri the page would let you tweak numbers that land in a dead file.
**Not a small normalization.** Either hide it on Niri (`Compositor.isHyprland`) or build a
parallel Niri path that writes the relevant block in `config.kdl`.

### 3. Display — ⚠️ half-aware, the interesting one
Already has a Niri read path (`Display.qml:50-53,110-113`): when `runningCompositor === "niri"`,
`loadMonitorsFromCompositor()` populates the cards from `Compositor.monitors` instead of
spawning `hyprctl monitors -j`. Good — you can SEE modes on Niri.

But the write path is entirely Hyprland:
- `display-apply.sh` runs `hyprctl eval "hl.monitor({ output, mode, position, scale })"` —
  Hyprland-only. On Niri this command fails / no-ops, so **Apply does nothing**.
- `keep()` persists by rewriting the `hl.monitor({...})` block in `monitors.lua` (via
  `monitors.js:setMonitor`). Niri has no `monitors.lua`, so **Keep writes a dead file**.
- `monitors.js:parse()` consumes `hyprctl monitors -j` (the Hyprland read path). The Niri
  read path bypasses it, so `parse()` is Hyprland-only but that's fine.

Per project memory, Display is *meant to be unified and shared between waffle and pill*
(`waffle.pill.monitors.shared`), so a Niri apply path here is the high-leverage fix.
Niri applies outputs via `niri msg output <NAME> ...` (mode, scale, etc.) — a real
equivalent exists, unlike Look/Input/Keybinds.

### 4. Input — ❌ architecturally Hyprland-bound
Writes `input.lua` (pointer sensitivity/accel), `env.lua` + `autostart.lua` (cursor),
applies cursor via `hyprctl setcursor`, reloads via `hyprctl reload`. Niri cursor is set
via `cursor` block in `config.kdl` + `XCURSOR_SIZE`/`XCURSOR_THEME` env. `hyprctl setcursor`
does nothing on Niri. **Not a small normalization** — either hide on Niri or write the
`config.kdl` cursor block + env.

### 5. Keybinds — ❌ architecturally Hyprland-bound
Edits `binds.js` (Hyprland Lua binds), reloads via `hyprctl reload`. Niri keybinds live in
the `binds { }` block of `config.kdl`. **Not a small normalization** — either hide on Niri
or write `config.kdl`'s binds block.

### 6. Idle / Lock — ❌ architecturally Hyprland-bound
Builds `hypridle.conf`, restarts `hypridle` (a Hyprland idle daemon), uses
`hyprctl dispatch dpms on/off`. Niri has its own idle timeout (`config.kdl` `settings.idle`)
and DPMS via `niri msg action` / `wlr-output-power-management`. **Not a small normalization**
— either hide on Niri or build the `config.kdl` idle block + Niri DPMS calls.

### 7. Background — ✅ safe (already guarded)
`Compositor.isHyprland` / `isNiri` guards already hide double-paint (Hyprland-only) and
disable transitions on Niri (`!Compositor.isNiri`). Wallpaper is driven by `after-wall.sh`.
No change needed.

### 8. Updates — ✅ safe
git + `qs ipc call reload`. Compositor-agnostic.

---

## 3. Summary / recommended order

| Priority | Page | Gap | Effort |
|---|---|---|---|
| **HIGH** | Display | read works, apply/keep are dead on Niri. Real Niri equivalent exists (`niri msg output`). Also slated to be shared with waffle. | Medium — write a Niri apply/keep path. |
| LOW/info | Appearance, Background, Updates | already Niri-safe | none |
| OUT-OF-SCOPE-small | Look, Input, Keybinds, IdleLock | architecturally Hyprland-bound (edit Hyprland Lua/config that Niri doesn't read). No Niri equivalent for the *edit-Lua* model. | Large — each needs either a Niri rewrite or a `Compositor.isHyprland` hide-guard. |

**Suggestion:** Fix Display first (it's half-done and has a clean Niri equivalent), then
decide whether Look/Input/Keybinds/IdleLock should simply be hidden on Niri or get full
Niri counterparts. Display is the only settings page where the fix is a normalization
rather than a from-scratch port.
