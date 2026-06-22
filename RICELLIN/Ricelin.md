# Ricelin

## Overview

Ricelin is a custom Hyprland desktop shell setup developed by Gakuseei. It represents a hand-written Quickshell environment designed for CachyOS, featuring a unique "pill" interface that morphs into various functional surfaces as needed. The shell provides a complete desktop experience with custom UI components for media controls, calendar, wallpaper selection, clipboard history, audio/brightness controls, and network/bluetooth management.

## Project Structure and Dependencies

The Ricelin project is organized into several configuration domains:

- **WM**: Hyprland (configured in Lua)
- **Shell UI**: Custom Quickshell
- **Terminal**: Ghostty
- **Shell**: Fish
- **Font**: JetBrains Mono Nerd
- **Colors**: wallust (palette extraction from wallpaper)

### Core Dependencies

The project requires several key packages for full functionality:

| Package Category | Components | Purpose |
|------------------|------------|---------|
| Window Manager | hyprland-git | Core window management |
| Shell UI | quickshell | Custom UI framework |
| Terminal | ghostty | Terminal emulator |
| Shell | fish | Default shell |
| Theming | matugen, wallust | Color generation and theming |
| Clipboard | cliphist, wl-clipboard | Clipboard management |
| Media | playerctl, brightnessctl | Audio and brightness control |
| Graphics | imagemagick, hyprpicker | Image manipulation and color picking |
| System | networkmanager, bluez, pipewire | System services |

## Configuration Components

### Hyprland Configuration

Located in [configs/hypr/](file:///home/yemi/.config/quickshell/.Ricelin/configs/hypr), this includes:
- Lua-based Hyprland configuration
- Monitor setup and environment variables
- Keybinding definitions
- Module configurations

### Quickshell Components

Located in [configs/quickshell/](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell), this contains:
- Pill shell UI components ([pill/shell.qml](file:///home/yemi/.config/quickshell/.Ricelin/configs/quickshell/pill/shell.qml))
- Custom surfaces for different functions
- Media controls, calendar, wallpaper picker
- Clipboard history, audio/brightness mixer
- Network and bluetooth controls

### Terminal Configuration

Located in [configs/ghostty/](file:///home/yemi/.config/quickshell/.Ricelin/configs/ghostty), this includes:
- Ghostty terminal emulator settings
- Theme integration with the overall shell

### System Integration

Additional configurations include:
- KDE settings ([configs/kde/](file:///home/yemi/.config/quickshell/.Ricelin/configs/kde))
- Systemd user services ([configs/systemd/](file:///home/yemi/.config/quickshell/.Ricelin/configs/systemd))
- SDDM login theme ([configs/sddm/](file:///home/yemi/.config/quickshell/.Ricelin/configs/sddm))
- Fastfetch configuration ([configs/fastfetch/](file:///home/yemi/.config/quickshell/.Ricelin/configs/fastfetch))

## Key Features

### Dynamic Pill Interface
The central feature of Ricelin is its "pill" interface that transforms into different functional surfaces:
- Media controls and now playing information
- Calendar view
- Wallpaper picker
- Clipboard history
- Audio and brightness mixer
- Network and bluetooth controls
- App launcher
- Lock screen

### Wallpaper Integration
Uses wallust to extract color palettes from wallpapers and automatically retheme the entire desktop environment, including:
- Terminal colors
- Window borders
- Fastfetch output
- Shell color scheme

### Screenshot Tool (rishot)
Includes rishot - a custom screenshot and annotation tool that lives in its own repository but integrates seamlessly with the shell.

## Installation Process

The installation is managed through [install.sh](file:///home/yemi/.config/quickshell/.Ricelin/install.sh) which:

1. Clones the repository to `~/.local/share/ricelin`
2. Creates symbolic links to `~/.config` for all configuration files
3. Backs up existing configurations before linking
4. Neutralizes hardware-specific settings for portable use
5. Optionally installs additional packages and services

### Installation Options

| Option | Description |
|--------|-------------|
| `--full` | Installs daily apps (dolphin, keepassxc, zathura, imv, rnote) |
| `--sddm` | Installs the torii SDDM login theme |
| `--quickstart` | Uses core defaults with no questions |
| `--no-prompt` | Takes defaults for headless installation |
| `--uninstall` | Removes symlinks and restores backups |

## Default Keybindings

| Key Combination | Action |
|-----------------|--------|
| `Super` + `Return` | Open terminal |
| `Super` + `Space` | App launcher |
| `Super` + `V` | Clipboard history |
| `Super` + `C` | Wallpaper picker |
| `Super` + `B` | Shuffle wallpaper and retheme |
| `Super` + `E` | File manager |
| `Super` + `T` | Toggle floating |
| `Super` + `L` | Lock screen |
| `Print` | Launch rishot (screenshot tool) |

## Project Philosophy

Ricelin was initially developed as a learning project to understand how Linux desktop systems work. It evolved into a daily driver that demonstrates the power of hand-written configurations rather than copying dotfiles. The project emphasizes:

- Complete customizability through hand-written configurations
- Seamless integration between different components
- Dynamic theming based on wallpaper content
- A unified interface paradigm (the pill concept)
- Hardware-agnostic configuration through portable defaults

## File Structure

```
.Ricelin/
├── .github/              # GitHub workflow configurations
├── assets/               # Project images and GIFs
│   ├── hero.png          # Main desktop screenshot
│   ├── shell.png         # Pill interface demonstration
│   ├── retheme.gif       # Re-theming animation
│   └── wallust.gif       # Wallpaper theming animation
├── configs/              # All configuration files
│   ├── hypr/             # Hyprland configuration
│   ├── quickshell/       # Quickshell UI components
│   ├── ghostty/          # Terminal configuration
│   ├── fish/             # Fish shell configuration
│   ├── sddm/             # SDDM login manager theme
│   ├── systemd/          # Systemd user services
│   ├── wallust/          # Wallpaper theming configuration
│   ├── fastfetch/        # Fastfetch system info
│   ├── grub/             # GRUB bootloader theme
│   ├── kde/              # KDE integration
│   └── brave-theme/      # Brave browser theme
├── wallpapers/           # Wallpaper documentation
├── install.sh            # Installation script
├── README.md             # Main project documentation
├── WALLPAPERS.md         # Wallpaper attribution
├── .gitignore            # Git ignore rules
└── LICENSE               # Project license
```

## Customization and Extensibility

Ricelin is designed to be easily customizable while maintaining its core architectural principles. Users can:

- Modify individual configuration files without breaking the system
- Add new Quickshell surfaces to extend the pill functionality
- Customize the theming system to suit personal preferences
- Extend the keybinding system with additional shortcuts

## Troubleshooting

Common issues and solutions:

- If Hyprland doesn't start properly, ensure hyprland-git is installed via an AUR helper
- For theming issues, verify that matugen and wallust are properly installed
- If Quickshell components don't load, check that the qs binary is in PATH
- For NVIDIA GPU users, the install script automatically adds necessary environment variables

## Credits

The project acknowledges various contributors and uses assets from different creators. The lock screen, SDDM background, and wallpapers are credited separately in the repository.