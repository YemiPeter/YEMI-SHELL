# Yemi-Shell Project Bible (CONTEXT.md) — Updated August 18, 2026

## 1. User & Environment
- **User:** Yemi. Backend/Systems mindset. Runs CachyOS (Arch) on a Dell Vostro 3520.
- **Desktop:** Hyprland (HyDE-based modular config: `~/.config/hypr/modules/` with `.lua` files) + **Niri** (second compositor).
- **Shell:** Quickshell (QML/Qt). Config at `~/.config/quickshell/`.
- **Multi-compositor:** Hyprland + Niri. Quickshell has compositor abstraction at `compositor/Compositor.qml`, `compositor/Hyprland.qml`, `compositor/Niri.qml`.
- **Two panel families in yemishell:**
  - **Waffle** — Niri-focused, derived (copied) from iNiR. Lives in `modules/waffle/`.
  - **Pill** — Hyprland-focused, derived (copied) from Ricelin (`/home/yemi/Ricelin`). Lives in `modules/pill/`.
- **Dependencies:** Python 3 (stdlib only), ImageMagick (color extraction), jq (JSON parsing in bash).
- **Communication:** Plain English. Short. Direct. No jargon without explanation. Challenge lazy thinking.

## 2. Project Overview
Yemi-Shell is a custom Hyprland/Niri rice built on Quickshell. The core of this project is the **Theme System** (Dominance Color Engine). The shell hosts **two independent panel families** — **Waffle** (Niri, from iNiR) and **Pill** (Hyprland, from Ricelin) — that **each keep their own settings UI** but **both read from ONE unified services source** (`yemishell/services/`). This mirrors iNiR's own two-desktop design (material/ii + waffle panel families living side-by-side, sharing services, never triggering each other).

iNiR is a **read-only reference** (never modified). pibble (`/home/yemi/pibble`) is a **reference for upgrading Pill's UI/UX** (copy some source only). Ricelin is the **source for Pill**.

## 3. Theme System Architecture & Data Flow
The system relies on a strict **Single-Writer Pattern**:

1. `after-wall.sh` → The ONLY script allowed to write theme files.
2. `scripts/dominance-extract.py` → ImageMagick extracts 8 distinct colors from wallpaper, ranked by pixel frequency. Grayscale palettes (saturation < 0.06) crushed to pure grayscale.
3. `scripts/dominance-engine.py` → Derives full Material 3 schema (24 tokens for BOTH Dark and Light moods).
4. `~/.cache/yemi-shell/colors.json` (v2 schema) → Single source of truth.
5. `singletons/Dyn.qml` → Watches colors.json via FileView.
6. `config/Appearance.qml` → Adapts Dyn tokens + static Mood fallbacks.
7. `singletons/Theme.qml` → Public facade consumed by UI components (Pill, Bar, OSD).

## 4. AltSwitcher Status (RETAINED — Niri-focused, 2026-08-18)
- **Decision reversed:** The QML AltSwitcher is **retained** because it is **Niri-focused**. The earlier "abandoned" status is superseded.
- **Prior attempt (context):** iNiR's QML AltSwitcher was ported into `modules/altSwitcher/`. It hit repeated `IconImage is not a type` errors and the agent hallucinated fixes.
- **Current approach (both coexist by compositor):**
  - **Niri path:** iNiR-derived QML AltSwitcher (kept — Niri-focused).
  - **Hyprland path:** `snappy-switcher` (https://github.com/OpalAayan/snappy-switcher) — standalone C daemon, Cairo/Pango, Wayland Layer Shell. Installed via AUR.
- **snappy-switcher config:** `~/.config/snappy-switcher/config.ini`
- **snappy-switcher themes:** `~/.config/snappy-switcher/themes/*.ini`
- **snappy-switcher IPC:** `snappy-switcher next/prev/toggle/select/hide`
- **snappy-switcher daemon:** `snappy-switcher --daemon` (Hyprland autostart)

## 5. CRITICAL RULES (Do Not Break)
1. **Single-Writer Rule:** Only `after-wall.sh` writes theme files. No QML file or external script may write to `colors.json`.
2. **Inode Rule:** `after-wall.sh` MUST write files using `cat tmp > target`. NEVER use `mv`. `mv` changes the inode, breaking Quickshell's FileView live-reload watcher.
3. **Async Reload Rule:** `FileView.reload()` is async. `Dyn.reload()` must only trigger the reload. JSON parsing MUST happen in `onLoaded` signal handler, never synchronously inside `reload()`.
4. **Hue Rule:** The engine may ONLY change Lightness (L). Hue (H) and Saturation (S) of wallpaper colors must be preserved exactly. Never inject chroma.
5. **Role Rule:** Dominant 1 (most pixels) = Surface/Background. Dominant 2 = Primary/Accent.
6. **No Matugen.** No pipeline rewrites. The dominance engine is final.
7. **Git Hygiene:** No `git commit -a` or `git add .`. Stage explicitly. Verify with `git diff --cached --name-only` before committing.
8. **iNiR is read-only:** Never modify iNiR source. Waffle is a *copy* in yemishell; changes go in yemishell, not in `/home/yemi/iNiR`.
9. **Two families, one services source:** Waffle and Pill must read shared state from `yemishell/services/` (`qs.services`). Neither family writes to or triggers the other.

## 6. Current State & Known Issues
- **Live Reload:** Works perfectly. Wallpaper change → `after-wall.sh` → IPC → `Dyn.reload()` → FileView → UI updates instantly.
- **Static Mode:** Solid surfaces. Grayscale-accents toggle works.
- **Waffle (iNiR clone, Niri-focused) — ported 2026-08-18:**
  - `modules/waffle/{bar,background,backdrop,looks}` present.
  - `services/WindowPreviewService.qml` + `scripts/capture-windows.{fish,sh}` copied from iNiR; all deps present (`Cliphist`, `ShellExec`, `Directories`, `FileUtils`, `NiriService`).
  - `modules/waffle/settings/` + `waffleSettings.qml` + `modules/settings/WaffleConfig.qml` copied but **PARKED** — standalone launcher needs iNiR-only singletons (`ThemeService`, `MaterialThemeLoader`, `AppLauncher`, `ShellUpdates`, `Idle`) we are NOT porting (they are part of the dropped iNiR app architecture). Waffle's own settings UI stays bar-tied, not a merged app.
- **Pill (Ricelin clone, Hyprland-focused):** present at `modules/pill`. UI/UX being upgraded by copying some source from pibble (`/home/yemi/pibble`, mapped in `docs/pibble-repo-map.md`).
- **AltSwitcher (RETAINED, Niri-focused):** `modules/altSwitcher/AltSwitcher.qml` still throws `IconImage is not a type` on boot — this must be **fixed**, not deleted.
- **KNOWN BUG:** `singletons/CompositorService.qml` may still be registered in `singletons/qmldir`. If no other component uses it, remove it. (Note: a separate `services/CompositorService.qml` is the live multi-compositor bridge and must stay.)
- **KNOWN BUG:** `modules/pill/Updates.qml` throws `ReferenceError: Quickshell is not defined` at lines 27-28.
- **snappy-switcher:** Installed but NOT yet themed to match Yemi-Shell colors. NOT yet wired to `after-wall.sh` for dynamic updates. Hyprland layer rules for blur NOT yet added.

## 7. Roadmap
### Immediate (map-first, no rush)
1. **Map the shell:** Audit Waffle vs Pill — what each reads/writes; separate **shared** code paths (→ unified `services/` source) from paths **uniquely tied to each bar/feature**. Resolves Ricelin-vs-vendored, config schema, and service de-duplication decisions.
2. **AltSwitcher:** Keep (Niri-focused). Fix the `IconImage is not a type` boot error. Keep `snappy-switcher` for the Hyprland path.
3. **Hyprland blur rules:** Add `layerrule = blur, snappy-switcher` to decoration config.
4. **Keybinds:** Wire Alt+Tab to `snappy-switcher next --mod alt` in `~/.config/hypr/modules/binds.lua`.
5. **Dynamic theming:** Create `scripts/snappy-theme-gen.py` that reads `colors.json` and generates `~/.config/snappy-switcher/themes/yemi-dynamic.ini`. Wire it into `after-wall.sh`.

### Unification workstream (incremental, as we work)
- Incrementally unify the shared "basic + robust" services into `yemishell/services/`.
- When the same capability exists on both sides, evaluate **merge vs keep**; merge only where clearly better.
- Upgrade Pill to consume Waffle-derived services where it makes sense (window previews, waffle-style features).
- Apply pibble UI/UX snippets into Pill when upgrading its UX.

### Future
- **Phase 4:** Terminal (`terminal.json`) and Hyprland (`hypr-colors.lua`) fan-out with strict readability.
- **Phase 5:** Live verification across edge cases (B&W, bright, dark, pastels).
- **Phase 6:** Cleanup, documentation, removing dead Matugen wiring.
- **Future:** yemishell-owned QML Settings features for both families (built on the unified services source, not iNiR's).
- **Future:** "Liquid Glass" static mode for Quickshell panels.

## 8. Agent Lessons Learned (From This Project)
1. **Agents hallucinate.** After every file write, force a read-back verification (`grep`, `cat`) before claiming success.
2. **Audit every phase.** Every implementation prompt gets a matching audit prompt run by a second agent.
3. **Check `qs ipc` output** to verify IPC targets actually registered. `Target not found` means the component failed to load silently.
4. **Hyprland config is Lua-based** in this setup. Never paste raw Hyprlang into `.lua` files.
5. **Quickshell logs** live at `/run/user/1004/quickshell/by-id/*/log.qslog`. Use `grep -a` (binary-safe) to search them.
6. **Clone drift is real.** Copying from iNiR/pibble leaves dangling references (e.g., `WindowPreviewService` missing; 5 iNiR-only singletons the Waffle settings needed). Map shared vs unique BEFORE merging.
7. **Don't rush unification.** Learned the hard way — merge-as-you-go during normal work, not a big-bang pass.

## 9. Architecture Direction — Unified Waffle + Pill (2026-08-18)
**Repo topology:**
| Repo | Role | Modified? |
|------|------|-----------|
| `/home/yemi/iNiR` | Reference ONLY for Waffle (Niri). Source of Waffle clone. | **Never** |
| `/home/yemi/Ricelin` | Source for **Pill** (Hyprland). | reference for Pill |
| `/home/yemi/pibble` | Reference for upgrading **Pill UI/UX** (copy some source). | never (copy only) |
| `/home/yemi/.config/quickshell` | **yemishell** — shell config + unified architecture (hosts Waffle + Pill + unified services). | yes |

**Principles:**
- Two independent panel families, ONE services source (`yemishell/services/`). Each keeps its own settings UI + bar-tied features.
- Neither side writes to or triggers the other; they cooperate hand-in-hand (mirrors iNiR's two-desktop system).
- Waffle is the richer family; its robust services are added to the unified source so Pill can adopt them.
- iNiR stays reference-only; pibble used only to copy UI/UX snippets into Pill.

**Full plan:** see `.kilo/plans/1787070586627-unified-waffle-pill-architecture.md`.
