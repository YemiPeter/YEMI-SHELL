# Pill Performance Audit — open-path latency & jank

**Date:** 2026-09-03
**Compositor in effect:** Hyprland 0.55.4 · themeStyle `aurora` (Glass live)
**Hardware reality:** i3-1215U UHD Graphics (iGPU), 1080p @ 120 Hz
**Method:** audits/01–05 cross-read, then independent trace of the open path:
`PillState.toggleSurface → Pill.mode → width/height Behavior (420 ms) → per-frame
re-eval of everything bound to pill geometry`. Live `qs log` captured while the
shell idles and morphs.

---

## TL;DR

The pill doesn't struggle to open because of any single huge cost — it's three
stacked per-frame costs, each of which alone would be fine:

1. A **broken color binding spamming the render thread every frame** (audit B1,
   still unfixed — verified live).
2. An **aurora Glass blur re-rendering a full-screen source on every morph
   frame** on an iGPU, *while Hyprland also blurs the same wallpaper behind it*.
3. **18 eagerly-instantiated surfaces** whose layout bindings re-evaluate each
   frame of the 420 ms morph, some in a size↔content feedback loop with the
   pill itself.

---

## P0 — Binding-failure storm (audit 04 B1/B2, CONFIRMED STILL LIVE)

`Theme.flameGlow` / `Theme.flameCore` are still **not declared** on
`singletons/Theme.qml`. 38 call sites reference them across
`modules/pill/*`.

Live capture (idle shell, no interaction):

```
WARN scene: @modules/pill/Calendar.qml[656:25]: Unable to assign [undefined] to QColor
```

…repeating **per repaint, per calendar cell**. A failed QColor assignment
means: JS exception thrown inside the binding → string-formatted warning →
log write → property left unpolished → re-evaluated next frame. During the
420 ms morph at 120 Hz that is thousands of exception+log cycles inside the
render loop. This is not "cosmetic log noise"; it runs on the critical path
of every frame the pill animates.

Worst sites (per-frame or per-open): `Calendar.qml:656` (one per event-dot
cell, every repaint while the calendar is open — matches "calendar is the
slowest open"), `Filament.qml:62`, `Wallpaper.qml:405`. Per-state-change
sites: `Pill.qml:1035` (battery), `LinkBt`, `LinkWifi`, `Link`, `Osd`,
`Toast`, `Recorder`, `BatterySurface`.

**Fix (audit 04's own prescription, still pending):** declare
`flameGlow`/`flameCore` on `Theme.qml` (or re-point the 38 sites at existing
palette entries), then verify the warning stream goes silent. One hour of
work, likely the single biggest open-stutter win.

---

## P1 — Glass aurora blur: full-screen source re-blurred every morph frame

`Appearance.auroraEverywhere = themeStyle === "aurora" && isHyprland` — so on
- an `Image` sized **1920×1080 + 32 px bleed** with
  `sourceSize: ceil(width) × ceil(height)` — a ~2 MP texture per Glass
  instance,
- fed to `MultiEffect` with `blur: 0.5, blurMax: 24, saturation: 0.25`,
- **re-rendered every frame** the pill's `width`/`height` animate (morph is
  420 ms ≈ 50 frames at 120 Hz; hover morphs and toast/osd modes retrigger
  it too), because the mask rect and the effect's geometry change each frame,
- **stacked on top of Hyprland's own layerrule blur** of the same wallpaper —
  the iGPU blurs the wallpaper twice per frame during every open.

MultiEffect blur is multi-pass; at blurMax 24 over a 2 MP source that is far
outside the ~8 ms/frame budget of a UHD Graphics at 120 Hz. This is the
"struggle" — the pill's own animation fighting the blur for the GPU.

Glass is also instantiated in **`Tooltip.qml`** and **`Background.qml`** —
each holds its own screen-sized Image/texture. Any tooltip showing near a
morph doubles the cost again.

**Fixes, cheapest first:**

1. **Downscale `sourceSize` ÷4** (≈480×270). The blur radius (≥24 px) hides
   the resolution loss completely; texture memory and per-frame blur cost
   drop ~16×. Three-line change in `Glass.qml`, zero visual difference —
   do this first.
2. **Drop the `saturation` pass** on weak GPUs or fold the 0.25 saturation
   into the tint rectangle's color (it's a static adjustment of a blurred
   wallpaper; it does not need its own shader pass every frame).
3. **Pick one blur, not two.** On Hyprland the compositor already blurs
   behind the translucent pill body (`layerrule = blur on`). Either keep the
   QML Glass and drop the layerrule for the pill window, or keep the
   layerrule and render the Glass as tint-only (no `blurEnabled`). Design
   decision — but paying for both is the worst of the options.
4. (Optional) cache the blurred output while geometry animates:
   `layer.enabled` + `layer.cacheSource`-style freeze on the Glass during
   `morphCloseness < 1` — removes per-frame re-blur entirely, at the cost of
   a slightly stale frost mid-morph (invisible at blur radius 24).

this machine the aurora Glass in `Pill.qml` is **active right now**, and it is:


## P2 — 18 surfaces eagerly instantiated (audit 01 D3 / 05, quantified)

`Pill.qml` instantiates Mixer, Calendar, Launcher, Clipboard, Wallpaper,
Power, Media, Link ×2, BatterySurface, Settings, Keybinds, Recorder,
SysmonSurface, Appearance, Updates, Display, Input, Look, IdleLock,
FontPicker, BarPills, Background — **all at startup, none behind a Loader**
(the only Loader in the file is `toastLoader`).

`PillSurface` correctly gates `opacity`/`enabled`/`visible` (audit-verified),
so closed surfaces mostly don't *paint*. But every surface still:

- re-evaluates its **`morphCloseness`** binding on all ~50 frames of every
  morph (`morphCloseness` derives from animated `width`/`height`),
- contributes to **`targetSize`**: the `surfaces` descriptor calls
  `size()` thunks that read each surface's `implicitWidth`/`implicitHeight`
  (e.g. `calendarH: calendar.implicitHeight + 32*s`,
  `settingsH: settings.implicitHeight + 29*s`). Several surfaces' implicit
  heights depend on their width — which is `pill.width − margins` — which is
  animating. Result: a **pill↔surface layout feedback loop re-running every
  frame** of the morph. This is the classic "QML resize jank" pattern, times
  18 surfaces.
- keeps its **Timers** alive (25 in `modules/pill/*.qml`: Link 600 ms,
  LinkWifi 1200 ms, Wallpaper 600 ms, Media 500 ms, IdleLock 300 ms,
  Display 1000 ms, Recorder 1000 ms — most gated on `open`, some not
  audited), and **76 `Process {}` objects** (well-gated at the singleton
  layer — Sysmon/ScreenRec/Devices are the correct pattern; surface-local
  ones need a reachability check).

**Fix, phased:**

- **Phase 1 (mechanical, low risk):** break the feedback loop — surfaces
  report `implicitHeight` from *constant* content, never from
  parent-bound width. Audit each surface for `implicitHeight` depending on
  `width` and pin it (e.g. compute from `s`-scaled constants like `powerH`
  already does correctly).
- **Phase 2 (real win, larger refactor):** wrap each surface in
  `Loader { active: pill.<x>Open || pill.surface === "<x>" }`, keeping the
  fade-out alive with `active` held ~1 morph duration after close. The
  id-referencing helper functions (`mixerStep`, `keybindsMove`, …) need the
  `loader.item?.` guard — mechanical but wide.
- **Phase 3 (optional):** convert the per-open `size()` thunks to constants
  where the surface doesn't actually need intrinsic measurement (launcher,
  clipboard, media, recorder, sysmon… already are constants).

---

## P3 — Input mask re-applied every frame during morph

`PillOverlay.pillRegion` binds `pill.width`/`pill.height`/`targetW`/
`targetH` — the animated values. Every morph frame re-applies a Wayland input
region to the fullscreen overlay surface. Measured cost is small, but it's on
the same frame budget, and trivially avoidable: bind the Region to the
**target** geometry (or current + 1 frame lag) so the mask updates once per
open, not 50×. Hover-halo click accuracy within a 20 px pad is unaffected.

---

## P4 — Wallpaper surface open spike

`Wallpaper.qml` runs a 600 ms search timer and decodes wallpaper images for
thumbs at open. Ensure every thumb `Image` sets a downscaled `sourceSize`
(decode-at-size, not decode-then-scale) — a row of full-res decodes on open
is a multi-hundred-ms stall on this iGPU. *(Verify in the thumb delegate
before fixing — listed for completeness.)*

---

## P5 — Live-log hygiene (audits 04 B3–B7, still open)

Captured during this audit, all pre-existing per audit 04:
- `PillOverlay.qml[29]` — PanelWindow `height` deprecation (B6).
- `Updates.qml` used-before-declared handler vars ×5 (B4-adjacent).
- `MusicPanel.qml` deprecated `onFoo` Connections syntax.
- `StatusIndicators.qml` `setPaused()` on non-running animation (B7).
- Unresolvable imports `Background.qml → ../../../config`,
  `WallpaperCrossfader.qml → ../../singletons` (B5).

Each is small; together they keep the QML engine in warning paths on
startup and reload. Audit 05's note stands: the warning storm itself is a
performance cost.

---

## Recommended order

| # | Fix | Effort | Expected effect on open lag |
|---|-----|--------|------------------------------|
| 1 | Declare/re-point `flameGlow`+`flameCore` (P0) | ~1 h | Removes per-frame exception+log storm — biggest single win |
| 2 | Glass `sourceSize` ÷4 + fold saturation into tint (P1.1–1.2) | ~15 min | Morph frames go from multi-pass 2 MP blur to trivial |
| 3 | Single-blur decision: Glass vs layerrule (P1.3) | design | Halves remaining blur cost on Hyprland |
| 4 | Break implicitHeight↔width feedback loops (P2.1) | ~2 h | Layout stabilizes; morph no longer cascades through 18 surfaces |
| 5 | Loader-gate heavy surfaces (P2.2) | ~0.5–1 day | Startup + open allocation drops to near zero for closed surfaces |
| 6 | Mask region → target geometry (P3) | ~15 min | Small but free |
| 7 | P4/P5 hygiene sweep | ~1 h | Removes residual stalls and startup noise |

Steps 1–3 are safe, mechanical, and reversible; 4–5 change surface lifecycle
and deserve their own pass with per-surface verification.
