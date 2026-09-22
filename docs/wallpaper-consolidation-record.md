# Wallpaper Consolidation — Execution Record (Phases 0–3)

Companion to `wallpaper-engine-audit.md`. Documents what was **actually done**
on 2026-09-22 to consolidate the wallpaper stack on skwd-wall v2 as the single
engine. skwd suite at `1.0.0_beta.17-1` (AUR `*-bin` packages).

## Final architecture

```
   Pill picker ────────►┌──────────────────────────────┐
   Random keybind ─────►│  set-wallpaper.sh            │──► state file:
   Legacy callers ─────►│  (single dispatcher)         │    ~/.local/state/quickshell-wallpaper
   (wallpaper.sh shim)  └──────────────┬───────────────┘
                                      │ skwd-helm apply <path>
                                      ▼
                            skwd-walld (systemd user svc)
                                      │
                                      ▼
                        skwd-wall-still / skwd-paper-v2
                        (owns the layer + transitions —
                         per-wallpaper via v2 sceneProperties)
                                      │
                                      ▼
                        after-wall.sh (dominance colors — sole color writer)
```

- **One painter:** skwd (v2), via `skwd-helm apply`. awww is retired.
- **One state file:** `~/.local/state/quickshell-wallpaper` — read by
  Backdrop, the pill, and the color pipeline; written by the dispatcher
  (except `restore`, read-only by design).
- **One transition owner:** skwd (per-wallpaper via v2 sceneProperties). The
  flags.json `transition*` keys fed only the dead awww path — dead config.
- **One color engine:** `after-wall.sh` (dominance) — unchanged, sole writer.

## Phase 0 — zombie awww layer (done)

Live system was three-way desynced: awww painted `On-the-phone.webp` on eDP-1
while skwd and the state file agreed on a different pick. Killed pid 304559
(`pkill -x awww-daemon`); screen unaffected — skwd owns the layer.
## Phase 1 — `set-wallpaper.sh` is now skwd-only (done)

`/home/yemi/.config/quickshell/scripts/set-wallpaper.sh`:

- **Removed** `ensure_daemon()` (awww spawner) → replaced with `wait_helm()`:
  polls `skwd-helm current` up to 10s so login-time `init` survives the
  `skwd-walld --wait-for-session` boot race.
- **Removed** the entire awww fallback branch and the `AWWW_ARGS` transition
  block (incl. the ms→seconds conversion — that whole scheme was awww-only).
- **Loud failures:** `fail_loud()` (stderr + critical notify-send) + `exit 1`
  when `skwd-helm apply` or first-frame extraction fails. No more silent
  `|| true` fallbacks that left a stale wallpaper.
- **`restore`** now re-applies via `skwd-helm apply` (paint-only, no state
  write, no color pipeline — semantics preserved).
- Remaining `awww` mentions in the file are historical comments only.

## Phase 2 — `Walls.qml` lifecycle (done)

`/home/yemi/.config/quickshell/modules/pill/Singletons/Walls.qml`:

- `syncAwww()` → **`syncSkwd(hide, initial)`**:
  - hide ON (Niri only): `skwd-helm pause` (was `pkill awww-daemon`)
  - hide OFF toggle: `skwd-helm resume`
  - **startup with hide OFF: `syncProc`** re-applies the state-file pick via
    `set-wallpaper.sh restore` (falls back to `init`). Preserves the old
    restoreProc behavior — Niri has no spawn-at-startup paint, and skwd
    restores from *its own* state, which can diverge from the shell's.
- `killProc`/`restoreProc` removed; header comments updated.
- Left alone (deliberate): `AwwwBackend.qml` (no importers — dead but
  harmless), `WallpaperCrossfader.qml` (Niri-only, off on Hyprland), the
  transition* UI group in `pill/Background.qml` (dead config; Phase 6).

## Phase 3 — legacy `wallpaper.sh` retired (done)

- Original (awww-based) script moved to
  `hypr/scripts/retired/wallpaper.sh.awww-legacy`.
- **Compat shim** at `hypr/scripts/wallpaper.sh` maps the old CLI
  (`wallpaper.sh <cmd> [path]`) onto the dispatcher (`set-wallpaper.sh
  <compositor> <cmd> [path]`); compositor defaults to `hyprland`, overridable
  via `$COMPOSITOR` (Niri callers set `COMPOSITOR=niri`).
- `hypr/modules/autostart.lua:4` now execs
  `~/.config/quickshell/scripts/set-wallpaper.sh hyprland init` directly.
- Niri `50-startup.kdl` comment updated to the syncSkwd flow (Niri paints

## Validation performed

- `bash -n` on dispatcher + shim: OK.
- Live `set` E2E: `skwd-helm apply` repainted, exit 0 (`applied: …`).
- Live `restore` E2E: exit 0, no state write, no color pipeline run.
- Post-run: `pgrep awww` → none (nothing resurrects it: autostart repointed,
  legacy script retired, syncAwww gone).
- Three-way agreement confirmed: state file == `skwd-helm current` == on-screen.

## Follow-up fixes (thumbnails + animated WebP mislabel)

Three defects found while verifying the pill strip after consolidation:

### 1. Wallpaper thumbnails silently failed for every source (FIXED)

`magick "${src}[0]"` under the security cage in
`~/.config/hypr/scripts/magick-policy/policy.xml` died with:

```
magick: cache resources exhausted '<file>' @ error/cache.c/OpenPixelCache/4036
```

Cause: the cage capped `memory` at 256MiB and `map` at 512MiB, but a
2048x1080 animated WebP needs ~9MiB of pixel cache *per frame*, and the
decoder materialises all 96 frames (~850MiB). Every thumbnail silently
produced nothing because the caller discarded stderr (`2>/dev/null`).

Fix:
- `policy.xml`: `memory` 256MiB → **2GiB**, `map` 512MiB → **4GiB** (still
  bounds a hostile file; dangerous coders — `PS`, `XC`, delegates, `@file`
  paths — remain blocked, re-verified).
- `wallpaper-thumbs.sh`: added `-define webp:decode-thumbnail=true` /
  `gif:decode-thumbnail=true` so only frame 0 is decoded, and moved the
  `$thumb.tmp` handling *inside* the image branch so the video branch no
  longer emits a false "no thumbnail" warning. Failures now print to stderr
  instead of vanishing.

### 2. `blueBeedroomTv.gif` was not a GIF (FIXED)

The file was actually an **animated WebP** (96 frames, 2048x1080) with a
`.gif` extension. skwd routes by extension, so it went to `skwd-wall-vk`
(the video renderer) while the still renderer only ever decoded frame 0 —
hence "works at startup then goes static". Renamed to
`blueBeedroomTv.webp` and converted to `blueBeedroomTv.mp4` (H.264, 1.8MB,
hardware-decoded via VAAPI, `"type": "video"`). A full library scan found no
other extension/content mismatches.

### 3. Stale path in the state file (FIXED)

After the rename, `~/.local/state/quickshell-wallpaper` still held the
deleted `blueBeedroomTv.gif`, promising a broken restore on next login.
Re-applied through the dispatcher
(`set-wallpaper.sh hyprland set …blueBeedroomTv.mp4`); three-way agreement
restored (state file == `skwd-helm current` == on-screen renderer).

Verified end-to-end: both tiles generate (`512x270` PNGs), `sh -n` clean,
and the on-screen wallpaper animates (33k pixels change per 3s sample).

## Remaining work (user decisions / later phases)

- **Phase 4 (user, in v2 Settings):** disable skwd's color engine so
  `after-wall.sh` stays sole color writer: `effects.autoRecolor=false`,
  autoTheme off, `theme.backend` none. (v2 settings are sqlite-backed — not
  safely editable from here.) Optionally then delete
  `~/.config/skwd-wall-v2/matugen/templates/` and the unconsumed
  `~/.config/kitty/skwd-theme.conf` / ghostty skwd-theme.
- **Phase 5:** GIF native test — `skwd-helm apply <gif>` (skwd-wall-still
  bundles a GIF decoder). If native playback works, the mpvpaper branch can
  be deleted later. Until then the animated branch stays as-is.
- **Phase 6:** delete/hide dead flags.json `transition*` keys and the
  "Wallpaper transitions" UI group in `pill/Background.qml`; delete
  `AwwwBackend.qml`; refresh comments in `WallpaperCrossfader.qml`,
  `Backdrop.qml`, `Glass.qml`; audit `boot-wallpaper-debug.sh`.
- **Return path (open):** picks made in v2's own picker (`$mod+Shift+W`) do
  not yet write the shell's state file, so Backdrop/colors lag until the next
  pill pick or login. Planned glue: `skwd-helm watch --exec` hook writing the
  state file on daemon wallpaper events (deferred — `watch` streams forever;
  needs event-schema parsing work).
- **"Pill-only transition" requirement:** dropped as unimplementable —
  transitions belong to skwd's engine, not a selector; both pickers now share
  one engine and one transition behavior, which is the consolidation goal.
  nothing at startup — the shell owns first paint).

---

## Post-reboot failure: "the wallpaper pill section can't be seen"

Reported after a reboot. Root cause was **not** in the wallpaper pipeline at
all — the pipeline was healthy throughout (1072 wallpapers, 1063 thumbs,
`skwd-paper` layer up, 0 awww processes). Two separate defects:

### 1. The shell was never guaranteed to start on Hyprland (the actual bug)

`hyprland.conf` had:

```
exec-once = quickshell -p $RICE_HOME/quickshell/shell.qml
```

Problems with this line as the *only* launch path:

- **`$RICE_HOME` is referenced at line 8 but exported by `env.lua`, which is
  only sourced at line 20.** It works by luck because
  `environment.d/rice.conf` exports it before Hyprland starts; if that ever
  regresses, the path becomes `/quickshell/shell.qml` and quickshell exits.
- **`exec-once` runs once and never retries.** It races the Wayland socket and
  `skwd-walld`. If quickshell loses that race it exits and the session comes up
  with **no bar and no pill**, which is exactly the reported symptom. Niri does
  not have this problem because `50-startup.kdl` spawns it separately.
- **A bare `quickshell` (no `-p`) loads the DEFAULT config**, not this rice's
  `shell.qml` — so a path slip degrades into a config-less shell rather than an
  obvious error.

Fix: new `~/.config/quickshell/scripts/start-shell.sh`, now the sole `exec-once`
entry. It waits (≤5 s) for the Wayland socket, waits (≤3 s) for `skwd-walld`,
then launches `setsid --fork quickshell -p <explicit path>` and retries **once**
if the process dies during startup (~6 s). It logs to
`~/.cache/quickshell/start-shell.log` and exits non-zero with a FATAL line if
the config is missing or both attempts fail — no more silent bar-less sessions.

### 2. `reload-shell.sh` started the wrong config

```bash
nohup quickshell > /dev/null 2>&1 &     # ← no -p
```

Bare `quickshell` → default config, so reloading produced a shell with the
wrong/absent bar and pill. This is what made the problem look like broken QML
during debugging: the shell reported `Configuration Loaded` and looked healthy
while rendering nothing of this rice. Now passes `-p "$CONFIG"` explicitly.

### 3. Latent: Hyprland fullscreen detector could strand the pill hidden

Found while investigating; fixed defensively in `pill/PillOverlay.qml`.

`monFullscreen` drives a slide-to-`-(pill.height + topGap)` transform and a
`PillState.close()` call, so a **stuck-true** value hides *every* pill surface
with no event left to clear it. The detect path was fragile on Hyprland:

- The polling `Timer` was `running: Compositor.runningCompositor === "niri"` —
  **Niri only**. Hyprland relied solely on `Component.onCompleted` plus the
  `Compositor.rawEvent` `Connections`.
- `Component.onCompleted` fires **before** the gated `Loader` has an `item`, so
  the Hyprland branch (`hyprFsLoader.item`) silently no-opped. With no timer
  there was no retry.
- Both `onExited` branches were **empty**, so a failed or unparseable
  `hyprctl activeworkspace -j` left `monFullscreen` latched at its previous
  value forever.

Changes: the timer now also runs on Hyprland (2 s vs Niri's 500 ms, since
Hyprland also gets event-driven updates), the docs explain the async-loader
race, and both failure paths now **fail open** (`monFullscreen = false`) — a
flash of pill over a fullscreen window is far cheaper than a permanently
invisible pill.

> Note: this defect was **not** the cause of the reported symptom. The
> `y=-350` layer seen in `hyprctl layers` during debugging was the **Music
> panel parked off-screen by design** (`MusicPanel.qml` → `margins.top: -350`,
> `implicitHeight: 188`), not a hidden pill. Recorded so the next reader does
> not chase the same false trail.

### Verified end state

```
shell      quickshell -p /home/yemi/.config/quickshell/shell.qml   (running)
pill       qs ipc call wallpaper toggle eDP-1 → opens, thumbnails render,
           stays open (burst capture at 0.25/0.5/0.8/1.2/2.0 s)
layers     skwd-paper 1920x1080 ; quickshell bar 1920x47 ;
           overlay 1920x1073 ; Music panel parked at y=-350 (by design)
wallpapers 1072        thumbs 1063
state file /home/yemi/Pictures/Wallpapers/City-2.webp
awww       0 processes
config     hyprctl reload → ok, hyprctl configerrors → empty
```