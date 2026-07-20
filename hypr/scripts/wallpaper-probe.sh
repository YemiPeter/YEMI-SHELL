#!/usr/bin/env bash
{
echo "=== $(date) ==="
echo "ARGS: $@"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
} >> /tmp/skwd-probe.log
