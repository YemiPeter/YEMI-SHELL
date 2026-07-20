# Shell by Yemi — Product Overview

Shell by Yemi is a custom QML-based desktop shell for Linux, built on [Quickshell](https://quickshell.outfoxxed.me/). It targets Hyprland as the primary compositor with secondary Niri support in progress.

## What it is

A fully integrated desktop experience: top bar, app launcher, wallpaper browser, music controls, control center, OSD overlays, notifications, and a settings UI. Colors are generated dynamically from the active wallpaper via [matugen](https://github.com/InioX/matugen) (Material You color extraction), replacing the older Pywal pipeline.

## Core features

- **Dynamic theming** — wallpaper → matugen → colors propagated to shell, terminals, and other tools
- **App launcher** — usage-based sorting, desktop file parsing, search
- **Wallpaper browser** — grid with thumbnail generation (vipsthumbnail / ImageMagick), random picker
- **Music panel** — MPRIS/MPD controls with album art
- **Control center** — quick toggles, volume/brightness sliders, notification list, system stats, media card
- **OSD overlays** — volume and brightness on-screen displays
- **Settings UI** — dynamically loaded settings window
- **Alt+Tab switcher** — window switcher (in progress, see `modules/altswitcher/`)
- **Compositor abstraction** — runtime detection of Hyprland vs Niri, single interface for both

## Compositor support

- **Hyprland** — primary target, fully integrated
- **Niri** — secondary, compositor layer exists, keybinds in `dist/niri/`

## IPC targets (callable via `qs ipc call <target> <function>`)

| Target | Function | Action |
|--------|----------|--------|
| `launcher` | `toggle` | Open/close launcher (app tab) |
| `wallpaper` | `toggle` | Open/close launcher (wallpaper tab) |
| `wallpaper` | `random` | Apply random wallpaper |
| `music` | `toggle` | Open/close music panel |
| `colors` | `reload` | Re-apply matugen color scheme |
| `settings` | `toggle` | Open/close settings window |
