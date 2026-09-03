# Audit 05 — Performance (qt-qml-profiler pass)

## GPU / compositing
**43 `MultiEffect` / `layer.enabled` / `ShaderEffectSource` usages in 19 files**
(bar popups ×4, `Glass.qml`, `Tooltip`, `SettingsRow`, `Pill`, `Tray`,
`MusicPanel`, `AltSwitcher`, `AppIcons`, dialogs, wallpaper path,
`WallpaperCrossfader`).

Wins, cheapest first:
1. **Visibility-gate effects** — an effect on a hidden popup still costs a
   layer + shader unless the effect itself is `visible: false`. Gate every
   popup-effect on its window's visible state.
2. **SettingsRow per-row layer effects** — settings surfaces instantiate many
   rows; static icons should be pre-colored assets (fluent-white pattern)
   instead of `layer.effect` colorization.
3. **Backdrop blur/saturation/contrast** runs per-frame on Niri — fine, but
   keep defaults conservative for weak GPUs (blurMax 64 is the ceiling; verify
   only when radius > 0).

## Timers (~40)
- ✅ two `interval: 1` one-shot startup kicks (SystemInfo, Updates) — fine.
- 🟡 8×1000ms, 6×2000ms, 5×500ms, 3×300ms pollers. Convert to
  `running: <surfaceVisible>` where they only feed UI (clock, network, battery),
  and to event/watcher-driven where a FileView or daemon signal exists.
- ✅ debounces (Mixer 160ms ×3, WallpaperListener 80ms) fine.

## Processes (47 `Process {}`)
Poll-based ones → FileView watchers or signals. Biggest suspects: anything
polling on an interval that just reads a file (battery, brightness, updates).

## Log spam as a perf cost
`Theme.flameGlow` undefined-assignment spam (4,104 warnings, see
04-hidden-bugs B1) means binding re-evaluation + string formatting on every
change — fixing B1–B3 is itself a performance win, not just correctness.

## Startup
Two one-shot timers + 47 processes at boot: order non-critical probes
(Updates availability, Weather, Devices) behind `Timer`/idle so the shell's
first frame isn't competing for exec slots.
