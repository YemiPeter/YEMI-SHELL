# Skill Audit Roundup — pill-perf branch

Generated 2026-09-04 by running the audit skills one at a time against the
working tree. Merges with the canonical audits in `audits/01–05` (open items
R1–R3, C1–C5, D1–D4, H1 still stand — not repeated here).

## Skill 1 — qt-qml-review (static lint + manual verification)

Scope: all 132 QML files. **1,954 findings.**

| Rule | Count | Severity | Verdict |
|---|---|---|---|
| JS-1 `var` → let/const | 638 | style | real but cosmetic; fix opportunistically |
| STY-3 (naming/ordering) | 455 | style | noise |
| ORD-1 declaration order | 206 | style | noise |
| JS-2 loose equality | 146 | low | worth sweeping — real `==` bugs hide here |
| BND-1 untyped `property var` | 136 | low | blocks qmlsc compilation path |
| BND-2 imperative `=` | 107 | **verify** | mostly false positives (Quickshell Process pattern); Backdrop/Niri ones verified intentional |
| PRF-1 transparent Rectangle | 53 | low | real, batched cleanup |
| PRF-3 `clip: true` | 45 | low | acceptable on ListViews; audit non-ListView cases |
| PRF-6 `layer.enabled` always-on | 13 | **medium** | real: Glass (intentional, cached), MusicPanel ×3, popups ×3 |
| LAY-2 width/height in RowLayout | 24 | medium | real layout bugs-in-waiting in popup windows |
| IMG-1 Image without sourceSize | 4 | **high** | see below |
| BND-5 list<> no granular signals | 10 | verify | WallpaperCrossfader ones are read-only constants — false positives |
| ERR-1 missing error handling | 1 | **high** | Weather.qml:132 curl |

### Verified real (high-value)

- **`modules/music/MusicPanel.qml:167`** — album artwork decodes at full
  resolution (often 1000px+) into a ~60–300px slot, through an FBO mask
  layer. Set `sourceSize` to the displayed dimensions. Biggest single
  decode win in the shell.
- **`modules/background/Wallpaper.qml:44`** — Niri QML wallpaper Image has
  no `sourceSize`; decodes full res. Screen-sized `sourceSize` bounds it.
- **`modules/pill/Singletons/Weather.qml:132`** — ip-api curl has no
  failure path (no `onExit`/stderr handling); on timeout the location
  silently stays stale with no log.
- **`modules/pill/Osd.qml:252`, `modules/pill/SettingsRow.qml:81`** —
  same missing-sourceSize pattern, smaller images.

## Skill 2 — zen-comprehensive-review (branch diff vs main)

Scope: 13k-line diff, 3.5k lines of code changes on `pill-perf`. No
subagent backend available in this environment, so the orchestrated
multi-model pass was executed as a single verified review (deviation
noted).

### Code changes reviewed — verdict: sound

- `Theme.qml` flame tokens / `pillAlpha` / `pillSurface` canonicalization: correct, single-source.
- `Glass.qml` ¼-res texture + folded saturation: geometry untouched, screenPos contract holds.
- `Bar.qml` side-pill glass: matches pill body pattern; `pillBg` reads `Theme.pillSurface` (no double-alpha).
- `Backdrop.qml` imperative `wall.source`: documented intentional (Connections forwarding) — false positive.

### New findings

| Sev | Finding |
|---|---|
| **P2** | Junk binary file `"\314\2042"` (718 bytes, mangled name) is **tracked in HEAD** — accidental artifact. `git rm` it. |
| **P2** | More root-level junk tracked: `watch_20260713-024050` (stray log), `app_usage.json` (runtime state), `.codex` (agent leftover — same category as the kilo/kiro/roo purge). Review + delete. |
| **P3** | `Bar.qml` leftPills collapse sets `visible: false` **and** animates `opacity` — the fade never plays because `visible: false` removes the item from rendering immediately. Animate width or delay `visible`. |
| P3 | `test-binds.js` / `test-parse.js` at repo root — stray test scripts, move or delete. |

## Roundup fix order (merged, cheapest-first)

1. **Junk purge** (5 min): `\314\2042`, `watch_*`, `app_usage.json`, `.codex`, root test js files.
2. **IMG-1 sourceSize sweep** (20 min): MusicPanel artwork, Wallpaper backdrop, Osd, SettingsRow.
3. **Weather curl error path** (10 min).
4. **PRF-6 layer audit** (30 min): MusicPanel ×3 and popup `layer.enabled: true` → gate on animation; Glass stays.
5. **LAY-2 popup RowLayout sizing** (45 min): four popup windows.
6. **JS-2 `==` sweep** (1h): 146 sites, highest hidden-bug density.
7. **PRF-1 transparent Rectangles → Item** (1h, mechanical).
8. Then rejoin the canonical audits' open items: R1/R2 (pill morph perf), R3/D1 (single-blur decision), C1–C5, D2–D4, H1.
9. Deferred cosmetics: JS-1 var sweep, ORD-1/STY-3, BND-1 typing — fold into files as they're touched, don't mass-edit.
