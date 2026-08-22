# ⚠️ DO NOT MERGE — `whole-waffle` (Backup / Reference Only)

This branch is a **frozen backup and reference snapshot** of the full Waffle port
into Yemi-Shell. It exists **only** so we can look back at the Waffle work later
if we decide to re-add Waffle.

## Rules (for humans AND agents)

- **DO NOT MERGE** this branch into `main`, `pill-upgrade-inir-niri`, or any
  feature branch.
- **DO NOT REBASE** or otherwise rewrite it — it is an archive.
- Use it **read-only**: `git checkout whole-waffle -- <path>` to pull a specific
  file if needed, or just browse it for reference.
- The current `main` line is the **Dominance theme** baseline; Waffle is intentionally
  excluded from active development.

## What this branch contains

- The complete Waffle port (bar, panels, settings, services) plus the Pill/waffle
  work, Dominance fixes, and supporting services as of commit `6fb7732`.
- `docs/reference/INIR_WAFFLE_SCOPE.md` describes the original Waffle porting scope.

## History

- Created `2026-08-22` when the user asked to rewind `main` to before the Waffle
  copy and preserve the Waffle state here as a reference branch.
