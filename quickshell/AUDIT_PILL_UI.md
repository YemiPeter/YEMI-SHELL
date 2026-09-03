# AUDIT — Unexpected black border lines on buttons

**Date:** 2026-09-04 · **Branch:** `pill-perf` · **Base commit:** `b0755f7`

**Scope:** Visual drift between the local quickshell pill UI and the original
Ricelin reference, focused on the "black hairline around buttons/tiles" that the
reference never produced.

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
   The warm static `border: "#3a2a22"` in `DarkMood.qml` exists but is
   **unreachable** while a scheme is valid.
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

**Live palette — `~/.cache/yemi-shell/colors.json` (dark block):**

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

**Active pipeline — `scripts/after-wall.sh`:** v2 default path runs
`dominance-engine.py` as the *single writer* of `colors.json` (legacy
`wallcolors.py` only via `YEMI_LEGACY_COLORS=1`).

---

## 3 · Root-cause chain

### 3.1 RCA-1 — `dominance-engine.py` collapses both outline tokens to the floor

`scripts/dominance-engine.py`:

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

`config/theme/moods/DarkMood.qml` already defines the correct static fallback:

```qml
readonly property color border: "#3a2a22"   // line 34 — warm brown, matches Ricelin exactly
```

…it just can never be reached. Ricelin reference
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

The body switch (`Pill.qml` lines 618–619, diff `Pill.diff:226-227 → 250-251`) is a
separate, deliberate change (`"!TWEAK ZONE"` frameborder comment) — but it means the
pill outline is now a white @10% translucent veil while every button inside still
shows the black token, so the black-rim look concentrates on buttons.

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
| `outline_variant` (dark) | `base + 0.225` — **lighter**, warm tint | `anchor − 0.20`, floor `0.02` — **black** |
| `outline` (dark)        | `base + 0.35` — lighter, warm | `anchor − 0.10`, floor `0.02` — near-black |
| Separates text tones?   | yes — dedicated `TEXT_KEYS` ramp | no — `dim`=`outline`, `faint`=`outline_variant` (bundle in schema) |
| Result on this wallpaper | L≈0.27 warm hairline | `#080302` → L≈0.02 |

### 4.2 Border token

| | Reference `Theme.border` | Local `yemiBorder` |
|---|---|---|
| dynamic | `Dyn.outlineVariant` (Ricelin adapter → warm) | `Dyn.outlineVariant` (`#080302`) |
| static / no scheme | `"#3a2a22"` | `#080302` (still the dynamic token) |

---

## 5 · Recommended fixes (ordered by leverage)

### Fix 1 · Engine — never let `outline_variant` hit ink-black (root cause)

Replace the dark-mode outline derivation in `scripts/dominance-engine.py`
(lines 328–342) **and** the acceptance check it depends on.

**Option A (zero-risk, minimal):** keep the "darker than surface" polarity (so the
`G-dark-vs-light` check still passes untouched) but replace the absolute `0.02`
floor with a **surface-proportional** floor:

```python
if mood == "dark":
    ol  = clamp01(anchor - 0.06, anchor * 0.60, 0.98)   # stays under surface, never ink
    olv = clamp01(anchor - 0.02, anchor * 0.85, 0.98)   # quiet warm shadow frame
else:
    ol  = clamp01(anchor + 0.10, 0.02, 0.98)
    olv = clamp01(anchor + 0.20, 0.02, 0.98)
```

On the current wallpaper (`anchor = 0.108`): `ol ≈ 0.065`, `olv ≈ 0.092` → a
warm, dark-brown edge — visible against `#2b110c` but not black. Dark-vs-light
asymmetry is preserved so `verify()`/`G` stays green.

**Option B (true Ricelin parity):** flip dark outlines *lighter* than surface,
matching wallcolors.py, and **exempt the outline family from the G-check** (they
are decorative frames, not text — text legibility comes from
`ensureReadable(outline…)` in `Appearance.yemiDim/yemiFaint`):

```python
if mood == "dark":
    ol  = clamp01(anchor + 0.10, 0.02, 0.98)
    olv = clamp01(anchor + 0.20, 0.02, 0.98)   # ≈ Ricelin base+0.225
```

This restores the exact reference look (warm `L≈0.25–0.30` hairline) but
requires editing `verify()` (G-check `same_l` for `outline`/`outline_variant`)
so dark/light equality for these two tokens is allowed.

> **Recommendation:** Option A now (safe, ships immediately), Option B as a
> follow-up if the exact reference warmth is wanted. After either fix,
> re-run `after-wall.sh` and confirm `colors.json` no longer contains `#080302`
> in both outline slots.

### Fix 2 · `Appearance.qml` — restore the static/scheme fallback (mandatory)

`config/Appearance.qml` line 177:

```qml
readonly property color yemiBorder: QsSingletons.Dyn.schemeValid
    ? (isDynamic ? QsSingletons.Dyn.outlineVariant : activeMood.border)
    : activeMood.border
```

This mirrors Ricelin's `dyn ? Dyn.outlineVariant : "#3a2a22"` and makes
`DarkMood.qml`'s `border: "#3a2a22"` reachable in static mode / no-scheme cases.

### Fix 3 · Pill body border — decide cream-veil vs warm hairline

`modules/pill/Pill.qml` lines 617–619 currently use `Theme.frameBorder`
(cream @ 0.10). The reference used `Theme.border`. Two coherent end-states:

- **Reference parity:** `border.color: Theme.border` (post Fix 1/2 it is a warm,
  visible hairline — the pill frame then matches its buttons).
- **Keep current design:** leave `Theme.frameBorder`, but *then* also fix the
  per-button rest-state borders to `Theme.frameBorder` so nothing inside shows
  the black token. (More churn; not recommended.)

### Fix 4 · No per-file border edits needed after Fix 1

The new Power profile-cycle tile (`Power.diff`, rest border `Theme.border`) and
all other rest-state borders self-heal once `Theme.border` is warm again. Keep
`kbFocus ? Theme.frameBorder : Theme.border` as-is.

---

## 6 · Per-file drift matrix (from `/tmp/audit/`)

| File | Drift |
|---|---|
| `Appearance.diff` | Removed reference avatar-ring border (`Theme.cream`, 2.5px) and a `Theme.border` frame in the popup tier wiring. |
| `Pill.diff` | Body border `Theme.border` → `Theme.frameBorder` (lines 226→251); pill outline + top highlight comment; niri layer shadow. |
| `Power.diff` | New power-profile cycle tile — rest border `Theme.border`, hover `Theme.frameBorder`; new Hibernate action (snowflake glyph). |
| `Media.diff` | Skip buttons gained 1px `Theme.border` outlines on hover (new affordance; fine once border is warm). |
| `Link/Mixer/Calendar/Clipboard/SearchField/DisplayLabel…` | Kanji → latin glyph removal, mute UX, etc. — no border-token logic changes. |

---

## 7 · Verification plan

1. Re-run the palette (Fix 1 applies first):
   ```sh
   python3 /home/yemi/.config/quickshell/scripts/dominance-engine.py \
     /home/yemi/Pictures/Wallpapers/wallhaven-k8l167.webp
   ```
   → expect `dark.outline_variant` ≠ `#080302`, and `dark.outline` ≠ `dark.outline_variant`.
2. Confirm `G-dark-vs-light` acceptance passes (Option A) or is deliberately
   relaxed (Option B), exit code 0.
3. Relaunch quickshell; screenshot the pill hovered + settings/power buttons.
   Borders should read as *warm* edges (≈`#1a110c`-family on this wallpaper)
   or, with Option B, light warm hairlines — never black.
4. Toggle `paletteMode: static` → border should become `#3a2a22` (warm brown),
   matching the Ricelin static fallback exactly.
5. Sanity: `yemiFaint`/`yemiDim` text still pass `ensureReadable` after engine
   changes (they re-raise outline tokens for text contrast).

---

## 8 · Appendix — numbers

- `#080302` → HLS `L ≈ 0.020` (the engine floor), relative luminance ≈ 0.0018.
- `#2b110c` (surface) → HLS `L ≈ 0.108`, rel. luminance ≈ 0.0097.
- Contrast surface-vs-outline now: **≈ 1.15 : 1** (imperceptible → "blobby" black line).
- Ricelin static fallback `#3a2a22` → HLS `L ≈ 0.180`, rel. luminance ≈ 0.027,
  warm hue: **≈ 1.3 : 1** (deliberate quiet frame).
- Ricelin dynamic `outline_variant` (dark base+0.225) → `L ≈ 0.27`: clearly
  visible *warm* hairline, the intended look.