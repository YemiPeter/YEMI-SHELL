#!/usr/bin/env bash
set -euo pipefail
MOOD="${1:-dark}"

if [ -d "/usr/share/icons/breeze" ] || [ -d "/usr/share/icons/breeze-dark" ]; then
  GTK_THEME_NAME="Breeze$([ "${MOOD}" = "dark" ] && echo "-Dark" || echo "")"
else
  GTK_THEME_NAME="Adwaita$([ "${MOOD}" = "dark" ] && echo "-dark" || echo "")"
fi

gsettings set org.gnome.desktop.interface color-scheme "prefer-${MOOD}" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME_NAME}" 2>/dev/null || true

if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$([ "${MOOD}" = "dark" ] && echo BreezeDark || echo BreezeLight)" 2>/dev/null || true
elif command -v kvantummanager >/dev/null 2>&1; then
    kvantummanager --set "$([ "${MOOD}" = "dark" ] && echo Kvantum-dark || echo Kvantum)" 2>/dev/null || true
fi
