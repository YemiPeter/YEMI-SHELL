#!/usr/bin/env bash
# Single-instance standalone settings window launcher for iNiR settings UI
# Uses flock to prevent multiple instances and kills previous ones

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCK_FILE="/tmp/settings-window.lock"

# Kill any existing settings window
pkill -f "quickshell -n -p" 2>/dev/null
sleep 0.2

# Run with flock to prevent concurrent instances
exec flock -n "$LOCK_FILE" quickshell -n -p "$SCRIPT_DIR/../settings/settings.qml"