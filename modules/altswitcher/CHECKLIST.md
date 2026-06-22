# AltSwitcher — Build Checklist

Alt+Tab window switcher. Hold Alt, press Tab → shows open windows, cycle to the one you want.

**Modes:**
- Normal — visual list, tab through it
- Skew style — animated card layout (later)
- No-UI — skips the overlay, jumps straight to next window on quick double-tap
- IPC interface (`open` / `close` / `toggle` / `next` / `previous`) so keybinds and the bar can drive it

---

## Blocking — nothing works without these

- [x] **Add imports** — `AltSwitcher.qml` line 1 is still `// TODO(yemi): add your own imports here`.
  Needs the standard Qt/Quickshell set: `QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls`, `Quickshell`, `Quickshell.Io`, `Quickshell.Wayland`, and whatever IPC import `IpcHandler` comes from.

- [x] **Add a visual layer** — the entire UI was stripped. There is no window, no list, nothing renders.
  Minimum viable: a plain box that shows window titles as text rows, with the selected item highlighted.
  No animation, no icons, no skew style needed yet. Just enough to confirm the logic works.

- [ ] **Wire the keybind** — once `qs ipc call altSwitcher next` works from a terminal, update
  `70-binds.kdl`: change `Alt+Tab` / `Alt+Shift+Tab` from the old dead script path to the IPC call.

---

## Verified clear — do NOT block on these for normal mode

`mruWindowIds`, `inOverview`, `toggleOverview` are **only** used inside:
- `rebuildSnapshot` / `rebuildSnapshotSync` / `rebuildNoUiSnapshotSync` — the `mruIds` arg is passed to
  `buildItemsFrom`, which only uses it when `altUseMostRecentFirst === true`. Falls back to
  workspace-sorted order silently when the array is empty. **Normal mode works without MRU.**
- `maybeOpenOverview` / `maybeCloseOverview` — these functions are stubs and are **never called** in
  the current file. No code path reaches them yet.
- `noUiSnapshotUpdateTimer` — only runs when `effectiveNoVisualUi === true`, which requires
  `altNoVisualUi: true` in config. Off by default.

**Conclusion:** build and test normal mode completely. None of these block it.

---

## Later / polish (not blocking)

- [ ] **MRU ordering** — add `mruWindowIds` to `Niri.qml` + surface through `Compositor.qml`,
  then remove the three `mruIds = []` TODOs in the rebuild functions.
- [ ] **Overview integration** — add `inOverview` + `toggleOverview()` to `Niri.qml` / `Compositor.qml`,
  then implement `maybeOpenOverview` / `maybeCloseOverview` properly.
- [ ] **Window preview capture** — `WindowPreviewService.captureForTaskView()` stub in `showPanel`
  (skew + niri path only). Not needed until skew style is built.
- [ ] **Icons** — `getCachedIcon` returns `""` right now (safe stub). Decide: build a lookup or
  leave icon-less. See the two `// TODO(yemi): decide whether to build icon lookup` comments.
- [ ] **Skew style** — the geometry/scale properties are all there; needs visual layer first.
- [ ] **`listView` dangling refs** — `listView.positionViewAtIndex`, `listView.currentItem.activate`
  are called in `nextItem` / `previousItem` / `activateCurrent`. These become real once the
  visual layer adds a `ListView` with `id: listView`.
- [ ] **`autoHideTimer`** — referenced in several places but not defined anywhere yet. Add it to
  the visual layer once that exists (simple `Timer { id: autoHideTimer; interval: root.altAutoHideDelayMs }`).
- [ ] **`skewCardShowTimer`** — same situation, belongs in the visual layer.
- [ ] **`slideInAnim` / `slideOutAnim`** — animation objects for the slide-in panel, belong in
  the visual layer.
- [ ] **Rapid-dispatch drop** — `Niri.qml dispatch()` silently drops calls while one is in-flight.
  If rapid Alt-Tab ever misses a step, this is why — not a broken keybind.