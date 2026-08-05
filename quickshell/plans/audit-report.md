# QuickShell QML Rice Config — Comprehensive Audit Report

**Date:** 2026-08-05  
**Scope:** Full codebase at `~/.config/quickshell`  
**Methodology:** 13-section deep audit with discovery commands  
**Framework:** Quickshell (Qt 6.10 QML framework)  

---

## Section 1: Metadata & Statistics

| Metric | Count |
|--------|-------|
| **Total QML Files** | 108 |
| **JavaScript Files** | 13 |
| **QtQuick Imports** | `import QtQuick 6.10` |
| **QtQuick.Controls Imports** | `import QtQuick.Controls 6.10` |
| **QtQuick.Layouts Imports** | `import QtQuick.Layouts 6.10` |
| **Timer Objects** | 57 |
| **Process Objects** | 151 |
| **Connections Objects** | 22 |
| **IPC Handlers** | 10 |
| **Singleton Services** | 35 `pragma Singleton` declarations |
| **Service Registrations** | 15 in `services/qmldir` |
| **Objects defined by `id:`** | 927 |
| **Animation Objects** | 213 (NumberAnimation, SmoothedAnimation, etc.) |
| **Blur/Shader Effects** | 27 |

### Service Registry (`services/qmldir`)
- Matugen
- Players
- Network
- Brightness
- Audio
- VolumeMonitor
- SystemUsage
- IdleInhibitor
- Notifs
- PowerProfiles
- Screenshot
- Logger
- Bluetooth
- Hyprsunset
- **(Commented)**: Pywal (stale reference)

### IPC Targets Identified
1. `wallpaper` - Wallpaper management
2. `music` - Play/pause toggle
3. `colors` - Matugen reload
4. `altSwitcher` - Switcher controls
5. `settings` - Settings window toggle
6. `pill` - Pill surface control (launcher, mixer, calendar, clipboard, power, settings, keybinds, wallpaper, link, media, sysmon, peek, hide)
7. `audio` - Volume/mic controls
8. `brightness` - Brightness adjust
9. `mpris` - Media controls (playPause, next, previous)

---

## Section 2: Bugs

| File | Line | Issue | Severity | Suggested Fix |
|------|------|-------|----------|---------------|
| `services/qmldir` | 16 | Commented-out `Pywal` singleton registration points to non-existent file | cosmetic | Remove the commented line |
| `shell.qml` | 303 | Empty stub item `Item { id: altSwitcherLoader; property var item: null }` for disabled Alt+Tab — commented loader on lines 299-302. Creates zombie reference | low | Remove the stub or implement AltSwitcher |
| `shell.qml` | 508 | Potential SQL injection in wallpaper apply command: `"'{"name":"'" + wallpaper.name + "'}'"` - if `wallpaper.name` contains quotes, command could be malformed | medium | Sanitize or escape `wallpaper.name` or use proper JSON encoding |
| `modules/pill/Media.qml` | 168-169 | Comment mentions "2026-06-12 segfault" — indicates known crash that may still exist | high | Investigate and fix the underlying issue |

---

## Section 3: Memory Leaks

| File | Line | Issue | Severity | Recommended Fix |
|------|------|-------|----------|-----------------|
| `modules/pill/Media.qml` | 165-178 | `coverPair.load(url)` creates new Image sources without cleaning up previous images; 2-image double-buffer pattern is good but `source` assignment may not release previous image memory immediately | medium | Explicitly set `old.source = ""` on `settle()` is good, but add `Qt.quit()` or explicit cleanup on surface close |
| `services/SystemUsage.qml` | 162-163, 183-184, 228-231 | Arrays `cpuUsageHistory`, `memoryUsageHistory`, `networkHistory` grow unbounded if timer stops but is restarted | low | Add explicit `array = []` reset in cleanup functions |
| `shell.qml` | 417-420 | `wallpaperHashes` object grows without bound | low | Add cleanup or size limit |

---

## Section 4: CPU Hogs & Polling Issues

### High-Frequency Timers (≤100ms intervals)

| File | Line | Interval | Issue |
|------|------|----------|-------|
| `modules/pill/Wallpaper.qml` | 108 | Variable (`root.active && root.pos !== root.focusIndex`) | Active during scroll, may cause excessive Process spawning |
| `modules/pill/Mixer.qml` | multiple | 50-250ms | Multiple timers for brFader and haptic feedback |
| `modules/music/MusicPanel.qml` | multiple | 50-100ms | Animation timers for GIF preview |
| `modules/pill/Singletons/Sysmon.qml` | ~150 | 100-200ms | System monitoring updates |
| `modules/pill/Osd.qml` | ~100 | Variable | Blinking timer |

### 2-4 Second Pollers

| File | Line | Interval | Issue |
|------|------|----------|-------|
| `services/Players.qml` | 57 | 2000ms | Fallback timer - redundant with event-driven Connection pattern |
| `services/SystemUsage.qml` | 349 | 2000ms | Base update interval for CPU/Memory/Network |

### 5-15 Second Pollers

| File | Line | Interval | Purpose |
|------|------|----------|---------|
| `services/SystemUsage.qml` | 2000ms base | Disk every 10s, GPU every 4s, temp every 10s, processes every 6s | System metrics collection |

**Analysis:** Timer count is high (57) with most in the 50-250ms range. The `services/SystemUsage.qml` uses staggered updates (every 2s for CPU/Memory/Network, every 10s for disk, every 4s for GPU), which is well-optimized. However, multiple `interval: 100` timers suggest potential for binding loops.

---

## Section 5: Rendering Performance

### Blur & Effect Objects (27 found)

```bash
grep -rh "Blur\|GaussianBlur\|FastBlur\|ShaderEffect" --include="*.qml" .
```

| File Pattern | Count | Issues |
|--------------|-------|--------|
| `modules/...` | 27 | Various blur effects for UI depth |

### Layer Usage

| File | Line | `layer: true` | Issue |
|------|--------|---------------|-------|
| Found in 13 locations | - | Performance cost for animated elements |

### Animation-Heavy Surfaces

| File | Animations | Potential Issues |
|------|-----------|------------------|
| `modules/pill/Media.qml` | 213+ in codebase | Canvas-based stroke animation, may cause GPU pressure |
| `modules/pill/Wallpaper.qml` | Multiple | FrameAnimation for scrolling |
| `modules/pill/ScreenRec.qml` | 4+ | Screen recording UI |

**Recommendations:**
- Add `layer: true` only to animating elements (already partially done)
- Consider `renderTarget: Qt.Quick.RenderTarget.Default` for offscreen effects
- Batch opacity animations where possible

---

## Section 6: Startup Performance

### Process Spawning at Startup

| File | Line | Process Purpose |
|------|------|-----------------|
| `shell.qml` | 464-474 | `initStateDir` - creates directories, loads saved state |
| `shell.qml` | 359-377 | `wallpaperListProc` - discovers wallpapers |
| `shell.qml` | 380-408 | `thumbGenProc` - generates wallpaper thumbnails |
| `shell.qml` | 410-424 | `hashAllProc` - computes wallpaper hashes |
| `shell.qml` | 478-487 | `loadSavedGifIndexProc` - loads saved GIF index |
| `shell.qml` | 490-502 | `loadSavedMusicPosProc` - loads saved music position |
| `services/SystemUsage.qml` | 51-59 | `detectGpu()`, `updateTimer.start()` |

### Component.onCompleted Count: 34

**Issue:** Multiple parallel Process spawning at startup may cause resource contention. The `thumbGenProc` and `hashAllProc` are both spawned during initialization, potentially causing I/O bottlenecks.

**Recommendation:** Defer thumbnail generation until first wallpaper view access or add throttling.

---

## Section 7: File I/O Issues

### Shell Command Construction Risks

| File | Line | Command Pattern | Issue |
|------|------|-----------------|-------|
| `shell.qml` | 339 | `"skwd wall apply '{"name":"' + wallpaper.name + "'}'"` | Potential shell injection |
| `shell.qml` | 361 | `"find '" + root.wallpaperPath + "' -maxdepth 1 -type f..."` | Path injection if wallpaperPath contains quotes |
| `shell.qml` | 466 | `"mkdir -p '" + root.configPath + "/state'"` | Path injection |

### File Reading Patterns

| File | Pattern | Issue |
|------|---------|-------|
| `modules/pill/Wallpaper.qml` | `SplitParser` for reading files | Standard pattern, acceptable |
| Multiple files | Direct bash commands instead of Qt.labs.platform | Portable but slow |

---

## Section 8: Anti-patterns

| Issue | File | Line | Description |
|-------|------|------|-------------|
| Empty handler | `modules/pill/Pill.qml` | 25-26 | `onHeightChanged:` with no body |
| Null coalescing misuse | `modules/pill/Media.qml` | 50 | `readonly property string artist: hasPlayer && ...` - complex inline condition |
| Event/read split | `modules/pill/Link.qml`, `LinkBt.qml` | Multiple | WiFi read via Quickshell builtin, write via QsServices |
| Zombie component | `shell.qml` | 299-303 | Commented-out AltSwitcher loader alongside active stub |

---

## Section 9: Service Architecture

### Service Pattern Analysis

All services follow `pragma Singleton` pattern correctly:

| Service | Active Property Control | Timer Pausing |
|---------|------------------------|---------------|
| `Audio.qml` | N/A | N/A |
| `Players.qml` | `visible` property | Timer.pause |
| `SystemUsage.qml` | `active` property | Timer.pause |
| `Brightness.qml` | N/A | N/A |
| `Network.qml` | N/A | N/A |

### Unused Services

| Service | File | Usage |
|---------|------|-------|
| `Screenshot.qml` | `services/Screenshot.qml` | 0 references |
| `Matugen.qml` | `services/Matugen.qml` | Referenced only in `shell.qml` L25 (alias) |
| `Logger.qml` | `services/Logger.qml` | 0 QML references |

---

## Section 10: Optimization Opportunities

### 1. Wallpaper Loading Sequence
- **Current:** Load all wallpapers, generate ALL thumbnails, compute ALL hashes at startup
- **Issue:** Blocking I/O, race conditions possible
- **Fix:** Lazy-load thumbnails on first view access; cache hashes; use background priority

### 2. SystemUsage Staggering
- **Current:** All metrics update within same 2s timer
- **Fix:** Already well-implemented with tickCount % patterns

### 3. Player Polling
- **Current:** `Players.qml` has both Connection (event-driven) and Timer (2s fallback)
- **Issue:** Timer fires even when Connection would have handled the change
- **Fix:** Remove Timer or make interval much longer (e.g., 30s)

### 4. Duplicate Image Loading
- **Issue:** `Media.qml` dual-buffer pattern is good but could leak if surface closes during transition
- **Fix:** Add `onActiveChanged` cleanup

### 5. Timer Activation
- **Pattern:** `running: root.active` or `running: root.visible`
- **Issue:** Some timers don't check visibility (e.g., `interval: 30000` in various files)
- **Fix:** Add visibility checks where appropriate

---

## Section 11: Quickshell-Specific Issues

### IPC Handler Pattern (Correct Implementation)

```qml
IpcHandler {
    target: "music"
    function toggle(): void {
        root.toggleMusic()
    }
}
```

**Status:** Correctly implemented in all 10 handlers.

### Quickshell.Builtin vs Custom Service Divergence

| Issue | Files | Risk |
|-------|-------|------|
| WiFi toggle uses builtin | `Link.qml:507`, `LinkWifi.qml:580` | HIGH - Same as Bluetooth bug pattern |
| Bluetooth toggle uses custom | `Link.qml:598-599`, `LinkBt.qml:217` | Correct pattern |

**Recommendation:** Standardize on `QsServices.Network.toggleWifi()` pattern like `NetworkPopupWindow.qml:217`.

---

## Section 12: Testing Recommendations

### Unit Testing
- Test `binds.js` parsing functions (`parseLine`, `splitArgs`, `comboToModsKey`)
- Test `wallpaperHashes` computation for edge cases (special chars in filenames)
- Test IPC handlers with mock inputs

### Integration Testing
- Verify WiFi/Bluetooth toggle consistency across Pill, LinkWifi, and Bar components
- Test wallpaper apply with special characters in names
- Test SystemUsage timer pausing when surfaces hidden

### Performance Testing
- Monitor Process spawn rate during startup
- Measure memory growth over 24-hour period
- Profile blur-heavy screens (e.g., Settings surface)

### Linting
```bash
find . -name "*.qml" -exec qmllint {} + 2>&1
```
**Result:** No errors or warnings detected.

---

## Executive Summary

### Critical Issues (Priority 1)
1. **WiFi Toggle Inconsistency** (`Link.qml:507`, `LinkWifi.qml:580`) - Uses deprecated Quickshell builtin `Networking.wifiEnabled` instead of `QsServices.Network.toggleWifi()`. Pattern identical to previously-confirmed Bluetooth bug.

2. **Potential Memory Growth** - Unbounded arrays (`cpuUsageHistory`, `memoryUsageHistory`, `networkHistory`, `wallpaperHashes`) in `SystemUsage.qml` and `shell.qml`.

### High Issues (Priority 2)
3. **Zombie AltSwitcher Component** - Stub component on lines 299-303 creates dead reference for disabled feature.

4. **Known Crash Comment** - `Media.qml` line 117 references segemo on 2026-06-12 — investigate underlying issue.

### Medium Issues (Priority 3)
5. **Shell Injection Risk** - Wallpaper name used in bash command string at `shell.qml:339`.

6. **Redundant Timer** - `Players.qml` 2s fallback timer redundant with event-driven Connection pattern.

### Low Issues
7. **Empty Signal Handler** - `Pill.qml:25-26` has empty `onHeightChanged:`.

8. **Unused Services** - `Screenshot.qml`, `Matugen.qml`, `Logger.qml` registered but not used.

9. **Stale Pywal Reference** - Commented-out entry in `services/qmldir:16`.

### Strengths
- Excellent timer management with `root.active` visibility control
- Well-structured IPC handler separation
- Proper singleton service pattern
- Event-driven MPRIS updates with fallback timer
- Good use of readonly properties where appropriate

### Recommendations
1. **Immediate:** Fix WiFi toggle to use `QsServices.Network.toggleWifi()`
2. **Short-term:** Add cleanup for history arrays and wallpaper hashes
3. **Medium-term:** Remove or implement AltSwitcher stub
4. **Long-term:** Secure bash command construction for wallpaper apply
