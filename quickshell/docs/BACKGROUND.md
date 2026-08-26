# iNiR Background Section — Reference

This document describes the **Background** section of iNiR: the settings page
(`modules/settings/BackgroundConfig.qml`), the backing **services**
(`services/Wallpapers.qml`, `services/WallpaperListener.qml`,
`services/AwwwBackend.qml`), the parallax math (`parallax.js`), and how palette
generation is wired through `switchwall.sh` + matugen.

> Scope note: this covers the **standalone / II** family. The `Waffle Mode`
> card (`BackgroundConfig.qml:43-58`, `visible: !root.isIiActive`) is an
> info banner for waffle users only and is excluded here. In II mode
> `isIiActive = Config.options.panelFamily !== "waffle"`
> (`BackgroundConfig.qml:17`).

---

## 1. Where it lives

| Layer | File | Notes |
|---|---|---|
| Settings page registration | `settings.qml:46-51` | page `"Background"` (icon `"texture"`, `essential:false`), `component: "modules/settings/BackgroundConfig.qml"` |
| Settings page body | `modules/settings/BackgroundConfig.qml` (2157 lines) | 10 `SettingsCardSection` cards |
| Core service | `services/Wallpapers.qml` (990) | singleton `Wallpapers` — apply/select/random, per-monitor, video, thumbs, auto-cycle, queue |
| Reactive state | `services/WallpaperListener.qml` (215) | singleton `WallpaperListener` — per-monitor map from `Config` + compositor |
| Backend abstraction | `services/AwwwBackend.qml` | `supportsMainWallpaper`, `transitionDurationMs`, `active` |
| Parallax math | `modules/common/functions/parallax.js` (140) | `.pragma library` pure functions |
| Palette engine | `services/ThemeService.qml` + `services/MaterialThemeLoader.qml`, `scripts/colors/switchwall.sh` | matugen-driven |
| Renderer (UI, not service) | `modules/background/Background.qml`, `modules/background/Backdrop.qml` | consumes the config + `Wallpapers` |

> Fracture note: the widgets that live **"on the desktop background"**
> (Clock / Weather / Media / Visualizer / System Monitor / Battery) are
> configured on **pageIndex 14** (`settings.qml:501-557`, keyword
> `"background"`), not page 3. The conceptual "background section" is split
> across two settings pages.

---

## 2. Settings subsections (II mode)

Visibility is gated by `isIiActive` (`BackgroundConfig.qml:17`).

| # | Card | Line | II-only? | Config namespace |
|---|---|---|---|---|
| S2 | Parallax | 60 | yes (`:61`) | `background.parallax.*` |
| S3 | Multi-monitor | 211 | yes (`:212`) | `background.multiMonitor.*`, `background.wallpaperPath`, `background.backdrop.*` |
| S4 | Wallpaper backend (awww) | 1037 | shared | `background.backend` |
| S5 | Wallpapers folder | 1094 | shared | `background.wallpaperPath` |
| S6 | Shuffle wallpapers | 1114 | shared | `background.shuffle.*` |
| S7 | Wallpaper transitions | 1170 | yes (`:1171`) | `background.transition.*` |
| S8 | Wallpaper scaling | 1312 | yes (`:1313`) | `background.fillMode`, `background.pan` |
| S9 | Wallpaper effects | 1652 | yes (`:1653`) | `background.effects.ripple.*`, `background.backdrop.*` |
| S10 | Notifications | 2140 | shared | `background.hideUpscaleNotification` |

(The `Waffle Mode` card at `:43-58` is waffle-only and hidden in II.)

---

## 3. Config key tree (`background.*`)

```
background
├─ autoWallpaper { enable, intervalMinutes, generateColors, folder }
├─ backend
├─ wallpaperPath                (S3, S5)
├─ thumbnailPath
├─ wallpapersByMonitor [ { monitor, path, workspaceFirst, workspaceLast, backdropPath } ]
├─ fillMode                     (S8)            "fill" | "fit"
├─ pan                          (S8)
├─ enableAnimation
├─ hideUpscaleNotification      (S10)
├─ multiMonitor { enable, wallpaperPath }                  (S3)
├─ parallax { enable, axis, autoVertical, vertical,
│            zoom, workspaceZoom, workspaceShift, panelShift,
│            widgetDepth, widgetsFactor, enableWorkspace,
│            enableSidebar, pauseDuringTransitions, transitionSettleMs }   (S2)
├─ transition { style, direction, duration }               (S7)
├─ shuffle { ... }                                   (S6)
└─ effects
   ├─ ripple { enable, overview, hotcorners, lock, charging,
   │           session, reload, rippleDuration, sparkleIntensity,
   │           glowIntensity, ringWidth }             (S9)
   └─ backdrop { enable, useAuroraStyle, auroraOverlayOpacity,
                 hideWallpaper, useMainWallpaper, wallpaperPath,
                 blurRadius, dim, saturation, contrast,
                 vignetteEnabled, vignetteIntensity, vignetteRadius,
                 enableAnimation, enableAnimatedBlur }  (S3, S9)
```

Cross-style note (`BackgroundConfig.qml:52`): *"Only the **Backdrop** section
below applies to both styles."* → `background.backdrop.*` is the single shared
surface between II and Waffle.

---

## 4. Service architecture

### 4.1 `Wallpapers` (singleton) — `services/Wallpapers.qml`

Responsibilities:

- **Apply** `apply(path, darkMode, monitorName)` (`:538`) → requests a blur
  transition, then `_queueWallpaperScript` → `switchwall.sh --image --mode
  --skip-config-write [--noswitch]` (`:397-414`). Per-monitor applies write
  `background.wallpapersByMonitor` directly (`:584`) to avoid a config write race.
- **Targets** `applySelectionTarget(path, target, …)` (`:479`): `main`,
  `backdrop`, `waffle`, `waffle-backdrop`. Each writes the matching nested key
  (`background.backdrop.*`, `waffles.background.*`, …).
- **Select / random** `select`, `randomFromCurrentFolder` (`:694`, `:698`):
  folder navigation via `FolderListModelWithHistory` (`folderModel`, `:767`).
- **Per-monitor resolution** `currentMainWallpaperPath`,
  `currentWallpaperPathForTarget`, `currentThemingWallpaperPath` (`:307`,
  `:323`, `:53`) — reads `WallpaperListener.effectivePerMonitor` when
  multi-monitor is on.
- **Video first-frames** `ensureVideoFirstFrame` (`:137`): ffmpeg extracts a
  JPG, cached in `$XDG_CACHE_HOME/quickshell/video_thumbnails`,
  keyed by MD5 of the full path.
- **Thumbnails** Freedesktop thumbnail path math `getExpectedThumbnailPath`
  (`:222`); batch gen via `thumbgen-venv.sh` / magick fallback (`:871`).
- **Auto-cycle** `autoWallpaper` timer (`:918-988`): timed random swap,
  optional custom folder, optional color regeneration.
- **Apply queue / dedupe** `applyProc` with `activeRequestKey` /
  `pendingRequestKey` (`:442-462`), key =
  `[noswitch|switch, path, dark|light]` — replays the last queued request.

### 4.2 `WallpaperListener` (singleton) — `services/WallpaperListener.qml`

- Builds `effectivePerMonitor` map (`:38`) from `Config.options.background.*`
  + `Quickshell.screens` + compositor (`Hyprland.monitorFor`, `NiriService`).
- Reacts to `multiMonitorEnabled`, `wallpapersByMonitorRef`, `globalWallpaperPath`
  changes, `Quickshell.onScreensChanged`, and a debounced `Config.onConfigChanged`
  (80 ms, `:204-214`).
- `wallpaperUrlForScreen` (`:72`) returns a video-safe URL (thumbnail) for
  Aurora blur / color consumers.

### 4.3 `AwwwBackend` — `services/AwwwBackend.qml`

Backend abstraction: `active`, `transitionDurationMs`,
`supportsMainWallpaper(path)`. `Wallpapers._wallpaperTransitionSettleMs`
(`:386`) combines it with `background.transition.duration`.

### 4.4 `parallax.js` — `modules/common/functions/parallax.js`

`.pragma library` pure math. Presets `subtle / balanced / immersive`
(`:8-12`). Key functions: `effectiveScale`, `parallaxPosition`,
`centerOffset`, `resolveAxis`, `axisValue`, `resolveWidgetDepth`,
`resolveWorkspaceShift`, `resolveTransitionSettle`, `detectPreset`. Consumed by
the `Background.qml` renderer for widget Z-depth + workspace/panel shift.

### 4.5 Palette generation (matugen)

`Wallpapers.apply` calls `switchwall.sh` which runs **matugen**; palette then
flows through `ThemeService` / `MaterialThemeLoader` into `Appearance.m3colors`.
Hooks: `applyColorsOnly` (`Wallpapers.qml:572`),
`appearance.wallpaperTheming.useBackdropForColors` (`:498`, `:51`).

---

## 5. Complect (entanglement) map

| Edge | Ties together | Evidence | Severity |
|---|---|---|---|
| C1 | Parallax ↔ Desktop Widgets | `parallax.widgetDepth`/`widgetsFactor` (`:39-40,185-186`) set widget Z-depth (page 14 widgets) | High |
| C2 | Parallax ↔ Panel/Workspace/Sidebar | `enableWorkspace`, `enableSidebar`, `panelShift` (`:121,131,162-173`) | High |
| C3 | Whole page ↔ Panel family | `isIiActive` gates S2/S3/S7/S8/S9 (`:61,212,1171,1313,1653`) | High |
| C4 | Multi-monitor ↔ `Wallpapers` service | `Wallpapers.apply/select/ensureVideoFirstFrame/videoFirstFrames/randomFromCurrentFolder` (`:227,958,973,309,385,532,673,714,898`) | High |
| C5 | All cards ↔ `Appearance` theme families | ~30 × `Appearance.inirEverywhere ? Appearance.inir.* : … : Appearance.colors.*` 4-way ternaries (`:269-277,326-334,453-461,654-660,827-834`) | High |
| C6 | Effects.Ripple ↔ `modules/background` renderer | `effects.ripple.*` (`:1746-1875`) drive Fluid Ripple AOSP port (`Background.qml`) | Med |
| C7 | Effects.Backdrop ↔ Backdrop.qml + Aurora | `backdrop.useAuroraStyle` / `auroraOverlayOpacity` (`:1948,1964`) | Med |
| C8 | Backdrop config touched by two cards | `background.backdrop.*` edited in S3 (`:259,303`) and S9 (`:1892-2128`) | Med |
| C9 | `wallpaperPath` ×3 | `background.wallpaperPath` (S3 `:225,255`, S5) and `background.backdrop.wallpaperPath` (S9 `:1992,2007`) | Med |
| C10 | II parallax writes shared keys | `applyIiParallaxPreset` (`:32-41`) writes generic `background.parallax.*` (shared with waffle) | Med |
| C11 | Page 3 ↔ Page 14 fracture | Background effects (page 3) vs widgets on background (page 14) | High (discoverability) |

---

## 6. Diff vs a STATE-file / bash-driven setup (porting reference)

| Concern | iNiR (here) | STATE-file / bash setup |
|---|---|---|
| Current wallpaper source of truth | `Config.options.background.wallpaperPath` (JSON) + reactive `WallpaperListener` | flat `STATE` file read back via a process |
| Per-monitor | `background.wallpapersByMonitor` + compositor-aware map | single global wallpaper |
| Apply pipeline | one `switchwall.sh` (awww + matugen + config) | `wallpaper.sh` (awww) → separate `after-wall.sh` (colors) |
| Palette engine | **matugen** → `Appearance.m3colors` | custom engine (e.g. dominance-engine) → `colors.json` → palette singleton |
| Backend | abstracted `AwwwBackend` | hardcoded in shell script |
| Queue/dedupe | keyed (`activeRequestKey`/`pendingRequestKey`) | single-string replay |
| Thumbnails/video | in-QML (`Process` + ffmpeg/magick) | external thumbnail script |
| Auto-cycle | built-in timer | keybind "bag" shuffle only |
| Parallax | `parallax.js` (pure, portable) | none |

Fundamental divergences to decide on first when porting:

1. **Config model** — config-JSON-driven (reactive) vs STATE-file-driven.
2. **Palette engine** — matugen vs custom engine (the `Wallpapers.apply` color
   hook is the only seam).
3. **QML-heavy vs bash-heavy** — iNiR keeps thumbs/video/queue in QML.

Clean drop-in ports: `parallax.js`, the keyed apply-queue, `AwwwBackend`,
auto-cycle timer. Needs re-pointing: `Wallpapers.apply` (swap `switchwall.sh`
for your pipeline) and `WallpaperListener` (read your STATE or JSON). Novel /
optional: per-monitor map, matugen palette, video first-frames, the parallax
renderer consumer.
