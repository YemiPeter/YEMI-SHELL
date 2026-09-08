# Look

## 1. Component Overview

Look is a Hyprland-only pill settings surface for the desktop's window-decoration knobs: window gaps, rounding, border size, the blur block (enabled / strength / passes), active & inactive window opacity and the pill's own opacity. Every change is written straight back to `hypr/modules/decoration.lua` — its source of truth — and Hyprland is reloaded so the change lands live, no shell reload needed. The border colours are sourced from the palette pipeline and never touched here.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Look.qml`
- **Helper library**: `modules/pill/lib/setDeco.js` — Lua-text read/rewrite helpers
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Io`, `lib/setDeco.js`, `Singletons` (Flags)
- **Base component**: `SettingsSurface` (`backSurface: "settings"`; implicit height from `content.implicitHeight`)
- **Instantiated by**: the pill surface loader when `Pill.surface === "look"`, reached from the Settings index
- **Compositor scope**: Hyprland only — the Settings index filters the Look row out when `!Compositor.isHyprland`
- **Config files**: `$RICE_HOME/hypr/modules/decoration.lua` (live, edited) and `decoration.defaults.lua` (reset source)

## 3. Component Hierarchy and Role

Look is a `SettingsSurface` that renders a `Column` of `GroupLabel` / `FieldRow` groups, each row pairing a label+caption with a `Stepper` (or a `LinkToggle` for the blur enable). Groups, in order:

- **Window** — Gaps inner (0–40), Gaps outer (0–60), Rounding (0–30), Border size (0–8)
- **Blur** — Enabled toggle (`LinkToggle`), Strength = `blur.size` (1–20), Passes (1–5); the Strength/Passes rows collapse when blur is off
- **Opacity** — Active window / Inactive window steppers (0.50–1.00 in 0.05 steps)
- **Pill** — Pill opacity (0.50–1.00, via `Flags.pillOpacity`; Hyprland only — niri stays solid)

`Stepper` is an inner `Row` component (−/value/+ buttons with hover styling) emitting `stepped(dir)`. The back chevron morphs back to the `settings` surface.

## 4. Properties

Seeded from the live `decoration.lua` every time the surface activates (stale fields fall back to the shipped values):

- `gapsIn` (6), `gapsOut` (12), `rounding` (12), `borderSize` (2)
- `blurOn` (true), `blurSize` (3), `blurPasses` (2) — read from the `blur` block
- `activeOpacity` / `inactiveOpacity` (1.0)
- `decoText` — in-memory snapshot of the file all writes splice against

## 5. Signals

Look defines no custom signals; it uses `onActiveChanged` to `reload()` + `seed()` on open and clear keyboard-focus state on close.

## 6. Methods

- `seed()` — re-reads `decoration.lua` into `decoText` and every control. Blur fields are read with `SetDeco.getBlockField(t, "blur", …)` so a name shared with the sibling `shadow` block (`enabled`) resolves to the right one.
- `writeDeco(name, literal)` — `SetDeco.setField` top-level rewrite → `decoWriter.setText` (atomic `FileView`) → `hyprctl reload` (detached via `setsid`, 0.4 s delay).
- `writeBlur(name, literal)` — same pipeline but `SetDeco.setBlockField(text, "blur", …)`, scoped to the `blur` block (the shared `enabled` field makes top-level rewrites wrong for blur).
- `writeOpacity(name, literal)` — `writeDeco` plus a `hyprctl eval hl.config({ decoration = { active_opacity = …, inactive_opacity = … } })` push; a plain reload only animates alphas on the next focus change, the eval hits `REFRESH_WINDOW_STATES` and recomputes every live window at once (both fields always sent).
- `resetToDefault()` — copies `decoration.defaults.lua` over the live file, resets `Flags.pillOpacity` to 0.55, re-seeds and reloads.

**setDeco.js helpers**: `getField`/`setField` operate on top-level `name = value` fields; `getBlock`/`getBlockField`/`setBlockField` operate inside a named block, brace-balanced so nested tables don't end the scan. The block head matches both `block = {` and the bare hyprlang form `block {` that `decoration.lua` uses (this bare form is why block-scoped writes used to silently fail — see the audit's D4 note). `findNamedRule`/`hasNamedRule`/`removeNamedRule`/`addNamedRule` manage `hl.layer_rule` calls for other consumers of the lib.

## 7. Inter-Component Interactions

- **Settings.qml** — settings index; nav row `surface: "look"` (Hyprland-gated)
- **PillState** — `QsSingletons.PillState.toggleSurface(mon, "look")` opens it; back chevron returns to `settings`
- **Flags** — `pillOpacity` is a persisted flag, not a decoration.lua field
- **FileView ×3** — `decoFile` (blocked read), `decoWriter` (atomic writes), `decoDefaultsFile` (reset source)
- **Hyprland** — `hyprctl reload` and `hyprctl eval` subprocesses apply changes live

## 8. Usage Example

Open from the pill: settings index → **Look** row (Hyprland sessions only). Turn blur off and the Strength/Passes rows collapse; nudge Strength and `decoration.lua`'s `blur { size = … }` is rewritten and Hyprland reloads within ~0.4 s:

```ini
# ~/.config/hypr/modules/decoration.lua after stepping Strength from 3 to 6
blur {
    enabled = true
    size = 6
    passes = 2
    ...
}
```

