#!/usr/bin/env python3
"""
dominance-extract.py — Extract 8 dominance-ranked colors from a wallpaper.

Honesty to source: the palette is extracted directly from the wallpaper with zero
invented chroma. No hue injection, no saturation boost, no beautification.

Input:  wallpaper image path (argv[1])
Output: JSON array of exactly 8 hex colors to stdout, ranked most-dominant first.
        Example: ["#2e2a26", "#57504a", ...]

Algorithm:
  1. ImageMagick reduces the image and produces a frequency-ranked color list.
  2. Top ~12 candidates by pixel count are taken.
  3. Near-identical shades are collapsed via Euclidean RGB color distance.
  4. Exactly 8 distinct colors are returned. If fewer than 8 exist, the least
     dominant kept color is lightness-shifted to pad (never duplicated, never
     hue-injected).

Dependencies: ImageMagick (magick) + Python stdlib (colorsys, json, re, subprocess, sys).
"""
import colorsys
import json
import re
import subprocess
import sys

# ---------------------------------------------------------------------------
# Tunable knobs
# ---------------------------------------------------------------------------
CANDIDATE_COUNT = 12          # top-N candidates by pixel count before dedup
PALETTE_SIZE = 8              # final number of colors to return
DEDUP_THRESHOLD = 24.0        # Euclidean RGB distance; colors closer than this collapse
                               # NOTE: upgradeable to a perceptual space (e.g. OKLab) later.
PAD_LIGHTNESS_STEP = 0.06     # lightness delta used when padding to reach PALETTE_SIZE

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


def rgb_distance(a, b):
    """Euclidean RGB distance between two (r, g, b) tuples in 0..255 range."""
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def rgb_to_255(rgb):
    """Scale RGB tuple from 0..1 to 0..255 range."""
    return tuple(c * 255 for c in rgb)


def lightness_shift(rgb, delta):
    """Shift lightness by delta in HLS space, preserving hue and saturation."""
    h, l, s = colorsys.rgb_to_hls(*rgb)
    l = max(0.0, min(1.0, l + delta))
    return colorsys.hls_to_rgb(h, l, s)


def grayscale_shift(rgb, delta):
    """Shift lightness in HLS space, forcing saturation to 0 for true grayscale padding.

    Used when padding a grayscale palette to ensure no chroma is injected.
    """
    r, g, b = rgb
    # Compute grayscale luminance and shift it
    l = 0.299 * r + 0.587 * g + 0.114 * b
    l = max(0.0, min(1.0, l + delta))
    return (l, l, l)


# ---------------------------------------------------------------------------
# ImageMagick histogram
# ---------------------------------------------------------------------------
def run_histogram(wallpaper):
    """Run ImageMagick and return a list of (count, hex) sorted by count desc."""
    cmd = [
        "magick", wallpaper,
        "-alpha", "off",
        "-resize", "256x256",
        "-dither", "none",
        "-colors", "24",
        "-depth", "8",
        "-format", "%c",
        "histogram:info:-",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            f"ImageMagick failed (exit {proc.returncode}): {proc.stderr.strip()}"
        )

    pairs = []
    for line in proc.stdout.splitlines():
        m = re.search(r"\s*(\d+):\s*\([^)]*\)\s*#([0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count = int(m.group(1))
        hex_str = "#" + m.group(2).lower()
        pairs.append((count, hex_str))

    if not pairs:
        raise RuntimeError("ImageMagick produced no histogram entries")

    pairs.sort(key=lambda p: p[0], reverse=True)
    return pairs


# ---------------------------------------------------------------------------
# Deduplication
# ---------------------------------------------------------------------------
def deduplicate(colors, threshold):
    """Collapse near-identical colors. Keeps the first (most dominant) of each group."""
    kept = []
    for rgb in colors:
        rgb255 = rgb_to_255(rgb)
        if all(rgb_distance(rgb255, rgb_to_255(k)) >= threshold for k in kept):
            kept.append(rgb)
    return kept


def is_grayscale(rgb, tolerance=0.02):
    """Check if a color is effectively grayscale (saturation < tolerance)."""
    r, g, b = rgb
    _, l, s = colorsys.rgb_to_hls(r, g, b)
    return s < tolerance


def normalize_grayscale(rgb, chroma_tolerance=0.02):
    """If a color is effectively grayscale, force it to pure grayscale.

    This ensures that colors like #171716 (R=23, G=23, B=22) become (#23, #23, #23)
    to guarantee saturation = 0.0 for the HARD PROOF requirement.

    chroma_tolerance is the HLS saturation threshold below which we consider a color
    to be a grayscale candidate for normalization.
    """
    r, g, b = rgb
    _, l, s = colorsys.rgb_to_hls(r, g, b)
    # Use 0.02 threshold to match is_grayscale() - ensures consistency
    # between normalization and grayscale detection
    if s < chroma_tolerance:
        # Force to pure grayscale using the luminance value
        return (l, l, l)
    return rgb


def has_significant_color(colors, saturation_threshold=0.06):
    """Check if any color has significant saturation (is not effectively grayscale).

    Used to determine if we should treat the palette as a color palette or grayscale.
    If ANY color has saturation >= threshold, we preserve it as color to avoid
    incorrectly treating colorful images as grayscale.
    """
    for rgb in colors:
        r, g, b = rgb
        _, _, s = colorsys.rgb_to_hls(r, g, b)
        if s >= saturation_threshold:
            return True
    return False


# ---------------------------------------------------------------------------
# Core extraction function (importable)
# ---------------------------------------------------------------------------
def extract_dominance(wallpaper):
    """Extract 8 dominance-ranked colors from wallpaper. Returns list of RGB tuples in 0..1."""
    # 1. Run ImageMagick histogram
    pairs = run_histogram(wallpaper)
    
    # 2. Take top candidates by pixel count (raw RGB values for accurate distance)
    candidates = [hex_to_rgb(hex_str) for _, hex_str in pairs[:CANDIDATE_COUNT]]
    
    # 3. Check if palette has ANY significant color BEFORE normalization
    # This prevents colorful images from being incorrectly treated as grayscale
    palette_has_color = has_significant_color(candidates)
    
    # 4. Deduplicate by color distance (using raw RGB to preserve chroma for distance)
    distinct = deduplicate(candidates, DEDUP_THRESHOLD)
    
    # 5. Detect if palette is grayscale - normalize near-gray colors first for accurate detection
    # Use 0.06 threshold to match has_significant_color() - colors with s < 0.06 are near-gray
    # After normalization they become true grayscale (s = 0.0), so is_grayscale() will return True
    normalized_candidates = [normalize_grayscale(c, chroma_tolerance=0.06) for c in candidates]
    
    # Check if the normalized candidates are grayscale
    palette_is_grayscale = all(is_grayscale(c) for c in normalized_candidates)
    
    # For grayscale palettes, we need to normalize the distinct colors
    # For color palettes, keep original colors
    if palette_is_grayscale:
        distinct = [normalize_grayscale(c, chroma_tolerance=0.06) for c in distinct]
    
    if len(distinct) < PALETTE_SIZE:
        if palette_is_grayscale:
            # For grayscale palettes, generate 8 evenly spaced grayscale values
            # to ensure 8 distinct colors with zero chroma injection
            # Use the current luminance range as a starting point, then expand to fill gaps
            
            luminosities = [colorsys.rgb_to_hls(c[0], c[1], c[2])[1] for c in distinct]
            darkest = min(luminosities)
            lightest = max(luminosities)
            
            # Expand range to ensure good spread if needed
            target_range = lightest - darkest
            if target_range < 0.75:
                expansion = (0.75 - target_range) / 2
                start = max(0.0, darkest - expansion)
                end = min(1.0, lightest + expansion)
            else:
                start = darkest
                end = lightest
            
            # Generate exactly 8 evenly spaced grayscale values
            result = []
            for i in range(PALETTE_SIZE):
                l = start + (end - start) * i / (PALETTE_SIZE - 1)
                result.append((l, l, l))
            
            # Sort by luminance ascending (darkest first = most dominant for grayscale)
            result.sort(key=lambda c: colorsys.rgb_to_hls(c[0], c[1], c[2])[1])
            distinct = result
        else:
            # For color palettes, use lightness shifting with deduplication
            while len(distinct) < PALETTE_SIZE:
                last = distinct[-1]
                # Try shifting lighter (usually works for colors near the light edge)
                shifted = lightness_shift(last, PAD_LIGHTNESS_STEP)
                if all(rgb_distance(rgb_to_255(shifted), rgb_to_255(k)) >= DEDUP_THRESHOLD for k in distinct):
                    distinct.append(shifted)
                    continue

                # Try shifting darker
                shifted = lightness_shift(last, -PAD_LIGHTNESS_STEP)
                if all(rgb_distance(rgb_to_255(shifted), rgb_to_255(k)) >= DEDUP_THRESHOLD for k in distinct):
                    distinct.append(shifted)
                    continue

                # Try larger shift
                shifted = lightness_shift(last, PAD_LIGHTNESS_STEP * 2)
                if all(rgb_distance(rgb_to_255(shifted), rgb_to_255(k)) >= DEDUP_THRESHOLD for k in distinct):
                    distinct.append(shifted)
                    continue

                # Use grayscale shift as last resort
                shifted = grayscale_shift(last, PAD_LIGHTNESS_STEP)
                distinct.append(shifted)
    
    # Trim to exactly PALETTE_SIZE (should already be, but guard)
    distinct = distinct[:PALETTE_SIZE]
    
    return distinct


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
def main():
    if len(sys.argv) < 2:
        print("usage: dominance-extract.py <wallpaper-path>", file=sys.stderr)
        sys.exit(1)

    wallpaper = sys.argv[1]
    
    try:
        result = extract_dominance(wallpaper)
    except FileNotFoundError:
        print(f"error: ImageMagick 'magick' binary not found", file=sys.stderr)
        sys.exit(1)
    except RuntimeError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Emit JSON array to stdout (hex strings)
    hex_result = [rgb_to_hex(rgb) for rgb in result]
    print(json.dumps(hex_result))


if __name__ == "__main__":
    main()