# Pill Workspace Section — Niri Inconsistency Audit

**Scope:** Pill dashboard workspace indicator (dots next to the hover clock/date) and
the workspace OSD. Hyprland works; Niri leaves the pill "blind" to the current space.
**Date:** 2026-08-28
**Compositor in effect:** `XDG_CURRENT_DESKTOP=niri` (verified, niri binary present).

---

## 1. Section map (where the workspace UI lives)

| Symptom surface | File:line | What it shows |
|---|---|---|
| Hover dot strip (the "workspace section by time/date") | `modules/pill/Pill.qml:751` → `Workspaces { id: ws }` inside `hoverRow`, sitting left of the clock divider (`Pill.qml:765`) and the `Column` clock/date (`Pill.qml:777`) | Active workspace = larger vermillion dot; rest are small dim dots. Click focuses a space. |
| Workspace OSD flash | `modules/pill/Osd.qml:440` `Workspaces { id: wsIndicator }` + `Osd.qml:63` `activeWsName` | On switch, morphs pill open to show where you landed. |
| Active-space resolution (shared logic) | `modules/pill/Workspaces.qml:55` `activeName`, `Workspaces.qml:31` `range` | Single source of truth for "which dot is lit" + "which dots exist". |
| Compositor backend | `compositor/Compositor.qml`, `compositor/Niri.qml`, `compositor/Hyprland.qml` | Normalizes workspace/monitor data for both compositors. |
| Rule-driven dot range (Hyprland only) | `modules/pill/Singletons/Workspacerules.qml` | Empty on Niri (no `hyprctl`); Niri falls back to live workspaces. |

`Compositor.focusedWorkspace`, `Compositor.monitors[i].activeWorkspace`, and
`Compositor.workspaces` are the three fields every consumer reads.

---

## 2. Data flow (Niri)

```
niri msg --json workspaces  ──parseWorkspaces──▶  _niriState.workspaces { id → ws }
niri msg --json outputs      ──parseMonitors──▶    _niriState.monitors  { output → mon }
                                              └─linkWorkspacesToMonitors─▶ mon.activeWorkspace = ws (if ws.is_focused)
Timer 500ms (Niri.qml:139) ──▶ updateNiriState ──▶ 3 async processes (workspaces/windows/outputs)
Workspaces.qml reads Compositor.focusedWorkspace / Compositor.monitors → activeName
```

**Niri raw shape (captured live):**
```json
[{"id":4,"idx":4,"name":null,"output":"eDP-1","is_urgent":false,"is_active":true,"is_focused":true,"active_window_id":3}, ...]
```
Key fields: `id` (int), `idx` (int), **`name` (null by default!)**, `output` (string), `is_focused`/`is_active`.

---

## 3. Root cause — Niri `name` is `null`

`Workspaces.qml` and `Osd.qml` identify the active space by **`name`**, assuming the
Hyprland convention where a workspace's `name` is the string form of its id ("1","2",…).

- `Workspaces.qml:55` `activeName`:
  - Fast path (`Workspaces.qml:60`): `fw.monitor && fw.monitor.name === screenName`.
    Niri workspaces have **no `monitor`** field (they use `output`), so this path is
    **dead on Niri** and always falls through.
  - Slow path (`Workspaces.qml:70`): returns `mons[i].activeWorkspace.name`. On Niri that
    is **`null`** → coerced to `""`. So `activeName === ""`.
  - `isActive` (`Workspaces.qml:115`): `activeName === wsName` where `wsName = String(w.id)`
    (e.g. `"2"`). `"" !== "2"` → **no dot ever lights up.**
- `Osd.qml:67` `activeWsName`: same `mon.activeWorkspace.name` → `null`/`""`.
  `onActiveWsNameChanged` (`Osd.qml:70`) only flashes when length > 0, so the workspace
  OSD **never fires on Niri.**

The `range` (dots that *exist*) is built from `w.id` (`Workspaces.qml:43`), so the dots
**do** appear — but the active marker is computed from the null `name`, leaving the pill
blind to the current space. This exactly matches the reported symptom.

Clicking a dot still works: `Compositor.dispatch('workspace ' + slot.wsName)`
(`Workspaces.qml:140`) → Niri backend parses `parts[1]` as the id (`Niri.qml:106`) →
`focus-workspace <id>`. So focus changes, but the highlight/OSD never reflect it.

---

## 4. Inconsistencies found (ranked)

1. **CRITICAL — `name` is `null` on Niri (no active highlight, no workspace OSD).**
   `Workspaces.qml:55,70` and `Osd.qml:63,67` consume `name`; Niri defaults it to `null`.
   Fix in one place: normalize `name` to `String(id)` in `Niri.qml` so both backends share
   Hyprland semantics (`ws.name` ≈ id string). This repairs dots + OSD with no consumer changes.

2. **HIGH — Niri fast path is dead code.** `Workspaces.qml:60` `fw.monitor.name` never
   exists on Niri (uses `output`), so Niri always uses the 0–500 ms slow path. After the
   normalization above the slow path works, but the dead fast path means Niri never gets
   the instant update Hyprland gets. Optionally add a `monitor` alias on the Niri ws
   object (e.g. `monitor: { name: ws.output }`) so the fast path engages.

3. **MEDIUM — No event-driven updates on Niri.** Hyprland refreshes workspaces instantly
   via `rawEvent` (`Hyprland.qml:60`) + `refreshWorkspaces()`; Niri relies solely on the
   500 ms polling `Timer` (`Niri.qml:139`). Result: up to ~500 ms lag and missed rapid
   switches. Niri has no native event socket here, so the pragmatic fix is to (a) shorten
   the poll and (b) trigger `updateNiriState()` immediately after a successful
   `dispatch` (focus/scroll) so the UI catches up without waiting a full cycle.

4. **MEDIUM — Multi-monitor: only the keyboard-focused output gets an `activeWorkspace`.**
   `linkWorkspacesToMonitors` (`Niri.qml:296`) links `mon.activeWorkspace` only when
   `ws.is_focused`. On Niri, `is_focused` is true on exactly one workspace total; other
   outputs keep `activeWorkspace = null` → their pill shows no lit dot. Niri exposes
   `is_active` per output (`true` for the workspace currently shown on each output). Use
   `is_active` (fallback `is_focused`) when linking so every monitor resolves its space.
   (Single-monitor eDP-1 here is unaffected, but this bites on real multi-monitor setups.)

5. **LOW — Latent id/name mismatch even on Hyprland.** `range` is keyed by `w.id`
   (`Workspaces.qml:43`) while `activeName` is keyed by `w.name` (`Workspaces.qml:70`).
   They coincide for numbered workspaces but diverge for *named* workspaces on either
   compositor. Normalizing `name → id` everywhere keeps the two consistent; if named
   workspaces must be supported, switch the `range` key to the same field `activeName` uses.

---

## 5. Recommended fix (single normalization point)

In `compositor/Niri.qml` `parseWorkspaces`, when constructing each workspace object, set:
```js
ws.name = ws.name ?? String(ws.id);   // Niri defaults name to null; mirror Hyprland id-string
```
Optionally also inject `ws.monitor = { name: ws.output }` so `Workspaces.qml`'s fast path
engages, and switch `linkWorkspacesToMonitors` to prefer `is_active` over `is_focused` for
multi-monitor. After this, `Workspaces.qml` and `Osd.qml` need no edits — they already
read `name` correctly once it is populated.

This keeps the existing backend-normalization philosophy (`_toArray` in `Compositor.qml`)
and avoids duplicating Niri-specific branching in every consumer.

---

## 6. Verification (post-fix)

- `niri msg --json workspaces` shows `name:null`; after fix, confirm `Compositor` exposes
  a non-null `name` per workspace (log or temp debug binding).
- Switch spaces with Super+arrow / Super+wheel / clicking a dot → the correct pill dot
  lights vermillion and the workspace OSD flashes within one cycle.
- Confirm `wsIndicator`/dots track `Compositor.focusedWorkspace` live on Niri (not blank).

---

## 7. VERDICT (user + re-verify) — `--id` does NOT exist on this niri

User caught a gap (and a wrong premise in the doc's "preferred fix"):

- **`is_active` vs `is_focused`** ✅ confirmed: `is_active` = visible on its output (one per
  monitor) — the only correct field for a per-monitor pill dot. Using `is_focused` made the
  dot vanish on unfocused monitors.
- **`id` vs `idx`** ⚠️ real: `idx` is the workspace's *current position* on its monitor and
  **changes when workspaces are reordered/deleted**, so anything assuming `id == idx` drifts.
- **BIGGER gap (user):** `focus-workspace <idx>` is scoped to the **focused monitor**, not the
  monitor the workspace visually sits on. Clicking monitor B's slot while focus is on A silently
  moves monitor A. Worse than id/idx drift — needs no deleted workspace to trigger.

**Re-verified the `--id` premise against the installed binary (`niri 26.04`):**
```
niri msg action focus-workspace --help   →  <REFERENCE> (index or name)  →  NO --id
niri msg action focus-workspace --id 2   →  error: unexpected argument '--id' found
niri msg action focus-window   --id <ID> →  exists (window only)
```
So the "dispatch by stable id" fix is **invalid on this version**. `focus-workspace` only
takes an index/name; there is no output-independent id targeting.

**Resolution implemented (version-accurate, no `--id`):**
1. `Niri.qml parseWorkspaces` — normalize each row: `name` falls back to `"WS <idx>"`
   (never null, so OSD/label work); keep `id` (stable) **and** `idx` (position); add
   `isActive` (= raw `is_active`).
2. `Niri.qml linkWorkspacesToMonitors` — link `mon.activeWorkspace` on `isActive`
   (fallback `is_focused`). Every monitor now resolves its own active dot (fixes the
   unfocused-monitor blind dot).
3. `Workspaces.qml` — dot `range` carries the workspace object; active marker binds to
   `wsObj.isActive` on Niri (per-output), `activeName` match on Hyprland; `activeIndex`
   rewritten to scan `isActive`/id instead of `parseInt(activeName)` (range is now objects).
4. `Niri.qml dispatch` — `workspace <idx>` → resolve `idx`→`output` and run
   `focus-monitor '<output>' && focus-workspace <idx>`. Correct on multi-monitor (targets the
   right monitor) and harmless on single-monitor. Dispatch by `idx`, not `id`, so no id/idx drift.

**Live verification (session restored after):**
- Sim against live `niri msg --json workspaces` + `outputs`: per-monitor active resolves to
  `eDP-1 → idx 2 (isActive true)` ⇒ dot lights.
- `focus-monitor 'eDP-1' && focus-workspace 1` accepted; focused idx moved 2→1→2 (restored).
  Confirms index-scoped focus + chain works.

**Caveat:** Niri has no event socket here, so updates still ride the 500 ms poll
(`Niri.qml:139`); switching is correct but can lag up to ~500 ms. `name` fallback `"WS <idx>"`
is a generic label (no user-set name shown) — fine for dots/OSD.
