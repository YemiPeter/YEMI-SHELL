# Task: Confirm Discrepancy Report — Show Your Work, Teach the Method

## Why this prompt exists

A previous agent produced a report claiming mismatches between
`CHECKLIST.md`'s design and Ricelin's actual implementation. Before any
decision (Option A vs B) gets made, EVERY factual claim in that report
must be independently checked against the real files on disk — not
re-stated, not assumed, not trusted because it sounds thorough.

You are not redoing the analysis. You are auditing it.

---

## Rules — non-negotiable

1. For each claim in Section B, run the actual command and paste the
   **raw, unedited** output. Never paraphrase output as if it were a quote.
2. **Before** each command, explain in plain English: what the command
   does, and why THIS command is the right way to check THIS specific
   claim. This explanation is the point — the user is learning the method,
   not just collecting a verdict.
3. After the output, give one explicit verdict: `CONFIRMED`,
   `CONTRADICTED`, or `PARTIAL` (state exactly what part differs).
4. If the output contradicts the original report, say so plainly. Do not
   soften it, rationalize it, or assume the report meant something else.
5. Don't skip a claim because it "seems obviously true." Every claim gets
   a command and real output — no exceptions for confidence level.
6. If a file/path doesn't exist where expected, that's information, not a
   failure to paper over — show the actual error, don't substitute a guess
   for what probably would have been there.

---

## Section A — What to check against

Original discrepancy report (5 discrepancies + pre-flight checks) from the
prior agent. [Paste the full report here when sending this prompt.]

---

## Section B — Claims to verify, with commands

### Pre-flight claims
| # | Claim | Command |
|---|---|---|
| 1 | Current git branch is `restructure/clean-tree` | `git branch --show-current` |
| 2 | matugen 4.1.0 installed at `/usr/bin/matugen` | `matugen --version && which matugen` |
| 3 | `singletons/` doesn't exist yet | `ls -d ~/.config/quickshell/singletons 2>&1` |
| 4 | `services/qmldir` has both Pywal and Matugen active (uncommented) | `cat ~/.config/quickshell/services/qmldir` |

### Discrepancy 1 — architecture doc
| # | Claim | Command |
|---|---|---|
| 5 | `theme-system-architecture.md` shows as deleted in git, not just moved | `git status PLANS/theme-system-architecture.md` then `git log --all --diff-filter=D -- PLANS/theme-system-architecture.md` |

### Discrepancy 2 — Dyn.qml
| # | Claim | Command |
|---|---|---|
| 6 | Real path is `~/.cache/ricelin/colors.json`, not `~/.cache/matugen/colors.json` | `grep -n "cache/" ~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml` |
| 7 | Uses `JsonAdapter`, not manual `JSON.parse` | `grep -n "JsonAdapter\|JSON.parse" ~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml` |
| 8 | The ~17 named properties (`surface`, `cream`, `tickRest`, etc.) | `cat ~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Dyn.qml` |

### Discrepancy 3 — Theme.qml
| # | Claim | Command |
|---|---|---|
| 9 | ~40 properties, none matching checklist's canonical 5 | `grep -n "property" ~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Theme.qml \| wc -l` then `cat` the file |
| 10 | No `isLightMode`; depends on `Flags` singleton | `grep -n "isLightMode\|Flags\." ~/.config/quickshell/.Ricelin/configs/quickshell/pill/Singletons/Theme.qml` |

### Discrepancy 4 — color pipeline
| # | Claim | Command |
|---|---|---|
| 11 | `wallcolors.py` exists and does histogram analysis via ImageMagick | `find ~/.config/quickshell/.Ricelin -iname "wallcolors.py" -exec cat {} \;` |
| 12 | It separately shells out to `matugen color hex ... -m dark -j hex` | `grep -n "matugen" <path found in #11>` |
| 13 | Light/dark threshold is `mean_l >= 0.40` | `grep -n "mean_l\|0.4" <path found in #11>` |
| 14 | Neither cache JSON file exists yet on this system | `ls ~/.cache/matugen/colors.json ~/.cache/ricelin/colors.json 2>&1` |

---

## Section C — Teach-back (mandatory, after all claims)

Write a short section titled "How to verify this yourself next time"
covering, in plain language, no unexplained jargon:

- For each *type* of claim above (property-list claims, path claims,
  deleted-file claims, behavior-in-a-script claims) — what's the general
  command pattern, and why does it work
- What language patterns in an agent's report are red flags that mean
  "verify this before trusting it" — e.g. confident claims with zero
  quoted output, round numbers ("~40 properties") without a count shown,
  behavioral claims about a script with no line cited

---

## Output format — use exactly this per claim

> **Claim N: `<short label>`**
> 🧠 Why this command: `<plain-English reason this specific command proves
> or disproves this specific claim>`
> 💻 Command: `<exact command>`
> 📋 Real output:
> ```
> <paste raw output here>
> ```
> ✅/❌ Verdict: `CONFIRMED` / `CONTRADICTED` / `PARTIAL` — `<one-line why>`

---

## Final summary (required)

After all 14 claims: one table — claim # | verdict | one-line note. End
with a single line: either `ALL CLAIMS HOLD` or `MISMATCHES FOUND: <list
the claim numbers>`.
