# Audit 05 — Performance
*Refreshed 2026-09-05 on branch `pill-perf`. Hardware: i3-1215U iGPU, 120Hz, Hyprland, aurora theme. Full plan with effort estimates: `plans/pill-perf-audit.md`.*

## Resolved since last audit ✅
- ~~P0: per-frame warning storm on the render thread~~ — `a13b119`, `e15503c`. Biggest single win; the morph no longer fights thousands of JS exceptions + log writes.
- ~~P1.1: Glass blurred a full-screen 1920×1080+bleed texture every morph frame~~ — ¼-res cached layer, ~16× less GPU work, `dc9b30b`.
- ~~P1.2: saturation as a separate per-frame shader pass~~ — folded into the cached layer's `layer.effect`; runs once per wallpaper change, `b84983d`.
- ~~P3: input-mask Region re-applied per morph frame~~ — verified already target-aware on open; close path intentionally tracks animated size so clicks never land on a vanished pill. Won't-fix by design.
- ~~P4: wallpaper thumbnails decoded at full resolution~~ — verified already `sourceSize: 512×220`.
- ~~P5: deprecation/hygiene log noise~~ — `b84983d`; steady-state log is clean.
- ~~**R1 — P2.1: layout feedback loops during the morph**~~ — several surfaces' `implicitHeight` depended on the animating pill width, re-laying-out all 23 eager surfaces every morph frame. Fixed: Toast's wrapped body text now measures against the settled width (`27dab71`); all 23 surface-id references null-guarded (`e3503cf`); 13 rarely-opened surfaces Loader-gated so closed surfaces don't evaluate bindings at all (`607d6e8`, `53aee79`, `e91674c`, `dd25cdb`).
- ~~**R2 — P2.2: Loader-gate the surfaces**~~ — `active: open || closingGrace` with the grace held one morph-duration after close for the fade-out. Eliminates the per-frame binding evaluation of closed surfaces entirely and makes per-screen duplication (D3) cheap. Implemented with a single-slot + `Motion.morph + 50` timer pattern (`607d6e8`); 13 surfaces gated (keybinds, recorder, sysmon, updates, look, appearance, display, input, idlelock, fontpicker, barpills, background, wallpaper); 10 stay eager (mixer, media, power, calendar, clipboard, launcher, osd, toast, link, bluetooth, battery).
- ~~**R3 — P1.3: double blur on Hyprland**~~ — QML Glass blur + compositor layerrule blur both ran. Resolved by stripping Glass to tint-only (`5d64483`) and restoring Hyprland's native layerrule blur as the sole frost source (`58b1e5c`). See audit 01 D1 for the full detour story.

## Open — where the remaining open-lag lives

### R4 — Timer/process sweep from the old root `AUDIT.md` (folded in on its deletion)
Still valid, never acted on: ~8×1000ms, 6×2000ms, 5×500ms pollers — several can become event-driven or `running: visible && …` (clock, system info, network state, battery). The two `interval: 1` timers are one-shot startup kicks (fine). 47 `Process {}` objects, some poll-based where a `FileView` watcher would do. Zero behavior change, steady background-CPU win.

## Measured state
- `qs log` steady state: clean (only environmental H2 noise).
- Glass GPU cost: ~130k px texture vs ~2MP before (16×).
- Aurora-mode side pills: 4 small Glass blurs sampling the ¼-res texture — negligible.
- Pill morph: confirmed by Yemi to be noticeably smoother after D2 Loader-gating (13 surfaces no longer evaluate bindings while closed).
- Live IPC target: all 20 pill functions registered and verified (13 original + 7 ported from dead handler).

## Next recommended pass
R4 (timer/process sweep) is the only remaining open performance item. ~8×1000ms, 6×2000ms, 5×500ms pollers — several can become event-driven or `running: visible && …` (clock, system info, network state, battery). Zero behavior change, steady background-CPU win.