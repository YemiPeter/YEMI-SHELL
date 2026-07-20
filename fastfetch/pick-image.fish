#!/usr/bin/env fish

set FASTFETCH_DIR "$HOME/Pictures/fastfetch"
set selected_image (find "$FASTFETCH_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \) ! -name ".*" | shuf -n1)

if test -n "$selected_image"; and test -f "$selected_image"
    fastfetch --logo "$selected_image"
else
    fastfetch
end
