# Audit 02 — Code Review (qt-qml-review lint pass)

Deterministic lint across all tracked `.qml` files.

## IMP-2 — Versioned imports: 45 occurrences
Qt 6 dropped version numbers; they cap API surface and block `qmlsc`
compilation. Examples of the pattern: `import QtQuick 6.10`,
`import QtQuick.Controls 6.x`, etc. (45 files/lines).
**Fix:** mechanical sweep — strip versions from all Qt module imports.
High-value because `qmlsc`/`qmllint` type inference unlocks the rest.

## IMP-3 — Plain `QtQuick.Controls` + deep customization: 6 files
Customizing `contentItem` / `background` / `indicator` while importing the
style-agnostic module can render differently per style:
- `pill/Calendar.qml`
- `pill/FontPicker.qml`
- `pill/Keybinds.qml`
- `pill/LinkWifi.qml`
- `pill/SearchField.qml`
- `pill/Background.qml`
**Fix:** `import QtQuick.Controls.Basic` in these six.

## IMP-4 — Import ordering
No file passed full Qt→third-party→local ordering check; non-blocking,
`qmlformat --sort-imports` would settle it in one pass.

## IMP-1/IMP-5/IMP-6 — clean
No `Qt.include()`, no duplicate imports, no version-incompatible patterns
found. Good.

## Binding hygiene (deep-analysis spot checks)
- `Backdrop.qml`: the explicit `Connections { onCurrentChanged … }` forwarding
  of `WallpaperState.current` works around flaky singleton bindings — works,
  but is a smell; a single `readonly property` chain through `Flags`/state
  would be cleaner.
- `WallpaperCrossfader.qml`: assigns `undefined` into int/QString bindings
  (see 04-hidden-bugs B3) — the binding chain, not the widget, is at fault.

## Composability note (YemiWorkingRules §architecture)
Settings surfaces (SettingsRow/SettingsSurface/BarPills) now duplicate a
row-declaration pattern that could be one declarative model + Repeater. Not a
bug — flag for the design pass.
