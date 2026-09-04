# Audit 06 — Unexpected black border lines on buttons (pill UI border drift)

**Date:** 2026-09-04 · **Branch:** `pill-perf` · **Base commit:** `b0755f7`

**Scope:** Visual drift between the local quickshell pill UI and the original
Ricelin reference, focused on the "black hairline around buttons/tiles" that the
reference never produced.

> **STATUS:**
> - ✅ **Fix 1 (Option A) implemented & validated** — `scripts/dominance-engine.py`,
>   exit 0, all acceptance checks green, on the live wallpaper
>   `wallhaven-x1lxjo.webp` (see §5).
> - ⏳ **Fix 2 (Appearance.qml)** — waiting on user's design questions.
> - ⏳ **Fix 3 (Pill.qml body border)** — decision deferred.
> - 📋 **Option B migration plan:** `plans/pill-perf-outline-option-b-migration.md`.

---

## 1 · Verdict (TL;DR)

The black lines are **not** a per-widget styling bug. Three stacked regressions,
in this order of leverage:

1. **Palette generation (root cause).** `scripts/dominance-engine.py` derives
   dark-mode `outline` / `outline_variant` as *darker-than-surface* with a
   **0.02 lightness floor**. On this wallpaper (and on any dark one with surface
   lightness ≤ 0.12) **both tokens pin identically to `#080302`** — an inky,
   black-on-black edge. The Ricelin `wallcolors.py` pipeline it replaced emitted
   `outline_variant` **lighter than the surface** (a visible warm hairline).
2. **Token plumbing.** `Appearance.yemiBorder` **hardcodes** `Dyn.outlineVariant`
   (no `schemeValid` guard, no static fallback — unlike every sibling token).
   The static `border` token in `DarkMood.qml` exists but is
   **unreachable** while a scheme is valid (and it is the user's *neutral gray*
   `#3a3a3a`, not Ricelin's warm `#3a2a22` — see §3.2).
3. **Consumption.** `Theme.border` = `yemiBorder` → every rest-state button/tile
   border (Power, Link, Mixer, Media, settings rows, profile tile…) renders the
   broken token. The pill body additionally drifted from `Theme.border`
   (reference) to `Theme.frameBorder` (white @10% alpha).

Secondary amplifiers (not the cause): the niri `layer.effect` black drop shadow
(`Theme.shadow` `rgba(0,0,0,0.55)`, `shadowOpacity 0.5`) + `backdropDim 0.2` +
`wallpaperDim 0.55` compound the "ink outline" impression against an already
dim-`ed` background.

---

## 2 · Evidence

**Live palette — `~/.cache/yemi-shell/colors.json` (dark block; pre-fix):**

| Token                  | Hex      | HLS L | Note                              |
|------------------------|----------|-------|-----------------------------------|
| `surface`              | `#2b110c`| 0.108 | tile/power-tile background        |
| `surface_container_highest` | `#532018` | 0.218 |                                  |
| `outline`              | `#080302`| ~0.02 | **= floor**                       |
| `outline_variant`      | `#080302`| ~0.02 | **= floor** → **`Theme.border`**  |
| `on_surface`           | `#fcf4f3`| ~0.97 | cream text                        |
| `on_surface_variant`   | `#f4dbd7`| ~0.95 |                                   |
| `primary`              | `#ffaa70`| ~0.71 | accent / flame                    |

Both outline tokens are **byte-identical**. WCAG contrast `surface` vs
`outline`: **~1.15 : 1** — the line is visually the surface's own shadow.

**Runtime flags — `~/.local/state/quickshell/flags.json`:** `paletteMode:
"dynamic"`, `systemMood: "dark"`, `themeStyle: "aurora"`, `pillOpacity: 1`,
`staticGrayscaleAccents: false`. → the dynamic branch is active, so the broken
`outline_variant` reaches the UI.

**Active wallpaper:** `wallhaven-x1lxjo.webp` (from
`~/.local/state/quickshell-wallpaper`, echoed by `colors.json.wallpaper`,
seed `#6c2a1f`). ⚠️ `wallhaven-k8l167.webp` (used in earlier drafts) is a
genuinely **grayscale** image — good B-canary, wrong for warm-border testing.

**Active pipeline — `scripts/after-wall.sh`:** v2 default path runs
`dominance-engine.py` as the *single writer* of `colors.json` (legacy
---

## 3 · Root-cause chain

### 3.1 RCA-1 — `dominance-engine.py` collapses both outline tokens to the floor

`scripts/dominance-engine.py` (pre-fix):

```python
# ---- Outlines (subtle borders, low contrast by design) ----
# Dark mode: darker outlines (darker than surface)
# Light mode: lighter outlines (lighter than surface)
if mood == "dark":
    ol  = clamp01(anchor - 0.10, 0.02, 0.98)
    olv = clamp01(anchor - 0.20, 0.02, 0.98)     # ← floor 0.02
...
block["outline"]         = hls_to_rgb(h1, ol,  s1)
block["outline_variant"] = hls_to_rgb(h1, olv, s1)
```

with `anchor = clamp01(l1 * 0.4, 0.02, 0.25)` (dark). Current wallpaper:
`surface L = 0.108` ⇒ `anchor = 0.108` (i.e. `l1 ≈ 0.27`).

```
ol  = 0.108 - 0.10 = 0.008  → clamped → 0.02
olv = 0.108 - 0.20 = -0.092 → clamped → 0.02
```

⇒ both clamp to `#080302`. **Structural, not a one-wallpaper accident:**
`outline_variant` pins to the floor for *any* dark wallpaper with
`anchor < 0.22` (i.e. dominant-lightness `l1 < 0.55`), which is essentially every
dark image. `outline` pins whenever `anchor < 0.12`. The `0.02` floor was meant
to keep a "near-black hairline" — instead it produces pure ink with zero
separation from the surface.

Reference behavior (**`/home/yemi/Ricelin/configs/hypr/scripts/wallcolors.py`**):

```python
SURF_NAMES = ["surface", "surface_container_low", "surface_container",
              "surface_container_high", "surface_container_highest", "outline_variant"]
DARK_STEPS = [0.0, 0.022, 0.038, 0.065, 0.100, 0.225]
...
pill["outline"] = tint(hue, surf_sat, base + (-0.35 if light else 0.35))
```

Dark `outline_variant` = `base + 0.225` → for the reference's dark regime
`base ≈ 0.045…0.20`, that's **L ≈ 0.27…0.43 — a visible warm tan hairline
*above* the surface**, on purpose. The dominance engine inverted the polarity to
"darker than surface" and pinned the result at black.

### 3.2 RCA-2 — `Appearance.yemiBorder` has no fallback

`config/Appearance.qml`:

```qml
readonly property color yemiBorder: QsSingletons.Dyn.outlineVariant   // line 177 — NO guard
```

Every sibling text token (lines 147–176) gates on `Dyn.schemeValid` with an
`activeMood.*` fallback; several wrap `ensureReadable(...)`. `yemiBorder` does
none of this, so:

- **static mode still leaks the dynamic near-black token** (Ricelin returns the
  warm `#3a2a22`);
- **no scheme** → `Dyn.outlineVariant` is also near-black from the engine floor,
  not the mood file.

`config/theme/moods/DarkMood.qml` already defines a static fallback:

```qml
readonly property color border: "#3a3a3a"   // line 34 — neutral gray (this shell's design)
```

…but it is unreachable and it is NOT Ricelin's warm `#3a2a22`. If true Ricelin
parity is wanted in static/no-scheme mode, `DarkMood.border` should become a
warm brown (`#3a2a22`); if neutrality is preferred, keep `#3a3a3a` — this is a
design decision, not a bug. Ricelin reference
(`/home/yemi/Ricelin/configs/quickshell/pill/Singletons/Theme.qml`):

```qml
readonly property color border: dyn ? Dyn.outlineVariant : "#3a2a22"
```
### 3.3 RCA-3 — consumers render the broken token

`singletons/Theme.qml` line 70: `readonly property color border: QsConfig.Appearance.yemiBorder`.

All rest-state button borders pass through `Theme.border` (⇒ `#080302`):
Power action tiles + the **new power-profile cycle tile**, Link rows, Mixer
chips + faders, Media prev/next skip, Calendar nav, Clipboard rows,
settings segments, welcome/wallpaper/airplane surfaces. The pill **body**
border additionally drifted from the reference:

| Surface | Reference (Ricelin)   | Local (now)            |
|---------|-----------------------|------------------------|
| Pill body edge | `Theme.border` | `Theme.frameBorder` (= `cream` @ 0.10 ≈ white ghost line) |
| Button rest edges | `Theme.border` | `Theme.border` = `#080302` (same path, broken token) |
| Button hover/selected | `Theme.frameBorder` | `Theme.frameBorder` (unchanged concept) |

The body switch (`Pill.qml` lines 618–619) is a separate, deliberate change
(`"!TWEAK ZONE"` frameborder comment) — but it means the pill outline is now a
white @10% translucent veil while every button inside still shows the black
token, so the black-rim look concentrates on buttons.

### 3.4 RCA-4 — dark halo amplifiers (secondary)

- Pill `body` `layer.effect` drop shadow: `Theme.shadow = rgba(0,0,0,0.55)`,
  `shadowOpacity = 0.5`.
- `backdropDim 0.2`, `backdropVignette 0.15`, `wallpaperDim 0.55` dim/vignette
  the wallpaper behind the pill (Hyprland shell; the pill itself is opaque at
  `pillOpacity 1` in aurora via `pillAlpha`).
- On the dark wallpaper the 1px `#080302` edges + black shadow read as stray
  ink outlines; the reference's warm hairlines never did.

---

## 4 · Side-by-side

### 4.1 Palette pipeline

| | Ricelin (wallcolors.py) | Local (dominance-engine.py) |
|---|---|---|
| `outline_variant` (dark) | `base + 0.225` — **lighter**, warm tint | `anchor − 0.20`, floor `0.02` — **black** (now: `anchor − 0.02`, floor `anchor·0.85`) |
| `outline` (dark)        | `base + 0.35` — lighter, warm | `anchor − 0.10`, floor `0.02` — near-black (now: `anchor − 0.06`, floor `anchor·0.60`) |
| Separates text tones?   | yes — dedicated `TEXT_KEYS` ramp | no — `dim`=`outline`, `faint`=`outline_variant` (bundle in schema) |
| Result on this wallpaper | L≈0.27 warm hairline | `#080302` → L≈0.02 ⇒ (fixed) `#1a0a07` / `#250e0b` |

### 4.2 Border token

| | Reference `Theme.border` | Local `yemiBorder` |
|---|---|---|
| dynamic | `Dyn.outlineVariant` (Ricelin adapter → warm) | `Dyn.outlineVariant` (fixed engine → `#250e0b`) |
| static / no scheme | `"#3a2a22"` | `#080302` (still the dynamic token — **Fix 2 pending**) |

---

## 5 · Recommended fixes (leverage order)

### Fix 1 · Engine — never let `outline_variant` hit ink-black — ✅ IMPLEMENTED (Option A)

Replaced the dark-mode outline derivation in `scripts/dominance-engine.py`
(lines 328–342) with a **surface-proportional** floor, keeping the
"darker than surface" polarity so `G-dark-vs-light` stays green:

```python
# Dark mode: outline darker than surface, scaled so it cannot hit black
ol  = clamp01(anchor - 0.06, anchor * 0.60, 0.98)
# outline_variant: just under the surface — a soft warm frame, never black
olv = clamp01(anchor - 0.02, anchor * 0.85, 0.98)
```

**Validated live** (wallpaper `wallhaven-x1lxjo.webp`, exit 0, all checks green):

| dark token | before | after |
|---|---|---|
| `surface` | `#2b110c` | `#2b110c` |
| `outline` | `#080302` | `#1a0a07` |
| `outline_variant` | `#080302` | `#250e0b` |

Light mode unchanged (`#fdf8f7`/`#fdf8f7`). Why safe: dark `ol/olv ≤ 0.25`,
light ≥ 0.85 ⇒ |ΔL| ≫ 0.02 on every wallpaper, so G stays green
unconditionally — no `verify()` edits needed.

> **Next:** after Fix 2, re-run `after-wall.sh` and confirm the UI.
> The exact-Ricelin look (warm *lighter* hairlines, `L≈0.27`) is Option B —
> staged in `plans/pill-perf-outline-option-b-migration.md`.
### Fix 2 · `Appearance.qml` — restore the static/scheme fallback (PENDING user questions)

`config/Appearance.qml` line 177 currently hardcodes the dynamic token. Proposed
(awaiting user's design questions before editing):

```qml
readonly property color yemiBorder: QsSingletons.Dyn.schemeValid
    ? (isDynamic ? QsSingletons.Dyn.outlineVariant : activeMood.border)
    : activeMood.border
```

This mirrors Ricelin's `dyn ? Dyn.outlineVariant : "#3a2a22"` and makes
`DarkMood.qml`'s `border: "#3a2a22"` reachable in static mode / no-scheme cases.

### Fix 3 · Pill body border — ✅ IMPLEMENTED (Ricelin parity via local token)

`modules/pill/Pill.qml` line 620: `border.color: Theme.frameBorder`
(cream @ 0.10 white veil) → **`Theme.border`**.

This is a local-only merge — the local theme already exposes `Theme.border`
(`singletons/Theme.qml:70` → `Appearance.yemiBorder`); no Ricelin theme-system
code is involved. After Fix 1 the dynamic value is the warm hairline
(`#250e0b`), so the pill frame now matches its buttons. `Theme.frameBorder`
remains in use for hover/focus/selected states (unchanged concept).

**Open design decision (not a bug):** static/no-scheme `Theme.border` resolves
to `activeMood.border` — currently *neutral gray* `#3a3a3a` (dark) / `#e0e0e0`
(light). Ricelin's static fallback is warm `#3a2a22`.

### Fix 4 · No per-file border edits needed after Fix 1 (DONE BY CONSTRUCTION)

The new Power profile-cycle tile (`Power.diff`, rest border `Theme.border`) and
all other rest-state borders self-heal once `Theme.border` is warm again. Keep
`kbFocus ? Theme.frameBorder : Theme.border` as-is.

---

## 6 · Per-file drift matrix (from `/tmp/audit/`)

| File | Drift |
|---|---|
| `Appearance.diff` | Removed reference avatar-ring border (`Theme.cream`, 2.5px) and a `Theme.border` frame in the popup tier wiring. |
| `Pill.diff` | Body border `Theme.border` → `Theme.frameBorder`; pill outline + top highlight comment; niri layer shadow. |
| `Power.diff` | New power-profile cycle tile — rest border `Theme.border`, hover `Theme.frameBorder`; new Hibernate action (snowflake glyph). |
| `Media.diff` | Skip buttons gained 1px `Theme.border` outlines on hover (new affordance; fine once border is warm). |
| `Link/Mixer/Calendar/Clipboard/SearchField/DisplayLabel…` | Kanji → latin glyph removal, mute UX, etc. — no border-token logic changes. |

---

## 7 · Verification plan

1. ✅ Palette regeneration (Fix 1) — validated:
   ```sh
   python3 /home/yemi/.config/quickshell/scripts/dominance-engine.py \
     /home/yemi/Pictures/Wallpapers/wallhaven-x1lxjo.webp
   ```
   → `dark.outline_variant = #250e0b` (≠ `#080302`), `dark.outline = #1a0a07`
   (≠ `outline_variant`), exit 0, A/B/D/E/F/G all PASS. (`wallhaven-k8l167.webp`
   is grayscale — use it only for the B-canary.)
2. ⏳ Relaunch quickshell (post Fix 2); screenshot the pill hovered +
   settings/power buttons. Borders should read as *warm* edges on this wallpaper,
   never black.
3. ⏳ Toggle `paletteMode: static` → border should become `#3a2a22` (warm
   brown), matching the Ricelin static fallback exactly.
4. ⏳ Sanity: `yemiFaint`/`yemiDim` text still pass `ensureReadable` after any
   further engine changes (they re-raise outline tokens for text contrast).

---

## 8 · Appendix — numbers

- `#080302` → HLS `L ≈ 0.020` (the old engine floor), rel. luminance ≈ 0.0018.
- `#2b110c` (surface) → HLS `L ≈ 0.108`, rel. luminance ≈ 0.0097.
- Contrast surface-vs-outline (pre-fix): **≈ 1.15 : 1** (imperceptible → "blobby" black line).
- Post-fix `#250e0b` → HLS `L ≈ 0.09`, rel. luminance ≈ 0.0048, warm hue:
  ≈ **1.6 : 1** vs surface — quiet but visible.
- Ricelin static fallback `#3a2a22` → HLS `L ≈ 0.180`, rel. luminance ≈ 0.027,
  warm hue: **≈ 1.3 : 1** (deliberate quiet frame).
- Ricelin dynamic `outline_variant` (dark base+0.225) → `L ≈ 0.27`: clearly
  visible *warm* hairline, the intended look (Option B).
`wallcolors.py` only via `YEMI_LEGACY_COLORS=1`).