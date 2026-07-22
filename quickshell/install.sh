#!/usr/bin/env bash

set -euo pipefail

# ── Visual ────────────────────────────────────────────────────────────────────
RESET='\033[0m';  BOLD='\033[1m';  DIM='\033[2m'
RED='\033[31m';   GREEN='\033[32m'; YELLOW='\033[33m'
CYAN='\033[36m';  MAGENTA='\033[35m'; WHITE='\033[37m'

ok()   { printf "    ${DIM}[${RESET}${GREEN} OK ${RESET}${DIM}]${RESET} %s\n" "$*"; }
warn() { printf "    ${DIM}[${RESET}${YELLOW}WARN${RESET}${DIM}]${RESET} %s\n" "$*"; }
err()  { printf "    ${DIM}[${RESET}${RED}ERR${RESET}${DIM}]${RESET} %s\n" "$*" >&2; }

# ── progress bar ──────────────────────────────────────────────────────────────
TOTAL_STEPS=12
CURRENT_STEP=0

draw_progress() {
    local filled=$(( CURRENT_STEP * 30 / TOTAL_STEPS ))
    local empty=$(( 30 - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done
    printf "\r  ${DIM}[${RESET}${MAGENTA}%s${RESET}${DIM}]${RESET} ${DIM}%d/%d${RESET}\n" \
        "$bar" "$CURRENT_STEP" "$TOTAL_STEPS"
}

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$*"
    draw_progress
}

# ── spinner ───────────────────────────────────────────────────────────────────
_spinner_pid=""

spinner_start() {
    local msg="$1"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    (
        local i=0
        while true; do
            printf "\r    ${MAGENTA}%s${RESET}  %s" "${frames[$i]}" "$msg"
            i=$(( (i+1) % 10 ))
            sleep 0.08
        done
    ) &
    _spinner_pid=$!
}

spinner_stop() {
    local status=$1   # 0 = ok, 1 = fail
    local msg="${2:-}"
    [[ -n "$_spinner_pid" ]] && kill "$_spinner_pid" 2>/dev/null && wait "$_spinner_pid" 2>/dev/null
    printf "\r\033[K"  # clear spinner line
    _spinner_pid=""
    if [[ $status -eq 0 ]]; then
        [[ -n "$msg" ]] && ok "$msg"
    else
        err "${msg:-Failed}"
    fi
}

trap 'spinner_stop 1' ERR

# ── banner ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "██╗   ██╗███████╗███╗   ███╗██╗"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "╚██╗ ██╔╝██╔════╝████╗ ████║██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" " ╚████╔╝ █████╗  ██╔████╔██║██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "  ╚██╔╝  ██╔══╝  ██║╚██╔╝██║██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "   ██║   ███████╗██║ ╚═╝ ██║██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝"
    echo
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "███████╗██╗  ██╗███████╗██╗     ██╗"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "██╔════╝██║  ██║██╔════╝██║     ██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "███████╗███████║█████╗  ██║     ██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "╚════██║██╔══██║██╔══╝  ██║     ██║"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "███████║██║  ██║███████╗███████╗███████╗"
    printf "${BOLD}${MAGENTA}%s${RESET}\n" "╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝"
    echo
    printf "${DIM}  by YemiPeter • github.com/YemiPeter${RESET}\n"
    printf "${DIM}  ─────────────────────────────────────${RESET}\n"
    echo
}

# ── arguments ─────────────────────────────────────────────────────────────────
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
        printf "${YELLOW}dry-run:${RESET} %s\n" "$*"
    else
        "$@"
    fi
}

# ── paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/quickshell"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FASTFETCH_DIR="$HOME/Pictures/fastfetch"
DEFAULT_WALLPAPER=""

# ── sample assets bundled with this repo ──────────────────────────────────────
# 5 wallpapers — drop them in ~/Pictures/Wallpapers so skwd-wall has a starting
# point and colors generate on first run. Add your own wallpapers there.
SAMPLE_WALLPAPERS=(
    "assets/wallpapers/pacman-ghosts.webp"
    "assets/wallpapers/Girl-Face-Resting-On-Hands.webp"
    "assets/wallpapers/Girl-Waves.webp"
    "assets/wallpapers/Snoopy.webp"
    "assets/wallpapers/wallhaven-e8xlgw.webp"
)

# 5 fastfetch images — shown randomly in the terminal on shell start.
# Add your own images (PNG/JPG/WebP) to ~/Pictures/fastfetch/
SAMPLE_FASTFETCH=(
    "assets/fastfetch/archlinux.png"
    "assets/fastfetch/nyarch.png"
    "assets/fastfetch/itachipro.png"
    "assets/fastfetch/pochita.png"
    "assets/fastfetch/obito.png"
)

# ── packages found from the QuickShell config ───────────────────────────────
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

# ── preflight ─────────────────────────────────────────────────────────────────
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

# ── package helpers ───────────────────────────────────────────────────────────
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

# ── yay ───────────────────────────────────────────────────────────────────────
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

# ── pacman packages ───────────────────────────────────────────────────────────
install_pacman_packages() {
    step "Checking pacman packages"

    mapfile -t missing < <(missing_pacman_packages)
    if ((${#missing[@]} == 0)); then
        ok "pacman packages already installed"
        return
    fi

    warn "Missing pacman packages: ${missing[*]}"
    spinner_start "Installing pacman packages..."
    run sudo pacman -S --needed --noconfirm "${missing[@]}"
    spinner_stop $? "pacman package step done"
}

# ── AUR packages ──────────────────────────────────────────────────────────────
install_aur_packages() {
    step "Checking AUR packages"

    mapfile -t missing < <(missing_aur_packages)
    if ((${#missing[@]} == 0)); then
        ok "AUR packages already installed"
        return
    fi

    warn "Missing AUR packages: ${missing[*]}"
    spinner_start "Installing AUR packages..."
    run yay -S --needed --noconfirm "${missing[@]}"
    spinner_stop $? "AUR package step done"
}

# ── pip packages ──────────────────────────────────────────────────────────────
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
        spinner_start "Installing pip packages..."
        run python -m pip install --user "${missing[@]}"
        spinner_stop $? "pip package step done"
    fi
}

# ── npm packages ──────────────────────────────────────────────────────────────
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
        spinner_start "Installing npm packages..."
        run npm install -g "${missing[@]}"
        spinner_stop $? "npm package step done"
    fi
}

# ── RICE_HOME ─────────────────────────────────────────────────────────────────
ensure_rice_home() {
    step "Setting RICE_HOME"

    local rice_path="$HOME/.config"
    local env_d_dir="$HOME/.config/environment.d"
    local env_d_file="$env_d_dir/rice.conf"
    local hypr_env="$HOME/.config/hypr/modules/env.lua"

    # --- environment.d (systemd user session) ---
    run mkdir -p "$env_d_dir"
    if grep -q "^RICE_HOME=" "$env_d_file" 2>/dev/null; then
        ok "environment.d/rice.conf already set"
    else
        echo "RICE_HOME=$rice_path" >> "$env_d_file"
        ok "Added RICE_HOME to environment.d/rice.conf"
    fi

    # --- Hyprland env directive ---
    if grep -q "^env = RICE_HOME," "$hypr_env" 2>/dev/null; then
        ok "env.lua already has RICE_HOME"
    else
        echo "env = RICE_HOME,$rice_path" >> "$hypr_env"
        ok "Added RICE_HOME to hypr/modules/env.lua"
    fi
}

# ── config copy ───────────────────────────────────────────────────────────────
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

# ── services and directories ──────────────────────────────────────────────────
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

# ── pywal ─────────────────────────────────────────────────────────────────────
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

# ── summary ───────────────────────────────────────────────────────────────────
finish() {
    step "Done"
    ok "QuickShell rice install complete"
    echo
    echo "  ${BOLD}Next steps:${RESET}"
    echo "    1. Put wallpapers in ~/Pictures/Wallpapers"
    echo "    2. Hyprland config already has: exec-once = quickshell -p \$RICE_HOME/quickshell/shell.qml"
    echo "    3. Log out and back in to load RICE_HOME, then run: quickshell"
    echo
}

# ── main ──────────────────────────────────────────────────────────────────────
print_banner

# Pre-cache sudo credentials to avoid mid-spinner password prompts
# Skip in dry-run mode — no actual install steps will run
if ! "$DRY_RUN"; then
    sudo -v || { err "sudo required for system-level install steps"; exit 1; }
fi

require_arch
ensure_yay
install_pacman_packages
install_aur_packages
install_pip_packages
install_npm_packages
ensure_rice_home
copy_config
enable_services
prepare_runtime_dirs
init_pywal
finish
