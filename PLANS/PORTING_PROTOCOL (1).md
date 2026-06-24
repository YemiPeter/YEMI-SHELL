# Porting Protocol — Manual Copy, AI as Navigator

> **Companion doc.** Read this alongside `MASTER_PLAN.md` + `CHECKLIST.md`
> before starting ANY task that ports code from a reference source
> (`.Ricelin/`) into the live project. Applies to Phase 3 (Overlay
> Launcher), Phase 4 (Pill Launcher), and any future port task.
>
> **Who does what:** You do the copying, pasting, and refactoring by hand.
> The AI's job is navigation — point you to the right spot, explain what's
> there, scaffold empty files/folders so you have somewhere to paste into.
> The AI never writes ported logic into your project files.

---

## 1. The core rule

The AI never edits your actual feature code. It can `mkdir` a folder or
create an empty file with boilerplate (imports, `pragma Singleton`,
`qmldir` registration line) — but the body of what's being ported is
typed by you, by hand, every time.

---

## 2. What counts as one chunk

Same boundary logic as before:
- One file, if short (~under 80–100 lines)
- One logical section if longer — one function, one component block, one
  property group
- Never two unrelated files in one go

---

## 3. Navigator report format (what the AI gives you per chunk)

> 🔧 **CHUNK [n/total]: <short label>**
>
> 📍 **Source:** `<exact path in .Ricelin/>` — lines X–Y
> 📍 **Destination:** `<exact path in project>` — lines X–Y, or "new file"
>
> 🧠 **What this chunk does:** <2-3 sentences — enough that you understand
> it before you paste, not just transcribe it>
>
> ⚠️ **Adapt when you paste:** <e.g. "rename `Theme.qml`'s singleton import
> path," "swap `pywal.background` → `theme.backgroundColor`"> — described,
> not done for you
>
> 🛠 **Scaffolding:** if the destination file/folder doesn't exist yet, the
> AI creates it empty (folder + boilerplate header) so you have a place to
> paste into — the AI does this part, you do the rest
>
> ⏸ Over to you. Report back when it's in and tested.

---

## 4. What "scaffolding" means, precisely

| Allowed (AI does this) | Not allowed (yours to do) |
|---|---|
| `mkdir` for a new folder | Pasting the ported function/component body |
| Empty file with `pragma Singleton`, imports, `qmldir` entry | Writing the actual logic |
| Pointing out the exact line range in both files | Doing the rename/adapt for you |

---

## 5. Your loop, each chunk

1. Read the chunk explanation — make sure it actually makes sense first
2. Open source + destination side by side
3. Copy → paste, applying the flagged adaptations yourself
4. Test what's testable at this granularity (`qs -p`, or just visual check
   if it's not wired up yet)
5. Report back: `done, works` / `done but X broke` / `confused about Y —
   explain`
6. AI gives you the next chunk

If a chunk's logic doesn't click as you're pasting it — ask before moving
on. That's the moment for a real explanation, not a summary.

---

## 6. STOP conditions

- The chunk depends on something not yet ported (a singleton/component
  from a later chunk) — AI flags this, you decide: stub it, or reorder
- The actual file on disk doesn't match what the checklist describes —
  don't paste against a guess, stop and check
- You've adapted something and it doesn't match the mapping table in
  `CHECKLIST.md` — flag the mismatch before continuing, don't silently
  pick one

---

## 7. Testing cadence

Test after every chunk if it's testable standalone. If a chunk only makes
sense wired into something else (e.g. `AppRow.qml` needs `Launcher.qml` to
render), test after the smallest group of chunks that forms one working
unit — not after the whole file/feature.
