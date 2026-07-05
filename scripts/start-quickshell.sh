#!/usr/bin/env bash
if pgrep -x "qs" > /dev/null; then
    echo "qs already running, not starting a duplicate"
    exit 1
fi
exec qs
