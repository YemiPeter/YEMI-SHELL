#!/usr/bin/env bash
# Single-instance standalone settings window launcher for iNiR settings UI
# Uses flock to prevent multiple instances and kills previous ones

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCK_FILE="/tmp/settings-window.lock"

# Kill any existing settings window
pkill -f "quickshell -n -p" 2>/dev/null
sleep 0.2

# Remove stale lock file if no quickshell process is running
if ! pgrep -f "quickshell -n -p" >/dev/null 2>&1; then
    rm -f "$LOCK_FILE" 2>/dev/null
fi

# Run with flock to prevent concurrent instances.
# Point -p at the root-level entry point (NOT settings/settings.qml): quickshell
# resolves qs.* module imports relative to the directory holding the -p file.
# settings.qml lives in settings/, so pointing -p directly at it makes quickshell
# treat settings/ as the config root and `import qs.services` /
# `import qs.modules.common` fail to resolve. The entry point sits at the real
# config root (fixes qs.* resolution) and loads settings/settings.qml as-is,
# so settings.qml's own relative paths keep working unchanged.
exec flock -n "$LOCK_FILE" quickshell -n -p "$SCRIPT_DIR/../settings-window-entry.qml"
