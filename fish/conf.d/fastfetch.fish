if status is-interactive
    if test -n "$WAYLAND_DISPLAY$DISPLAY"
        if test -x "$HOME/.config/fastfetch/pick-image.fish"
            "$HOME/.config/fastfetch/pick-image.fish"
        else
            fastfetch
        end
    end
end
