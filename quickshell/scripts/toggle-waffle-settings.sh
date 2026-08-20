#!/usr/bin/env bash
# Toggle the Waffle settings window.
# If an instance is already running, kill it (toggle off).
# Otherwise, launch a new instance (toggle on).

set -euo pipefail

CONFIG_DIR="${RICE_HOME:-$HOME/.config}/quickshell"
QML_PATH="$CONFIG_DIR/waffleSettings.qml"
QS_BIN="$(command -v qs || echo qs)"

if [[ ! -f "$QML_PATH" ]]; then
    echo "Could not find waffleSettings.qml at $QML_PATH" >&2
    exit 1
fi

# Detect existing instance(s)
INSTANCE_LIST="$("$QS_BIN" -p "$QML_PATH" list 2>/dev/null || true)"
if [[ -n "$INSTANCE_LIST" && "$INSTANCE_LIST" != *"No running instances"* ]]; then
    # Toggle off: kill all existing instances (retry until none remain)
    for _ in $(seq 1 5); do
        "$QS_BIN" -p "$QML_PATH" kill >/dev/null 2>&1 || true
        sleep 0.5
        REMAINING="$("$QS_BIN" -p "$QML_PATH" list 2>/dev/null || true)"
        if [[ -z "$REMAINING" || "$REMAINING" == *"No running instances"* ]]; then
            break
        fi
    done
    exit 0
fi

# Toggle on: launch new instance detached
"$QS_BIN" -p "$QML_PATH" >/dev/null 2>&1 &
disown
exit 0