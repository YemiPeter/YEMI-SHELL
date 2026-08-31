# Pill Aurora Glass — Design & UI Audit

**Target:** Aurora blur background for the pill (`modules/common/Glass.qml`) and its consumers
**Date:** 2026-08-29
**Status:** P0 fixes landed (see §5); polish items still open

---

## 1. What "Aurora" is

- A theme style: `Flags.themeStyle` = `"yemi"` (default) | `"aurora"`, toggled in
  pill Appearance → Theme style (`modules/pill/Appearance.qml`).
- When active, `config/Appearance.qml` transparentizes the surface tokens
  (`yemiTileBg` / `yemiCardTop` / `yemiCardBot` by `aurora.layerTransparentize`
  = 0.32, ×0.75 in light mood) so the wallpaper shows through.
- `modules/common/Glass.qml` is the blur background itself: a Rectangle that
  draws a blurred copy of the live wallpaper (`WallpaperState.current`) plus an
  aurora tint (`aurora.colSubSurface`). Only paints when aurora is active.

## 2. Glass consumers

| Consumer | Usage |
|---|---|
| `modules/pill/Pill.qml:494` | `Glass { anchors.fill: parent; radius: pill.morphRadius }` behind the pill body |
| `modules/pill/Tooltip.qml:62` | `Glass { anchors.fill: parent; radius: bubble.radius }` — 5 instances total (Mixer ×4, Clipboard ×1) |
| `modules/altswitcher/AltSwitcher.qml` | NOT Glass — uses compositor-level `BackgroundEffect.blurRegion` (real blur) |

## 3. Findings

### Glass.qml (the blur background itself)

1. **HIGH — Square-corner clipping bug.** `clip: true` on a Rectangle clips to
   the bounding rect, not the rounded corners. The blurred wallpaper pokes out
   as square corners beyond the rounded `radius`; the tint Rectangle on top has
   a radius but doesn't mask the image behind it. Fix: rounded masking
   (layer + OpacityMask or a rounded ShaderEffectSource), not `clip`.
2. **HIGH — No `sourceSize` on the wallpaper Image.** Every Glass instance
   decodes the full-resolution wallpaper (4K-class). With ~6 instances
   (pill + 5 tooltips) that's ~6 full decodes in VRAM for tiny frost cards.
   Fix: `sourceSize: Qt.size(width * dpr, height * dpr)`.
3. **MEDIUM — Image loads even when inactive.** `wp.source` is bound
   unconditionally; in the default "yemi" style the Glass is invisible but the
   wallpaper still decodes. Bind `source` to `root.active`.
4. **MEDIUM — Misaligned frost (fake glass).** `PreserveAspectCrop` centers the
   wallpaper inside each card, so the blur shown is the *center* of the
   wallpaper scaled to the card — not the wallpaper region actually behind the
   card. Decorative, not a true backdrop sample. Could compute the crop offset
   from the pill's screen position to sample the correct region.
5. **LOW — Static only.** Animated (GIF) wallpapers are not reflected; Glass
   always shows the still image.
6. **LOW — Hardcoded blur params.** `blur: 0.6`, `blurMax: 64`,
   `saturation: 0.25` are fixed; not tied to any user setting.
7. **LOW — No fallback.** If `WallpaperState.current` is empty the glass is
   tint-only; a mood-gradient fallback would look better than flat tint.

### Pill.qml body ↔ Glass layering (aurora double-dim)

8. **HIGH — Double transparency in aurora mode.** The pill body paints
   `Theme.cardBot` at `Flags.pillOpacity` (0.55) — but in aurora mode cardBot is
   *already* transparentized by 0.32. Effective fill ≈ 0.37 alpha stacked over
   the Glass tint (itself 0.42-transparentized). Result: muddier/darker than
   the aurora design intends. Either skip the body fill in aurora mode or use
   the aurora token consistently in one place.
9. **MED — Same double-alpha in the media `bud`** gradient
   (`Qt.alpha(Theme.cardTop, pillOpacity)` where cardTop is already
   aurora-transparentized).
10. **LOW — Hardcoded border alpha.** Body border uses
    `Qt.rgba(cream..., 0.10)` instead of the `Theme.frameBorder` token.

### Tooltip.qml

11. **HIGH — Gradient over glass.** The bubble paints a cardTop→cardBot
    gradient *over* the Glass; in aurora mode both layers are already
    transparentized → the tooltip can be near-unreadable over a bright
    wallpaper.
12. **MEDIUM — Pointer triangle mismatch.** The Canvas arrow paints
    `Theme.cardBot` (translucent in aurora) with no glass behind it → alpha
    mismatch against the bubble body.

### Systemic / cleanup

13. **Three blur systems coexist:** Glass (fake QML blur) for pill/tooltip,
    `BackgroundEffect.blurRegion` (real compositor blur) for AltSwitcher, and
    the wallpaper backdrop blur (`Flags.backdropBlurRadius`). Plus a
    commented-out Hyprland `pill-blur` layer rule in `Look.qml` ("BLUR
    DISABLED") and the orphaned `Flags.pillBlur` flag it drove. A cleanup
    should pick one strategy per surface and remove or wire the dead flag.
14. **Backup files in tree:** `modules/pill/Mixer.qml.bak`, `modules/pill/lib/binds.js.bak`.

## 4. Suggested fix order (original)

1. Glass.qml: rounded-corner mask + `sourceSize` + gate `source` on `active`
   (fixes 1–3, biggest visual + perf win).
2. Decide the aurora layering contract: Glass provides the surface; body/
   tooltip stop double-painting transparentized tokens over it (8, 9, 11, 12).
3. Optional polish: position-aware crop (4), blur setting hook (6), fallback
   gradient (7), token cleanup (10), dead-flag/backup-file cleanup (13, 14).

## 5. Landed fixes (2026-08-29)

Order flipped per review: transparency contract before geometry, cleanup
commit first so the fix diffs stay reviewable.

| Commit | What |
|---|---|
| `8ea47d1` | Cleanup: dead `Flags.pillBlur` flag, `pill-blur` layer rule + hooks, parked UI block, `Mixer.qml.bak`, `binds.js.bak` (findings 13, 14) |
| `da5e978` | Transparency contract (findings 8, 9, 10, 11, 12 + hidden `Media.qml` stacking site): token layer owns theme translucency, paint layer owns user alpha (`pillOpacity`) applied exactly once against **base** tokens; Glass-backed surfaces skip token fills. `Theme` gains `cardTopBase`/`cardBotBase`/`auroraActive`; `Glass` gains `tintScale`. |
| `96f9894` | Glass rounded-corner mask via `MultiEffect.maskEnabled` + white rounded-rect `maskSource` (channel-agnostic), `sourceSize` card-size decode, wallpaper load gated on aurora being active (findings 1, 2, 3) |
| `9c4ec3c` | Frost readiness gate: the blur fades in only once the wallpaper `Image` is `Ready`, so activating Aurora (or changing wallpaper) never flashes a tint-only card. `active` itself verified stable across the theme-style switch (plain JsonAdapter comparison; write/reload re-assigns the same value). |

**Contract (decided):** the token layer owns theme translucency (aurora
transparentize stays for non-Glass consumers, e.g. bar pills); the paint layer
owns user alpha — `Flags.pillOpacity` and design alphas apply exactly once,
always to base tokens, never on top of an already-transparentized token. When
a card is Glass-backed, the Glass IS the surface.

**Flagged, not touched:** `Bar.qml:23` `pillBg = cardBot @ 0.7` is the same
pattern but a 2-layer stack (token + fixed alpha) with no `pillOpacity`
involved — that IS the intended aurora translucency for bar pills. Revisit
only if bar pills look wrong in aurora.

## 6. Newly observed runtime warnings (pre-existing, unfixed)

From a clean shell start after the fixes — none originate in the changed files:

- `modules/pill/Calendar.qml[656:25]` (and 636): `Unable to assign [undefined] to QColor` (repeats)
- `modules/pill/Background.qml[697:21]`: `ReferenceError: isDirectional is not defined`
  (unqualified reference to the Group's property from inside a FieldRow under
  `pragma ComponentBehavior: Bound`)
- `modules/pill/PillOverlay.qml[29:5]`: deprecated `height` on PanelWindow (use `implicitHeight`)
- `modules/music/MusicPanel.qml[742:5]`: deprecated implicit `onFoo` in Connections

## 7. Still open (polish)

- Position-aware crop so the frost samples the wallpaper region actually
  behind the card (finding 4) — in progress (step 3 of the iNiR port)
- Animated (GIF) wallpaper support in Glass (5)
- Blur params tied to a setting (6)
- Fallback gradient when no wallpaper is set (7)

Known open item: fullscreen Translate transform (shell.qml:437-438) is not
tracked by screenPos; believed harmless because opacity is 0 during the
transform's active state, but the opacity/transform timing relationship
(Behavior vs instant snap) was not directly verified. Revisit if frost
flashes misaligned during fullscreen toggle.

## 8. Real compositor frost for the pill (2026-08-31)

User feedback: AltSwitcher's compositor blur looks more like real glass than
the pill's fake QML blur. Fix: the pill now uses the same real frost.

- `modules/pill/shell.qml` — the overlay PanelWindow attaches
  `BackgroundEffect.blurRegion` to a `Region { item: pill; radius:
  pill.morphRadius }`, gated on `Theme.auroraActive && Compositor.isNiri &&
  !monFullscreen` (`overlay.realGlass`). The Region tracks the pill's morph
  geometry live.
- `modules/common/Glass.qml` — new `realBlur` property: when set, the fake
  wallpaper copy (Image + MultiEffect) is skipped entirely (no decode, no
  blur pass — also retires findings 2/3 for the pill on niri) and only the
  aurora tint paints over the compositor's blur.
- `modules/pill/Pill.qml` — passes `realBlur: barWindow.realGlass` to its
  Glass.

Tooltips keep the fake Glass: they float outside the pill's blur region, so
tint-only there would sit over raw wallpaper. Finding 13's "one strategy per
surface" is now resolved for the pill (compositor blur on niri, fake Glass
elsewhere, e.g. Hyprland); tooltips still fake. Blur strength is the
compositor's (niri config), not QML's — finding 6 is moot for the pill on
niri.

**Follow-up (same day):** finding 1's rounded mask was credited to `96f9894`
but was not present in the working tree (`clip: true` was). Now actually
landed in `Glass.qml`: `clip` removed, the blur MultiEffect masks through a
white rounded-rect `maskSource` (`maskEnabled: true`, channel-agnostic), so
the blurred wallpaper can no longer poke out as square corners past
`radius`. The mask rect tracks `radius` live, so morph animations stay
correct.

## 9. Square Shadow Artifact Elimination (2026-08-31)

User feedback: The compositor blur (`BackgroundEffect.blurRegion`) left a faint
square blur box / shadow around the pill's rounded corners.

**Root cause:** Wayland `ext-background-effect-v1` specifies blur regions via
`wl_region`, which only supports axis-aligned rectangles (no corner radii).
Niri blurred the full `[x, y, w, h]` bounding rectangle of the pill. Outside the
pill's 4 rounded corners, the compositor's rectangular blur leaked onto the desktop
as a square shadow. Furthermore, in QML, setting `visible: false` on an item
prevents scene graph layer rendering in Qt 6, leaving `MultiEffect.maskSource`
with an unrendered texture.

**Fix:**
- `modules/pill/shell.qml` & `modules/pill/Pill.qml` — removed `BackgroundEffect.blurRegion`
  and `realGlass` / `realBlur` from the floating overlay window.
- `modules/common/Glass.qml` — implemented rounded corner masking using
  `ShaderEffectSource` (`hideSource: true`, `live: true`). This forces Qt Quick
  to render the rounded rectangle (`maskRect`) offscreen to a GPU texture for
  `MultiEffect.maskSource`, cropping all blurred wallpaper pixels cleanly at
  `root.radius` with no edge leaking or square shadow artifacts.

