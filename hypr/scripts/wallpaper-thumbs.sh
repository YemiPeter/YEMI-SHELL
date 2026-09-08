#!/bin/sh
MAGICK_CONFIGURE_PATH="$(dirname "$0")/magick-policy"
export MAGICK_CONFIGURE_PATH

wpdir="$HOME/Pictures/Wallpapers"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-wp-thumbs"
mkdir -p "$cache"

# Prune thumbs whose source file is gone. This used to run a `find` per cached
# thumb (O(cache × dir)) — with ~1000 wallpapers a single refresh blocked the
# wallpaper strip's list behind 5-20s of pure directory scanning. Now both name
# sets are built with one `find` each and diffed with awk (hash-based, O(n+m),
# order-independent — no sort/comm collation pitfalls).
tmp="$(mktemp -d "${TMPDIR:-/tmp}/qs-wp-prune.XXXXXX")" || exit 1
find "$wpdir" -type f -printf '%f\n' > "$tmp/live"
find "$cache" -maxdepth 1 -name '*.png' -printf '%f\n' | sed 's/\.png$//' > "$tmp/thumb"
awk 'NR==FNR { live[$0]=1; next } !($0 in live) { print }' "$tmp/live" "$tmp/thumb" \
    | while IFS= read -r base; do rm -f -- "$cache/$base.png"; done
rm -rf "$tmp"

find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) | while IFS= read -r src; do
    thumb="$cache/$(basename "$src").png"
    if [ ! -s "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        magick "${src}[0]" -strip -resize 512x "png:$thumb.tmp" 2>/dev/null
        if [ -s "$thumb.tmp" ]; then
            mv "$thumb.tmp" "$thumb"
        else
            rm -f "$thumb.tmp"
        fi
    fi
done