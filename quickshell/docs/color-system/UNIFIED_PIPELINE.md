# UNIFIED_PIPELINE.md — Single-Source-of-Truth Color Architecture for YEMI-SHELL

> The goal of this document is to define the **one** flow that takes a wallpaper
> change (or a palette/mood toggle) and produces a consistent, reloadable color
> set for (a) the Quickshell UI and (b) every terminal emulator, with **no
> duplicate writers** and **no schema mismatch**. It is the target state
> described in `COLOR_FIX_PLAN.md` Phase 1.

---

## 1. The Problem: two writers, one file

Two Python scripts — `~/.config/hypr/scripts/wallcolors.py` (247 lines, *camelCase*
semantic schema) and `~/.config/quickshell/scripts/wallcolors.py` (186 lines,
*snake_case* HSL-ramp schema) — both compute `CACHE = ~/.cache/yemi-shell/colors.json`
and `terminal.json`. They are invoked by **different** triggers:

| Trigger (current) | Invokes which script | Writes which schema | Signals Quickshell? |
|-------------------|---------------------|---------------------|---------------------|
| Picker tile / `skwd wall apply` → `wallpaper.sh` → `Walls.applyProc exit` → `after-wall.sh` | **both** (hypr copy in `wallpaper.sh`, quickshell copy in `after-wall.sh`) | hypr first, then quickshell overwrites ✅ | ✅ via `after-wall.sh` (but currently to no-op `matugenReload`) |
| Appearance surface palette/mood toggle → `staticProc`/`dynamicProc` | **hypr copy only** | ❌ camelCase → Dyn can't read → fallbacks | ❌ |
| `qs ipc call colors reload` | nothing (no-op `matugen.reload()`) | — | ❌ |

Because `Dyn.qml` reads `colors.json` and its `JsonAdapter` only defines the
**quickshell** (snake_case) keys, any path that leaves the **hypr copy's**
camelCase payload as the final write silently collapses every `Dyn.*` token to
its baked-in warm-teal default. The UI keeps *looking* themed (the defaults are
deliberately close to the static hex) while the wallpaper hue is ignored.

`terminal.json` is also written twice with two different ANSI→matugen mappings,
so terminal colors are a write-order race.

---

## 2. The Target Architecture

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │  TRIGGER                                                             │
  │  ─ wallpaper change (picker / skwd-wall / keybind / boot)            │
  │  ─ palette/mood toggle in Appearance surface                         │
  │  ─ external (hyprlust reload)                                        │
  └───────────────────────────────┬──────────────────────────────────────┘
              (one entry point)   │
              ▼                    ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │  single entry: scripts/after-wall.sh <mood> <wallpaper?>            │
  │     mood ∈ {dark, light} ; wallpaper optional (read from state      │
  │     file if omitted; required only when Flags.paletteMode=dynamic)  │
  └───────────────┬──────────────────────────┬───────────────────────────┘
                  │                          │
          mode=static?                    mode=dynamic?
                  ▼                          ▼
   wallcolors.py --mode static --mood <mood>   wallcolors.py <wallpaper>   ◀── UNIQUE writer
                  │                          │
                  └───────────┬──────────────┘
                            ▼
            ~/.cache/yemi-shell/
               ├── colors.json     (snake_case palette  →  Dyn.qml FileView watches + auto-reloads)
               ├── terminal.json   (ANSI 16 → apply-terminal-colors.py)
               └── hypr-colors.lua (active/inactive border colors → hyprctl reload)

  ┌──────────────────────────────────────────────────────────────────────┐
  │  CONSUMERS (all read-only, no writes)                                │
  │                                                                      │
  │  Dyn.qml   FileView{watchChanges:true} → JsonAdapter → Dyn.* tokens  │
  │  Theme.qml dyn = Flags.paletteMode !== "static"; tokens = dyn?Dyn.X:"#hex"│
  │  ─ all QML surfaces bind Theme.* only (never Dyn directly)           │
  │  apply-terminal-colors.py reads terminal.json → kitty/ghostty        │
  │  compositor reads hypr-colors.lua                                    │
  └──────────────────────────────────────────────────────────────────────┘
```

### 2.1 Responsibilities (no overlap)

| Actor | Does | Does NOT |
|-------|------|----------|
| `wallpaper.sh` (hypr) | Set the image via `awww`, write the state file | Generate colors.json (delegated) |
| `after-wall.sh` (quickshell) | **Sole** writer of `colors.json` + `terminal.json` + `hypr-colors.lua`; terminal fan-out; signal Quickshell | Read wallpaper pixels (delegated to `wallcolors.py`) |
| `wallcolors.py` (quickshell, 186-line) | Read one wallpaper → emit the snake_case palette + ANSI map + lua | Touch the compositor or terminal configs |
| `Dyn.qml` | Watch `colors.json`, expose tokens | Write / call external tools |
| `Theme.qml` | Gate `dyn ? Dyn.X : "#hex"` | Know about wallpaper |
| `Flags.qml` | Persist `paletteMode`, `systemMood` | Extract colors |
| `Matugen.qml` | (deprecated) — only `reload()` which calls `Dyn.file.reload()` for safety | Generate `colors.qml` |

### 2.2 Signal / file-watcher wiring

- **Wallpaper change** → `Wallpapers.qml.applyProc.onExited` → `afterWallProc`
  runs `after-wall.sh <pic>`. (`Wallpaper.qml:127`, `Walls.qml:127-156`.)
- **skwd-wall** delegates to `wallpaper.sh` via
  `externalWallpaperCommand` (config). `wallpaper.sh` no longer calls
  `wallcolors.py` itself — it only sets the image + state file and exits 0; the
  `afterWallProc` in `Walls.qml` then drives the palette. (If skwd's
  `sync-colors.sh` also fires, the second `after-wall.sh` is idempotent — it
  just rewrites the same file.)
- **File watch**: `Dyn.qml` `FileView { path: colors.json; watchChanges: true;
  onFileChanged: reload() }`. Because only one writer touches `colors.json`, the
  watch event is always consistent (no mid-schema race). No IPC reload needed in
  the common case; the `colors` IPC handler still exists as a manual
  "re-read now" button (pointing at `Dyn.file.reload()`, not the no-op
  `Matugen.reload()`).
- **Mode/mood toggle**: `Appearance.qml:62-63` writes `Flags.paletteMode` /
  `Flags.systemMood` (→ `flags.json`), then calls `applyMode()` →
  `after-wall.sh <mood>` which runs the single `wallcolors.py` with
  `--mode` derived from `flags.json .paletteMode`. Same writer, same schema,
  guaranteed.

### 2.3 Why this resolves every reported symptom

| Symptom | Cause (before) | Resolution (after) |
|---------|----------------|--------------------|
| Two wallpaper paths fighting | `wallpaper.sh` + Appearance toggle each call a *different* `wallcolors.py` | Both go through `after-wall.sh` → the *one* quickshell `wallcolors.py` |
| Only topbar pill colored, others not | After the toggle path, `colors.json` held the camelCase schema → `Dyn.*` fell to defaults; non-bar surfaces use `Dyn`-derived tokens so they all froze to the same default | `colors.json` always snake_case → `Dyn.*` returns real wallpaper values |
| `qs ipc call colors reload` useless | Targeted `matugenReload` (unregistered) → no-op | Targets `Dyn.file.reload()` (real re-read, also unnecessary thanks to `watchChanges`) |
| `Matugen.qml`/`colors.qml` dead path | Writes `state/colors.qml`, never read | Removed or reduced to a re-read shim |

---

## 3. Migration Steps (consolidated — see `COLOR_FIX_PLAN.md` for diffs)

1. **`scripts/after-wall.sh`** — become mode/mood-aware; single writer; signal `colors reload` (registered target).
2. **`modules/pill/Appearance.qml`** (L40, L48) — call `after-wall.sh` instead of the hypr copy.
3. **`~/.config/hypr/scripts/wallpaper.sh`** — stop invoking `wallcolors.py`; keep only `awww img` + state + `hyprctl reload`.
4. **`services/Matugen.qml`** — drop `applyWallpaper()`/`colorsPath`; keep `reload()` → `Dyn.file.reload()`.
5. **`shell.qml`** (L25, L53-60, L455-461) — keep the `colors` IPC, make it call `Dyn.file.reload()`; optionally keep `matugen` alias for back-compat.
6. **Delete** `~/.config/hypr/scripts/wallcolors.py` once `wallpaper.sh` no longer references it (or keep it as a thin wrapper that delegates, for safety).

---

## 4. Output File Inventory (post-migration)

```
~/.cache/yemi-shell/colors.json      ← one writer (wallcolors.py quickshell copy)
~/.cache/yemi-shell/terminal.json     ← one writer (same script)
~/.cache/yemi-shell/hypr-colors.lua   ← one writer (same script)
~/.local/state/quickshell/flags.json  ← Flags.qml (paletteMode, systemMood, …)
~/.local/state/quickshell-wallpaper   ← wallpaper.sh (current image path)
```

No other component writes `colors.json` or `terminal.json`. The skwd-wall
`quickshell-colors.json` matugen integration stays **dormant** (`"matugen": false`
in its config) — it is a fallback for users who disable the Hyprland `wallpaper.sh`
hook entirely, not part of the active chain.

---

## 5. Verification Snapshot

After migration, a single wallpaper change produces exactly this call chain
(no duplicates, no schema flip):

```bash
$ strace -e trace=openat -f quickshell 2>&1 | grep colors.json   # one writer
$ inotifywait -e modify ~/.cache/yemi-shell/colors.json          # one event
# → Dyn.qml FileView.onFileChanged → JsonAdapter repopulates → Theme.* rebinds
$ grep surface_container_low ~/.cache/yemi-shell/colors.json     # snake_case present
$ grep accent ~/.cache/yemi-shell/colors.json                   # camelCase ABSENT
```
