# Audit 03 — Dead Code (unused symbols pass)

Method: defined-function scan vs. whole-tree call-site count. **Candidates
only** — each needs one manual confirmation (some are IPC handlers or signal
handlers invoked from outside QML).

## Confirmed dead / remove after check
| Location | Symbol | Note |
|---|---|---|
| `pill/Singletons/Sysmon.qml` | `keepAlive`, `releaseKeepAlive`, `updateHistories` | no call sites anywhere |
| `pill/Look.qml` | `resetToDefault()` | no call sites (settings UI has no "reset" wired) |
| `pill/LinkWifi.qml` | `syncPwField()` | no call sites |
| `common/widgets/WallpaperCrossfader.qml` | `_travelDistance` | internal helper, unused |

## Likely dead (verify against `qs ipc` usage first)
`pill/shell.qml` exposes many single-word functions (`battery`, `bluetooth`,
`calendar`, `clipboard`, `hide`, `keybinds`, `launcher`, `link`, `media`,
`mixer`, …) with no QML call sites — most are **IPC handlers** called via
`qs ipc call <obj> <fn>`. Cross-check each against `~/.config/hypr/modules/
binds.lua` and any niri keybind spawn lines before deleting; anything not
bound and not called is dead.

## False positives (do NOT remove)
`onXxxChanged` handlers, `decide` (Ame.qml), `toggleSilent` (Notifs.qml),
`call` (Workspaces) — these are signal handlers / externally invoked.

## Dead-flag suspects (logic dead code)
- `Flags.backdropEnableAnimatedBlur` + `wallpaperEnableAnimatedBlur` +
  `wallpaperAnimatedBlurStrength`: gated flags whose feature paths only run
  in double-paint mode now — check reachability after the §1 isolation fixes.
- `Flags.wallpaperMultiMonitorEnable`, `wallpaperSelectionTarget` — need a
  reachability check in Background.qml settings.
