#!/usr/bin/env bash
set -euo pipefail

usage_file="${HOME}/.config/quickshell/app_usage.json"
tmp_file="${usage_file}.tmp"

mkdir -p "$(dirname "$usage_file")"
printf '{}\n' > "$tmp_file"
mv "$tmp_file" "$usage_file"
