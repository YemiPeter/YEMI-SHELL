# Audit 03 — Dead Code
*Refreshed 2026-09-05 on branch `pill-perf`. Method: grep-verified zero references for every entry.*

## Resolved since last audit ✅
- ~~`Compositor.hasLayerBlur`~~ — interim flag, removed when `qmlShadows` landed; zero references.
- ~~`modules/pill/shaders/`~~ — experimental Hyprland shadow shader (vert/frag/qsb ×2); removed when the approach was abandoned.
- ~~`Theme.flameGlow` / `flameCore` / `todayWarm`~~ — were *referenced-but-undeclared* (worse than dead); now declared and live (`a13b119`, `e15503c`).
- ~~`modules/pill/shell.qml`~~ — old self-contained entry point (`pragma UseQApplication`, its own `PanelWindow` + `IpcHandler target: "pill"`); never referenced by the current `shell.qml` (which imports `modules/pill` as a namespace and instantiates `Pill.PillOverlay`). Deleted in `6555425`; its 5 still-needed IPC functions were ported to the live handler in `456b200`.

## Verified clean ✅
- **Theme singleton**: every `Theme.<token>` referenced anywhere in `modules/` is declared in `singletons/Theme.qml` (checked by extracting all declared properties + functions vs all referenced tokens). Zero dangling references. `Theme.joinArtists` (function, `Theme.qml:107`) is live — used by `Media.qml:51` and `Osd.qml:49`.
- **Flags**: spot-checked `pillBlur`, `backdropEnableAnimatedBlur`, `wallpaperEnableAnimatedBlur`, `barShadow` — all have live consumers.
- **Versioned imports**: zero `import Qt*.x.y` versioned imports remain in the tree.
- **`_travelDistance`**: only its definition site; no external callers — it's a private helper, fine.

## Candidates (verify before deleting)

### X1 — `keepAlive` / `restartIfRunning` pattern sweep
Earlier audit flagged possible unused process-keepalive plumbing. Current grep shows the pattern exists but each instance needs a consumer check before removal. **Do not bulk-delete** — some are load-bearing for services that must respawn (e.g. network polling).

### X2 — Old shadow-related Flags
If `Flags` grew any Hyprland-shadow experiment toggles during the shader attempt, they're orphaned now. Next time `singletons/Flags.qml` is open, cross-check its keys against `~/.local/state/quickshell/flags.json` and delete any key neither the QML nor the JSON references.

## Policy note
This repo's audits explicitly hunt orphaned flags/tokens. The `qmlShadows` refactor established the pattern: **one semantic gate in the compositor singleton, deleted interim flags immediately** — keep following it.