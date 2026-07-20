#!/usr/bin/env bash

set -euo pipefail

# --- colors ------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

ok() { printf "${GREEN}[OK] %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}[WARN] %s${NC}\n" "$*"; }
err() { printf "${RED}[ERR] %s${NC}\n" "$*" >&2; }
step() { printf "\n${BLUE}==> %s${NC}\n" "$*"; }

# --- arguments ---------------------------------------------------------------
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: ./install.sh [--dry-run]"
            exit 0
            ;;
        *)
            err "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

run() {
    if "$DRY_RUN"; then
        printf "${YELLOW}dry-run:${NC} %s\n" "$*"
    else
        "$@"
    fi
}

# --- paths -------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/quickshell"
WALLPAPER_DIR="$HOME/wallpapers"
DEFAULT_WALLPAPER=""

# --- packages found from the QuickShell config -------------------------------
PACMAN_PACKAGES=(
    awww
    bash
    base-devel
    blueman
    bluez
    bluez-utils
    brightnessctl
    coreutils
    findutils
    gawk
    git
    grep
    hyprland
    hyprsunset
    imagemagick
    jq
    libnotify
    libvips
    network-manager-applet
    networkmanager
    pipewire
    pipewire-pulse
    playerctl
    power-profiles-daemon
    procps-ng
    python-pywal
    quickshell
    qt6-5compat
    qt6-declarative
    rsync
    sed
    slurp
    ttf-jetbrains-mono-nerd
    ttf-material-icons
    inter-font
    upower
    util-linux
    wf-recorder
    wireplumber
    wl-clipboard
    wlogout
    xdg-utils
)

AUR_PACKAGES=(
    ttf-material-design-icons-extended
)

PIP_PACKAGES=()
NPM_PACKAGES=()

# --- preflight ---------------------------------------------------------------
require_arch() {
    step "Checking system"

    if ! command -v pacman >/dev/null 2>&1; then
        err "This installer is for Arch-based systems only. pacman was not found."
        exit 1
    fi

    ok "Arch-based system detected"
    if "$DRY_RUN"; then
        warn "Dry run enabled. Nothing will be installed or copied."
    fi
}

# --- package helpers ---------------------------------------------------------
is_pacman_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

is_aur_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

missing_pacman_packages() {
    local pkg
    for pkg in "${PACMAN_PACKAGES[@]}"; do
        if ! is_pacman_installed "$pkg"; then
            echo "$pkg"
        fi
    done
}

missing_aur_packages() {
    local pkg
    for pkg in "${AUR_PACKAGES[@]}"; do
        if ! is_aur_installed "$pkg"; then
            echo "$pkg"
        fi
    done
}

# --- yay ---------------------------------------------------------------------
ensure_yay() {
    step "Checking yay"

    if command -v yay >/dev/null 2>&1; then
        ok "yay already installed"
        return
    fi

    warn "yay is missing"
    if "$DRY_RUN"; then
        warn "Would install yay from AUR"
        return
    fi

    sudo pacman -S --needed --noconfirm git base-devel
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    ok "yay installed"
}

# --- pacman packages ---------------------------------------------------------
install_pacman_packages() {
    step "Checking pacman packages"

    mapfile -t missing < <(missing_pacman_packages)
    if ((${#missing[@]} == 0)); then
        ok "pacman packages already installed"
        return
    fi

    warn "Missing pacman packages: ${missing[*]}"
    run sudo pacman -S --needed --noconfirm "${missing[@]}"
    ok "pacman package step done"
}

# --- AUR packages ------------------------------------------------------------
install_aur_packages() {
    step "Checking AUR packages"

    mapfile -t missing < <(missing_aur_packages)
    if ((${#missing[@]} == 0)); then
        ok "AUR packages already installed"
        return
    fi

    warn "Missing AUR packages: ${missing[*]}"
    run yay -S --needed --noconfirm "${missing[@]}"
    ok "AUR package step done"
}

# --- pip packages ------------------------------------------------------------
install_pip_packages() {
    step "Checking pip packages"

    if ((${#PIP_PACKAGES[@]} == 0)); then
        ok "No pip packages required"
        return
    fi

    if ! command -v python >/dev/null 2>&1; then
        err "python is required for pip packages but was not found"
        exit 1
    fi

    local pkg missing=()
    for pkg in "${PIP_PACKAGES[@]}"; do
        if ! python -m pip show "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if ((${#missing[@]} == 0)); then
        ok "pip packages already installed"
    else
        warn "Missing pip packages: ${missing[*]}"
        run python -m pip install --user "${missing[@]}"
    fi
}

# --- npm packages ------------------------------------------------------------
install_npm_packages() {
    step "Checking npm packages"

    if ((${#NPM_PACKAGES[@]} == 0)); then
        ok "No npm packages required"
        return
    fi

    if ! command -v npm >/dev/null 2>&1; then
        err "npm is required for npm packages but was not found"
        exit 1
    fi

    local pkg missing=()
    for pkg in "${NPM_PACKAGES[@]}"; do
        if ! npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if ((${#missing[@]} == 0)); then
        ok "npm packages already installed"
    else
        warn "Missing npm packages: ${missing[*]}"
        run npm install -g "${missing[@]}"
    fi
}

# --- config copy -------------------------------------------------------------
copy_config() {
    step "Checking QuickShell config"

    run mkdir -p "$HOME/.config"

    if [[ "$SCRIPT_DIR" == "$TARGET_DIR" ]]; then
        ok "Already running from $TARGET_DIR"
        return
    fi

    warn "Copying config from $SCRIPT_DIR to $TARGET_DIR"
    run mkdir -p "$TARGET_DIR"
    run rsync -a --exclude '.git' --exclude 'install.sh' "$SCRIPT_DIR"/ "$TARGET_DIR"/
    run install -m 755 "$SCRIPT_DIR/install.sh" "$TARGET_DIR/install.sh"
    ok "Config copied"
}

# --- services and directories ------------------------------------------------
enable_services() {
    step "Enabling services"

    run sudo systemctl enable --now NetworkManager.service
    run sudo systemctl enable --now bluetooth.service
    run sudo systemctl enable --now power-profiles-daemon.service
    run systemctl --user enable --now pipewire.socket
    run systemctl --user enable --now pipewire-pulse.socket
    run systemctl --user enable --now wireplumber.service

    ok "Service step done"
}

prepare_runtime_dirs() {
    step "Preparing runtime directories"

    run mkdir -p "$WALLPAPER_DIR" "$TARGET_DIR/state" "$HOME/Pictures/Screenshots"

    if [[ ! -f "$TARGET_DIR/state/colormode" ]]; then
        run sh -c "printf '%s\n' dark > '$TARGET_DIR/state/colormode'"
    fi

    if [[ ! -f "$TARGET_DIR/app_usage.json" ]]; then
        run sh -c "printf '%s\n' '{}' > '$TARGET_DIR/app_usage.json'"
    fi

    ok "Runtime directories ready"
}

# --- pywal -------------------------------------------------------------------
find_default_wallpaper() {
    local candidate

    candidate="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1 || true)"
    if [[ -n "$candidate" ]]; then
        DEFAULT_WALLPAPER="$candidate"
        return
    fi

    candidate="$(find "$SCRIPT_DIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1 || true)"
    DEFAULT_WALLPAPER="$candidate"
}

init_pywal() {
    step "Initializing Pywal"

    find_default_wallpaper
    if [[ -z "$DEFAULT_WALLPAPER" ]]; then
        warn "No wallpaper image found in $WALLPAPER_DIR or this repo; skipping wal -i"
        return
    fi

    warn "Using wallpaper: $DEFAULT_WALLPAPER"
    run wal -i "$DEFAULT_WALLPAPER" --backend wal
    ok "Pywal colors initialized"
}

# --- summary -----------------------------------------------------------------
finish() {
    step "Done"
    ok "QuickShell rice install complete"
    echo
    echo "Next steps:"
    echo "  1. Put wallpapers in ~/wallpapers"
    echo "  2. Add this to Hyprland: exec-once = quickshell"
    echo "  3. Start it now with: quickshell"
}

# --- main --------------------------------------------------------------------
require_arch
ensure_yay
install_pacman_packages
install_aur_packages
install_pip_packages
install_npm_packages
copy_config
enable_services
prepare_runtime_dirs
init_pywal
finish
