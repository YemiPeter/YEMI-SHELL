#!/usr/bin/env python3
"""apply-colors.py – populate ~/.config/fastfetch/config.template.jsonc
from ~/.cache/yemi-shell/palette.json and write config.jsonc."""

import json
import re
import sys
from pathlib import Path

CACHE = Path.home() / ".cache" / "yemi-shell" / "palette.json"
CONF_DIR = Path.home() / ".config" / "fastfetch"
TMPL = CONF_DIR / "config.template.jsonc"
OUT = CONF_DIR / "config.jsonc"

PLACEHOLDERS = {
    "primary": "accent",
    "secondary": "accentSoft",
    "tertiary": "accentHover",
    "on_primary_container": "content",
    "primary_container": "surface",
    "secondary_container": "surfaceLow",
    "tertiary_container": "surfaceHigh",
    "bright": "content",
    "cream": "contentMuted",
}

USAGE_USAGE = [k for k in PLACEHOLDERS.values()]

def validate(value):
    if not re.fullmatch(r"^#[0-9a-fA-F]{6}$", value):
        raise SystemExit(f"FATAL: palette color {value!r} is not a valid #rrggbb hex")
    return value


def main() -> int:
    target_arg = sys.argv[1] if len(sys.argv) > 1 else "fastfetch"

    if not CACHE.is_file():
        raise SystemExit(f"FATAL: palette cache missing: {CACHE}")
    if not TMPL.is_file():
        raise SystemExit(f"FATAL: template missing: {TMPL}")
    if target_arg != "fastfetch":
        raise SystemExit(f"FATAL: expected 'fastfetch', got {target_arg!r}")

    try:
        data = json.loads(CACHE.read_text())
    except (json.JSONDecodeError, OSError) as exc:
        raise SystemExit(f"FATAL: cannot read palette.json: {exc}")

    colors: dict[str, str] = {}
    for ph, key in PLACEHOLDERS.items():
        try:
            raw = data[key]
        except KeyError:
            raise SystemExit(
                f"FATAL: palette.json is missing required key '{key}' "
                f"(needed for placeholder '{ph}'). "
                f"Run wallpaper.sh or wallcolors.py to regenerate."
            )
        colors[ph] = validate(str(raw).strip())

    text = TMPL.read_text()
    for ph, value in colors.items():
        text = text.replace(f'"{{{{{ph}}}}}', f'"{value}')

    OUT.write_text(text)
    print(f"OK: regenerated {OUT} from {CACHE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
