#!/usr/bin/env python3
"""
Theme engine — dark-mode-only, semantic-only.

Pipeline (contract-first):
  Stage 1  Analyze  — detect every meaningful color family in the wallpaper.
  Stage 2  Assign   — rule-based resource allocation of families to semantic
                      roles (surface, accent, attention). Content & accents are
                      generated as tints of the assigned family.
  Stage 3  Generate — emit the per-role shade variants the UI consumes.
  Stage 4  Write    — colors.json + terminal palette + downstream callers.

Semantic contract (output keys, read by Dyn.qml / Theme.qml):
  surface, surfaceLow, surfaceHigh, surfaceHighest,
  accent, accentSoft, accentHover,
  content, contentMuted, contentDim, contentFaint,
  attention, border, icon, tick

Architectural principle: the semantic contract is stable; the extraction and
assignment algorithms are expected to evolve over time without requiring
changes to the UI. Scoring here is intentionally minimal (population +
saturation) so the algorithm can be replaced in isolation later.
"""
import colorsys
import json
import subprocess
import sys
import re
from pathlib import Path

CACHE = Path.home() / ".cache" / "yemi-shell"

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 — Analysis
# ─────────────────────────────────────────────────────────────────────────────
HUE_BUCKETS = 12  # 30deg each, around the wheel


def analyze(wallpaper):
    """Return (families, mean_l).

    families: list of dicts with hue, sat, light, population, wsat. Sorted by
    weighted saturation (population * saturation) descending. Each represents a
    30deg hue bucket's most characteristic color. Families below a small
    population threshold are pruned — the engine adapts to the wallpaper rather
    than targeting a fixed count.
    """
    out = subprocess.run(
        ["magick", wallpaper, "-alpha", "off", "-resize", "200x200",
         "-colors", "96", "-format", "%c", "histogram:info:-"],
        capture_output=True, text=True).stdout
    buckets, total, lum, chroma = {}, 0, 0.0, 0
    for line in out.splitlines():
        m = re.search(r"\s*(\d+):\s*\([^)]*\)\s*#([0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count, hex_str = int(m.group(1)), m.group(2)
        r, g, b = (int(hex_str[i:i + 2], 16) / 255 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        total += count
        lum += count * l
        if s < 0.12 or l < 0.05 or l > 0.92:
            continue
        chroma += count
        bk = buckets.setdefault((int(h * 360) // 30) % HUE_BUCKETS,
                                {"wsat": 0.0, "pop": 0, "best": None})
        # weighted score pushes selection toward vivid, mid-light pixels
        score = count * s * (1 if 0.12 < l < 0.55 else 0.4)
        bk["wsat"] += count * s
        bk["pop"] += count
        if not bk["best"] or score > bk["best"][0]:
            bk["best"] = (score, h, s, l)
    mean_l = lum / total if total else 0.0
    if not buckets or chroma < 0.05 * total:
        return [], mean_l  # achromatic — surface stays neutral, no families

    families = []
    for bk in buckets.values():
        if not bk["best"] or bk["pop"] < 0.01 * total:
            continue  # adaptive threshold: drop sub-1% splinters
        _, h, s, l = bk["best"]
        families.append({"hue": h, "sat": s, "light": l,
                         "pop": bk["pop"], "wsat": bk["wsat"]})
    families.sort(key=lambda f: f["wsat"], reverse=True)
    return families, mean_l


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
def tint(hue, sat, light):
    r, g, b = colorsys.hls_to_rgb(hue % 1.0,
                                  max(0.0, min(1.0, light)),
                                  max(0.0, min(1.0, sat)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def lerp(x, x0, x1, y0, y1):
    t = max(0.0, min(1.0, (x - x0) / (x1 - x0)))
    return y0 + t * (y1 - y0)


def hue_distance(a, b):
    d = abs(a - b) % 1.0
    return min(d, 1.0 - d)


# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 — Assignment (resource allocator, rule-based, score-driven)
# ─────────────────────────────────────────────────────────────────────────────
def assign(families, mean_l):
    """Map families to the 3 wallpaper-driven roles (surface, accent, attention).

    Each family is consumed at most once. Rules (color-agnostic):
      surface    = largest visually stable family (population-weighted; favor
                   lower saturation so the dark body stays calm).
      accent     = highest visual energy among remaining (sat * pop).
      attention  = highest contrast remaining family; if none suitable,
                   derived from accent.

    Achromatic wallpapers yield nothing here; generate() builds a neutral theme.
    """
    if not families:
        return {"surface": None, "accent": None, "attention": None, "mean_l": mean_l}

    pool = list(families)
    roles = {}

    # Surface: the family with the greatest visual mass. Mass leans on
    # population but damps saturation so a small vivid family doesn't outrank
    # a huge calm one. The saturation penalty is mild: a vivid dominant family
    # (like a deep blue that covers the wallpaper) still wins — the surface is
    # darkened and desaturated at generate() time, not at assignment time.
    def mass(f):
        return f["pop"] * (1.0 - 0.35 * f["sat"])

    surface = max(pool, key=mass)
    roles["surface"] = surface
    pool = [f for f in pool if f is not surface]

    # Accent: highest visual energy among remaining
    accent = max(pool, key=lambda f: f["wsat"])
    roles["accent"] = accent
    pool = [f for f in pool if f is not accent]

    # Attention: highest `sat * hue_distance_from_accent` among remaining
    # (most spectrally distinct family → strongest attention pull).
    if pool:
        attention = max(
            pool,
            key=lambda f: f["sat"] * (hue_distance(f["hue"], accent["hue"]) + 0.1),
        )
        roles["attention"] = attention
    else:
        roles["attention"] = None
    return roles


# ─────────────────────────────────────────────────────────────────────────────
# Stage 3 — Generate (per-role shade variants & derived tokens)
# ─────────────────────────────────────────────────────────────────────────────
# Generation is anchored on darkness. All surfaces are dark tints; all content
# is high-lightness so it stays readable on a dark body.

SURF_STEPS = [0.0, 0.022, 0.038, 0.065, 0.100]  # surface → surfaceHighest


def generate(roles, mean_l):
    """Produce the 15 semantic keys Dyn.qml expects."""
    surf = roles.get("surface")
    acc = roles.get("accent")
    att = roles.get("attention")

    # Neutral fallbacks — no brown dye injected on achromatic wallpapers.
    surf_h = surf["hue"] if surf else 0.0
    surf_s = min(surf["sat"], 0.30) if surf else 0.0
    acc_h = acc["hue"] if acc else surf_h
    acc_s = min(acc["sat"] + 0.18, 0.85) if acc else 0.0
    att_h = att["hue"] if att else acc_h
    att_s = min(att["sat"] + 0.10, 0.80) if att else (acc_s * 0.6 if acc else 0.0)

    # Dark base — anchored low; minor lerp from mean_l for atmospherics.
    base = lerp(mean_l if mean_l < 0.45 else 0.20, 0.0, 0.40, 0.045, 0.18)

    palette = {}
    # Surfaces
    palette["surface"] = tint(surf_h, surf_s, base + SURF_STEPS[0])
    palette["surfaceLow"] = tint(surf_h, surf_s, base + SURF_STEPS[1])
    palette["surfaceHigh"] = tint(surf_h, surf_s, base + SURF_STEPS[2])
    palette["surfaceHighest"] = tint(surf_h, surf_s, base + SURF_STEPS[3])

    # Accent ramp
    palette["accent"] = tint(acc_h, acc_s, 0.62)
    palette["accentSoft"] = tint(acc_h, min(acc_s - 0.20, 0.55), 0.30)
    palette["accentHover"] = tint(acc_h, max(acc_s - 0.35, 0.20), 0.80)

    # Content — text family. Very low saturation so text stays legible on dark
    # surfaces regardless of the surface hue. Lightness tiers map to the old
    # cream/subtle/dim/faint ladder.
    content_sat = min(surf_s * 0.8, 0.08)
    palette["content"] = tint(surf_h, content_sat, 0.90)
    palette["contentMuted"] = tint(surf_h, content_sat, 0.73)
    palette["contentDim"] = tint(surf_h, content_sat, 0.54)
    palette["contentFaint"] = tint(surf_h, content_sat, 0.44)
    palette["icon"] = tint(surf_h, content_sat + 0.02, 0.81)
    palette["tick"] = tint(surf_h, content_sat + 0.03, 0.75)

    # Outline / border
    palette["border"] = tint(surf_h, surf_s + 0.06, base + 0.18)

    # Attention (single emphasized role — brightness warn / DND / today cell)
    palette["attention"] = tint(att_h, att_s, 0.62)
    return palette


# ─────────────────────────────────────────────────────────────────────────────
# Terminal ANSI palette (internal) — uses top 3 families for syntax variety
# ─────────────────────────────────────────────────────────────────────────────
def build_ansi16(families, palette):
    bg = palette["surface"]
    bg_bright = palette["surfaceHighest"]
    fg = palette["content"]

    def pair(fam, lift=0.0):
        h = fam["hue"] if fam else 0.0
        s = min((fam["sat"] if fam else 0.0) + 0.20, 0.85)
        return tint(h, s, 0.50 + lift), tint(h, s, 0.65 + lift)

    f1 = families[0] if len(families) > 0 else None
    f2 = families[1] if len(families) > 1 else f1
    f3 = families[2] if len(families) > 2 else f2

    c1a, c1b = pair(f1)
    c2a, c2b = pair(f2)
    c3a, c3b = pair(f3)
    v1a, v1b = tint(f1["hue"], max(f1["sat"] - 0.1, 0.2), 0.35) if f1 else "#333333", "#cccccc"
    v2a, v2b = tint(f2["hue"], max(f2["sat"] - 0.1, 0.2), 0.35) if f2 else "#333333", "#cccccc"
    v3a, v3b = tint(f3["hue"], max(f3["sat"] - 0.1, 0.2), 0.35) if f3 else "#333333", "#cccccc"

    return {
        "term0": bg, "term1": c1a, "term2": c2a, "term3": c3a,
        "term4": v1a, "term5": v2a, "term6": v3a, "term7": fg,
        "term8": bg_bright, "term9": c1b, "term10": c2b, "term11": c3b,
        "term12": v1b, "term13": v2b, "term14": v3b, "term15": fg,
    }


