# Audit 01 — Design & Architecture
*Refreshed 2026-09-04 on branch `pill-perf`. Outdated entries deleted; see git history for the old snapshot.*

## Resolved since last audit ✅
- ~~Shadow strategy split per compositor~~ — **done.** Single gate `Compositor.qmlShadows` (= `isNiri`) in `compositor/Compositor.qml`; every shadow site (Pill, Bar, Tray, AppIcons ×2) checks it. Hyprland gets zero QML shadows → the blur-halo bug class is closed.
- ~~Side pills visually inconsistent with center pill~~ — **done.** All four bar clusters host `Glass` under `Theme.auroraActive` and step their fill aside, matching the center pill's contract (`2d5693f`).
- ~~Glass blur cost~~ — **done.** ¼-res cached layer + saturation folded into the cache pass (`dc9b30b`, `b84983d`).

## Open design decisions

### D1 — Double blur on Hyprland (P1.3, needs your call)
The pill's `Glass` blurs the wallpaper in QML **and** Hyprland's `layerrule = blur on` (namespaces `quickshell`, `pill`, `pill-tray`) blurs the same wallpaper behind the surface. Two full blur chains for one visual. Options:
- **A.** Drop the QML Glass blur on Hyprland, lean on the layerrule (saves the most GPU; loses the aurora tint/saturation character; Niri path stays Glass-only).
- **B.** Keep Glass, remove blur from the layerrules (one code path for both compositors; loses compositor-native blur on the bar strip).
- **C.** Status quo (correct visuals, double cost).
Recommendation: **B** — one blur implementation to tune, and it already matches Niri.

### D2 — Eager surface instantiation (P2, needs approval)
All 18 pill surfaces are created at startup and re-evaluate geometry bindings every morph frame; several surfaces' `implicitHeight` depends on the *animating* pill width → layout feedback loop during the 420ms morph. Two-phase fix in `plans/pill-perf-audit.md`: (1) break the loops (~2h), (2) `Loader`-gate surfaces with `active: open || closingGrace` (~1 day). This is where the remaining open-lag lives.

### D3 — Per-screen duplication
`PillOverlay.qml` uses `Variants` per screen — each screen gets its own full pill + surface tree. Fine for 1–2 monitors; with 3+, the eager-instantiation cost (D2) multiplies. Loader-gating D2 makes this cheap by construction.

## Invariants to keep (do not regress)
- `Glass` must be the surface itself in aurora mode — never paint a card fill on top of it (double-dim).
- No translucent decorative pixels (shadows, glows) on blur-enabled layer surfaces on Hyprland.
- `Compositor.qmlShadows` is the only shadow gate; don't add per-file compositor checks.