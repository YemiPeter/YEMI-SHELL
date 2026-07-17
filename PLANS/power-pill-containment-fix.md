# Implementation Plan

Fix the Power pill containment bug where the hibernate action tile and profile-cycle tile render outside the pill's visible morph/background shape.

The Power surface in `Power.qml` has grown to 7 tiles (1 profile-cycle Loader + 6 action Repeater items) but the pill's morph background width in `Pill.qml` is hardcoded to `330 * s`, which is too small for the actual content. The morph shape's width must derive from the surface's actual content width rather than a stale constant.

[Types]

No new types needed. The existing `surfaces` descriptor in `Pill.qml` maps `"power"` to `Qt.size(powerW, powerH)` — only the `powerW` value changes.

[Files]

Two files modified, zero created or deleted:
- **`/home/yemi/.config/quickshell/modules/pill/Pill.qml`** — line 113: change `powerW` from hardcoded `330 * s` to a dynamic binding that reads the Power surface's actual content width.
- **`/home/yemi/.config/quickshell/modules/pill/Power.qml`** — add a `readonly property real contentWidth` that exposes the `tiles` Row's implicit width plus margins, so `Pill.qml` can bind to it.

[Functions]

No new or removed functions. No function signatures change.

[Classes]

No new or removed classes. No class hierarchies change.

[Dependencies]

No new dependencies. No package changes.

[Testing]

No test files exist for the pill surfaces. The fix is visual — reload the shell and verify the power pill's background shape encloses all 7 tiles (profile-cycle + lock, logout, suspend, reboot, hibernate, shutdown) without overflow.

[Implementation Order]

1. Add `contentWidth` property to `Power.qml` that computes the tiles Row's total width including margins.
2. Change `powerW` in `Pill.qml` to bind to `power.contentWidth` instead of the hardcoded `330 * s`.
3. Reload the shell and verify containment visually.
