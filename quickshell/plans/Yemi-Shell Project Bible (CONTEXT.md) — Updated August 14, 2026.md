# Yemi-Shell Project Bible (CONTEXT.md) — Updated August 14, 2026

## 1. User & Environment
- **User:** Yemi. Backend/Systems mindset. Runs CachyOS (Arch) on a Dell Vostro 3520.
- **Desktop:** Hyprland (HyDE-based modular config: `~/.config/hypr/modules/` with `.lua` files).
- **Shell:** Quickshell (QML/Qt). Config at `~/.config/quickshell/`.
- **Multi-compositor:** Hyprland + Niri. Quickshell has compositor abstraction at `compositor/Compositor.qml`, `compositor/Hyprland.qml`, `compositor/Niri.qml`.
- **Dependencies:** Python 3 (stdlib only), ImageMagick (color extraction), jq (JSON parsing in bash).
- **Communication:** Plain English. Short. Direct. No jargon without explanation. Challenge lazy thinking.

## 2. Project Overview
Yemi-Shell is a custom Hyprland/Niri rice built on Quickshell. The core of this project is the **Theme System** (Dominance Color Engine). The AltSwitcher was ported from iNiR but **abandoned in favor of snappy-switcher** (standalone C daemon).

## 3. Theme System Architecture & Data Flow
The system relies on a strict **Single-Writer Pattern**:

1. `after-wall.sh` → The ONLY script allowed to write theme files.
2. `scripts/dominance-extract.py` → ImageMagick extracts 8 distinct colors from wallpaper, ranked by pixel frequency. Grayscale palettes (saturation < 0.06) crushed to pure grayscale.
3. `scripts/dominance-engine.py` → Derives full Material 3 schema (24 tokens for BOTH Dark and Light moods).
4. `~/.cache/yemi-shell/colors.json` (v2 schema) → Single source of truth.
5. `singletons/Dyn.qml` → Watches colors.json via FileView.
6. `config/Appearance.qml` → Adapts Dyn tokens + static Mood fallbacks.
7. `singletons/Theme.qml` → Public facade consumed by UI components (Pill, Bar, OSD).

## 4. AltSwitcher Status (PIVOTED)
- **Old approach:** Ported iNiR's QML AltSwitcher into `modules/altSwitcher/`. Built `CompositorService.qml` facade. **ABANDONED.** The QML port hit `IconImage is not a type` errors repeatedly and the agent hallucinated fixes.
- **Current approach:** `snappy-switcher` (https://github.com/OpalAayan/snappy-switcher) — standalone C daemon, Cairo/Pango rendering, Wayland Layer Shell. Installed via AUR.
- **Config:** `~/.config/snappy-switcher/config.ini`
- **Themes:** `~/.config/snappy-switcher/themes/*.ini`
- **IPC:** `snappy-switcher next/prev/toggle/select/hide`
- **Daemon:** `snappy-switcher --daemon` (started via Hyprland autostart)

## 5. CRITICAL RULES (Do Not Break)
1. **Single-Writer Rule:** Only `after-wall.sh` writes theme files. No QML file or external script may write to `colors.json`.
2. **Inode Rule:** `after-wall.sh` MUST write files using `cat tmp > target`. NEVER use `mv`. `mv` changes the inode, breaking Quickshell's FileView live-reload watcher.
3. **Async Reload Rule:** `FileView.reload()` is async. `Dyn.reload()` must only trigger the reload. JSON parsing MUST happen in `onLoaded` signal handler, never synchronously inside `reload()`.
4. **Hue Rule:** The engine may ONLY change Lightness (L). Hue (H) and Saturation (S) of wallpaper colors must be preserved exactly. Never inject chroma.
5. **Role Rule:** Dominant 1 (most pixels) = Surface/Background. Dominant 2 = Primary/Accent.
6. **No Matugen.** No pipeline rewrites. The dominance engine is final.
7. **Git Hygiene:** No `git commit -a` or `git add .`. Stage explicitly. Verify with `git diff --cached --name-only` before committing.

## 6. Current State & Known Issues
- **Live Reload:** Works perfectly. Wallpaper change → `after-wall.sh` → IPC → `Dyn.reload()` → FileView → UI updates instantly.
- **Static Mode:** Solid surfaces. Grayscale-accents toggle works.
- **KNOWN BUG:** `modules/altSwitcher/AltSwitcher.qml` still exists and throws `IconImage is not a type` on every Quickshell boot. It needs to be deleted along with its Loader in `shell.qml`.
- **KNOWN BUG:** `singletons/CompositorService.qml` may still be registered in `singletons/qmldir`. If no other component uses it, remove it.
- **KNOWN BUG:** `modules/pill/Updates.qml` throws `ReferenceError: Quickshell is not defined` at lines 27-28.
- **snappy-switcher:** Installed but NOT yet themed to match Yemi-Shell colors. NOT yet wired to `after-wall.sh` for dynamic updates. Hyprland layer rules for blur NOT yet added.

## 7. Roadmap
### Immediate (snappy-switcher integration)
1. **Purge dead QML AltSwitcher code:** Delete `modules/altSwitcher/`, remove Loader from `shell.qml`, remove `CompositorService.qml` if orphaned.
2. **Hyprland blur rules:** Add `layerrule = blur, snappy-switcher` to decoration config.
3. **Keybinds:** Wire Alt+Tab to `snappy-switcher next --mod alt` in `~/.config/hypr/modules/binds.lua`.
4. **Dynamic theming:** Create `scripts/snappy-theme-gen.py` that reads `colors.json` and generates `~/.config/snappy-switcher/themes/yemi-dynamic.ini`. Wire it into `after-wall.sh`.

### Future
- **Phase 4:** Terminal (`terminal.json`) and Hyprland (`hypr-colors.lua`) fan-out with strict readability.
- **Phase 5:** Live verification across edge cases (B&W, bright, dark, pastels).
- **Phase 6:** Cleanup, documentation, removing dead Matugen wiring.
- **Future:** QML Settings App with "Color Strength" slider.
- **Future:** "Liquid Glass" static mode for Quickshell panels.

## 8. Agent Lessons Learned (From This Project)
1. **Agents hallucinate.** After every file write, force a read-back verification (`grep`, `cat`) before claiming success.
2. **Audit every phase.** Every implementation prompt gets a matching audit prompt run by a second agent.
3. **Check `qs ipc` output** to verify IPC targets actually registered. `Target not found` means the component failed to load silently.
4. **Hyprland config is Lua-based** in this setup. Never paste raw Hyprlang into `.lua` files.
5. **Quickshell logs** live at `/run/user/1004/quickshell/by-id/*/log.qslog`. Use `grep -a` (binary-safe) to search them.