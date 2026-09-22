# Wallpaper

## 1. Component Overview

The wallpaper surface is a morphing pill surface that selects, previews, applies, and removes wallpapers. The current Yemi implementation is a compact filmstrip; the Pibble source adds a full-screen launcher with grid/carousel selectors, video pooling, cached blurred backdrops, and a more general wallpaper-command backend.

This document records the read-only audit performed before the Pibble wallpaper port. No port code has been applied yet.

## 2. Current Yemi Implementation

### UI

- **File:** `modules/pill/Wallpaper.qml`
- **Instantiated by:** `modules/pill/Pill.qml`
- **Surface name:** `wallpaper`
- **Surface size:** `720 * s` by `172 * s`

The current surface provides:

- A depth-scaled filmstrip over `~/Pictures/Wallpapers`.
- Newest-first local entries with cached PNG thumbnails.
- Keyboard, wheel, and pointer navigation.
- Tap/Enter to apply the focused wallpaper.
- Hold-to-confirm deletion through `HeatHold`.
- A DuckDuckGo image-search mode with download, apply, and fallback to the local strip.
- Empty-state and search-state messages.

`Pill.qml` exposes forwarding helpers for the surface:

- `wallpaperMove(dir)`
- `wallpaperActivate()`
- `wallpaperType(ch)`

The surface is instantiated at `modules/pill/Pill.qml:1203-1209` and registered through `modules/pill/Singletons/qmldir`.

### Data and apply pipeline

`modules/pill/Singletons/Walls.qml` is the current bridge between QML and the shell scripts. It:

1. Runs `hypr/scripts/wallpaper-thumbs.sh`.
2. Lists local JPEG, PNG, WebP, and GIF files newest-first.
3. Builds entries containing `path`, `name`, `mtime`, and `thumb`.
4. Reads the current wallpaper from the state file.
5. Applies a selected file through `hypr/scripts/wallpaper.sh`.
6. Queues rapid successive picks while an apply is running.
7. Runs `quickshell/scripts/after-wall.sh` after a successful apply.

The current apply path is:

```text
Wallpaper.qml
  -> Walls.apply(path)
  -> hypr/scripts/wallpaper.sh set <path>
  -> quickshell/scripts/after-wall.sh <path>
  -> wallcolors.py
  -> terminal color files
  -> qs ipc call matugenReload
```

`wallpaper.sh` starts or reuses `awww-daemon`, applies a wave transition, writes the current path, regenerates colors, reloads Hyprland, and asks Ghostty to reload its configuration. `wallpaper-thumbs.sh` uses ImageMagick and stores previews in the XDG cache.

### Existing root-level wallpaper state

`quickshell/shell.qml` still contains an older wallpaper implementation:

- A separate `wallpaperList`, `filteredWallpapers`, `currentWallpaper`, and thumbnail state.
- A separate thumbnail process and current-wallpaper process.
- `applyWallpaper()` invokes `skwd wall apply`.
- A random wallpaper process selects a file from the wallpaper directory.

This legacy path is separate from `Walls.qml` and must be reconciled before or during the port. In particular, current state paths are inconsistent:

- `Walls.qml` reads/writes `~/.local/state/quickshell-wallpaper`.
- `Appearance.qml` reads `~/.local/state/yemi-shell-wallpaper`.
- `shell.qml` also tracks its own `currentWallpaper` value.

## 3. Pibble Wallpaper Findings

The relevant Pibble source is under `/home/yemi/pibble`.

### Service and cache model

`pibble/services/Wallpapers.qml` combines scanning, thumbnail generation, blurred-image generation, current-wallpaper tracking, and xray backdrop state.

Each entry contains:

```text
path | thumb | blur
```

The scan supports:

- PNG, JPEG, WebP, GIF, and MP4.
- Static thumbnails for images and GIFs.
- A decoded first frame for MP4 files.
- Optional cached blurred variants.
- User-supplied `<stem>blurred.<ext>` overrides.
- Cache keys based on source path, recipe version, output geometry, scale, and blur settings.
- Cache cleanup for missing source files and obsolete recipe keys.

The service prioritizes the current wallpaper during background generation so the active backdrop is ready before the rest of a large folder. It also samples a cached static thumbnail for GIF/MP4 sources before sending them to matugen, because matugen cannot reliably decode animated or video sources.

### Selectors

- `pibble/launcher/WallpaperGrid.qml` provides a paged thumbnail grid.
- `pibble/launcher/WallpaperCarousel.qml` provides an infinite horizontal carousel with parallax and edge-aware cell sizing.
- `pibble/launcher/WallpaperVideoPool.qml` keeps one `MediaPlayer` per video wallpaper and only plays the selected video.
- `pibble/launcher/WallpapersPage.qml` hosts both selector styles and their shared empty state.

The video pool is important for performance: opening a video player is deferred and spread over time, while navigation only changes the selected pooled surface. The source comments document measurable GUI-thread stalls from creating or re-sourcing players during navigation.

### Apply behavior

`pibble/launcher/LauncherWindow.qml` treats wallpaper application as a tracked process:

- The configured command receives `$WALL` and `$BLUR`.
- A pick is queued while another apply is running.
- A newer pick can supersede an in-flight command.
- The current wallpaper is committed only after the command succeeds or a long-running setter exceeds its grace period.
- The committed path is persisted in settings and used by the dynamic theme and xray backdrop.

This is more robust than assuming that starting a process means the wallpaper reached the screen.

### Xray backdrop and scale probing

Pibble supports three background-blur modes:

- `off`
- `compositor`
- `xray`

`pibble/launcher/XrayBackdrop.qml` draws a cached blurred wallpaper when available and falls back to a client-side `MultiEffect` blur. `pibble/startup/XrayScaleProbe.qml` measures the real fractional output scale from a mapped 1x1 layer-shell surface. This matters because an unmapped screen can report a rounded integer scale, producing an incorrectly sized cached blur on fractional outputs.

The xray blur is keyed to the output geometry and scale. A change in monitor or scale invalidates the relevant cache entries and triggers a new scan.

### Settings

`pibble/config/Settings.qml` centralizes wallpaper configuration, including:

- `wallpaperStyle`: `grid`, `carousel`, or `carousel-flat`.
- `wallpaperDir`.
- `wallCommand`.
- `currentWallpaper`.
- `bgBlur`.
- `preload`.
- Grid columns/rows and carousel visibility.
- Migration/healing for older setting names and values.

`pibble/config/SettingsStore.qml` persists the adapter to `settings.json`, watches external edits, and runs migrations without blindly overwriting a newly loaded configuration.

### Dynamic theme

`pibble/services/Theme.qml` runs matugen against `Settings.currentWallpaper` and updates the launcher palette. It uses the static thumbnail for animated or video wallpapers. This differs from Yemi's current `Dyn.qml` model, which watches `~/.cache/yemi-shell/colors.json` produced by `wallcolors.py`.

## 4. Architecture Differences

| Area | Yemi Shell | Pibble |
|---|---|---|
| Presentation | 720x172 morphing pill filmstrip | Full-screen launcher page |
| Selectors | One continuous filmstrip | Grid and infinite carousel |
| Video | Static GIF support in filmstrip | Shared pooled MP4 players |
| Cache | Thumbnail only | Thumbnail plus output-aware blurred variant |
| Apply | `wallpaper.sh` plus `after-wall.sh` | Freeform `$WALL`/`$BLUR` command with tracked success |
| Current state | Multiple state files and root-level state | One settings-backed current path |
| Palette | `wallcolors.py` -> `Dyn.qml` | matugen -> Pibble `Theme.qml` |
| Backdrop blur | Not part of the pill filmstrip | Optional compositor/xray backdrop |
| Compositor | Hyprland primary, Niri secondary | Wayland layer-shell launcher with per-output behavior |

Pibble's service and apply machinery can be reused, but its full-screen launcher window, reveal mask, page system, and gesture code should not be copied wholesale into the pill surface.

## 5. Port Integration Plan

1. **Resolve licensing first.** Pibble is GPLv3 (`/home/yemi/pibble/LICENSE`), while Yemi's README advertises MIT and the repository currently has no `LICENSE` file. Exact-source copying requires a compatible license decision and preserved notices.
2. **Unify the current-wallpaper state.** Choose one authoritative state path and make `Walls.qml`, `Appearance.qml`, `shell.qml`, and the apply scripts read/write the same value.
3. **Port the service layer before the UI.** Adapt `pibble/services/Wallpapers.qml` into the Yemi singleton/module boundary, preserving Yemi's existing `Walls` API where possible.
4. **Add cached blurred variants only when requested.** Generate `$BLUR` only when the configured command references it or an xray mode is enabled. This avoids unnecessary ImageMagick work.
5. **Adapt settings.** Add wallpaper directory, selector style, blur mode, preload, grid geometry, and command properties to the shared `Flags`/settings layer, with migrations for existing users.
6. **Adapt the apply path.** Decide whether Yemi keeps `wallpaper.sh`/`after-wall.sh` or adopts Pibble's freeform command model. The chosen path must preserve queued picks, success tracking, palette regeneration, and terminal reloads.
7. **Port selectors incrementally.** Keep the existing filmstrip as a compatibility surface, then add grid/carousel components under `modules/pill` or a dedicated wallpaper subdirectory.
8. **Port video pooling separately.** Use one shared player surface and warm players off-screen; do not create a player per carousel/grid cell.
9. **Port xray only if the UI needs a backdrop.** The current pill surface does not have Pibble's full-screen backdrop. `XrayScaleProbe.qml` is only needed if Yemi adds an xray layer-shell surface or another component consumes cached blurred backdrops.
10. **Reconcile palette ownership.** Either keep `wallcolors.py` -> `Dyn.qml` and feed it the selected wallpaper, or replace it with matugen. Avoid running both pipelines for one wallpaper change.
11. **Validate both compositors.** Test Hyprland and Niri, including fractional scaling, monitor changes, cold/warm caches, GIFs, MP4s, missing dependencies, and rapid repeated picks.

## 6. Compatibility and Risk Notes

- Pibble imports `root:/config`, `root:/services`, `SystemInfo`, `Notifier`, `ActiveOutput`, and other project-specific modules. These need explicit Yemi equivalents or an adapter layer.
- Pibble source uses typed QML function declarations such as `function rescan(): void`. Yemi's current QML/QuickShell setup must be checked before copying these verbatim; adapt syntax if the local parser rejects type annotations.
- Pibble's full-screen window relies on layer-shell focus, masks, background-effect regions, and input behavior that do not map directly onto the pill's two-window architecture.
- Cached blurred images can be expensive on cold startup. The Pibble implementation deliberately prioritizes the current wallpaper and generates remaining files in a locked background pass.
- Keeping a mapped full-screen surface and preloaded video players trades memory for lower open latency. The current Yemi pill should not inherit that cost unless `preload` is explicitly enabled.
- The legacy `shell.qml` wallpaper pipeline and `skwd-wall` integration should be audited before removal so random-wallpaper keybinds and existing user configuration continue to work.
- Cache paths, state paths, and configuration paths must be normalized before the port is considered complete.

## 7. Validation Status

The audit was read-only. No source files were changed. The repository currently has an unrelated modification to `skwd-wall/config.json`; it must remain untouched. Runtime validation, QML parsing, linting, and compositor testing have not yet been performed for the port.
