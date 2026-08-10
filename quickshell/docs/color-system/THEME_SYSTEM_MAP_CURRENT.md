# Theme System Map — Current Pipeline

> Section 13 — Yemi-shell Theme Rebuild. Describes the ACTIVE color pipeline.
> Generated: 2026-08-10

## 1. Pipeline overview

```
after-wall.sh ──► matugen (CLI) ──► ~/.cache/yemi-shell/colors.json (v2)
                                        │
                                        ▼
                                   Dyn.qml (FileView)
                                        │
                                        ▼
                              Appearance.qml (adapter)
                                        │
                                        ▼
                                  Theme.qml (facade)
```

- **after-wall.sh** is the **single writer** of `colors.json`. It runs Matugen twice
  (once `-m dark`, once `-m light`) and writes both schemes into one v2 contract:
  `{ "version": 2, "dark": {…}, "light": {…} }`.
- **Dyn.qml** watches the file and parses the nested dark/light objects into
  `Dyn.darkScheme` / `Dyn.lightScheme`; `Dyn.active` follows `Flags.systemMood`.
- **Appearance.qml** resolves the Yemi compatibility tokens (surfaces + text).
- **Theme.qml** maps the old public token names onto Appearance's resolved tokens.

## 2. Async reload chain

```
qs ipc call colors reload
  └─► Dyn.reload()          // thin wrapper — only forces FileView
        └─► file.reload()   // FileView re-reads colors.json
              └─► onLoaded
                    └─► applyLoaded()   // parse JSON, assign schemes
                          └─► _revision++  // bump → bindings refresh
```

Parsing never happens inside `reload()`; it only runs after FileView finishes
loading, so stale text is never read.

## 3. Failure fallback (safety net)

- `Dyn.schemeValid` is `true` when a real v2 scheme loaded, `false` when the file
  is missing/corrupt and Dyn fell back to its hand-picked palette.
- In **Appearance.qml**, surfaces and text resolve to the active mood solids
  (near-black in dark mood, near-white in light mood) **only when the scheme is
  invalid**. When the scheme is valid, the dynamic/ensureReadable values are used
  unchanged.

## 4. FileView inode preservation

`after-wall.sh` writes with `cat > colors.json` (never `mv`), preserving the file
inode so FileView's `watchChanges` keeps firing on the same watched file.

## 5. Legacy / rollback

The old `wallcolors.py` pipeline is **not** the active path. It is preserved at
`scripts/legacy/wallcolors.py` as a rollback safety net only, and can be selected
via `YEMI_LEGACY_COLORS=1` in `after-wall.sh`.