#!/bin/sh
pgrep -f "lock_shell.qml" >/dev/null 2>&1 && exit 0
exec ~/.local/share/quickshell-lockscreen/lock.sh "$@"
