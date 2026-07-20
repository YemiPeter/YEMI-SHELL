#!/usr/bin/env bash

# Try dolphin first, then thunar, then nautilus (Files)
if command -v dolphin &> /dev/null; then
  exec dolphin
elif command -v thunar &> /dev/null; then
  exec thunar
else
  exec nautilus
fi
