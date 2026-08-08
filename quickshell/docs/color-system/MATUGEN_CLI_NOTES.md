# MATUGEN CLI Notes

> Section 1 — Yemi-shell Theme Rebuild. Verified environment: Matugen on CachyOS/Arch (Linux 7.1).
> Generated: 2026-08-08

## 1. Install

Matugen was **already installed** on this system — no install action was required.

```bash
$ matugen --version
matugen 4.1.0
```

If a clean install is ever needed, the standard approaches are:

- **pacman (AUR)** — most common on CachyOS/Arch:
  ```bash
  paru -S matugen            # or: yay -S matugen
  ```
- **Cargo** (from source / or `cargo-binstall`):
  ```bash
  cargo install matugen
  ```

## 2. CLI commands used to generate JSON

The output directory `docs/color-system/matugen-samples/` was created with:

```bash
mkdir -p docs/color-system/matugen-samples/
```

Wallpaper source (read from `~/.local/state/quickshell-wallpaper`):

```
/home/yemi/Pictures/Wallpapers/wallhaven-3q23od.webp
```

### Dark scheme

```bash
matugen image /home/yemi/Pictures/Wallpapers/wallhaven-3q23od.webp \
  -j hex -m dark --dry-run -t scheme-tonal-spot -q --source-color-index 0 \
  > docs/color-system/matugen-samples/dark.json
```

### Light scheme

```bash
matugen image /home/yemi/Pictures/Wallpapers/wallhaven-3q23od.webp \
  -j hex -m light --dry-run -t scheme-tonal-spot -q --source-color-index 0 \
  > docs/color-system/matugen-samples/light.json
```

Flag breakdown:

| Flag | Meaning |
|------|---------|
| `matugen image <PATH>` | Generate scheme from an image |
| `-j hex` | Dump JSON of colors in `hex` format (alt: `rgb`, `rgba`, `hsl`, `hsla`, `strip`) |
| `-m dark` / `-m light` | Scheme mode (the only valid values) |
| `--dry-run` | Do not render templates, reload apps, set wallpaper, or run commands — **safe for testing** |
| `-t scheme-tonal-spot` | Scheme type (see §4) |
| `-q` | Quiet output — only print the JSON |
| `--source-color-index 0` | Auto-pick the most dominant source color (0–4) and suppress the interactive prompt |

## 3. Does it support both dark and light in one run?

**The `--mode` flag accepts only ONE value per invocation** (`light` or `dark`, default `dark`).
There is **no "both" flag**. To get both schemes you run Matugen twice — once with `-m dark` and once with `-m light`.

**Important nuance for the theme system:** Even a single `hex`-format dump contains **both** variants for every key. Each color object in the JSON has `dark`, `default`, and `light` sub-entries. The `--mode` flag only controls which variant is copied into `default`. This is visible in the `base16` section:

```jsonc
"base00": {
  "dark":     { "color": "#22221d" },
  "default":  { "color": "#22221d" },  // <- reflects --mode
  "light":    { "color": "#e4ded9" }
}
```

> **Consequence:** A single `-m dark` run technically contains the full light palette too (in the per-key `light` sub-entry). However, dumping **two separate runs** (`dark.json` + `light.json`) is cleaner and more reliable because:
> 1. The top-level `colors` section and the `default` entries are mode-resolved.
> 2. It avoids confusion about which entry to read.
>
> **Recommendation:** Run twice, keep one file per mode, as done here.

## 4. Default scheme type recommendation

Available `--type` values: `scheme-content`, `scheme-expressive`, `scheme-fidelity`, `scheme-fruit-salad`,
`scheme-monochrome`, `scheme-neutral`, `scheme-rainbow`, `scheme-tonal-spot`, `scheme-vibrant`.

- Matugen's default is **`scheme-tonal-spot`**.
- For a shell/bar UI (neutrals, restrained accents, high readability), **`scheme-content` is recommended** as the default:
  it targets the median color of the image so neutrals and surfaces stay close to the wallpaper without
  excessive chroma, and it reads especially well in text surfaces.
- `scheme-tonal-spot` is a fine secondary choice; `scheme-expressive` and `scheme-vibrant` are best left as
  user overrides for more saturated looks.

**Recommendation:** default `-t scheme-content`, overridable per user in config.

## Summary

- Install state: **already installed** (`matugen 4.1.0`); no action needed.
- JSON generation: two runs (`dark` + `light`), `hex` format, `--dry-run` for safety.
- Dark/light in one run: **No** (mode takes one value); dump both runs.
- Recommended default scheme type: **`scheme-content`**.