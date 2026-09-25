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
TOTAL_STEPS=11
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
    printf "${DIM}  YEMI-Shell • by YemiPeter • github.com/YemiPeter${RESET}\n"
    printf "${DIM}  ─────────────────────────────────────${RESET}\n"
    echo
}

# ── arguments ─────────────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_SERVICES=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --no-services) SKIP_SERVICES=true ;;
        -h|--help)
            echo "Usage: ./install.sh [--dry-run] [--no-services]"
            echo "  --dry-run      Show changes without installing or writing files"
            echo "  --no-services  Do not enable system or user services"
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

# Support both the repository root (which contains quickshell/) and an
# installer copied directly into the quickshell configuration directory.
if [[ -f "$SCRIPT_DIR/shell.qml" ]]; then
    SOURCE_DIR="$SCRIPT_DIR"
elif [[ -f "$SCRIPT_DIR/quickshell/shell.qml" ]]; then
    SOURCE_DIR="$SCRIPT_DIR/quickshell"
else
    err "Could not find quickshell/shell.qml next to this installer"
    exit 1
fi

# ── packages found from the QuickShell config ───────────────────────────────
PACMAN_PACKAGES=(
    bash
    base-devel
    bluez
    bluez-utils
    brightnessctl
    cava
    cliphist
    coreutils
    findutils
    gawk
    git
    grim
    grep
    hyprland
    hyprsunset
    imagemagick
    jq
    libnotify
    networkmanager
    niri
    pipewire
    pipewire-pulse
    power-profiles-daemon
    procps-ng
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
    quickshell-git
    skwd-deck-bin
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
    if grep -q "^RICE_HOME=" "$env_d_file" 2>/dev/null; then
        ok "environment.d/rice.conf already set"
    elif "$DRY_RUN"; then
        warn "Would add RICE_HOME to environment.d/rice.conf"
    else
        mkdir -p "$env_d_dir"
        printf 'RICE_HOME=%s\n' "$rice_path" >> "$env_d_file"
        ok "Added RICE_HOME to environment.d/rice.conf"
    fi

    # --- Hyprland env directive (only when the user's config already has it) ---
    if [[ ! -f "$hypr_env" ]]; then
        warn "Hyprland env.lua not found; relying on environment.d instead"
    elif grep -q "^env = RICE_HOME," "$hypr_env"; then
        ok "env.lua already has RICE_HOME"
    elif "$DRY_RUN"; then
        warn "Would add RICE_HOME to hypr/modules/env.lua"
    else
        printf 'env = RICE_HOME,%s\n' "$rice_path" >> "$hypr_env"
        ok "Added RICE_HOME to hypr/modules/env.lua"
    fi
}

# ── config copy ───────────────────────────────────────────────────────────────
copy_config() {
    step "Checking QuickShell config"

    run mkdir -p "$HOME/.config"

    if [[ "$SOURCE_DIR" == "$TARGET_DIR" ]]; then
        ok "Already running from $TARGET_DIR"
        return
    fi

    warn "Copying YEMI-Shell from $SOURCE_DIR to $TARGET_DIR"
    run mkdir -p "$TARGET_DIR"
    run rsync -a --exclude '.git' --exclude '.agents' --exclude '.codex' --exclude '.kilo' "$SOURCE_DIR"/ "$TARGET_DIR"/
    ok "Config copied"
}

# ── services and directories ──────────────────────────────────────────────────
enable_services() {
    step "Enabling services"

    if "$SKIP_SERVICES"; then
        warn "Service setup skipped by --no-services"
        return
    fi

    run sudo systemctl enable --now NetworkManager.service
    run sudo systemctl enable --now bluetooth.service
    run sudo systemctl enable --now power-profiles-daemon.service
    run systemctl --user enable --now pipewire.socket
    run systemctl --user enable --now pipewire-pulse.socket
    run systemctl --user enable --now wireplumber.service
    # The wallpaper daemon waits for a Wayland session before rendering, so
    # enable it now but leave its first start to the next graphical session.
    run systemctl --user enable skwd-walld.service

    local user_unit_dir="$HOME/.config/systemd/user"
    run mkdir -p "$user_unit_dir"
    run install -m 644 "$SOURCE_DIR/quickshell-reset-app-usage.service" "$user_unit_dir/quickshell-reset-app-usage.service"
    run systemctl --user daemon-reload
    run systemctl --user enable quickshell-reset-app-usage.service

    ok "Service step done"
}

prepare_runtime_dirs() {
    step "Preparing runtime directories"

    run mkdir -p "$WALLPAPER_DIR" "$TARGET_DIR/state" "$HOME/Pictures/Screenshots"

    if [[ ! -f "$TARGET_DIR/app_usage.json" ]]; then
        run sh -c "printf '%s\n' '{}' > '$TARGET_DIR/app_usage.json'"
    fi

    ok "Runtime directories ready"
}

# ── summary ───────────────────────────────────────────────────────────────────
finish() {
    step "Done"
    ok "YEMI-Shell install complete"
    echo
    printf "  ${BOLD}Next steps:${RESET}\n"
    echo "    1. Put wallpapers in ~/Pictures/Wallpapers"
    echo "    2. Start it now: ~/.config/quickshell/scripts/start-shell.sh"
    echo "    3. Add the same command to your compositor's startup configuration"
    echo "       Hyprland: exec-once = ~/.config/quickshell/scripts/start-shell.sh"
    echo "       Niri:     spawn-at-startup \"bash\" \"-lc\" \"~/.config/quickshell/scripts/start-shell.sh\""
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
finish
