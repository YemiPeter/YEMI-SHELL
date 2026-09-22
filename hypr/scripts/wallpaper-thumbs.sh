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
# Media = raster images (ImageMagick) + video files (ffmpeg frame extract).
find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) -printf '%f\n' | sort > "$live"
find "$cache" -maxdepth 1 -type f -name '*.png' -printf '%f\n' | sed 's/\.png$//' | sort > "$cached"

comm -23 "$cached" "$live" | while IFS= read -r gone; do
    rm -f -- "$cache/$gone.png"
done

is_video() {
    # POSIX-safe lowercase (dash has no ${var,,}); extension decides.
    ext=$(echo "${1##*.}" | tr '[:upper:]' '[:lower:]')
    case "$ext" in
        mp4|webm|mkv|mov) return 0 ;;
        *) return 1 ;;
    esac
}

# Generate missing/stale thumbs. ${src##*/} avoids a basename spawn per file.
find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) | while IFS= read -r src; do
    thumb="$cache/${src##*/}.png"
    if [ ! -s "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        if is_video "$src"; then
            # Video files: ffmpeg grabs a representative frame (~10% in, so
            # intros/fade-ins don't yield a black tile). NOTE: ffmpeg needs a
            # real .png output extension (no IM-style "png:" prefix, no .tmp
            # suffix — both break the muxer), so the atomic rename writes to
            # a hidden dotfile instead.
            ffmpeg -y -loglevel error -ss 3 -i "$src" -frames:v 1 -vf "scale=512:-2" "$cache/.vthumb.png" 2>/dev/null \
                && mv "$cache/.vthumb.png" "$thumb"
        else
            # [0] picks the first frame: animated WebP/GIF sources otherwise
            # decode every frame and blow the ImageMagick pixel-cache budget
            # ("cache resources exhausted"). The decode-thumbnail defines keep
            # the decoder from materialising the full animation too.
            magick "${src}[0]" -define webp:decode-thumbnail=true \
                -define gif:decode-thumbnail=true \
                -strip -resize 512x "png:$thumb.tmp" 2>/dev/null
            # png: prefix is ImageMagick-only (a plain .tmp path breaks its
            # coder detection), so the image branch stages through $thumb.tmp
            # and the video branch above publishes $thumb itself.
            if [ -s "$thumb.tmp" ]; then
                mv "$thumb.tmp" "$thumb"
            else
                rm -f "$thumb.tmp"
                echo "wallpaper-thumbs: no thumbnail for ${src##*/}" >&2
            fi
        fi
    fi
done