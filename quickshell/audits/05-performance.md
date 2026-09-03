# Audit 05 — Performance
*Refreshed 2026-09-04 on branch `pill-perf`. Hardware: i3-1215U iGPU, 120Hz, Hyprland, aurora theme. Full plan with effort estimates: `plans/pill-perf-audit.md`.*

## Resolved since last audit ✅
- ~~P0: per-frame warning storm on the render thread~~ — `a13b119`, `e15503c`. Biggest single win; the morph no longer fights thousands of JS exceptions + log writes.
- ~~P1.1: Glass blurred a full-screen 1920×1080+bleed texture every morph frame~~ — ¼-res cached layer, ~16× less GPU work, `dc9b30b`.
- ~~P1.2: saturation as a separate per-frame shader pass~~ — folded into the cached layer's `layer.effect`; runs once per wallpaper change, `b84983d`.
- ~~P3: input-mask Region re-applied per morph frame~~ — verified already target-aware on open; close path intentionally tracks animated size so clicks never land on a vanished pill. Won't-fix by design.
- ~~P4: wallpaper thumbnails decoded at full resolution~~ — verified already `sourceSize: 512×220`.
- ~~P5: deprecation/hygiene log noise~~ — `b84983d`; steady-state log is clean.

## Open — where the remaining open-lag lives

### R1 — P2.1: layout feedback loops during the morph (~2h, needs approval)
Several surfaces' `implicitHeight` depends on the animating pill width, so every morph frame re-lays-out all 18 eager surfaces. Fix: give each surface a width-independent `implicitHeight` (bind to content, not to `pill.width`-derived values).

### R2 — P2.2: Loader-gate the surfaces (~1 day, needs approval)
`active: open || closingGrace` with the grace held one morph-duration after close for the fade-out. Eliminates the per-frame binding evaluation of closed surfaces entirely and makes per-screen duplication (D3) cheap. Biggest remaining structural win.

### R3 — P1.3: double blur on Hyprland (design call, see audit 01 D1)
QML Glass blur + compositor layerrule blur both run. Picking one halves the remaining per-frame blur cost.

### R4 — Timer/process sweep from the old root `AUDIT.md` (folded in on its deletion)
Still valid, never acted on: ~8×1000ms, 6×2000ms, 5×500ms pollers — several can become event-driven or `running: visible && …` (clock, system info, network state, battery). The two `interval: 1` timers are one-shot startup kicks (fine). 47 `Process {}` objects, some poll-based where a `FileView` watcher would do. Zero behavior change, steady background-CPU win.

## Measured state
- `qs log` steady state: clean (only environmental H2 noise).
- Glass GPU cost: ~130k px texture vs ~2MP before (16×).
- Aurora-mode side pills: 4 small Glass blurs sampling the ¼-res texture — negligible.

## Next recommended pass
R1 + R2 together (they share the same files), after your call on R3. If the pill already feels snappy enough after the P0/P1 fixes, R2 alone gives the best effort-to-win ratio.