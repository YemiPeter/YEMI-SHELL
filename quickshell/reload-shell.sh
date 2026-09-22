#!/bin/bash

# NOTE: the instance MUST be started with the explicit config path. Launching a
# bare `quickshell` loads the DEFAULT config (not shell.qml), so the bar/pill
# come up missing or wrong and the failure looks like a broken QML config.
CONFIG="$HOME/.config/quickshell/shell.qml"

# Kill existing instance gracefully first, then force if needed
if pgrep -x quickshell > /dev/null; then
    echo "Stopping QuickShell..."
    pkill quickshell
    # Wait up to 5 seconds
    for i in {1..50}; do
        if ! pgrep -x quickshell > /dev/null; then
            break
        fi
        sleep 0.1
    done
    # Force kill if still running
    if pgrep -x quickshell > /dev/null; then
        pkill -9 quickshell
    fi
fi

# Start new instance
echo "Starting QuickShell..."
nohup quickshell -p "$CONFIG" > /dev/null 2>&1 &

echo "Done."
