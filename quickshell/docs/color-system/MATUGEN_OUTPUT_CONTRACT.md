# Matugen Output Contract → Yemi `colors.json v2`

> Section 2 — Yemi-shell Theme Rebuild.
> Maps Matugen's raw JSON output to the target Yemi `colors.json v2` schema.
> Source samples: [`dark.json`](matugen-samples/dark.json), [`light.json`](matugen-samples/light.json).
> Generated: 2026-08-08

## 1. Documented jq extraction pattern (mode-safe)

Every `.colors.<token>` object in Matugen's output has this identical shape:

```jsonc
"primary": {
  "dark":    { "color": "#dac76f" },
  "default": { "color": "#dac76f" },
  "light":   { "color": "#6c5e0f" }
}
```

**Invariant (verified for all tokens in both files):** `.default` always mirrors the mode that Matugen was run with —
`.default == .dark` in `dark.json` (`-m dark`), and `.default == .light` in `light.json` (`-m light`).
A full-file check on `light.json` returned an empty array `[]`, proving **no** token deviates.

**Therefore the single universal path is:**

```bash
jq -r '.colors.<TOKEN>.default.color' <dark|light>.json
```

This works unchanged against both `dark.json` and `light.json` — the consumer does **not** need to
know which mode produced the file (read `.mode` if you ever need to assert it).

Alternative mode-locked path (only if you insist on the literal mode):
```bash
jq -r '.colors.<TOKEN>.dark.color'  dark.json    # dark run
jq -r '.colors.<TOKEN>.light.color' light.json   # light run
```

---

## 2. Mapping table

### Metadata

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `wallpaper` | `.image` | `/home/yemi/Pictures/Wallpapers/wallhaven-3q23od.webp` |
| `seed` | `.colors.source_color.default.color` | `#312d1c` |
| `scheme_type` | **Not in JSON** — passed via CLI `-t` flag | `scheme-tonal-spot` (from Section 1) |

> **Note on `scheme_type`:** Matugen does **not** embed the `--type` value in its JSON dump. It must be supplied
> by the pipeline via the `-t, --type` CLI flag and tracked separately (see [`MATUGEN_CLI_NOTES.md`](MATUGEN_CLI_NOTES.md:61)).
> Additional routing metadata `mode`/`is_dark_mode` exist at `.mode` (`"dark"`) and `.is_dark_mode` (`true`).

### Core

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `primary` | `.colors.primary.default.color` | `#dac76f` |
| `on_primary` | `.colors.on_primary.default.color` | `#393000` |
| `primary_container` | `.colors.primary_container.default.color` | `#524600` |
| `on_primary_container` | `.colors.on_primary_container.default.color` | `#f7e388` |

### Secondary / Tertiary

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `secondary` | `.colors.secondary.default.color` | `#d1c6a2` |
| `secondary_container` | `.colors.secondary_container.default.color` | `#4d472b` |
| `tertiary` | `.colors.tertiary.default.color` | `#a9d0b4` |
| `tertiary_container` | `.colors.tertiary_container.default.color` | `#2b4e39` |

*(`tertiary_container` exists in the JSON — no fallback to `secondary` was required.)*

### Surfaces

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `surface` | `.colors.surface.default.color` | `#15130b` |
| `surface_container_lowest` | `.colors.surface_container_lowest.default.color` | `#100e07` |
| `surface_container_low` | `.colors.surface_container_low.default.color` | `#1e1c13` |
| `surface_container` | `.colors.surface_container.default.color` | `#222017` |
| `surface_container_high` | `.colors.surface_container_high.default.color` | `#2c2a21` |
| `surface_container_highest` | `.colors.surface_container_highest.default.color` | `#37352b` |

### Text / Outlines

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `on_surface` | `.colors.on_surface.default.color` | `#e8e2d4` |
| `on_surface_variant` | `.colors.on_surface_variant.default.color` | `#cdc6b4` |
| `outline` | `.colors.outline.default.color` | `#969080` |
| `outline_variant` | `.colors.outline_variant.default.color` | `#4a4739` |

### Inverse

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `inverse_surface` | `.colors.inverse_surface.default.color` | `#e8e2d4` |
| `inverse_on_surface` | `.colors.inverse_on_surface.default.color` | `#333027` |

### Error

| Target Key (Yemi) | Matugen JSON Path (jq) | Example Value (from dark.json) |
|---|---|---|
| `error` | `.colors.error.default.color` | `#ffb4ab` |
| `on_error` | `.colors.on_error.default.color` | `#690005` |
| `error_container` | `.colors.error_container.default.color` | `#93000a` |
| `on_error_container` | `.colors.on_error_container.default.color` | `#ffdad6` |

---

## 3. Complete extraction script (drop-in)

For reference, here is one command that emits all 26 tokens from a given file:

```bash
jq -r '.colors | {primary, on_primary, primary_container, on_primary_container,
        secondary, secondary_container, tertiary, tertiary_container,
        surface, surface_container_lowest, surface_container_low, surface_container,
        surface_container_high, surface_container_highest,
        on_surface, on_surface_variant, outline, outline_variant,
        inverse_surface, inverse_on_surface,
        error, on_error, error_container, on_error_container}
      | to_entries[] | "\(.key)=\u001b[0m\(.value.default.color)\u001b[0m"' dark.json
```

(Only the mapping is authoritative; formatting is cosmetic.)

---

## 4. JSON structure reference (from section 1 dump)

- **Top-level keys:** `base16`, `colors`, `image`, `is_dark_mode`, `mode`, `palettes`
- **`.colors`:** Material 3 role tokens (49 keys) — each token `{ dark, default, light }` each with `.color`.
- **`.palettes`:** tonal palettes — `primary`, `secondary`, `tertiary`, `neutral`, `neutral_variant`, `error`.
  Each palette is keyed by tone (`0,10,15,20,…100`), e.g. `.palettes.primary."40".color`. Useful for
  granular tokens not covered above.
- **`.image`:** source image path (string).
- **`.mode`** / **`.is_dark_mode`:** scheme mode (`"dark"` / `true` for dark.json).
- **`.base16`:** wal-style 16-color ramp (each entry also has `dark`/`default`/`light`).