#!/usr/bin/env bash
LOCAL=$(git -C ~/YEMI-SHELL rev-parse HEAD 2>/dev/null)
REMOTE=$(git -C ~/YEMI-SHELL ls-remote origin HEAD 2>/dev/null | cut -f1)
if [ "$LOCAL" = "$REMOTE" ]; then
  echo "up-to-date"
else
  echo "update-available"
fi