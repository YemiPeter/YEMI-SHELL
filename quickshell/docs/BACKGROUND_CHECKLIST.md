# iNiR Background → Yemi's Shell — Port Checklist

Progress tracker. Tick a subsection only when its service is ported **and**
verified against the test noted. Target stack: `awww` (wallpaper) +
`pywal` → `~/.cache/wal/colors.json`, QuickShell, Hyprland.

Legend: `[ ]` not started · `[~]` partial · `[x]` done & verified.

---

## A. Foundational services (do these first)

- [x] **Clean apply script (`awww` + `pywal`)**
  - File: `~/.config/scripts/set-bg.sh` (created)
  - Verify: `set-bg.sh <img>` changes wallpaper AND updates `~/.cache/wal/colors.json`; `awww query` shows new image.
- [x] **Reactive color loader** (watch `~/.cache/wal/colors.json`, expose palette)
  - iNiR equiv: `Dyn.qml` (but it watched `yemi-shell/colors.json` + dominance — do NOT copy; build pywal-aware loader)
  - yemi has `Dyn.qml` watching `~/.cache/yemi-shell/colors.json` (v2 contract from dominance engine). Live reload via FileView + revision bump. Pre-existing.
- [x] **`Wallpapers` service** (apply / select / random / auto-cycle / apply-queue)
  - iNiR equiv: `services/Wallpapers.qml`
  - Commit `ccbc83a`. Simplified for yemi: wraps `Walls.qml`, adds per-monitor apply, selection target routing, auto-shuffle timer.
  - Verify: `Wallpapers.apply(path)` sets wallpaper + colors; rapid repeat converges on last pick.
- [x] **`WallpaperListener`** (reactive current-wallpaper + per-monitor state)
  - iNiR equiv: `services/WallpaperListener.qml`
  - Commit `ccbc83a`. effectivePerMonitor map, multiMonitorEnabled, screenCount, isVideoPath/isGifPath, getMonitorName, getFocusedMonitor via Compositor.
  - Verify: reports correct current wallpaper; updates on monitor add/remove.
- [x] **`AwwwBackend`** (backend abstraction + transition timing)
  - iNiR equiv: `services/AwwwBackend.qml`
  - Commit `ccb326d`. Wraps awww CLI: supportsMainWallpaper(), normalizedAwwwTransitionType(), apply() with full transition flags, clear(), query(). Probes awww --help on startup.
  - Verify: `supportsMainWallpaper` / `apply` / `transition` resolve; single place to swap backend.
- [x] **`parallax.js`** (pure math, zero-dep)
  - iNiR equiv: `modules/common/functions/parallax.js`
  - Commit `ccb326d`. PRESETS subtle/balanced/immersive, detectPreset(), effectiveScale(), parallaxPosition(), axisValue().
  - Verify: `ParallaxMath.effectiveScale` / `parallaxPosition` / `axisValue` return sane numbers; no renderer needed to unit-check.

---

## B. Settings subsections (UI deferred — verify the service behind each)

- [ ] **S4 Wallpaper backend (awww)** → `background.backend`
  - Backing service: `AwwwBackend`
  - Verify: backend selection drives `awww` transition call.
- [x] **S5 Wallpapers folder** → `background.wallpapers.directory` text field in `Background.qml`. Commit `4bf9630`.
  - Verify: set custom dir, confirm `Walls.wpDir` would pick it up (directory swap deferred).
- [x] **S6 Shuffle wallpapers** → `background.autoWallpaper.*` toggles + interval + regenerate-colors + optional folder in `Background.qml`. Auto-shuffle timer in `Wallpapers.qml`. Commit `4bf9630`.
  - Verify: enable shuffle, wait interval, confirm random wallpaper applies; colors regen when toggle is on.
- [ ] **S7 Wallpaper transitions** → deferred: needs `AwwwBackend` service for transition styles/directions/durations.
- [ ] **S7 Wallpaper transitions** → `background.transition.*`
  - Backing service: `AwwwBackend` + `Wallpapers`
  - Verify: chosen style/direction passed to `awww img --transition-*`.
- [ ] **S8 Wallpaper scaling** → `background.fillMode`, `background.pan`
  - Backing service: renderer scale (later UI)
  - Verify: fill vs fit behaves; pan offset applies.
- [x] **S3 Multi-monitor toggle** → `background.multiMonitor.enable` toggle exists in `Background.qml` Wallpaper group (`wallpaperMultiMonitorEnable`). Full management panel deferred to D6.2 (monitor cards, Change/Random/Apply buttons, backdrop view).
- [ ] **S2 Parallax** → `background.parallax.*`
  - Backing service: `parallax.js` + depth renderer (NOT portable until renderer exists)
  - Verify: `ParallaxMath` resolves; SDK shift/sidebar offset computed. **Defer until A has wallpaper+color+renderer.**
- [ ] **S9 Wallpaper effects** → `background.effects.ripple.*`, `background.backdrop.*`
  - Backing service: renderer (Ripple AOSP port) + `WallpaperListener` (backdrop)
  - Verify: ripple/backdrop toggles affect render. **Defer (renderer-dependent).**
- [ ] **S10 Notifications** → `background.hideUpscaleNotification`
  - Backing service: notification subsystem
  - Verify: toggle hides upscale notification.

---

## C. Cross-cutting (verify once)

- [ ] Single source of truth: config JSON (`background.*`) OR STATE file — pick one, not both.
- [ ] Palette engine is `pywal` only (no `matugen` / `dominance-engine` leakage).
- [ ] No file in `~/.local/share/hypr/hyprland.conf` (HyDE master) is touched.
- [ ] Each ported subsection has a test command recorded here.

---

### Dependency order
A (apply → loader → Wallpapers → Listener → AwwwBackend → parallax.js)
→ B in order S4, S5, S6, S7, S8, S3
→ S2 / S9 / S10 last (renderer-dependent).

---

## D. Wallpaper-effects port (Backdrop Overview + Wallpaper Effects cards)

Scope decided with user: **drop ripple** and keep **aurora** (now ported).
Renderer target: `modules/background/Backdrop.qml`. Settings target:
`modules/pill/Background.qml` (Backdrop group) + `modules/pill/Appearance.qml`
(theme toggle already added). Persist new keys in `singletons/Flags.qml`.
iNiR source of truth: `modules/waffle/settings/pages/WBackgroundPage.qml`
(cards "Backdrop (Overview)" `:1136` and "Wallpaper Effects" `:1065`) and
`modules/waffle/backdrop/WaffleBackdrop.qml`.

Legend: `[ ]` not started · `[~]` partial · `[x]` done & verified.

### D0. Aurora theme (FOUNDATION — done)
- [x] Aurora theme engine (`Flags.themeStyle`, `Appearance.aurora`, translucent layers)
  - Commit `783e34a`. Toggle in APPEARANCE (Yemi/Aurora).
- [x] Frosted `Glass` component + pill/tooltip wiring
  - Commit `01c7343`. `modules/common/Glass.qml` (MultiEffect blur + aurora tint).

### D1. Backdrop (Overview) card — keys `waffles.background.backdrop.*`
- [x] **#1 Enable backdrop** (master gate) → `Flags.backdropEnable`; gate `Backdrop.qml` (see commit below)
- [x] **#2 Enable animated wallpapers** (GIF) → `Flags.backdropEnableAnimation` + `Backdrop.qml` `AnimatedImage` (video deferred: needs QtMultimedia)
- [x] **#3 Blur animated wallpapers** → `Flags.backdropEnableAnimatedBlur` gates `wallFx` blur on GIF
- [x] **#4 Use separate wallpaper** → `Flags.backdropUseMainWallpaper` + second source (`WallpaperState`-style) — commit `3f82b75`
- [x] **#5 Backdrop wallpaper picker** → `selectionTarget: "backdrop"` selector + `Flags.backdropWallpaperPath` — commit `3f82b75`
- [x] **#6 Derive theme colors from backdrop** → `Flags.backdropThemeColors` + `after-wall.sh` swaps color source to `backdropWallpaperPath`; toggle in BACKGROUND→Backdrop re-runs `after-wall.sh`; picker regenerates when on
  - Verify: set a separate backdrop image, enable "Theme from backdrop", confirm `colors.json` dark/light shift to the backdrop image's palette (check `jq '.dark.primary' ~/.cache/yemi-shell/colors.json`).
- [x] **#7 Hide main wallpaper** → `Flags.backdropHideWallpaper`; suppresses the external wallpaper daemon (skwd/wallpaper.sh) so the QuickShell backdrop overlay is the sole renderer — mirrors iNiR `backdrop.hideWallpaper` (`externalMainWallpaperEligible=false`). `Backdrop.qml` keeps drawing the image; `Walls.qml` skips the daemon apply while hide is on and `stateProc` keeps `current` on the applied pick.
  - Verify: with a separate backdrop image set, enabling "Hide main wallpaper" makes the backdrop image the only thing painted (daemon no longer draws the desktop wallpaper). Toggle OFF restores the external daemon apply.
- [x] **#8 Backdrop blur** → `Flags.backdropBlurRadius` (0–100) on `Backdrop.qml` MultiEffect
- [x] **#9 Backdrop dim** → `Flags.backdropDim` kept 0–1 (UI shows %); default rescaled to 20% to match `backdrop.dim` (def 20)
- [x] **#10 Backdrop saturation** → `Flags.backdropSaturation` (−100..100) MultiEffect.saturation
- [x] **#11 Backdrop contrast** → `Flags.backdropContrast` (−100..100) MultiEffect.contrast
- [x] **#12 Enable vignette** (toggle) → `Flags.backdropVignetteEnable` gates `Backdrop.qml` + settings toggle
- [x] **#13 Vignette intensity** → `Flags.backdropVignette` exists (0–1)
- [x] **#14 Vignette radius** → `Flags.backdropVignetteRadius` (def 0.7) drives `Backdrop.qml` stops

### D2. Wallpaper Effects card — keys `waffles.background.*` / `waffles.background.effects.*`
- [x] **UI card added to `modules/pill/Background.qml`** → "Wallpaper Effects" group with all 7 controls. Commit `27b5bc6`. iNiR source: `WBackgroundPage.qml` `:1065-1134`.
- [x] **Flags keys added** → `wallpaperEnableAnimation`, `wallpaperEnableBlur`, `wallpaperEnableAnimatedBlur`, `wallpaperBlurRadius`, `wallpaperAnimatedBlurStrength`, `wallpaperDim`, `wallpaperDynamicDim`. Commit `27b5bc6`.
- [x] **Renderer wiring** → new `modules/background/Wallpaper.qml` PanelWindow renders main wallpaper with global effects (blur, dim, animation). `Backdrop.qml` reduced to backdrop-only effects. Commit `46e691c`.
- [ ] **Dynamic dim with windows** → deferred: requires `NiriService` window-presence detection to drive `wallpaperDynamicDim` extra dim.

### D6. Missing UI cards from iNiR WBackgroundPage.qml
- [x] **D6.1 Wallpaper card** (top of page) → toggles added to `modules/pill/Background.qml`:
  - "Use Material wallpaper" (`wallpaperUseMainWallpaper`) — gated in `Backdrop.qml`
  - "Per-monitor wallpapers" (`wallpaperMultiMonitorEnable`)
  - "Hide when fullscreen" (`wallpaperHideWhenFullscreen`) — fullscreen detection deferred (needs NiriService)
  - Wallpaper folder browser strip → **deferred** (needs `Wallpapers` service folderModel/thumbnail pipeline from section A)
  - Commit `97ca27a`. iNiR source: `WBackgroundPage.qml` `:90-315`
- [ ] **D6.2 Multi-monitor card** → lazy-loaded when `background.multiMonitor.enable` is true:
  - Visual monitor cards with hover scale/opacity, selection border, video/GIF badge, resolution label
  - Buttons: Change, Random, Reset to global, Apply to all, View backdrop / Change backdrop / Back to wallpaper
  - Inline wallpaper browser with video-first-frame + "Change" routing per monitor
  - "Derive theme colors from backdrop" switch
  - iNiR source: `WBackgroundPage.qml` `:317-1063`
- [ ] **D6.3 Desktop Clock card** → all clock widget settings (placement, style, time format, seconds, date, font, dim, scale, shadow, lock status, animate time change)
  - iNiR source: `WBackgroundPage.qml` `:1286-1477`

### D3. Excluded
- [x] **Ripple effects** — EXCLUDED by user (no port).

### D4. niri overview backdrop (the actual "show wallpaper behind workspaces" goal)
- [x] **Backdrop layer namespace** → `Backdrop.qml` now sets `WlrLayershell.namespace: "quickshell:yBackdrop"` so a niri layer-rule can match it.
- [x] **`place-within-backdrop true` rule** → added to `~/.config/niri/config.d/80-layer-rules.kdl` for `quickshell:yBackdrop` (mirrors the iNiR `quickshell:iiBackdrop`/`wBackdrop` rules). Keeps the wallpaper stationary and filling the whole overview canvas instead of being attached per-workspace (which zoomed and left solid gaps).
- [x] **`layout { background-color "transparent" }`** → already present in `~/.config/niri/config.d/20-layout-and-overview.kdl` (so gaps between zoomed workspaces don't show a solid block).
- [ ] **skwd daemon namespace (optional)** → if the wallpaper is actually painted by the `skwd` daemon rather than QuickShell's backdrop, also add a `place-within-backdrop true` rule for skwd's layer namespace. Namespace unknown; can be fetched from `niri` active-layer query if the wallpaper still zooms in overview.

### D5. Missing from iNiR Background.qml (found by source audit)
- [ ] **Fill modes** → `Image.FillMode` mapping for `fit`, `tile`, `center` (in addition to `fill`); expose in settings.
  - iNiR equiv: `Background.qml` `fillMode` + `Image.PreserveAspectFit/Tile/Pad`.
  - Verify: each mode behaves as expected.
- [ ] **Video wallpapers** → `Video` + `MediaPlayer`; first-frame thumbnail via `ffmpeg`; play/pause tied to lock/game-mode/overview; `loops: MediaPlayer.Infinite`; `muted: true`; `source` file:// URI handling.
  - iNiR equiv: `Background.qml` `videoWallpaper` block.
  - Verify: mp4/webm plays when enabled; pauses on lock/overview; first frame visible when paused.
- [ ] **Wallpaper transitions** → `WallpaperCrossfader` component; `enableTransitions`, `transitionType` (crossfade/slide), `transitionDirection`, `transitionBaseDuration`, `bezier` curve; container resize disabled during transitions.
  - iNiR equiv: `Background.qml` `wallpaper` + `wallpaperContainer` Behaviors.
  - Verify: transition fires on wallpaper change; bezier/duration respect config.
- [ ] **Multi-monitor rendering** → per-monitor wallpaper path lookup; Niri workspace range per output (`workspaceFirst`/`workspaceLast`); `usePerMonitorRange` gate.
  - iNiR equiv: `Background.qml` `_multiMonEnabled`, `monitorName`, `usePerMonitorRange`, `effectiveWorkspaceFirst/Last`.
  - Verify: different wallpapers per monitor; parallax range matches output workspaces.
- [ ] **Work safety** → hide wallpaper when `fileKeywords` match path AND `networkNameKeywords` match current SSID; fallback to dimmed solid color.
  - iNiR equiv: `Background.qml` `wallpaperSafetyTriggered` + `color` fallback.
  - Verify: trigger on matching file+network; restore when either changes.
- [ ] **Dynamic dim on windows** → `focusPresenceProgress` (0→1) driven by whether current workspace has windows; drives blur/dim/vignette only when windows present.
  - iNiR equiv: `Background.qml` `hasWindowsOnCurrentWorkspace`, `focusPresenceProgress`.
  - Verify: dim/blur off on empty workspace; on when windows open.
- [ ] **Awww reveal** → instant crossfader hide → awww transition → fade back in; `_manualWallpaperScaleOverride` during reveal.
  - iNiR equiv: `Background.qml` `_awwwRevealOpacity`, `_awwwParallaxRevealNeeded`, `_awwwRevealAnimation`.
  - Verify: awww transitions play without double-image; scale override clears after settle.
- [ ] **Keyboard focus OnDemand** → `WlrLayershell.keyboardFocus: OnDemand` when notes/text widget needs input; `None` otherwise.
  - iNiR equiv: `Background.qml` `_needsKeyboardFocus` + `keyboardFocus`.
  - Verify: sticky notes receive typing without stealing focus from apps when disabled.
- [ ] **Parallax transition pause** → freeze parallax position during wallpaper/family transitions; resume with settle timer.
  - iNiR equiv: `Background.qml` `beginParallaxTransition`, `parallaxTransitionActive`, `parallaxResumeProgress`.
  - Verify: wallpaper shift stops during transition; resumes smoothly after.
- [ ] **Wallpaper metrics** → `magick identify` for natural size; decode at `screen.width × monitor.scale`; cache by path.
  - iNiR equiv: `Background.qml` `getWallpaperSizeProc`, `_wallpaperSizeCache`.
  - Verify: no pixelation from CPU upscale; cache hit on second switch to same wallpaper.

### Suggested one-at-a-time order
- **Tier A (cheap):** D1#1, D1#9 (rescale), D1#12, D1#14.
- **Tier B (effect pass):** D1#8 blur, D1#10 saturation, D1#11 contrast (same MultiEffect as `Glass`).
- **Tier C (media):** D1#2/#3 animated wallpapers; then D2 items.
- **Tier D (cross-cutting):** D1#4/#5 separate wallpaper, D1#6 derive theme colors, D1#7 hide-main.
- **Tier E (missing UI cards):** D6.1 Wallpaper card → D6.2 Multi-monitor card → D6.3 Desktop Clock card.

### Dependency order
A (apply → loader → Wallpapers → Listener → AwwwBackend → parallax.js)
→ B in order S4, S5, S6, S7, S8, S3
→ S2 / S9 / S10 last (renderer-dependent).
→ D6 UI cards (need Wallpapers service + WallpaperListener + Flags keys already in place from D1/D2).
