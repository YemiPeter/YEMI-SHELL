#!/bin/sh
MAGICK_CONFIGURE_PATH="$(dirname "$0")/magick-policy"
export MAGICK_CONFIGURE_PATH

wpdir="$HOME/Pictures/Wallpapers"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-wp-thumbs"
mkdir -p "$cache"

live="$(mktemp)"
cached="$(mktemp)"
trap 'rm -f "$live" "$cached"' EXIT

# One streaming pass per side, then a single comm — the old prune ran a full
# directory scan per cached thumb (and basename per file), which on a big
# library stalled every refresh for seconds.
find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) -printf '%f\n' | sort > "$live"
find "$cache" -maxdepth 1 -type f -name '*.png' -printf '%f\n' | sed 's/\.png$//' | sort > "$cached"

comm -23 "$cached" "$live" | while IFS= read -r gone; do
    rm -f -- "$cache/$gone.png"
done

# Generate missing/stale thumbs. ${src##*/} avoids a basename spawn per file.
find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) | while IFS= read -r src; do
    thumb="$cache/${src##*/}.png"
    if [ ! -s "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        magick "${src}[0]" -strip -resize 512x "png:$thumb.tmp" 2>/dev/null
        if [ -s "$thumb.tmp" ]; then
            mv "$thumb.tmp" "$thumb"
        else
            rm -f "$thumb.tmp"
        fi
    fi
done