#!/usr/bin/env python3
"""
dominance-engine.py — Phase 2: Derivation Engine (mapping + dark/light + hue-preserving contrast).

Consumes scripts/dominance-extract.py (imported, not re-implemented) to obtain the 8
dominance-ranked RGB colors of a wallpaper, then derives the FULL colors.json token set
for BOTH dark and light moods with hue-preserving contrast.

Role mapping (locked — most-dominant is the anchor):
    Dominant 1 -> surface base family (surface, surface_container_lowest..highest)
    Dominant 2 -> primary (+ primary_container, on_primary, on_primary_container)
    Dominant 3 -> secondary (+ secondary_container)
    Dominant 4 -> tertiary  (+ tertiary_container)
    Dominant 5 -> supporting accent    (reserved — no colors.json slot)
    Dominant 6 -> supporting accent    (reserved — no colors.json slot)
    Dominant 7 -> pop / highlight      (reserved — no colors.json slot)
    Dominant 8 -> error family (error, on_error, error_container, on_error_container)

THE HUE RULE: hue and saturation of a source dominant are held CONSTANT. Only lightness
varies to meet a contrast target. No chroma is ever invented.

Dark and light both derive from the SAME 8 dominants; the two blocks differ by lightness
treatment only, never by hue.

Input : wallpaper path (argv[1])
Output: colors.json-compatible JSON to stdout (pure JSON — no diagnostics on stdout).
        Diagnostics / acceptance checks (PASS/FAIL) go to stderr.
Exit  : 0 when all acceptance checks pass, 1 otherwise.

Dependencies: Python stdlib (colorsys, importlib, json, os, sys) + ImageMagick (via the
extractor). No pip installs.
"""
import colorsys
import importlib.util
import json
import os
import sys

# ---------------------------------------------------------------------------
# Tunable knobs
# ---------------------------------------------------------------------------
TEXT_CONTRAST = 4.5    # WCAG AA text target
ACCENT_CONTRAST = 3.0  # accent-on-surface target
NEUTRAL_SATURATION = 0.06  # grayscale tolerance (matches extractor's normalize_grayscale)

# Fixed readable error red fallback — used ONLY when the palette is colorful but
# Dominant 8 is too neutral to serve as the error accent. (On genuinely grayscale
# wallpapers we never inject chroma, so the error family stays grayscale.)
ERROR_FALLBACK_DARK = {
    "error":               "#ffb4ab",
    "on_error":            "#690005",
    "error_container":     "#93000a",
    "on_error_container":  "#ffdad6",
}
ERROR_FALLBACK_LIGHT = {
    "error":               "#ba1a1a",
    "on_error":            "#ffffff",
    "error_container":     "#ffdad6",
    "on_error_container":  "#410002",
}

# ---------------------------------------------------------------------------
# Schema (exact key set of ~/.cache/yemi-shell/colors.json, both moods)
# ---------------------------------------------------------------------------
SCHEMA_KEYS = [
    "primary",
    "on_primary",
    "primary_container",
    "on_primary_container",
    "secondary",
    "secondary_container",
    "tertiary",
    "tertiary_container",
    "surface",
    "surface_container_lowest",
    "surface_container_low",
    "surface_container",
    "surface_container_high",
    "surface_container_highest",
    "on_surface",
    "on_surface_variant",
    "outline",
    "outline_variant",
    "inverse_surface",
    "inverse_on_surface",
    "error",
    "on_error",
    "error_container",
    "on_error_container",
]

SCHEMA_KEYS = list(SCHEMA_KEYS)


# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
def hex_to_rgb(hex_str):
    """'#rrggbb' -> (r, g, b) floats in 0..1."""
    return tuple(int(hex_str[i:i + 2], 16) / 255.0 for i in (1, 3, 5))


def rgb_to_hex(rgb):
    """(r, g, b) floats in 0..1 -> '#rrggbb'."""
    return "#{:02x}{:02x}{:02x}".format(
        max(0, min(255, round(rgb[0] * 255))),
        max(0, min(255, round(rgb[1] * 255))),
        max(0, min(255, round(rgb[2] * 255))),
    )


def rgb_to_hls(rgb):
    """(r,g,b) -> (h, l, s). colorsys order: (h, l, s)."""
    return colorsys.rgb_to_hls(*rgb)


def hls_to_rgb(h, l, s):
    """(h, l, s) -> (r,g,b). colorsys order: (h, l, s)."""
    return colorsys.hls_to_rgb(h, l, s)


def clamp01(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def linearize_srgb(c):
    """sRGB component -> linear RGB (WCAG)."""
    c = clamp01(c)
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb):
    """WCAG relative luminance of an (r,g,b) tuple in 0..1."""
    r, g, b = (linearize_srgb(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(rgb1, rgb2):
    """WCAG contrast ratio between two RGB colors (>= 1.0)."""
    l1, l2 = relative_luminance(rgb1), relative_luminance(rgb2)
    if l1 < l2:
        l1, l2 = l2, l1
    return (l1 + 0.05) / (l2 + 0.05)


def is_grayscale(rgb, tolerance=0.02):
    _, _, s = rgb_to_hls(rgb)
    return s < tolerance


def hue_delta_deg(h1, h2):
    """Minimal angular distance between two HLS hues in degrees (0..180)."""
    d = abs(h1 - h2)
    if d > 0.5:
        d = 1.0 - d
    return d * 360.0


# ---------------------------------------------------------------------------
# Hue-preserving contrast machinery
# ---------------------------------------------------------------------------
def ensure_contrast(fg, bg, target):
    """Vary fg's L only (hold H and S constant) until contrast >= target vs bg.

    Direction: lighten if the surface is dark, darken if the surface is light.
    Iterate until ratio >= target or L hits a boundary.
    """
    if contrast_ratio(fg, bg) >= target:
        return fg
    h, l, s = rgb_to_hls(fg)
    direction = 1.0 if relative_luminance(bg) < 0.5 else -1.0
    step = 0.02
    for _ in range(60):
        l = clamp01(l + direction * step)
        cand = hls_to_rgb(h, l, s)
        if contrast_ratio(cand, bg) >= target:
            return cand
        if (direction > 0 and l >= 1.0) or (direction < 0 and l <= 0.0):
            break
    return hls_to_rgb(h, 1.0 if direction > 0 else 0.0, s)


def set_luminance(rgb, target_lum, direction):
    """Vary L only (hold H, S) until relative luminance meets target_lum.

    direction: +1 raise luminance, -1 lower it. Stops at boundary.
    """
    h, l, s = rgb_to_hls(rgb)
    for _ in range(60):
        cand = hls_to_rgb(h, l, s)
        cur = relative_luminance(cand)
        if (direction > 0 and cur >= target_lum) or (direction < 0 and cur <= target_lum):
            return cand
        l = clamp01(l + direction * 0.02)
    return hls_to_rgb(h, 1.0 if direction > 0 else 0.0, s)


def text_on(bg, target=TEXT_CONTRAST, variant=False):
    """Readable text against bg, carrying bg's hue (L only differs, H/S held).

    Picks the light or dark edge that meets `target`; variant backs off one step
    toward a dimmer (but still passing) value so on_surface_variant reads as a
    slightly lower-priority text tone.
    """
    h, _, s = rgb_to_hls(bg)

    def mk(l):
        return hls_to_rgb(h, l, s)

    dark_l = 0.10 if variant else 0.03
    light_l = 0.90 if variant else 0.97
    if contrast_ratio(mk(dark_l), bg) >= target:
        return mk(dark_l)
    if contrast_ratio(mk(light_l), bg) >= target:
        return mk(light_l)
    # Safety net (should not trigger for our derived tokens): use stronger edge.
    d = contrast_ratio(mk(0.03), bg)
    w = contrast_ratio(mk(0.97), bg)
    return mk(0.03) if d >= w else mk(0.97)


def readable_accent(acc, surface, mood):
    """Hue/sat of `acc` held; adjust L so the accent:
       - meets ACCENT_CONTRAST vs `surface`, and
       - supports a readable text pair at TEXT_CONTRAST on some edge.
    """
    h, _, s = rgb_to_hls(acc)
    if mood == "dark":
        cand = hls_to_rgb(h, 0.72, s)
        if contrast_ratio(cand, surface) < ACCENT_CONTRAST:
            cand = ensure_contrast(cand, surface, ACCENT_CONTRAST)
        # Black-text edge must be achievable:
        black = hls_to_rgb(h, 0.03, s)
        need = TEXT_CONTRAST * (relative_luminance(black) + 0.05) - 0.05
        if relative_luminance(cand) < need:
            cand = set_luminance(cand, need, +1)
        return cand

    cand = hls_to_rgb(h, 0.42, s)
    if contrast_ratio(cand, surface) < ACCENT_CONTRAST:
        cand = ensure_contrast(cand, surface, ACCENT_CONTRAST)
    # White-text edge must be achievable:
    white = hls_to_rgb(h, 0.97, s)
    cap = (relative_luminance(white) + 0.05) / TEXT_CONTRAST - 0.05
    if relative_luminance(cand) > cap:
        cand = set_luminance(cand, cap, -1)
    return cand


# ---------------------------------------------------------------------------
# Consumption of the extractor
# ---------------------------------------------------------------------------
def load_extractor():
    """Import scripts/dominance-extract.py cleanly (no subprocess, no re-implementation)."""
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "dominance-extract.py")
    spec = importlib.util.spec_from_file_location("dominance_extract", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------------------
# Schema reference
# ---------------------------------------------------------------------------
def load_reference_keys():
    """The EXACT key set currently used by ~/.cache/yemi-shell/colors.json.

    Falls back to SCHEMA_KEYS if the cache file is unavailable.
    """
    path = os.path.expanduser("~/.cache/yemi-shell/colors.json")
    try:
        with open(path) as f:
            data = json.load(f)
        dk = list(data["dark"].keys())
        lk = list(data["light"].keys())
        if dk == lk and len(dk) == len(SCHEMA_KEYS):
            return dk
    except Exception:
        pass
    return list(SCHEMA_KEYS)


# ---------------------------------------------------------------------------
# Block derivation
# ---------------------------------------------------------------------------
def derive_block(dominance, mood, use_error_fallback):
    """Derive one mood's 24-token block from the 8 dominants (RGB 0..1)."""
    d1, d2, d3, d4, d5, d6, d7, d8 = dominance
    # d5 / d6 = supporting accents, d7 = pop/highlight: reserved for the supporting
    # roles (Phase 4 terminal/hypr outputs). colors.json has no slots for them.
    block = {}

    h1, l1, s1 = rgb_to_hls(d1)

    # ---- Surface family: lightness steps of Dominant 1 (mood-dependent) ----
    if mood == "dark":
        anchor = clamp01(l1 * 0.4, 0.02, 0.25)          # near-black, tinted by d1
        ramp = {
            "surface_container_lowest": anchor - 0.04,
            "surface":                 anchor,
            "surface_container_low":   anchor + 0.02,
            "surface_container":       anchor + 0.04,
            "surface_container_high":  anchor + 0.07,
            "surface_container_highest": anchor + 0.10,
        }
    else:
        anchor = clamp01(0.88 + (1.0 - l1) * 0.14, 0.75, 0.97)   # near-white, tinted
        ramp = {
            "surface_container_lowest": anchor + 0.05,
            "surface":                 anchor,
            "surface_container_low":   anchor - 0.03,
            "surface_container":       anchor - 0.05,
            "surface_container_high":  anchor - 0.08,
            "surface_container_highest": anchor - 0.11,
        }
    for token, lv in ramp.items():
        block[token] = hls_to_rgb(h1, clamp01(lv, 0.02, 0.98), s1)

    surface = block["surface"]

    # ---- Text on surface (subtle tint of d1's hue, pushed to meet contrast) ----
    block["on_surface"] = text_on(surface)
    block["on_surface_variant"] = text_on(surface, variant=True)

    # ---- Outlines (subtle decorative frames — lighter than surface, BOTH moods) ----
    # Ricelin wallcolors parity: dark outline_variant ≈ base + 0.225 → a warm tan
    # hairline ABOVE the surface (L ≈ 0.25–0.31); light stays near-white.
    # History: the original absolute 0.02 lightness floor collapsed BOTH dark
    # tokens to #080302 (the "black hairline" bug); interim Option A used
    # darker-than-surface with surface-proportional floors. Both superseded.
    # Dark/light outline lightness deliberately converges → these two keys are
    # exempt from the G same-lightness check (decorative frames, not text).
    ol = clamp01(anchor + 0.10, 0.02, 0.98)
    olv = clamp01(anchor + 0.20, 0.02, 0.98)
    block["outline"] = hls_to_rgb(h1, ol, s1)
    block["outline_variant"] = hls_to_rgb(h1, olv, s1)

    # ---- Inverse pair (opposite lightness of surface/on_surface) ----
    inv_l = 0.93 if mood == "dark" else 0.10
    inv = hls_to_rgb(h1, inv_l, s1)
    block["inverse_surface"] = inv
    block["inverse_on_surface"] = text_on(inv)

    # ---- Role accents (d2 -> primary, d3 -> secondary, d4 -> tertiary) ----
    def role_tokens(acc_rgb):
        h, _, s = rgb_to_hls(acc_rgb)
        accent = readable_accent(acc_rgb, surface, mood)
        on_accent = text_on(accent)
        container = hls_to_rgb(h, 0.30 if mood == "dark" else 0.74, s)
        on_container = text_on(container)
        return accent, on_accent, container, on_container

    p, op, pc, opc = role_tokens(d2)
    block["primary"] = p
    block["on_primary"] = op
    block["primary_container"] = pc
    block["on_primary_container"] = opc

    sec, _, sec_c, _ = role_tokens(d3)
    block["secondary"] = sec
    block["secondary_container"] = sec_c

    ter, _, ter_c, _ = role_tokens(d4)
    block["tertiary"] = ter
    block["tertiary_container"] = ter_c

    # ---- Error family (d8 -> error accent; fallback red only if palette colorful
    #      AND d8 neutral — never on genuinely grayscale wallpapers) ----
    h8, _, s8 = rgb_to_hls(d8)
    if use_error_fallback:
        fb = ERROR_FALLBACK_DARK if mood == "dark" else ERROR_FALLBACK_LIGHT
        for token, hexv in fb.items():
            block[token] = hex_to_rgb(hexv)
    else:
        error = readable_accent(d8, surface, mood)
        block["error"] = error
        block["on_error"] = text_on(error)
        ec = hls_to_rgb(h8, 0.28 if mood == "dark" else 0.76, s8)
        block["error_container"] = ec
        block["on_error_container"] = text_on(ec)

    return block


def derive_scheme(dominance):
    """Derive (dark, light) blocks from the same 8 dominants."""
    palette_colorful = any(rgb_to_hls(c)[2] >= NEUTRAL_SATURATION for c in dominance)
    d8_neutral = rgb_to_hls(dominance[7])[2] < NEUTRAL_SATURATION
    use_error_fallback = palette_colorful and d8_neutral
    dark = derive_block(dominance, "dark", use_error_fallback)
    light = derive_block(dominance, "light", use_error_fallback)
    return dark, light, use_error_fallback


# ---------------------------------------------------------------------------
# Acceptance checks (A–G; H is exercised by running on extra wallpapers)
# ---------------------------------------------------------------------------
def verify(dominance, dark, light, ref_keys, use_error_fallback):
    ok = True

    def report(name, passed, detail=""):
        nonlocal ok
        flag = "PASS" if passed else "FAIL"
        print(f"[{flag}] {name} {detail}".rstrip(), file=sys.stderr)
        if not passed:
            ok = False

    moods = {"dark": dark, "light": light}

    # A. Schema match
    for mood in ("dark", "light"):
        keys = sorted(moods[mood].keys())
        report(f"A-schema-{mood}",
               keys == sorted(ref_keys),
               f"({len(keys)} keys, exact match against colors.json)")

    palette_colorful = any(rgb_to_hls(c)[2] >= NEUTRAL_SATURATION for c in dominance)

    # B. B&W canary: NO chroma anywhere on a grayscale wallpaper
    if palette_colorful:
        report("B-bw-canary", True, "SKIP — colorful wallpaper (canary not applicable)")
    else:
        max_s = max(rgb_to_hls(v)[2] for block in moods.values() for v in block.values())
        report("B-bw-canary", max_s < 0.02, f"max saturation across tokens = {max_s:.4f}")

    # C. Colorful: valid blocks + accents carry real chroma
    if palette_colorful:
        accent_toks = ("primary", "secondary", "tertiary",
                       "primary_container", "secondary_container", "tertiary_container")
        chroma = any(rgb_to_hls(v)[2] > 0.02
                     for block in moods.values()
                     for k, v in block.items() if k in accent_toks)
        report("C-colorful", chroma, "accents carry real chroma")

    # D. Text contrast >= 4.5 vs the relevant surface
    text_pairs = (
        ("on_surface", "surface"),
        ("on_surface_variant", "surface"),
        ("on_primary", "primary"),
        ("on_primary_container", "primary_container"),
        ("on_error", "error"),
        ("on_error_container", "error_container"),
        ("inverse_on_surface", "inverse_surface"),
    )
    fails = []
    for mood, block in moods.items():
        for tok, bg in text_pairs:
            r = contrast_ratio(block[tok], block[bg])
            if r < TEXT_CONTRAST - 1e-9:
                fails.append(f"{mood}.{tok}={r:.2f}")
    report("D-text-contrast", not fails, "" if not fails else "below 4.5: " + ", ".join(fails))

    # E. Accent contrast >= 3.0 vs surface
    fails = []
    for mood, block in moods.items():
        for tok in ("primary", "secondary", "tertiary"):
            r = contrast_ratio(block[tok], block["surface"])
            if r < ACCENT_CONTRAST - 1e-9:
                fails.append(f"{mood}.{tok}={r:.2f}")
    report("E-accent-contrast", not fails, "" if not fails else "below 3.0: " + ", ".join(fails))

    # F. Hue preservation vs source dominants (< 2 degrees)
    sources = {"primary": dominance[1], "secondary": dominance[2], "tertiary": dominance[3]}
    deltas = []
    f_ok = True
    for tok, src in sources.items():
        for mood, block in moods.items():
            delta = hue_delta_deg(rgb_to_hls(block[tok])[0], rgb_to_hls(src)[0])
            deltas.append(f"{mood}.{tok}={delta:.1f}\u00b0")
            if delta >= 2.0:
                f_ok = False
    d8_neutral = rgb_to_hls(dominance[7])[2] < NEUTRAL_SATURATION
    if not d8_neutral:
        for mood, block in moods.items():
            delta = hue_delta_deg(rgb_to_hls(block["error"])[0], rgb_to_hls(dominance[7])[0])
            deltas.append(f"{mood}.error={delta:.1f}\u00b0")
            if delta >= 2.0:
                f_ok = False
    report("F-hue-preservation", f_ok, "hue deltas: " + ", ".join(deltas))

    # G. Dark vs light: tokens differ by HLS lightness; accent hue unchanged
    # Compare HLS lightness (the L value used for hue-preserving contrast).
    # outline / outline_variant are EXEMPT: they are decorative frames, lighter
    # than the surface in BOTH moods by design (Ricelin wallcolors parity), so
    # their dark/light lightness legitimately converges.
    outline_exempt = ("outline", "outline_variant")
    same_l = [k for k in ref_keys
              if k not in outline_exempt
              and abs(rgb_to_hls(dark[k])[1] - rgb_to_hls(light[k])[1]) < 0.02]
    accent_toks = ("primary", "on_primary", "primary_container", "on_primary_container",
                   "secondary", "secondary_container", "tertiary", "tertiary_container")
    hue_drift = [f"{k}={hue_delta_deg(rgb_to_hls(dark[k])[0], rgb_to_hls(light[k])[0]):.1f}\u00b0"
                 for k in accent_toks
                 if hue_delta_deg(rgb_to_hls(dark[k])[0], rgb_to_hls(light[k])[0]) >= 2.0]
    if not use_error_fallback:
        dh = hue_delta_deg(rgb_to_hls(dark["error"])[0], rgb_to_hls(light["error"])[0])
        if dh >= 2.0:
            hue_drift.append(f"error={dh:.1f}\u00b0")
    detail = ""
    if same_l:
        detail = "same-lightness tokens: " + ", ".join(same_l)
    if hue_drift:
        detail += ("; " if detail else "") + "hue drift: " + ", ".join(hue_drift)
    report("G-dark-vs-light", not same_l and not hue_drift, detail)

    return ok


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main():
    if len(sys.argv) < 2:
        print("usage: dominance-engine.py <wallpaper-path>", file=sys.stderr)
        sys.exit(2)

    wallpaper = sys.argv[1]
    ref_keys = load_reference_keys()
    print(f"Schema keys matched against colors.json ({len(ref_keys)}): "
          + ", ".join(ref_keys), file=sys.stderr)

    try:
        extractor = load_extractor()
        dominance = extractor.extract_dominance(wallpaper)   # list of 8 RGB tuples
    except FileNotFoundError:
        print("error: ImageMagick 'magick' binary not found (needed by the extractor)",
              file=sys.stderr)
        sys.exit(1)
    except RuntimeError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

    if len(dominance) != 8:
        print(f"error: extractor returned {len(dominance)} colors, expected 8",
              file=sys.stderr)
        sys.exit(1)

    dark, light, use_error_fallback = derive_scheme(dominance)
    ok = verify(dominance, dark, light, ref_keys, use_error_fallback)

    # Order output keys exactly as the live colors.json schema.
    dark_out = {k: rgb_to_hex(dark[k]) for k in ref_keys}
    light_out = {k: rgb_to_hex(light[k]) for k in ref_keys}

    output = {
        "version": 2,
        "generator": "dominance",
        "wallpaper": wallpaper,
        "seed": rgb_to_hex(dominance[0]),
        "scheme_type": "scheme-content",
        "dark": dark_out,
        "light": light_out,
    }

    sys.stdout.write(json.dumps(output) + "\n")
    sys.stdout.flush()
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()