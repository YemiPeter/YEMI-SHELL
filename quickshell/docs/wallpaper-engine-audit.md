# Wallpaper Engine Audit — awww vs skwd-wall vs YemiShell

**Date:** 2026-09-22
**Scope:** Wallpaper painting pipeline, engine selection, color generation, and how the shell (YemiShell / quickshell) integrates with `skwd-walld` (Skwd Deck v2) and the legacy `awww` daemon.

---

## 1. Executive summary

Three paint systems currently coexist on the machine:

| System | Binary / unit | Role today | Status |
|---|---|---|---|
| **awww** (legacy) | `awww-daemon`, `awww` | Old painter, kept alive by `~/.config/hypr/scripts/wallpaper.sh init` at autostart | **Should be retired to fallback-only** |
| **skwd-wall v2** | `skwd-walld.service` → `skwd-walld --wait-for-session`, paints via `skwd-wall-still`, controlled via `skwd-helm` | The **adopted** background owner — the dispatcher prefers it | ✅ Primary |
| **mpvpaper** | `mpvpaper` (started by `set-wallpaper.sh`) | Animated (video/gif) picks only, layered over a static first-frame | ✅ Keep |

The single source of truth is the state file `~/.local/state/quickshell-wallpaper`, and the single color writer is `~/.config/quickshell/scripts/after-wall.sh`. Those two invariants are sound. The problems are duplicated entry points, a resurrected legacy daemon, and two competing color engines.


---

## 2. Current architecture (verified live)

### 2.1 Boot path

```
autostart.lua
  exec-once = ~/.config/hypr/scripts/wallpaper.sh init     ← LEGACY: starts awww-daemon
systemd --user
  skwd-walld.service → /usr/bin/skwd-walld --wait-for-session  ← v2 daemon
```

`wallpaper.sh init` runs `ensure_daemon()`, which **resurrects `awww-daemon`** even though nothing consumes its output anymore.

### 2.2 Pick path (Pill picker / `$mod+W` / random keybind)

```
Walls.qml (modules/pill/Singletons/Walls.qml)
  └─ Process: set-wallpaper.sh <compositor> set <path>
       ├─ animated pick (video/gif) + wallpaperVideoEngine=true
       │    ├─ try: skwd-helm apply <first-frame>     ← v2 (adopted)
       │    ├─ fallback: awww img <first-frame>       ← legacy fallback
       │    └─ then: start_mpvpaper <video>           (video plays over the frozen frame)
       └─ static pick
            ├─ try: skwd-helm apply <path>            ← v2 (adopted)

### 2.4 Key files

| File | Role |
|---|---|
| `~/.config/hypr/scripts/wallpaper.sh` | **Legacy** init/set/random painter (awww-only). Duplicate logic. |
| `~/.config/quickshell/scripts/set-wallpaper.sh` | **Single dispatcher.** Engine selection (skwd-helm → awww fallback), state file, bag/shuffle, mpvpaper for animated. |
| `~/.config/quickshell/scripts/after-wall.sh` | **Single color writer** → `~/.cache/yemi-shell/colors.json` (dominance engine by default; `YEMI_LEGACY_COLORS=1` for old wallcolors.py). |
| `~/.config/quickshell/modules/pill/Singletons/Walls.qml` | Shell-side bridge: warm cache, queue, `syncAwww()` lifecycle. |
| `~/.local/state/quickshell-wallpaper` | State file — the pick currently on screen. |
| `~/.local/state/quickshell-wallpaper-bag` | Shuffle bag for random picks. |
| `~/.local/state/quickshell/flags.json` | All Settings-driven wallpaper flags (transitions, engine, blur, dim…). |
| `~/.cache/skwd-wall-v2/` | skwd v2 state: `last-wallpaper.json`, `monitors.json`, `colors.json`, `scheme.json`, logs. |
| `~/.cache/skwd-wall/gpu-tier` | GPU tier detection (used by skwd to pick renderer quality). |
| `/usr/share/skwd-wall-v2/data/matugen/templates/` | skwd v2's matugen templates (ghostty, kitty, waybar, quickshell-colors.json…). |

---

## 3. Issues found

### 3.1 Two engines painting simultaneously (bug, cosmetic)

`awww-daemon` is alive *and* `skwd-wall-still` owns the visible background layer. Both sit at the Wayland background layer level; skwd only wins by stacking order. Because the dispatcher prefers skwd-helm, **awww's layer silently goes stale** — it holds whatever was last painted through the legacy path. Consequences:

- If skwd crashes, the desktop briefly flashes an **old** wallpaper instead of black.
- skwd restarts can race with the awww layer beneath.

**Fix:** kill awww at skwd adoption (see §4 step 2) and stop resurrecting it.

### 3.2 Two competing "init" entry points

- `autostart.lua` runs the **legacy** `~/.config/hypr/scripts/wallpaper.sh init` (awww-only, own transition logic).
- The shell picker runs `set-wallpaper.sh` (skwd-first).

They duplicate the bag/shuffle logic, the flags.json transition reading, and the state-file write. The legacy script is ~90% dead code that can desync state.

### 3.3 Duplicate transition systems (UI lies)

`wallpaper.sh` builds awww transition args (`--transition-type/fps/step/duration/angle` from flags.json) — but those only apply on the **awww fallback path**. skwd v2 configures its own effects (`skwd-wall-effects` / its own v2 config). Result: the Settings transition UI silently does nothing on the adopted skwd path.

### 3.4 Color pipeline duplication (three palettes)

Both run on every wallpaper change:

| Producer | Engine | Output | Consumers |
|---|---|---|---|
| `after-wall.sh` | dominance engine (python) | `~/.cache/yemi-shell/colors.json` + `terminal.json` + `hypr-colors.lua` | YemiShell (Dyn.qml), terminals, hyprland colors |
| `skwd-walld` v2 | matugen | `~/.cache/skwd-wall-v2/{colors,scheme,skwd-colors}.json` + fan-out from `/usr/share/skwd-wall-v2/data/matugen/templates/*` (ghostty, kitty, waybar, quickshell-colors.json…) | skwd's own tooling + any template consumers |

Two theming engines generate palettes from the same wallpaper; whichever finishes last wins for any consumer that reads both. This causes flicker/inconsistency when the two palettes differ.

### 3.5 Process-per-pick in skwd

`skwd-wall-still` spawns **one process + one layer surface per pick** (`--persist`), and the log shows sequential replaces working. It works today, but rapid iteration depends on skwd cleaning up old surfaces. Not a bug — a design note. The shell-side queue in `Walls.qml` (`queuedApply`) already collapses shell-side races.

### 3.6 Zombie daemon bookkeeping

`awww-daemon` has no owner at boot anymore: `wallpaper.sh init`'s `ensure_daemon()` resurrects it, and nothing ever kills it. It lingers across sessions.

            └─ fallback: awww img <path> + awww transition args
       then:
         ├─ state file write  ~/.local/state/quickshell-wallpaper
         └─ after-wall.sh → dominance engine → ~/.cache/yemi-shell/colors.json
```

### 2.3 Verified process tree at audit time

---

## 4. Recommended consolidation plan

**Goal:** skwd v2 is the only painter; awww is a fallback that never runs unless skwd is genuinely absent/broken; one color engine; the Settings UI controls what actually happens.

| # | Change | Why |
|---|---|---|
| 1 | **Retire the legacy `wallpaper.sh`.** Reduce it to a shim that calls `set-wallpaper.sh hyprland init` (or delete it), and update `autostart.lua` accordingly | One init path, one state writer, kills the awww resurrection |
| 2 | **Kill the stale awww layer.** In `Walls.qml` `syncAwww()`, also stop `skwd-wall-still` when hiding; and after a successful `skwd-helm apply`, `pkill -x awww-daemon` so the fallback daemon doesn't linger | Prevents the stale second layer and the crash-flash |
| 3 | **Pick ONE color engine.** Either: (a) make skwd's matugen the single writer — drop the dominance path and update `after-wall.sh` consumers to read skwd's palette; or (b) configure skwd v2 to not run matugen and keep `after-wall.sh` as the only writer | One palette, no races, no flicker |
| 4 | **Map transitions properly.** Move the flags.json transition settings into skwd v2's effects config (or hide the awww transition UI when the skwd engine is active) | UI stops lying |
| 5 | **Keep the skwd-helm → awww fallback** in `set-wallpaper.sh` — the exit-checked design is genuinely good | Already correct; no change |

### Suggested order of execution

1. Step 1 first (lowest risk, highest de-duplication value).
2. Step 2 next (removes the visible artifact).
3. Step 3 is the big one — decide dominance vs matugen **before** touching it, since consumers (`Dyn.qml`, terminal fan-out, `hypr-colors.lua`) all read from `after-wall.sh`'s output today.
4. Step 4 last (cosmetic/UI truthfulness).

---

## 5. Appendix — engine behavior reference

### awww
- `awww query` — daemon liveness check
- `awww img <path> --transition-type <t> --transition-fps <n> --transition-step <n> --transition-duration <seconds> [--transition-angle <deg>]`
- Transitions: fade, wipe, wave, etc. Angles: right=0, bottom=90, left=180, top=270.
- Duration is **seconds** (flags.json stores ms; `set-wallpaper.sh` divides by 1000).
- Cache: `~/.cache/awww/`.

### skwd-helm (control client for skwd-walld)
```
apply <path|key> [-o OUT]   apply a wallpaper by file path or library key/name
random [-o OUT] [--favourites] [--type T] [--tag T]
next | prev / back | forward
list [--json] / current [--json] / outputs [--json]
pause | resume / mute | unmute / volume <0-100>
retheme                      regenerate app colours without changing wallpaper
watch [--exec 'cmd %path%']  stream daemon events as JSON
```

### skwd-walld.service (user unit)
```
ExecStart=/usr/bin/skwd-walld --wait-for-session
Restart=on-failure
Conflicts=skwd-daemon.service
```

### mpvpaper (animated path)
Started by `set-wallpaper.sh` over a frozen first-frame extract. If it dies, the first frame stays on screen (graceful degradation). Skipped entirely on `restore`.

### "Hide main wallpaper" semantics
Niri-only (`backdropHideWallpaper` + `Compositor.isNiri`): kills the awww layer so the QML Backdrop is the sole renderer. On Hyprland the daemon is currently kept alive regardless — **this comment in Walls.qml predates skwd adoption and should be revisited** (see §4 step 2).


```
pid 698     skwd-walld --wait-for-session                          (systemd, v2 daemon)
pid 311433  skwd-wall-still Pole.webp --fill-mode fill --persist   (visible "skwd-paper" layer)
pid 304559  awww-daemon                                            ← ALSO RUNNING (stale second layer)
```

**Recommendation:** consolidate on skwd v2 as the primary engine, keep awww strictly as an exit-checked fallback, retire the legacy `wallpaper.sh`, and pick ONE color engine (dominance vs matugen).
