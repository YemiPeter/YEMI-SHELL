#!/usr/bin/env bash
REPO="$HOME/YEMI-SHELL"
git -C "$REPO" fetch origin main --quiet 2>/dev/null || exit 1
LOCAL=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)
REMOTE=$(git -C "$REPO" rev-parse origin/main 2>/dev/null)
if [ "$LOCAL" = "$REMOTE" ]; then
 echo "up-to-date"
else
 echo "update-available"
fi
