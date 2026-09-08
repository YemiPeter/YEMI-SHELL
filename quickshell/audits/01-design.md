# Audit 01 — Design & Architecture
*Refreshed 2026-09-05 (2nd pass) on branch `pill-perf`. Outdated entries deleted; see git history for the old snapshot.*

## Resolved since last audit ✅
- ~~Shadow strategy split per compositor~~ — **done.** Single gate `Compositor.qmlShadows` (= `isNiri`) in `compositor/Compositor.qml`; every shadow site (Pill, Bar, Tray, AppIcons ×2) checks it. Hyprland gets zero QML shadows → the blur-halo bug class is closed.
- ~~Side pills visually inconsistent with center pill~~ — **done.** All four bar clusters host `Glass` under `Theme.auroraActive` and step their fill aside, matching the center pill's contract (`2d5693f`).
- ~~Glass blur cost~~ — **done.** ¼-res cached layer + saturation folded into the cache pass (`dc9b30b`, `b84983d`).

## Resolved this session ✅

### ~~D1 — Double blur on Hyprland~~ — **done (with a detour).**
The double-blur diagnosis was correct, but the first fix attempt (dropping Glass's blur, keeping only Hyprland's layerrule, `8819a34`) broke aurora mode entirely — Glass's own blur had *never* actually worked: its source Image sampled a permanently-empty `WallpaperState.current`, so Hyprland's layerrule blur had been carrying 100% of the visible frost the whole time. Final resolution:
- `Glass.qml` stripped to tint-only (no self-blur, no wallpaper-sampling machinery) — `5d64483`.
- Hyprland's native layerrule blur restored (`58b1e5c`) and is now the sole blur source in aurora mode.
- Bonus: `pillAlpha` now gates on `Theme.auroraActive`, not just compositor (`70ad1a1`) — solid mode is always fully opaque regardless of the opacity slider, closing a real leak.

### ~~D2 — Eager surface instantiation~~ — **done.**
Corrected count: **23 surfaces** (the old 18 was stale). All were eager except Toast.
- Toast's width→height re-target loop fixed (`27dab71`) — wrapped body text now measures against the settled width, not the animating one. Calendar's similar-but-conditional coupling (only while `editorShown`, bounded by `maximumLineCount`) deliberately left alone.
- All 23 surface-id references null-guarded as prep (`e3503cf`).
- `closingGrace` built from scratch (single-slot + `Motion.morph + 50` timer pattern) and 13 rarely-opened surfaces Loader-gated (`607d6e8`, `53aee79`, `e91674c`, `dd25cdb`): keybinds, recorder, sysmon, updates, look, appearance, display, input, idlelock, fontpicker, barpills, background, wallpaper.
- 10 stay eager (daily-driver / latency-critical): mixer, media, power, calendar, clipboard, launcher, osd, toast, link, bluetooth, battery.
- Confirmed by Yemi in practice: pill open/close noticeably smoother, no lag.
- All 13 Loader-gated surfaces visually spot-confirmed by Yemi: opens smoothly, no lag, no IPC errors.

### ~~D3 — Per-screen duplication~~ — **done (automatically, by D2).**
No separate work needed — D2's Loader-gating means each screen's `Variants` delegate only builds the surfaces it actually opens, so the multiplication cost is gone by construction.

## Open design decisions

### D4 — Glass polish backlog (folded from `plans/pill-aurora-glass-audit.md` §7 on its deletion)
- **Animated (GIF) wallpaper support** — investigated, **no Glass.qml change needed**: GIF handling already correctly lives in `Backdrop.qml` for Niri; Hyprland's awww deliberately excludes `.gif` entirely. Scope decision documented in Glass.qml's header.
- **Mood-gradient fallback when no wallpaper is set** — **done** (`139fa6e`), verified via pixel-diff screenshot comparison.
- Still open, not started, low priority: blur params as a user setting. ~~Frost-alignment verification during the fullscreen Translate transform~~ — **done** (`c08c441`): the opacity↔y-transform timing was captured at 10ms resolution and corrected (EXIT opacity now stays ~0 until the OutCubic slide completes, then rises on InQuint as the pill lands).

## Bugs found and fixed along the way ✅
Not part of the original audit; surfaced during D1–D4 work.
- **Wallpaper reverting to a stale pick on Niri shell reload** — root cause: a frozen "awww memory" file diverging from the live state file. Fixed by making `restoreProc` read the live state file directly (`209625b`) — matches reference project iNiR's architecture exactly, which has no memory file at all. Confirmed fully resolved by Yemi.
- **Backdrop's blur-before-image-ready race** (solid color until blur radius manually touched) — fixed with a `hasLoadedOnce` latch on the crossfader's `Image.Ready` signal (`278b981`).
- **Power.qml console error on every surface close** (phantom `kbFocus`/`pressed` property assignment on a Repeater id) — deleted, dead code, zero functional impact (`0d98472`).
- **Background.qml's height self-clamp silently broken** (NaN from an unresolvable cross-file `settings.implicitHeight` id reference) — fixed by passing `maxSurfaceH` in from Pill.qml where the id is actually in scope (`4bd2797`).
- **Two IpcHandlers both claiming `target: "pill"`, one fully dead** (`modules/pill/shell.qml`, deleted in `6555425`) — the live handler was missing 8 functions the dead one appeared to define. 5 ported and verified (system/recorder/screenrec/record/quickRecord, `456b200`); bluetooth/battery confirmed to map to real existing surfaces and **ported** (`ec07661`). Live pill IPC target now exposes all 20 functions.
- **Fullscreen pill opacity ran the stale easing on direction flip** — the shared `Behavior on opacity` snapshotted the wrong easing when entering/exiting fullscreen (EXIT rushed to ~57% opacity mid-slide; ENTER stayed opaque through the slide). Replaced with `State`+`Transition` per-direction easings (ENTER `OutCubic`, EXIT `InQuint`), making stale snapshots structurally impossible; verified with 10ms trajectory captures across toggle cycles (`c08c441`).
- **`wsId` parallax staleness on Niri** — `Niri.qml`'s `linkWorkspacesToMonitors()` mutated `activeWorkspace` on plain JS monitor objects, which emits no change signal, so a workspace switch only reached consumers when the *next* monitors poll completed (~0.5-1s later). Fixed by rebuilding + reassigning the monitors map (fires the `var` change notification) and re-linking from `parseWorkspaces()` in the same cycle; `BackdropParallax.wsId` also force-reads `Compositor.monitors` since `monitorFor()`'s internal reads don't reliably register binding dependencies (`9cf6505`). **Niri-only by construction** — parallax is Loader-gated to `Compositor.isNiri` (`Backdrop.qml:57`), and Hyprland's monitor objects are real notifying C++ properties, so nothing Hyprland-side was touched. Approach mirrors iNiR's notifying-property pattern (`~/iNiR`, `NiriService.qml`). Full event-stream socket (niri IPC, replacing the 500ms poll) is a possible future upgrade, not a bug.
- **Niri login flashed the wallpaper even with "hide wallpaper" ON** — `spawn-at-startup` ran `set-wallpaper.sh niri init` unconditionally (the script never checked `backdropHideWallpaper`), painting via awww before the shell existed; two painters with opposite intents. Resolved with the iNiR method (shell is the sole painter): the spawn line was removed from `niri/config.d/50-startup.kdl`; `Walls.qml`'s `Component.onCompleted → syncAwww()` already handles both startup cases (restore awww from the state file when hide is OFF, kill the daemon and let the mood-gradient own the screen when hide is ON). `niri validate` passes. Trade-off to be aware of: with hide OFF the desktop is black for the shell's startup gap instead of showing an early awww paint.

## Still open / carry forward ⏳
- Low priority, not started: D4 blur params as a user setting (see D4 above).

## Invariants to keep (do not regress)
- `Glass` must be the surface itself in aurora mode — never paint a card fill on top of it (double-dim).
- No translucent decorative pixels (shadows, glows) on blur-enabled layer surfaces on Hyprland.
- `Compositor.qmlShadows` is the only shadow gate; don't add per-file compositor checks.
- Glass is tint-only — never re-introduce self-blur or wallpaper-sampling into it; Hyprland's layerrule is the sole blur source (D1 lesson: Glass's blur silently never worked).