#!/usr/bin/env python3
"""
Generate the rice colour set from a wallpaper and fan it out to the consumers.
One histogram pass yields both the area-dominant chromatic hue (binned by hue
family so a small vivid accent never hijacks the theme) and the mean lightness.
The mean lightness drives the pill's whole tone: a bright wallpaper makes a light
pill with dark text, a dark or OLED-black one makes a near-black pill with cream
text, so the surfaces and the text flip together for contrast across the full
range. The dominant hue tints every tier in HSL. An achromatic wallpaper drops to
a neutral grey ramp. matugen still builds the dark base16 the always-dark terminal
reads; the pill JSON carries surfaces, accent and the contrast-matched text.
"""
import colorsys
import json
import re
import subprocess
import sys
from pathlib import Path

CACHE = Path.home() / ".cache" / "yemi-shell"

SURF_NAMES = ["surface", "surface_container_low", "surface_container",
              "surface_container_high", "surface_container_highest", "outline_variant"]
DARK_STEPS = [0.0, 0.022, 0.038, 0.065, 0.100, 0.225]
LIGHT_STEPS = [0.0, -0.045, -0.075, -0.115, -0.160, -0.340]
TEXT_KEYS = ["cream", "bright", "subtle", "dim", "faint", "icon_dim", "tick_rest"]
DARK_TEXT = [(0.90, 0.05), (0.97, 0.03), (0.73, 0.07), (0.54, 0.06),
             (0.44, 0.05), (0.81, 0.07), (0.75, 0.08)]
LIGHT_TEXT = [(0.20, 0.18), (0.10, 0.20), (0.36, 0.14), (0.48, 0.10),
              (0.56, 0.08), (0.28, 0.12), (0.34, 0.12)]


def analyze(wallpaper):
    out = subprocess.run(
        ["magick", wallpaper, "-alpha", "off", "-resize", "200x200", "-colors", "48",
         "-format", "%c", "histogram:info:-"],
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
        if s < 0.15 or l < 0.05 or l > 0.92:
            continue
        chroma += count
        bucket = buckets.setdefault((int(h * 360) // 30) % 12, {"wsat": 0.0, "best": None})
        bucket["wsat"] += count * s
        score = count * s * (1 if 0.12 < l < 0.55 else 0.4)
        if not bucket["best"] or score > bucket["best"][0]:
            bucket["best"] = (score, h, s)
    mean_l = lum / total if total else 0.0
    if not buckets or chroma < 0.08 * total:
        return None, 0.0, mean_l
    win = max(buckets.values(), key=lambda v: v["wsat"])
    return win["best"][1], win["best"][2], mean_l


def matugen(source_hex, mood="dark"):
    out = subprocess.run(
        ["matugen", "color", "hex", source_hex, "-m", mood, "-j", "hex"],
        capture_output=True, text=True, check=True,
    )
    return json.loads(out.stdout)


def tint(hue, sat, light):
    r, g, b = colorsys.hls_to_rgb(hue % 1.0, max(0.0, min(1.0, light)), max(0.0, min(1.0, sat)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def lerp(x, x0, x1, y0, y1):
    t = max(0.0, min(1.0, (x - x0) / (x1 - x0)))
    return y0 + t * (y1 - y0)


def main():
    mode = "dynamic"
    mood = "dark"
    wallpaper = None
    hue = None
    sat = None
    mean_l = None

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--mode" and i + 1 < len(args):
            mode = args[i + 1]
            i += 2
        elif args[i] == "--mood" and i + 1 < len(args):
            mood = args[i + 1]
            i += 2
        elif args[i] == "--hue" and i + 3 < len(args):
            hue = (float(args[i + 1]) % 360) / 360.0
            mood = args[i + 2]
            sat = float(args[i + 3])
            i += 4
        elif not args[i].startswith("-"):
            wallpaper = args[i]
            i += 1
        else:
            i += 1

    if mode == "static" and hue is None:
        hue, sat, mean_l = 0.09, 0.0, 0.12

    if mode == "dynamic" and wallpaper:
        if not Path(wallpaper).is_file():
            return 0
        hue, sat, mean_l = analyze(wallpaper)
        chromatic = hue is not None
        if not chromatic:
            hue, sat = 0.09, 0.0
    elif mode == "dynamic" and not wallpaper:
        return 1

    if mode == "static" and hue is not None:
        chromatic = sat > 0.02
        mean_l = 0.85 if mood == "light" else 0.12

    CACHE.mkdir(parents=True, exist_ok=True)

    light = mood == "light" if mode == "static" else (mean_l >= 0.40 if mean_l is not None else False)
    if mode == "static":
        light = mood == "light"
    surf_sat = min(sat, 0.26) if light else min(max(sat, 0.30 if chromatic else 0.0), 0.45)
    acc_sat = (min(sat + 0.18, 0.85) if light else min(max(sat, 0.30) + 0.12, 0.82)) if chromatic else 0.05
    if light:
        base = lerp(mean_l, 0.40, 0.66, 0.80, 0.93)
        steps, text, acc_l, deep_l, glow_l = LIGHT_STEPS, LIGHT_TEXT, 0.42, 0.30, 0.55
    else:
        base = lerp(mean_l, 0.0, 0.40, 0.045, 0.20)
        steps, text, acc_l, deep_l, glow_l = DARK_STEPS, DARK_TEXT, 0.70, 0.34, 0.86

    pill = {name: tint(hue, surf_sat, base + step) for name, step in zip(SURF_NAMES, steps)}
    pill["primary"] = tint(hue, acc_sat, acc_l)
    pill["primary_container"] = tint(hue, min(acc_sat + 0.08, 0.9), deep_l)
    pill["on_primary_container"] = tint(hue, min(acc_sat, 0.45), glow_l)
    pill["outline"] = tint(hue, surf_sat, base + (-0.35 if light else 0.35))
    for key, (lit, st) in zip(TEXT_KEYS, text):
        pill[key] = tint(hue, st, lit)
    (CACHE / "colors.json").write_text(json.dumps(pill, indent=2) + "\n")

    try:
        b = {k: v[mood]["color"] for k, v in
             matugen(tint(hue, sat, 0.45) if chromatic else "#787878", mood)["base16"].items()}
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        return 0

    (CACHE / "hypr-colors.lua").write_text(
        'return {\n    active = "%s",\n    inactive = "%s",\n}\n'
        % (pill["primary"], b["base01"]))

    # terminal.json — single source of truth for all terminal emulator colors
    # apply-terminal-colors.py reads this and fans out to kitty, ghostty, etc.
    terminal = {
        "term0":   b["base00"],  # background
        "term1":   b["base08"],  # red
        "term2":   b["base0b"],  # green
        "term3":   b["base0a"],  # yellow
        "term4":   b["base0d"],  # blue
        "term5":   b["base0e"],  # magenta
        "term6":   b["base0c"],  # cyan
        "term7":   b["base05"],  # white
        "term8":   b["base03"],  # bright black
        "term9":   b["base08"],  # bright red
        "term10":  b["base0b"],  # bright green
        "term11":  b["base0a"],  # bright yellow
        "term12":  b["base0d"],  # bright blue
        "term13":  b["base0e"],  # bright magenta
        "term14":  b["base0c"],  # bright cyan
        "term15":  b["base07"],  # bright white / foreground
        "primary": pill["primary"],
    }
    (CACHE / "terminal.json").write_text(json.dumps(terminal, indent=2) + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
