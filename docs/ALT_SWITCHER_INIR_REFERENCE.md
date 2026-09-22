# Alt-Tab Switcher — iNiR Source Reference (Material ii side)

Reference notes for porting the iNiR "Alt-Tab switcher (Material ii)" settings
section into YemiShell. This file documents **iNiR's source**, not ours — it is the
source-of-truth for what we port and what we deliberately drop.

Companion file: `docs/ALT_SWITCHER_MAP.md` (maps **our** current implementation).

---

## 1. Where the section lives in iNiR

| Role | File | Lines |
|---|---|---|
| Schema — `options.altSwitcher` (15 keys) | `modules/common/Config.qml` | 1589–1614 |
| Settings UI — `SettingsCardSection` "Alt-Tab switcher (Material ii)" | `modules/settings/InterfaceConfig.qml` | 158–337 |
| Implementation | `modules/altSwitcher/AltSwitcher.qml` | 2001 lines total |
| MRU data source — `mruWindowIds` | `services/NiriService.qml` | 35, 440–453, 576–578 |
| Skew preset dependency | `WindowPreviewService` (preview capture) | referenced L708, L748, L1691 |

Section visibility gate in iNiR: `visible: root.isIiActive && !Config.options.settingsUi.easyMode`
(i.e. Material ii family only, hidden in "easy mode"). **No Waffle variant is involved.**

---

## 2. Config schema (15 keys, defaults as shipped)

```qml
property JsonObject altSwitcher: JsonObject {
    property string preset: "default"          // "default" | "list" | "skew"
    property bool   noVisualUi: false
    property bool   monochromeIcons: false
    property bool   enableAnimation: true
    property int    animationDurationMs: 200
    property bool   useMostRecentFirst: true
    property bool   enableBlurGlass: true      // config-only, NOT exposed in UI
    property real   backgroundOpacity: 0.9
    property real   blurAmount: 0.4
    property int    scrimDim: 35               // 0–100
    property string panelAlignment: "right"    // "right" | "center"
    property bool   useM3Layout: false
    property bool   compactStyle: false
    property bool   showOverviewWhileSwitching: false
    property int    autoHideDelayMs: 500
}
```

14 of the 15 keys are exposed in the settings UI; `enableBlurGlass` is config-only.

---

## 3. UI controls (14 total)

Layout order, top to bottom, as rendered:

1. `SettingsSwitch`  — No visual UI (cycle windows only) — icon `visibility_off`
2. `SettingsSwitch`  — Tint app icons — icon `colors`
3. `SettingsSwitch`  — Enable slide animation — icon `movie`
4. `ConfigSpinBox`   — Animation duration (ms) — 0–1000, step 25, icon `speed`
5. `SettingsSwitch`  — Most recently used first — icon `history`
6. `ConfigSpinBox`   — Background opacity (%) — 10–100, step 5, icon `opacity`
7. `ConfigSpinBox`   — Blur amount (%) — 0–100, step 5, icon `blur_on`
8. `ConfigSpinBox`   — Scrim dim (%) — 0–100, step 5, icon `opacity`
9. `ConfigSpinBox`   — Auto-hide delay after selection (ms) — 50–2000, step 50, icon `hourglass_top`
10. `SettingsSwitch` — Show Niri overview while switching — icon `overview_key`
11. `ConfigSelectionArray` — Preset: Default (sidebar) / List (centered) / Skew previews
12. — `ContentSubsection` "Layout & alignment" begins —
13. `SettingsSwitch` — Compact horizontal style (icons only) — icon `view_compact`
14. `ConfigSelectionArray` — Align to right edge / Center on screen
15. `SettingsSwitch` — Use Material 3 card layout — icon `styler`

Count check: 7 switches + 5 spinboxes + 2 selection arrays + 1 subsection = 14 controls.

### Interlock rules baked into the UI
- Row 1 (`noVisualUi`) `enabled` only when `preset !== "skew"`; and when
  `preset === "skew"` it renders `checked: false` regardless of the stored value.
- Rows 13 & 14 (compact / alignment) `enabled` only when
  `preset !== "list" && preset !== "skew"`.
- Row 15 (M3 layout) additionally requires `!compactStyle`.
- Changing `preset` in row 11 **also writes** `altSwitcher.noVisualUi = false`.

---

## 4. Option → implementation map

| # | Option | Config key | Implementation |
|---|---|---|---|
| 1 | No visual UI | `noVisualUi` | `effectiveNoVisualUi` (L23); `next()` L1916–1939; `previous()` L1961+; `focusNoUiIndex()` |
| 2 | Tint app icons | `monochromeIcons` | L1128, L1550 (icon colourisation) |
| 3 | Slide animation | `enableAnimation` | `effectiveEnableAnimation` (L102) |
| 4 | Animation duration | `animationDurationMs` | `currentAnimDuration()` L1676; `slideInAnim`/`slideOutAnim` L1660–1673 |
| 5 | MRU first | `useMostRecentFirst` | `buildItemsFrom()` L255–277 |
| 6 | Background opacity | `backgroundOpacity` | L547 `ColorUtils.applyAlpha(base, …)` |
| 7 | Blur amount | `blurAmount` | L584–586 (`MultiEffect`, `blur: root.altBlurAmount`) |
| 8 | Scrim dim | `scrimDim` | L394–396 → `Qt.rgba(0,0,0, clamped/100)` |
| 9 | Auto-hide delay | `autoHideDelayMs` | `autoHideTimer` L1588–1593 |
| 10 | Niri overview | `showOverviewWhileSwitching` | L53, `maybeOpenOverview()` |
| 11 | Preset | `preset` | `listStyle` / `skewStyle` L51–52 |
| 12 | Compact style | `compactStyle` | L50, L486–531, L559, L1068 |
| 13 | Alignment | `panelAlignment` | `centerPanel` L49 |
| 14 | M3 layout | `useM3Layout` | L48, L584 |
| — | (config-only) | `enableBlurGlass` | `effectiveEnableBlurGlass` L101 |

---

## 5. Non-obvious mechanics (not visible in the settings UI)

1. **`isHighLoad` auto-degrade.** When `windowCount > 15`:

   ```qml
   readonly property bool isHighLoad: windowCount > 15
   readonly property bool effectiveEnableBlurGlass: root.altEnableBlurGlass && !isHighLoad
   readonly property bool effectiveEnableAnimation: root.altEnableAnimation && !isHighLoad
   ```

   Blur *and* animation are force-disabled regardless of user settings. A safety
   valve against lag with many windows. Worth keeping on port.

2. **Skew silently overrides cycle-only:**
   `effectiveNoVisualUi = altNoVisualUi && altPreset !== "skew"`.

3. **The slide animation is a translate, not a fade.** It animates
   `panelRightMargin` from `-panelWidth` → `0`:
   - open: `Easing.OutCubic`, `from = -panelWidth`, `to = 0`
   - close: `Easing.InCubic`, `from = panelRightMargin`, `to = -panelWidth`
   - **right-aligned only** — `centerPanel`, `compactStyle`, `listStyle`, `skewStyle`
     all bypass it and set `panelRightMargin = 0` directly (L1693, L1711).

   Our current switcher uses an opacity fade — a different animation primitive.

4. **`panelWidth` default is 380** (L20).

5. **MRU ordering algorithm** (`buildItemsFrom`, L255–277): take `mruIds` in order,
   push each matching item, then append any remaining items not yet used.

---

## 6. Portable vs. bloat

### Cheap & clean (maps onto tokens we already have)
- #3 + #4 — slide toggle + duration → retarget onto our existing fade constants
- #8 scrimDim — we already have `scrimDim = 0.35` as a constant; needs wiring
- #6 backgroundOpacity — our card colour alpha
- #7 blurAmount — we have binary `blurGlass`; iNiR uses 0–1
- #9 autoHideDelayMs — we currently have **no** auto-hide timer
- #1 noVisualUi — pure logic, no new visual code
- #5 MRU-first — small sort change, but needs a data-layer addition (see §7)

### Heavy — the "bloat/junk" to drop
- **Skew preset (#11)** — largest chunk. Pulls in
  `WindowPreviewService.captureForTaskView()` (screenshot-capture pipeline) plus
  ~150 lines of 12-slice 3D geometry (`baseSkewSliceWidth`, `baseSkewExpandedWidth`,
  `baseSkewSliceHeight`, `baseSkewOffset`, `skewSliceSpacing`, `skewScale`, L55–78).
- **List preset (#11)** — an entire second layout (~420px wide).
- **M3 card layout (#14)** — a third visual treatment.
- **Compact style (#12)** — a fourth visual treatment.
- **Show Niri overview (#10)** — `niri msg` overview action, niri-only; needs gating
  on Hyprland.
- **Tint app icons (#2)** — requires `ColorUtils` + icon colourisation not wired here.

---

## 7. The MRU blocker

iNiR's MRU is fed by a **live niri event stream**
(`NiriService.qml` L72–79 `DankSocket` → `handleWindowFocusChanged` L440–453),
which unshifts the focused window id and removes it from its old position.
Window close filters the id out (L576–578).

Our shell's situation differs:

| Compositor | Focus-change events | MRU feasibility |
|---|---|---|
| Hyprland | ✅ `activewindow` via `Compositor.rawEvent` (`compositor/Hyprland.qml` L74) | Buildable directly |
| Niri | ❌ `compositor/Niri.qml` is **poll-only** (`niri msg --json windows`), no event socket | Needs a focus-diff poller, or add an event socket |

MRU is therefore the one item that is **not** a pure UI port — it needs a small
data-layer addition (an MRU id list maintained from focus events/poll diffs).

---

## 8. Porting order (proposed)

Least risk → most work, each step independently shippable:

1. **Scrim dim + background opacity + blur amount** — visual-only; we already have
   the constants. No new layout code.
2. **Slide animation toggle + duration** — replace/parameterise our fade constants.
3. **Auto-hide delay** — add the timer.
4. **No visual UI (cycle only)** — logic-only; reuses our IPC `next`/`previous`.
5. **Preset / compact / alignment / M3** — layouts; pick which (if any) are worth the
   cost. Skew is the expensive one.
6. **MRU first** — requires the data-layer work in §7.

---

## 9. Open questions / decisions needed

- Do we want the **slide translate** (iNiR behaviour, right-edge only) or keep our
  **fade** as the animation primitive? They interact differently with our morphing
  pill and centre-aligned overlay.
- Which presets are actually wanted? `default` (our grid) is closest to what we
  already render; `list` / `skew` / `compact` / `M3` each add a layout.
- `showOverviewWhileSwitching` is niri-only (`niri msg`) — gate it off on Hyprland,
  or drop it entirely?
- `enableBlurGlass` is config-only in iNiR — expose it in our UI or keep it implicit?
