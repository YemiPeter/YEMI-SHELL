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
