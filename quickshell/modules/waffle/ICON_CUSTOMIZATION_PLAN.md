# Waffle Launcher — Icon Customization Notes

Personal reference / future-plan scratchpad. Not wired into anything yet.

## TL;DR — is changing the launcher icon easy?
YES. Trivially possible.

- Launcher (Start) icon is a single fixed file: `assets/icons/fluent/start-here.svg`
- Referenced statically at `modules/waffle/bar/StartButton.qml:17` -> `iconName: "start-here"`
- Resolved via `modules/waffle/looks/WAppIcon.qml:27` -> `${Looks.iconsPath}/${iconName}.svg`
- `Looks.iconsPath` = `assets/icons/fluent` (`modules/waffle/looks/Looks.qml:18`)

Two ways to change it (no code change for the first):
1. Swap the file: replace `assets/icons/fluent/start-here.svg` with your own SVG (same name). Instant.
2. Repoint: set `StartButton.qml:17` to `iconName: "my-launcher"` and drop `my-launcher.svg` in the same folder.

Why it's the EASIEST icon in the bar: it's a fixed name, not state-driven
(unlike volume/battery/mic/search-checked which swap on state).

## Planned upgrade: user-changeable icons (deferred)
Goal: let users change icons easily without editing QML.

Central chokepoint already exists: every bar icon routes through
`WAppIcon` + `Looks.iconsPath`. So two clean angles:

### A. Icon-pack swap (change everything at once)
Add config `Config.options.waffles.bar.iconPack` (default "fluent") and make
`Looks.iconsPath` select the subdir:
    property string iconsPath: `${Directories.assetsPath}/icons/${Config.options?.waffles?.bar?.iconPack ?? "fluent"}`
Users drop `assets/icons/<pack>/` full of same-named SVGs and pick from settings.

### B. Per-icon overrides (fine-grained)
Add `Config.options.waffles.bar.iconOverrides: { "start-here": "my-start", ... }`
and have `WAppIcon` consult it:
    property string resolved: (Config.options?.waffles?.bar?.iconOverrides ?? {})[root.iconName] ?? root.iconName
    source: `${Looks.iconsPath}/${resolved}.svg`
Needed for state-driven icons (SystemButton volume/battery/mic, SearchButton
checked state) that a pack swap can't always cover.

### C. UI in existing style page
`modules/waffle/settings/pages/WWaffleStylePage.qml:241` already references
`start-here`. Extend with: icon-pack dropdown (lists subdirs of
`assets/icons/`) + per-button override pickers.

### D. Avoid the "apple" fallback trap
`WAppIcon.qml:26` `fallback: root.iconName` falls back to the SYSTEM icon theme
when a custom SVG is missing (that's why a missing `start-here-pressed` showed
a GNOME apple). When overrides/packs are user-facing, fall back to the DEFAULT
pack's copy instead of the system theme, so a typo degrades to the normal icon
rather than a foreign one.

## Suggested first cut
Implement A + C (pack selector + settings UI). Highest impact, lowest risk,
builds on the existing centralized `WAppIcon`.

## Constraints / reminders
- Do NOT touch ghostty/, hypr/, kitty/, niri/, or /docs.
- Keep working-tree-only edits; no commits unless asked.
