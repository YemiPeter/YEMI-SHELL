# COLOR_FIX_PLAN.md — Incremental Color System Fix Plan for YEMI-SHELL

> Companion to `YEMI_COLOR_WALLPAPER_AUDIT.md`. Each phase is independently
> deployable and verifiable; do them in order. Phase 1 is the foundation —
> without it the dynamic palette resolves to baked-in fallback hex and **no
> wallpaper color ever reaches the UI**, however many surfaces you tokenize.

---

## Guiding Principles (from the author's philosophy)

1. **Two-layer token façade stays**: `Theme` = static fallback hex; `Dyn` = live
   wallpaper colors. `Theme.dyn` (gate on `Flags.paletteMode !== "static"`)
   swaps between them per token. This works and must be preserved.
2. **Wallpaper color drives surface tint; text stays locked.** The HSL tint
   ladder in `wallcolors.py` is intentional — do not revert to raw matugen.
3. **One writer** per output file. Two scripts writing `colors.json` /
   `terminal.json` to the same path is the root defect.
4. **Incremental, reversible** — each phase ships a working shell.

---

## Phase 1 — Unify the wallpaper path (foundation)

**Goal:** One wallpaper change → one `wallcolors.py` → one `colors.json` (quickshell snake_case schema) that `Dyn.qml` can read → auto-reloads via `FileView.watchChanges`.

**Root cause being fixed:** `modules/pill/Appearance.qml` (L40, L48) calls the
**hypr copy** `~/.config/hypr/scripts/wallcolors.py`, which emits camelCase keys
(`surfaceLow`, `accent`, `border`, `content`…) that `Dyn.qml`'s `JsonAdapter`
does **not** define. After a palette/mood toggle, `colors.json` is frozen in the
wrong schema and every `Dyn.*` token silently returns its baked-in warm-teal
default — so the wallpaper hue never reaches the pill.

### Step 1.1 — Point the Appearance toggle at the quickshell copy

**File:** `modules/pill/Appearance.qml`

```diff
  // BEFORE (lines 36-50) — calls the hypr copy (wrong schema)
-         command: ["sh", "-c",
-             "python3 \"$HOME/.config/hypr/scripts/wallcolors.py\" --mode static --mood \"$1\" && hyprctl reload >/dev/null 2>&1; busctl --user call com.mitchellh.ghostty /com/mitchellh.ghostty org.gtk.Actions Activate \"sava{sv}\" reload-config 0 0 >/dev/null 2>&1 || true",
+         command: ["sh", "-c",
+             "WALL=\"$(cat \"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper\" 2>/dev/null || true)\"; "
+           + "python3 \"$HOME/.config/quickshell/scripts/after-wall.sh\" \"${1:-dark}\" \"${WALL:-}\" >/dev/null 2>&1; "
+           + "hyprctl reload >/dev/null 2>&1; "
+           + "busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty org.gtk.Actions Activate \"sava{sv}\" reload-config 0 0 >/dev/null 2>&1 || true",
              "sh", mood]
```

> Rationale: `after-wall.sh` already runs the **quickshell** `wallcolors.py`
> (correct schema) + `apply-terminal-colors.py` + signals quickshell. We extend
> `after-wall.sh` to honor `--mode` so the static/dynamic and dark/light toggles
> are served by one writer.

### Step 1.2 — Make `after-wall.sh` mode/mood aware

**File:** `scripts/after-wall.sh`

```diff
- # yemi-shell wallpaper color pipeline ...
+ #!/bin/bash
+ # yemi-shell wallpaper color pipeline — now the SINGLE writer of colors.json.
+ # Usage: after-wall.sh <mood|dark|light> [wallpaper-path]
+ #   mood=dark|light   → static palette for that mood
+ #   no path, dynamic  → derive from current wallpaper in state file
  set -euo pipefail
-
- WALL_PATH="${1:-}"
- SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
-
- [ -f "$WALL_PATH" ] || { echo "[yemi-shell] no wallpaper path given"; exit 1; }
-
- python3 "$SCRIPTS/wallcolors.py" "$WALL_PATH"
- python3 "$SCRIPTS/apply-terminal-colors.py"
- qs ipc call matugenReload 2>/dev/null || true
+WALL_PATH="${2:-}"
+SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
+CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/yemi-shell"
+
+if [ -z "$WALL_PATH" ]; then
+    WALL_PATH="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper" 2>/dev/null || true)"
+fi
+
+# Build the wallcolors.py args based on Flags.paletteMode / --mood
+MOOD="${1:-dynamic}"
+PMODE="$(jq -r '.paletteMode // "dynamic"' "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json" 2>/dev/null || echo dynamic)"
+
+if [ "$PMODE" = "static" ]; then
+    python3 "$SCRIPTS/wallcolors.py" --mode static --mood "$MOOD"
+else
+    [ -f "$WALL_PATH" ] || { echo "[yemi-shell] no wallpaper path and not static"; exit 1; }
+    python3 "$SCRIPTS/wallcolors.py" "$WALL_PATH"
+fi
+python3 "$SCRIPTS/apply-terminal-colors.py"
+qs ipc call colors reload 2>/dev/null || true
```

> Change (L25): `matugenReload` → `colors reload` (the **registered** IpcHandler
> target in `shell.qml:54-55`). The `matugenReload` target does not exist and
> was silently dropped.

### Step 1.3 — Stop `wallpaper.sh` (hypr) from writing the wrong schema

**File:** `~/.config/hypr/scripts/wallpaper.sh` (external — outside repo)

```diff
- pmode=$(jq -r '.paletteMode // "static"' "$flags_file" 2>/dev/null || echo static)
- if [ "$pmode" = "manual" ]; then
-     mh=$(jq -r '.manualHue // 30' "$flags_file" 2>/dev/null || echo 30)
-     md=$(jq -r 'if .manualDark == false then "light" else "dark" end' "$flags_file" 2>/dev/null || echo dark)
-     python3 "$(dirname "$0")/wallcolors.py" --hue "$mh" "$md" >/dev/null 2>&1 || true
- else
-     python3 "$(dirname "$0")/wallcolors.py" "$pic" >/dev/null 2>&1 || true
- fi
- hyprctl reload >/dev/null 2>&1 || true
+ # Delegate color generation to the single quickshell writer so colors.json
+ # stays in the Dyn.qml-expected schema. wallpaper.sh only sets the image +
+ # state here; after-wall.sh owns the palette.
+ python3 "$HOME/.config/quickshell/scripts/after-wall.sh" "dynamic" "$pic" >/dev/null 2>&1 || true
```

> This collapses Path A to a single writer. The `manual` branch is removed
> because `Flags.paletteMode` only emits `static`/`dynamic` (§1.5 of the audit);
> if manual-hue is ever needed, add it as a `Flags` value and a branch in the
> quickshell `wallcolors.py`, not a third script.

### Step 1.4 — Delete / neutralize the dead `Matugen.qml` color path

**File:** `services/Matugen.qml` — remove `applyWallpaper()` and the
`colorsPath`-to-`colors.qml` property (§1.4 of the audit). Keep only a
`reload()` that forces `Dyn.qml` to reparse:

```qml
function reload(): void {
    // Force Dyn.qml's FileView to re-read colors.json
    QsSingletons.Dyn.file.reload()
    if (QsSingletons.Flags.debug) console.log("🔄 [Matugen] Dyn reloaded")
}
```
And remove `Matugen` from `services/qmldir` (the existing audit already flagged it
as "Referenced only in `shell.qml` L25 (alias)" and "0 QML references" beyond
the no-op `reload()`).

### Acceptance checks (run after Step 1.4)

```bash
# 1. Toggle palette/mood — colors.json keeps the quickshell schema:
qs ipc call pill appearance <mon>        # open Appearance
jq 'keys' ~/.cache/yemi-shell/colors.json # must include surface_container_low, primary_container...

# 2. Change wallpaper — one writer only:
grep -c "wallcolors.py" ~/.config/hypr/scripts/wallpaper.sh   # expect 0 (removed)

# 3. colors IPC is honest:
qs ipc call colors reload; tail -n5 ~/.cache/yemi-shell/colors.json
```

---

## Phase 2 — Extend token coverage to all surfaces

> **Note:** every pill overlay surface already binds `Theme.*` and has **0**
> hardcoded hex (the audit's §2.2 table). Once Phase 1 makes `Dyn.*` return
> real colors, those surfaces theme themselves automatically. Phase 2 fixes the
> surfaces that **bypass** tokens entirely.

### Priority 1 — `modules/bar/components/Battery.qml` (6 hex + 1 Qt.rgba)

```diff
- if (isCritical) return "#ef4444"        // L57
- if (isLow) return "#f59e0b"            // L58
- readonly property color chargingColor: "#2dd4bf"   // L62  teal
- readonly property color liquidColor: "#5eead4"      // L64
+ if (isCritical) return QsSingletons.Theme.verm      // red
+ if (isLow) return QsSingletons.Theme.vermLit        // amber-ish
+ readonly property color chargingColor: QsSingletons.Theme.flameGlow
+ readonly property color liquidColor: Qt.lighter(QsSingletons.Theme.flameGlow, 1.2)

- color: batteryLevel > 50 ? "#000000" : "#ffffff"   // L186 (plug)
+ color: QsSingletons.Theme.cream

- color: "#ffffff"                                      // L304 (label)
+ color: QsSingletons.Theme.bright

- color: Qt.rgba(0.1, 0.1, 0.12, 1)                    // L234
+ color: Qt.alpha(QsSingletons.Theme.tileBg, 0.9)
```

### Priority 2 — `modules/osd/VolumeOSD.qml` + `BrightnessOSD.qml`

Drop the unused `required property var matugen`; bind to `Theme.*`:

```diff
- required property var matugen                      // Wrapper + both OSDs
- color: Qt.rgba(0.1, 0.1, 0.1, 0.4)                // body bg
- border.color: Qt.rgba(1, 1, 1, 0.06)
- color: Qt.rgba(0.2, 0.6, 1.0, 1.0)                 // icon — fixed azure
- color: Qt.rgba(0.8, 0.8, 0.8, 0.15)               // bar track
- color: Qt.rgba(0.8, 0.8, 0.8, 0.4)                // muted icon
- color: Qt.rgba(0.2, 0.6, 1.0, 1.0)                // bar fill
- color: Qt.rgba(0.9, 0.9, 0.9, 1.0)                // text
+ color: Qt.alpha(QsSingletons.Theme.tileBg, 0.40)
+ border.color: QsSingletons.Theme.hair
+ color: QsSingletons.Theme.cream
+ color: Qt.alpha(QsSingletons.Theme.dim, 0.15)
+ color: QsSingletons.Theme.onGlow
+ color: root.currentMuted ? QsSingletons.Theme.iconDim : QsSingletons.Theme.onGlow
```

> `shell.qml` must drop the `matugen` injection (`readonly property var matugen:
> QsServices.Matugen` at L25 and the `matugen: root.matugen` lines) once Phase
> 1.4 removes the property from the OSDs; otherwise the `required property`
> binding errors at load time.

### Priority 3 — `modules/pill/Osd.qml` gradient (`Osd.qml:416-418`)

```diff
- GradientStop { position: 0.0; color: "#00ffffff" }
- GradientStop { position: 0.5; color: "#55ffe6d6" }
- GradientStop { position: 1.0; color: "#00ffffff" }
+ GradientStop { position: 0.0; color: "transparent" }
+ GradientStop { position: 0.5; color: Qt.alpha(QsSingletons.Theme.onGlow, 0.33) }
+ GradientStop { position: 1.0; color: "transparent" }
```

### Priority 4 — `modules/pill/Pill.qml` (the two literals in the "good" surface)

- **L531** `"rgba(255,246,240,0.6)"` → in a `Canvas.onPaint`. Replace with a
  token-built color: `Qt.rgba(QsSingletons.Theme.bright.r, .g, .b, 0.6)` (or
  `Qt.alpha(Theme.bright, 0.6)` — note `bright` is a `color` in Theme, a
  `string` in Dyn; `bright`/`cream` exist in both, safe).
- **L570** `Qt.rgba(1, 1, 1, 0.04)` → mood-aware:
  `Qt.rgba(1, 1, 1, Flags.systemMood === "light" ? 0.02 : 0.04)`.

### Priority 5 — bar popup fallbacks (`?? "#..."`)

| File | Line | Now | Make |
|------|------|-----|------|
| `BrightnessPopupWindow.qml` | 20 | `m3Primary: … ?? "#f9e2af"` | `?? QsSingletons.Theme.onGlow` |
| `VolumePopupWindow.qml` | 25 | `m3Primary: … ?? "#a6e3a1"` | `?? QsSingletons.Theme.onGlow` |
| `BluetoothPopupWindow.qml` | 209 | `color: "#ffffff"` | `QsSingletons.Theme.bright` |
| `NetworkPopupWindow.qml` | 209, 603 | `color: "#ffffff"` (×2) | `QsSingletons.Theme.bright` |

### Priority 6 — `config/Appearance.qml` (the config-layer one)

```diff
- colSuccess: "#a6e3a1"     // L44
+ colSuccess: QsSingletons.Theme.verm
```

### Priority 7 — `config/BarConfig.qml`

The 7 hex values (`activeColor #BE5052`, etc.) are **user-tunable defaults** in a
config file, not render-time literals. Leave them, but document that the Bar
renders through `Theme.*` (it already does — `Bar.qml` builds its pills from
`Qt.rgba(Theme.*)`). No code change required.

---

## Phase 3 — Improve the token system

Add the gaps surfaces currently paper over with ad-hoc `Qt.darker`/`Qt.lighter`
or hardcoded accents:

| New token | Definition (in `Theme.qml`) | Consumes |
|-----------|------------------------------|----------|
| `Theme.success` | `dyn ? Dyn.success : "#5ac85a"` | charging battery, update-ready |
| `Theme.error` | `dyn ? Dyn.error : "#ef4444"` | low battery, destructive power tile |
| `Theme.onSurface` | `dyn ? Dyn.bright : "#fff6f0"` | primary text (alias of `cream`/`bright`) |

And teach the single `wallcolors.py` to emit `success` and `error` keys so
`Dyn.qml` gains `success` / `error` aliases (one-line additions to the `pill`
dict + `JsonAdapter`).

> Keep `Theme` and `Dyn` **separate** (user philosophy). Do **not** merge. The
> `dyn ? Dyn.X : "#hex"` ternary is the contract; only the *set* of keys grows.

---

## Phase 4 — Dark/light & opacity polish

- **Authoritative `systemMood`:** the Appearance surface already writes
  `Flags.systemMood`; Phase 1.2 makes `after-wall.sh` honor it as the `--mood`
  arg. To make light mode actually flip *surfaces* (not just the terminal
  color-scheme), `wallcolors.py` already branches on mood internally
  (`LIGHT_STEPS`/`LIGHT_TEXT`). The gap is that `wallpaper.sh`'s removed code
  no longer passes `--mood light` for the static branch — ensure
  `after-wall.sh "light"` reaches `wallcolors.py --mood light`.
- **Expose surface opacity/blur:** add `Flags.surfaceOpacity` (default 0.45 to
  match the OSD body) and `Flags.surfaceBlur`; bind OSD `color`/bar popups to
  them so they glass-match the pill rather than hardcoding `0.4`.
- **Wire `Theme.shadowOpacity`:** it exists (Theme L67, `0.5`) but `Theme.shadow`
  (L36) hardcodes `0.55`. Connect: `color: Qt.rgba(0, 0, 0, shadowOpacity)`.

---

## Verification matrix

| After phase | Run | Expect |
|-------------|-----|--------|
| 1.4 | `wallcolors.py` source check | only `~/.config/quickshell/scripts/wallcolors.py` writes `yemi-shell/colors.json` |
| 1.4 | `jq 'has("primary_container")' ~/.cache/yemi-shell/colors.json` | `true` |
| 1.4 | `grep -c manual ~/.config/hypr/scripts/wallpaper.sh` | `0` |
| 2  | `grep -rnE "#[0-9a-fA-F]{6}" modules/osd/ modules/bar/components/Battery.qml modules/bar/components/*PopupWindow.qml` | no matches (0) |
| 2  | `qmlscene`/`quickshell --dry-run` load | no `required property var matugen` binding errors |
| 3  | surface audit loop (§6) | all surfaces `hex:0` except `config/BarConfig.qml` (intentional) |
| 4  | toggle light mood → surfaces lighten | `Theme.cardBot` alpha + `wallcolors.py LIGHT_STEPS` applied |
