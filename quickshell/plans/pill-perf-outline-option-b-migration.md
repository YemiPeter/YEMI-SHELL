# Plan — Outline Option B migration (Ricelin-parity lighter outlines)

**Date:** 2026-09-04 · **Branch:** `pill-perf` · **Tracks:** audits/06-pill-ui-border-drift.md

> **Why these two options exist.** `Outlines` in `dominance-engine.py` were
> derived *darker than the surface* (Option A, now implemented) so the
> `G-dark-vs-light` acceptance check stays trivially green. Ricelin's
> `wallcolors.py` derived them *lighter than the surface* (`base + 0.225`) — a
> warm, visible tan hairline. Option B restores that exact look and is riskier
> because it collides with `G` (by design) and with the `ensureReadable`-based
> text tokens `yemiDim`/`yemiFaint` that wrap the outline family.
> **Ship order: Option A first (DONE) → land Fix 2 → only then evaluate B.**

---

## 1 · Target state

```
dark  outline         = L(anchor) + 0.10   → warm hairline ABOVE surface
dark  outline_variant = L(anchor) + 0.20   → ≈ Ricelin base + 0.225  (L ≈ 0.25–0.30)
light outline         = L(anchor) + 0.10   (unchanged from today)
light outline_variant = L(anchor) + 0.20   (unchanged from today)
```

Rationale: on the live wallpaper (`anchor 0.108` dark) this yields
`outline ≈ #3xxxxx-ish L0.21`, `outline_variant ≈ L0.31` — matching the
reference's intended look. Static fallback (post Fix 2) stays `#3a2a22`.

---

## 2 · Work items (ordered, each independently committable)

### W1 · Flip the dark-mode outline derivation
`scripts/dominance-engine.py` (~line 335): change the `mood == "dark"` branch
to mirror the light branch:

```python
if mood == "dark":
    ol  = clamp01(anchor + 0.10, 0.02, 0.98)
    olv = clamp01(anchor + 0.20, 0.02, 0.98)
```

**Dependency:** none. **Effect alone:** G-dark-vs-light **fails** — expected,
W2 fixes it in the same change or a paired commit.

### W2 · Exempt the outline family from the G same-lightness check
`verify()` (~line 489): exclude `outline`/`outline_variant` from `same_l`,
with a comment that they are the *intentional* dark/light-branch pair
(decorative frames, not text). Optional tightening: assert instead that
`|L_dark(outline_variant) - L_light(outline_variant)| >= 0.4` (parity proof).
**Risk:** low — D-text-contrast never covered these keys.

### W3 · Re-check `yemiDim` / `yemiFaint` readability
`config/Appearance.qml` wraps dim/faint in `ensureReadable` against surfaces.
After W1 they lighten (L 0.2→0.3); `ensureReadable` re-raises lightness/contrast
as needed, so textual dim-labels stay ≥ 4.5:1. **Verify** on all 3 wallpaper
classes (colorful dark / grayscale / light) that:
- `D-text-contrast` still passes engine-side;
- QML `ensureReadable` doesn't push dim/faint to *equal* on_surface (visual
  hierarchy loss). If so, reduce `TEXT_CONTRAST`-style target only for the
  outline-based text tokens (separate knob) rather than loosening text globally.

### W4 · Validate matrix (regression gates)
Reuse the engine harness on a fixed matrix and eyeball screenshots:
1. `wallhaven-x1lxjo.webp` (live, warm dark) — target: warm hairlines.
2. `wallhaven-k8l167.webp` (grayscale) — allows B-canary AND the lenient G-check
   for `outline` to be exercised (they coincide at L≈0.3).
3. A light-mode wallpaper — confirm light outlines unchanged.
Expected: engine exit 0 on all three; png screenshots show no black hairlines.

### W5 · Colors.json diff-preview (no UI risk)
Run `dominance-engine.py | diff - <(old colors.json)` for the live wallpaper and
paste the token delta table into the audit doc's §5 before applying live.

---

## 3 · Rollback & pairing rules

- **W1+W2 must travel together** (a W1 alone breaks `return ok` → exit 1, which
  `after-wall.sh` treats as a failed regen).
- Rollback = `git revert` the pair; Option A floor code remains as the fallback
  branch so reinstating is a single-line flip.
- **Do not start until Fix 2 is decided and merged** — with `yemiBorder`
  hardcoding the dynamic token, Option B and Option A look identical in the UI
  today; B's extra risk is wasted until the fallback path exists.

---

## 4 · Open questions / decision gate

- [ ] Confirm B's *lighter* hairlines are actually wanted on bright wallpapers
      (contrast inversion vs today's shadow frames).
- [ ] If `yemiDim`/`yemiFaint` readability needs a new knob, prefer
      `TEXT_CONTRAST_OUTLINE = 3.0` (outline-family text only) — approve?
- [ ] Keep `outline` ≠ `outline_variant` separation mandatory (assert `>= 0.05`)
      in W2 as a permanent guard.