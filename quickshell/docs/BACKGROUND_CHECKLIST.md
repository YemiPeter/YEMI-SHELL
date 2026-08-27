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
- [ ] **Reactive color loader** (watch `~/.cache/wal/colors.json`, expose palette)
  - iNiR equiv: `Dyn.qml` (but it watched `yemi-shell/colors.json` + dominance — do NOT copy; build pywal-aware loader)
  - Verify: editing/replacing `colors.json` updates shell colors live without restart.
- [ ] **`Wallpapers` service** (apply / select / random / auto-cycle / apply-queue)
  - iNiR equiv: `services/Wallpapers.qml`
  - Port priority: `apply`, `randomFromCurrentFolder`, keyed apply-queue first; video/thumbs/auto-cycle later.
  - Verify: `Wallpapers.apply(path)` sets wallpaper + colors; rapid repeat converges on last pick.
- [ ] **`WallpaperListener`** (reactive current-wallpaper + per-monitor state)
  - iNiR equiv: `services/WallpaperListener.qml`
  - Verify: reports correct current wallpaper; updates on monitor add/remove.
- [ ] **`AwwwBackend`** (backend abstraction + transition timing)
  - iNiR equiv: `services/AwwwBackend.qml`
  - Verify: `supportsMainWallpaper` / `transitionDurationMs` resolve; single place to swap backend.
- [ ] **`parallax.js`** (pure math, zero-dep)
  - iNiR equiv: `modules/common/functions/parallax.js`
  - Verify: `ParallaxMath.effectiveScale` / `parallaxPosition` / `axisValue` return sane numbers; no renderer needed to unit-check.

---

## B. Settings subsections (UI deferred — verify the service behind each)

- [ ] **S4 Wallpaper backend (awww)** → `background.backend`
  - Backing service: `AwwwBackend`
  - Verify: backend selection drives `awww` transition call.
- [ ] **S5 Wallpapers folder** → `background.wallpaperPath`
  - Backing service: `Wallpapers` (directory config)
  - Verify: setting folder changes source dir; applies from it.
- [ ] **S6 Shuffle wallpapers** → `background.shuffle.*`
  - Backing service: `Wallpapers.randomFromCurrentFolder`
  - Verify: shuffle picks a different image than current.
- [ ] **S7 Wallpaper transitions** → `background.transition.*`
  - Backing service: `AwwwBackend` + `Wallpapers`
  - Verify: chosen style/direction passed to `awww img --transition-*`.
- [ ] **S8 Wallpaper scaling** → `background.fillMode`, `background.pan`
  - Backing service: renderer scale (later UI)
  - Verify: fill vs fit behaves; pan offset applies.
- [ ] **S3 Multi-monitor** → `background.multiMonitor.*`, `background.wallpapersByMonitor`
  - Backing service: `WallpaperListener` + `Wallpapers.apply(monitorName)`
  - Verify: per-monitor wallpaper persists; `effectivePerMonitor` correct.
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
- [ ] **#4 Use separate wallpaper** → `backdrop.useMainWallpaper` + second source (`WallpaperState`-style)
- [ ] **#5 Backdrop wallpaper picker** → `selectionTarget: "waffle-backdrop"` selector
- [ ] **#6 Derive theme colors from backdrop** → `appearance.wallpaperTheming.useBackdropForColors` (cross-cuts ThemeService/matugen)
- [ ] **#7 Hide main wallpaper** → `backdrop.hideWallpaper` (semantic: yemi has one layer, needs design)
- [x] **#8 Backdrop blur** → `Flags.backdropBlurRadius` (0–100) on `Backdrop.qml` MultiEffect
- [x] **#9 Backdrop dim** → `Flags.backdropDim` kept 0–1 (UI shows %); default rescaled to 20% to match `backdrop.dim` (def 20)
- [x] **#10 Backdrop saturation** → `Flags.backdropSaturation` (−100..100) MultiEffect.saturation
- [x] **#11 Backdrop contrast** → `Flags.backdropContrast` (−100..100) MultiEffect.contrast
- [x] **#12 Enable vignette** (toggle) → `Flags.backdropVignetteEnable` gates `Backdrop.qml` + settings toggle
- [~] **#13 Vignette intensity** → `Flags.backdropVignette` already exists
- [x] **#14 Vignette radius** → `Flags.backdropVignetteRadius` (def 0.7) drives `Backdrop.qml` stops

### D2. Wallpaper Effects card — keys `waffles.background.*` / `waffles.background.effects.*`
- [ ] **Enable animated wallpapers** (global) → `waffles.background.enableAnimation`
- [ ] **Enable blur** (blur wallpaper when windows open) → `waffles.background.effects.enableBlur`
- [ ] **Blur animated wallpapers** → `waffles.background.effects.enableAnimatedBlur`
- [ ] **Blur radius** → `waffles.background.effects.blurRadius` (0–100, def 32)
- [ ] **Animated blur strength** → `waffles.background.effects.thumbnailBlurStrength` (0–100, def 70)
- [~] **Dim overlay** → overlaps D1 #9 (`dim`)
- [ ] **Extra dim with windows** → `waffles.background.effects.dynamicDim`

### D3. Excluded
- [x] **Ripple effects** — EXCLUDED by user (no port).

### Suggested one-at-a-time order
- **Tier A (cheap):** D1#1, D1#9 (rescale), D1#12, D1#14.
- **Tier B (effect pass):** D1#8 blur, D1#10 saturation, D1#11 contrast (same MultiEffect as `Glass`).
- **Tier C (media):** D1#2/#3 animated wallpapers; then D2 items.
- **Tier D (cross-cutting):** D1#4/#5 separate wallpaper, D1#6 derive theme colors, D1#7 hide-main.
