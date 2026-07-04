# Pill Interactive Overlay — Non-Blocking Redesign

**Status:** 📌 Planned, deferred — build this LAST, after current bugs are stable.

---

## 1. Problem With Current Design

Right now the Overlay window (`PillOverlay.qml`) switches its input `mask` between two states:

```
Pill rest / hover  → pillRegion   (small, screen stays interactive)
Surface open       → fullRegion  (whole screen, blocks everything else)
```

`fullRegion` exists only to support a backdrop `MouseArea { anchors.fill: parent }` that detects "click outside the pill = close it." That's the actual cost — not the morph animation itself.

---

## 2. Interaction Model (Yemi's design — confirmed correct)

```
Cursor hovers pill      → morph to hover phase (icons revealed)
Click a hover icon      → morph to that icon's dashboard, PIN open
Cursor leaves (unpinned)→ auto-collapse back to rest
Escape (while pinned)   → close dashboard, return to rest
```

Key insight: **there is no "click outside to dismiss" step anywhere in this flow.** Hover is the open trigger, leaving is the close trigger, Escape closes a pinned surface. That means the full-screen input grab was solving a problem this design doesn't have.

✅ Screen stays fully interactive at every pill state — rest, hover, and pinned/dashboard.

---

## 3. Technical Design

### 3.1 Mask — always tracks live pill bounds, never full-screen

Replace the binary `pillRegion` / `fullRegion` switch with a single mask that's **recomputed every frame during morph**, bound directly to the pill's current geometry:

```
mask = Region {
    x: pill.x
    y: pill.y
    width: pill.width
    height: pill.height
    // shape can follow pill's current corner radius if Region supports it,
    // otherwise a bounding rect is fine — slightly generous input area
    // around the pill is not a UX problem
}
```

This applies identically whether the pill is at rest (160×38), hover (hoverW×58), or a pinned dashboard (e.g. calendar 318×N) — the mask just always equals "wherever the pill currently is and however big it currently is."

### 3.2 Drop the backdrop MouseArea entirely

No `anchors.fill: parent` MouseArea, no click-outside detection. Not needed — nothing in the interaction model requires it.

### 3.3 Keyboard focus for Escape — separate concern from the mask

`Region`/`mask` only controls **pointer** input. Escape needs **keyboard** input, which is a different property on the layer-shell window:

```
WlrLayershell.keyboardFocus: pinned || surfaceOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
```

Toggle this on the moment a surface pins/opens, release it the moment it closes. Otherwise Escape has nothing to land on — this isn't a tradeoff, it's just how Wayland separates pointer and keyboard input ownership.

### 3.4 Optional visual backdrop (cosmetic only)

You can still *paint* a dim rectangle behind a pinned dashboard for visual polish. Painting is independent of the input mask — draw it, but keep it excluded from `Region`. Purely visual, zero input cost.

---

## 4. What This Removes / Replaces

| Old | New |
|---|---|
| `pillRegion` vs `fullRegion` binary switch | Single mask bound live to `pill.x/y/width/height` |
| Backdrop `MouseArea` for click-outside-close | Removed — hover-leave / Escape handle all closing |
| Full-screen input grab while surface open | Never grabs more than the pill's current footprint |
| (missing) keyboard focus handling | `WlrLayershell.keyboardFocus` toggled on pin/open |

---

## 5. Implementation Checklist (when we get to it)

- [ ] Bind `Region` x/y/width/height to `pill`'s live geometry (not `restW`/`restH` constants)
- [ ] Verify mask updates correctly mid-morph, not just at animation end (may need to bind directly to animated properties, not just target values)
- [ ] Remove backdrop `MouseArea` from `PillOverlay.qml`
- [ ] Add `WlrLayershell.keyboardFocus` toggle keyed off `pinned || surfaceOpen`
- [ ] Confirm `Escape` key handler still fires and calls `PillState.close()` correctly with the new focus model
- [ ] Test edge case: clicking bare desktop wallpaper while a dashboard is pinned — since there's no more backdrop catcher, pinned dashboards ONLY close via hover-leave (if unpinned) or Escape (if pinned). Confirm this matches intended behavior (it should, per Yemi's model — no click-outside-close was ever wanted).
- [ ] Multi-monitor check: each screen's `Variants` delegate gets its own mask/pill — confirm no cross-monitor leakage

---

## 6. Why This Was Deferred

Current priority is stabilizing the `updateFullscreen()` / fullscreen-detection bug and confirming `modules/pill/shell.qml` cleanup (dead code removal) first. This redesign touches the same `PillOverlay.qml` file — safer to land it after the existing bugs are fixed and verified, not layered on top of unstable code.
