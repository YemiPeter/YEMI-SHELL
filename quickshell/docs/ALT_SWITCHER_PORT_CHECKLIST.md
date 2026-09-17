# Alt+Tab Port Checklist — iNiR → YemiShell

Working checklist for porting the iNiR "Alt-Tab switcher (Material ii)" features
into YemiShell. Source-of-truth for what iNiR does: `ALT_SWITCHER_INIR_REFERENCE.md`.
Map of our own implementation: `ALT_SWITCHER_MAP.md`.

---

## How this checklist is used

1. Items are worked **one at a time**.
2. The implementer **stops after each item** and waits for the user to confirm it
   works before starting the next.
3. Status column is updated in this file as items complete.
4. The user picks the order; the order below is the recommended one, not a mandate.

---

## Architecture answer: one file or many?

**One single file.** iNiR's `modules/altSwitcher/` contains exactly **one** source
file — `AltSwitcher.qml` (2001 lines, 90 KB). Every layout lives inside it as a
`visible:`-gated branch, all driven by the same root state:

| Layout | Gate | Where |
|---|---|---|
| Default (grid) | `!compactStyle && !listStyle && !skewStyle` | `ListView { id: listView }` L1400–1407 |
| Compact (icons row) | `root.compactStyle` | `id: compactRow` L1067; visible L1068 |
| List (centered) | `root.listStyle` | L1181 |
| Skew previews | `root.skewStyle && root.skewCardVisible` | L597, `ListView` L631 |
| Material 3 card | **not a layout** — a visual variant of the default grid | `!root.altUseM3Layout` L584 (swaps background/blur treatment) |

Also shared across all layouts in the same file: one scrim (`Rectangle` L390–399),
one empty state, one `autoHideTimer`, one `IpcHandler`, and one set of navigation
functions (`nextItem` L1767, `previousItem` L1781, `activateCurrent` L1795) that all
target the single `listView.currentIndex`.

**Not part of this**: `modules/waffle/altSwitcher/` is 3 separate files
(`WaffleAltSwitcher`, `WaffleAltSwitcherContent`, `WaffleAltSwitcherThumbnail`,
`WaffleAltSwitcherTile`) — that is the **Waffle (Windows 11) family**, explicitly
out of scope per the user.

**Implication for us:** we do not need to split our `AltSwitcher.qml` per layout.
Adding a preset = adding a `visible:`-gated branch inside our existing single file,
exactly as iNiR does.

---

## Settings storage plan

Our flags live in `singletons/Flags.qml` → `JsonAdapter` (persisted to
`$XDG_STATE_HOME/quickshell/flags.json`). Existing: `altSwitcherEnabled` (L53 alias,
L143 default).

New keys will be added there, prefixed `altSwitcher*` so they group together in the
file. Proposed names mirror iNiR's config keys so the mapping stays obvious:

| Our flag | Type | Default | iNiR equivalent |
|---|---|---|---|
| `altSwitcherEnabled` ✅ exists | bool | `true` | (master gate) |
| `altSwitcherAdvanceOnTap` | bool | `false` | *(new — user request, see §1.1)* |
| `altSwitcherNoVisualUi` | bool | `false` | `noVisualUi` |
| `altSwitcherScrimDim` | int 0–100 | `35` | `scrimDim` |
| `altSwitcherBackgroundOpacity` | real 0.1–1.0 | `0.9` | `backgroundOpacity` |
| `altSwitcherBlurAmount` | real 0–1 | `0.4` | `blurAmount` |
| `altSwitcherEnableBlurGlass` | bool | `true` | `enableBlurGlass` |
| `altSwitcherEnableAnimation` | bool | `true` | `enableAnimation` |
| `altSwitcherAnimationDurationMs` | int | `200` | `animationDurationMs` |
| `altSwitcherAutoHideDelayMs` | int | `500` | `autoHideDelayMs` |
| `altSwitcherUseMostRecentFirst` | bool | `true` | `useMostRecentFirst` |
| `altSwitcherPreset` | string | `"default"` | `preset` |
| `altSwitcherPanelAlignment` | string | `"right"` | `panelAlignment` |
| `altSwitcherCompactStyle` | bool | `false` | `compactStyle` |
| `altSwitcherUseM3Layout` | bool | `false` | `useM3Layout` |
| `altSwitcherMonochromeIcons` | bool | `false` | `monochromeIcons` |
| `altSwitcherShowOverview` | bool | `false` | `showOverviewWhileSwitching` |

---

## Phase 1 — Behaviour (user's priority requests)

### ✅ 1.1 — Advance-on-tap: keybind tap focuses the next window

| Field | Detail |
|---|---|
| **Goal** | Pressing Alt+Tab advances the highlight **and immediately focuses that window** — no mouse click, no Enter press. With a toggle to turn this behaviour on/off. |
| **New flag** | `altSwitcherAdvanceOnTap` (bool, default `false`) |
| **iNiR behaviour** | `next()` L1950–1953 → `ensureOpen(); nextItem(); activateCurrent(); autoHideTimer.restart()`. Note iNiR does this **unconditionally**; we are adding it as a **toggle** per user request, so default stays off. |
| **Our current state** | `next()` / `previous()` only open the overlay or increment `currentIndex`. Focusing happens **only** on Enter / mouse click via `focusWindow()`. |
| **Change** | In `next()` / `previous()`: after advancing `currentIndex`, if the flag is on, call `focusWindow()` on the newly-selected item. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` (toggle row) |
| **Dependency** | Pairs with **3.1 (auto-hide delay)** for the full iNiR feel. Standalone it still works — each tap re-focuses the next window — but the overlay stays open until Esc/click. |
| **Acceptance** | Tap Alt+Tab → highlight moves **and** window actually switches. Click / Enter still work. Toggle off → back to highlight-only, no switching on tap. |
| **Status** | ✅ **DONE** — flag `altSwitcherAdvanceOnTap` (default off) + `next()`/`previous()` focus-on-advance; toggle row "Advance on tap" added to Panels; **also fixed a latent Hyprland focus bug**: bare (non-`0x`) addresses are now prefixed before `focuswindow` dispatch — verified live, cycle produced zero `No such window found` errors. **Alt-release close added**: `bindr = ALT, ALT_L` (hypr binds.lua) → new `altSwitcher releaseCommit` IPC → `commitAndClose()`, gated on the flag (no-op when off, so Esc/click-away stays the dismissal). Hold-Alt-tap-Tab-then-release now feels like classic Alt+Tab. **Fallback auto-hide (600 ms `advanceHideTimer`, restarted on every tap)** added later the same session — mirrors iNiR's `autoHideTimer`-restarted-on-`next()` pattern, closes the overlay after you stop tapping on **both** niri and Hyprland; no-op when the flag is OFF. Verified live on a restarted instance (timer fired, layer surface unmapped). **First-tap fix**: with advance-on-tap the first tap now ALSO switches (open → advance past resting index → focus → arm hide); `previous()`'s first tap walks backward to `count - 1`. Verified live: focus changes on first tap, double-tap switches twice, overlay auto-unmaps. ⚠️ Ops note: a quickshell instance started outside the editor wasn't watching files (stale code, "release close didn't work" was this); after any restart, verify hot-reload with a `touch` + log check, or `qs kill && qs -d`. |

### ☐ 1.2 — No Visual UI (cycle windows only)

| Field | Detail |
|---|---|
| **Goal** | When on, Alt+Tab never shows the overlay — each tap cycles **and** focuses the next window directly. Per user rule: this mode **auto-enables advance-on-tap** (there is no UI left to commit a selection with). |
| **New flag** | `altSwitcherNoVisualUi` (bool, default `false`) |
| **iNiR behaviour** | `effectiveNoVisualUi` L23; `next()` L1916–1939 → **does not open** the overlay, rebuilds a no-UI snapshot, advances `noUiIndex`, calls `focusNoUiIndex()`, then restarts `quickSwitchResetTimer` (interval **800 ms**, L122–127) which resets `quickSwitchDone` so a pause makes the next tap start from the most-recent window again. `previous()` L1961+ mirrors this. |
| **Our current state** | No equivalent — the overlay always opens on `next()`. |
| **Change** | In `next()` / `previous()`: if the flag is on → skip opening, advance an internal cycle index, focus immediately. Add the ~800 ms reset window so `tap-tap … pause … tap` restarts the sequence. |
| **Interlock** | While No-Visual-UI is ON → **Advance-on-tap forced ON** and its row rendered locked/on (same idiom as iNiR's `noVisualUi enabled: preset !== "skew"`). |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` (toggle row + interlock) |
| **Acceptance** | No-Visual-UI on → Alt+Tab switches windows with **no overlay ever appearing**. Repeated taps cycle forward/back. Pause > 800 ms then tap → starts from the most-recent window. Advance-on-tap row shows ON and cannot be turned off while this is on. Turning No-Visual-UI off restores the overlay + normal toggle control. |
| **Status** | ⬜ not started |

### ✅ 1.3 — Card-only overlay (no screen takeover)

| Field | Detail |
|---|---|
| **Goal** | The switcher is **just the frosted card** — no full-screen dim, no screen takeover. Kill the Hyprland layer wobble. |
| **New flag** | none — architectural change |
| **Problem** | The layer was a full-monitor transparent window with a 0.35-alpha scrim filling it. Consequences: (a) toggling Alt visually covered the whole screen like an "overview mode"; (b) `ignore_alpha 0` blur therefore applied to **every** pixel (scrim alpha > 0), frosting the whole desktop; (c) Hyprland's `animation = layersIn, …, bounce, slide` animated that full-screen surface, so opening wobbled the entire monitor down and back. |
| **Change** | (1) Deleted the full-screen `scrim` `Rectangle` from `AltSwitcher.qml` — the layer is now transparent everywhere but the card. (2) `hyprland.conf`: blur / `ignore_alpha` rules scoped so only the card's pixels frost (the card is the only opaque region). (3) `layerrule = animation …, fade` replacing the global bounce+slide for this namespace — opens as a soft fade, no wobble. |
| **Note** | Removing the scrim alone killed the desktop-wide blur automatically, since no other pixel has alpha > 0. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `hypr/hyprland.conf` |
| **Commit** | `ce23687 altswitcher: card-only overlay, no screen takeover` |
| **Status** | ✅ **DONE** — verified live: only the card frosts, open is a fade (no bounce), close unmaps the layer. |

---

## Phase 2 — Visuals

### ❌ 2.1 — Scrim dim (%) — *cancelled by 1.3 (no scrim exists)*

| Field | Detail |
|---|---|
| **Goal** | User-settable darkness of the full-screen scrim behind the switcher. |
| **New flag** | `altSwitcherScrimDim` (int 0–100, default `35`) |
| **iNiR behaviour** | L394–396 → `Qt.rgba(0, 0, 0, clamped/100)` on the scrim `Rectangle` L390–399. UI range 0–100, step 5. |
| **Our current state** | `readonly property real scrimDim: 0.35` — hardcoded constant at L30 of our `AltSwitcher.qml`. |
| **Change** | Bind the scrim opacity to `Flags.altSwitcherScrimDim / 100` instead of the constant. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` |
| **Acceptance** | Change value in Settings → Panels → scrim darkness changes live; `0` = no dim, `100` = pure black. Survives shell restart (persisted). |
| **Status** | ⬜ not started |

### ☐ 2.2 — Background opacity (%)

| Field | Detail |
|---|---|
| **Goal** | Opacity of the switcher card background. |
| **New flag** | `altSwitcherBackgroundOpacity` (real 0.1–1.0, default `0.9`) |
| **iNiR behaviour** | L547 → `ColorUtils.applyAlpha(base, root.altBackgroundOpacity)`. UI shows %, range 10–100 step 5. |
| **Our current state** | Card colour is `QsSingletons.Theme.cardBot` used at full alpha. |
| **Change** | Apply `Qt.alpha()` on the card colour with the flag value. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` |
| **Acceptance** | Card becomes translucent at lower values; text stays readable; Hyprland layerrule blur shows through. |
| **Status** | ⬜ not started |

### ☐ 2.3 — Blur amount (%) + enable blur glass

| Field | Detail |
|---|---|
| **Goal** | User-settable frosted-glass strength, plus an on/off for the glass itself. |
| **New flags** | `altSwitcherBlurAmount` (real 0–1, default `0.4`), `altSwitcherEnableBlurGlass` (bool, default `true`) |
| **iNiR behaviour** | L101 `effectiveEnableBlurGlass = enableBlurGlass && !isHighLoad`; L584–586 gates a `MultiEffect` with `blur: root.altBlurAmount`. UI: "Blur amount (%)" 0–100 step 5. `enableBlurGlass` itself is **config-only** in iNiR — decision needed whether we expose it. |
| **Our current state** | `readonly property bool blurGlass: compositor.isNiri` — binary, niri-only (Hyprland gets blur from `layerrule`). |
| **Change** | Keep the compositor split, but make strength user-settable. On niri map the amount onto the `BackgroundEffect` blur region behaviour; on Hyprland the amount can't be animated per-overlay via layerrule — document the limitation. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` |
| **Acceptance** | Value changes visibly on niri. On Hyprland the behaviour is documented (either fixed by layerrule or gracefully ignored — **no errors**). |
| **Status** | ⬜ not started |

### ☐ 2.4 — Slide animation toggle + duration (ms)

| Field | Detail |
|---|---|
| **Goal** | Turn the switcher's open/close animation on/off and set its duration. |
| **New flags** | `altSwitcherEnableAnimation` (bool, default `true`), `altSwitcherAnimationDurationMs` (int, default `200`) |
| **iNiR behaviour** | `effectiveEnableAnimation` L102; `currentAnimDuration()` L1676; `slideInAnim`/`slideOutAnim` L1660–1673 animate `panelRightMargin` `-panelWidth → 0` (OutCubic) and back (InCubic). **This is a translate, not a fade** — right-aligned only; center/compact/list/skew bypass it (L1693, L1711). |
| **Our current state** | Zen fade — 300 ms in / 140 ms out, `Easing.OutCubic`, as **local constants** in our file. No scale/translate. |
| **Change** | Gate our fade on `enableAnimation`; replace the two constants with `animationDurationMs`. **Decision needed:** do we adopt iNiR's slide-translate, or keep our fade and let the setting control duration only? |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` |
| **Acceptance** | Animation off → instant open/close, no fade. Duration change → visibly faster/slower. No regressions in rapid Alt+Tab. |
| **Status** | ⬜ not started |

---

## Phase 3 — Timing & safety

### ☐ 3.1 — Auto-hide delay after selection (ms)

| Field | Detail |
|---|---|
| **Goal** | Overlay hides automatically ~N ms after the last keybind tap / selection. |
| **New flag** | `altSwitcherAutoHideDelayMs` (int 50–2000, default `500`) |
| **iNiR behaviour** | `autoHideTimer` L1588–1593 (`repeat: false`, `onTriggered: GlobalStates.altSwitcherOpen = false`); restarted at the end of every `next()`/`previous()` (L1953). |
| **Our current state** | **No auto-hide at all** — the overlay stays open until Esc, click-away, or a selection. |
| **Change** | Add a non-repeating `Timer`; restart it at the end of `next()`/`previous()` and on selection. |
| **Interaction** | This is what makes **1.1 (advance-on-tap)** feel right: tap-tap-tap then stop → overlay closes. Recommended to land together with or right after 1.1. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `singletons/Flags.qml`, `modules/pill/Panels.qml` |
| **Acceptance** | Tap Alt+Tab, stop → overlay closes after the set delay. Rapid taps keep it open. Esc/click still close immediately. Delay adjustable. |
| **Status** | ⬜ not started |

### ☐ 3.2 — `isHighLoad` auto-degrade (>15 windows)

| Field | Detail |
|---|---|
| **Goal** | Safety valve: with many windows open, disable blur + animation automatically to avoid lag. |
| **New flag** | none — derived internally |
| **iNiR behaviour** | `readonly property bool isHighLoad: windowCount > 15`, then `effectiveEnableBlurGlass = … && !isHighLoad` and `effectiveEnableAnimation = … && !isHighLoad` (L101–102). |
| **Our current state** | Not present. |
| **Change** | Add `isHighLoad` (`windows.length > 15`) and AND it into both effective values. |
| **Files** | `modules/altswitcher/AltSwitcher.qml` only |
| **Acceptance** | With >15 windows, switcher still opens smoothly with no blur/animation; below threshold, settings take effect normally. |
| **Status** | ⬜ not started |

---

## Phase 4 — Data layer

### ☐ 4.1 — Most-recently-used first

| Field | Detail |
|---|---|
| **Goal** | Order the switcher by most-recently-focused instead of our current workspace/app sort. |
| **New flag** | `altSwitcherUseMostRecentFirst` (bool, default `true`) |
| **iNiR behaviour** | `buildItemsFrom()` L255–277 sorts against `NiriService.mruWindowIds` (NiriService.qml L35, L440–453, L576–578), a live MRU list fed by niri's event stream (`WindowFocusChanged`). |
| **Our current state** | Sorted by workspace index, then app name (`AltSwitcher.qml` L57+). |
| **Blocker** | **Compositor disparity.** Hyprland: ✅ we receive `activewindow` events via `Compositor.rawEvent` (`compositor/Hyprland.qml` L74) → MRU is buildable. Niri: ❌ our `compositor/Niri.qml` is **poll-only** (`niri msg --json windows`, no event socket) → would need a focus-diff poller or an added event socket. |
| **Change** | Maintain an MRU list; sort by it when the flag is on, else keep current sort. |
| **Files** | `modules/altswitcher/AltSwitcher.qml`, `compositor/Hyprland.qml` (+ possibly `compositor/Niri.qml`), `singletons/Flags.qml`, `modules/pill/Panels.qml` |
| **Acceptance** | The last-used window appears first / second; ordering updates as you focus windows. Flag off → original deterministic sort. Works on **both** compositors (or is explicitly gated with a documented note). |
| **Status** | ⬜ not started |
---

## Phase 5 — Layout presets (heavy — the "bloat" items)

> Each of these is a whole alternate rendering inside the same single file.
> Treat each as its own mini-project; skip freely.

### ☐ 5.1 — Preset picker (Default / List / Skew)

| Field | Detail |
|---|---|
| **New flag** | `altSwitcherPreset` (string `"default"` \| `"list"` \| `"skew"`, default `"default"`) |
| **iNiR behaviour** | `listStyle`/`skewStyle` L51–52; UI Sel in InterfaceConfig.qml (render order L158–337). |
| **Cost** | **List** = a second full layout (~420 px, iNiR L1181). **Skew** = the expensive one: `WindowPreviewService.captureForTaskView()` screenshot pipeline + ~150 lines of 12-slice 3D geometry (`baseSkewSliceWidth`/`baseSkewExpandedWidth`/`skewScale`, L55–78). |
| **Interlock** | In iNiR, `noVisualUi` is silently forced off when preset = `skew` (`effectiveNoVisualUi = noVisualUi && preset !== "skew"`). |
| **Recommendation** | Default + List first; skew only if you actually want it. |
| **Status** | ⬜ not started |

### ☐ 5.2 — Compact horizontal style (icons only)

| Field | Detail |
|---|---|
| **New flag** | `altSwitcherCompactStyle` (bool, default `false`) |
| **iNiR behaviour** | L50 `compactStyle`; row `id: compactRow` L1067, visible L1068; further gates L486–531, L559. |
| **Cost** | A third rendering (~115 lines + layout gates). |
| **Status** | ⬜ not started |

### ☐ 5.3 — Right / Center alignment

| Field | Detail |
|---|---|
| **New flag** | `altSwitcherPanelAlignment` (string `"right"` \| `"center"`, default `"right"`) |
| **iNiR behaviour** | `centerPanel` L49; affects positioning across all layouts. |
| **Cost** | Low **if** presets already exist (just a position binding). Pairs with the slide animation, which is right-aligned only. |
| **Status** | ⬜ not started |

### ☐ 5.4 — Material 3 card layout

| Field | Detail |
|---|---|
| **New flag** | `altSwitcherUseM3Layout` (bool, default `false`) |
| **iNiR behaviour** | L48, L584 — **not a separate layout**, a visual variant of the default grid (`!root.altUseM3Layout` gates the glass layer). |
| **Cost** | Moderate — new card styling rather than new geometry. |
| **Status** | ⬜ not started |

### ☐ 5.5 — Tint app icons (monochrome)

| Field | Detail |
|---|---|
| **New flag** | `altSwitcherMonochromeIcons` (bool, default `false`) |
| **iNiR behaviour** | L1128, L1550 — icons rendered against the theme foreground instead of full colour. |
| **Cost** | Needs `ColorUtils` + icon colorisation we don't currently wire. |
| **Status** | ⬜ not started |

### ☐ 5.6 — Show Niri overview while switching

| Field | Detail |
|---|---|
| **New flag** | `altSwitcherShowOverview` (bool, default `false`) |
| **iNiR behaviour** | L53, `maybeOpenOverview()` — runs the niri overview action while the switcher is up. |
| **Cost** | Low, but **niri-only** — must be gated on `compositor.isNiri` (hide/disable the row on Hyprland). |
| **Status** | ⬜ not started |

---

## Recommended order

1. **1.1** advance-on-tap + toggle ← *the headline request*
2. **3.1** auto-hide delay (makes 1.1 feel complete)
3. **1.2** No Visual UI (auto-forces 1.1)
4. **2.1** scrim dim → **2.2** background opacity → **2.3** blur amount
5. **2.4** animation toggle + duration
6. **3.2** isHighLoad safety valve
7. **4.1** MRU (needs the compositor work)
8. **5.x** presets / compact / alignment / M3 / tint / overview

---

## Open decisions (need user input)

1. **1.1 default** — ship advance-on-tap **off** (opt-in) or **on**? Assumed **off** for now.
2. **1.1 + 3.1 together?** — advance-on-tap without auto-hide leaves the overlay open after each switch. One deliverable or two?
3. **2.3 on Hyprland** — `layerrule` blur can't take per-invocation strength. Accept fixed layerrule blur on Hyprland (slider affects niri only), or make it a simple on/off?
4. **2.4 animation** — adopt iNiR's slide-translate, or keep our zen fade with a user-settable duration?
5. **5.1 skew** — port it (brings the screenshot pipeline), or skip for Default + List only?
6. **enableBlurGlass** — config-only in iNiR; expose as a UI toggle here or leave it internal?

