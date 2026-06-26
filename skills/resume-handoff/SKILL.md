---
name: resume-handoff
description: Use when continuing work after a context window was cleared, when given a handoff file path to resume from, or when a previous session ended with a create-handoff acknowledgment message
version: 2.0.0
---

# Resume Handoff

## Overview

Resume a previous session with zero-ambiguity by fully validating the handoff document against current repository state, then continuing work with the original mental models and decisions intact. Never trust the handoff blindly — always verify.

## Invocation

**With path provided** (e.g. `/resume-handoff handoffs/2026-03-11_18-12-00_fix-auth.md`):
→ Read the file immediately and proceed to Step 1.

**No path provided:**
→ Respond exactly:

```
No handoff path specified. Available handoffs:
```
Then run `ls -lt handoffs/*.md 2>/dev/null | head -10` and list them. Ask the user which to resume.

---

## Process

### Step 1 — Read & Gather Current State (Run in Parallel)

Read the entire handoff document (no limit/offset). Simultaneously run all six git commands from `create-handoff`:

```bash
git rev-parse HEAD               # Compare to handoff git_commit
git branch --show-current        # Compare to handoff branch
git status --short               # Detect uncommitted changes not in handoff
git diff HEAD --stat             # Files changed since last commit
git log --oneline -8             # Commits since handoff's git_commit
git stash list                   # Stashed work
```

### Step 2 — Validate Every Handoff Section

Verify each section from the handoff against current reality. Run checks in parallel:

| Handoff Section | What to Verify |
|----------------|----------------|
| **§0 Executive Summary** | Is the "where stopped" description still accurate given git log? |
| **§1 Technical State → Active Working Set** | Do all `file:line` refs exist? Is that line still the relevant location? |
| **§1 Technical State → Current Errors/Blockers** | Does the exact error still reproduce? Has it been silently fixed? |
| **§1 Technical State → Environment** | Do uncommitted changes listed still exist? Do required ENV vars exist? |
| **§2 Progress Tracker** | Is each ✅/🔄/⏳/❌ status still accurate given current git state? |
| **§3 Mental Model → Dead Ends** | Do all dead-end `file:line` refs still exist? Are they still dead ends? |
| **§3 Mental Model → Assumptions** | Are the listed assumptions still valid? |
| **§4 Delta** | Reconcile: are the listed uncommitted changes still uncommitted, or were they committed? |
| **§5 Next Steps** | Is Step 1's verify command still the right starting point? |
| **§6 Artifacts** | Do all referenced files/docs still exist at the listed paths? |

### Step 3 — Present Fidelity Report

Output this exact structure (fill in all fields — never omit a section):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF RESUME ANALYSIS
Handoff: [handoff title from # heading]
Created: [date from frontmatter]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FIDELITY SCORE: XX/100
  SHA match:              +20  (or 0 — [actual SHA vs handoff SHA])
  All files exist:        +20  (or partial — list missing)
  Error state accurate:   +20  (or 0 — error resolved / changed)
  Progress tracker valid: +20  (or partial — list stale statuses)
  Next steps relevant:    +20  (or 0 — outdated by new commits)

━━━ §0 EXECUTIVE SUMMARY ━━━
[Restate the 3 sentences from the handoff — note any that are now stale]

━━━ §1 TECHNICAL STATE ━━━
Active Working Set (verified):
  • path/to/file.ts:42  ✅ exists / ❌ missing / ⚠️ line shifted to :67
  • ...

Current Errors / Blockers:
  [Exact error string from handoff — still present / resolved / changed to: ...]

Environment Delta:
  • Uncommitted changes: [matches handoff / differs: list specifics]
  • Staged changes: [matches / differs]
  • New stash entries since handoff: [yes/no]

━━━ §2 PROGRESS TRACKER (UPDATED) ━━━
| Task | Handoff Status | Current Status | Notes |
|------|---------------|----------------|-------|
| ... | ✅ Complete | ✅ Confirmed | |
| ... | 🔄 In Progress | 🔄 Still open | |
| ... | ⏳ Pending | ✅ Already done | Committed in [SHA] |

━━━ §3 MENTAL MODEL ━━━
Why current approach (from handoff — still valid / partially stale):
  [Restate. Flag any assumptions that have changed.]

Dead Ends (DO NOT REPEAT):
  • [approach] — [why failed] — still applies / no longer relevant because [X]

Assumptions status:
  • [Assumption 1] — ✅ still valid / ❌ broken: [what changed]

━━━ §4 DELTA RECONCILIATION ━━━
  Changes from handoff §4 now in git: [committed in SHA / still uncommitted]
  New changes since handoff not documented: [list files or "none"]
  Conflicts or regressions found: [yes + details / no]

━━━ §5 NEXT STEPS (VALIDATED) ━━━
  Handoff's Step 1 (verify command): [still valid / updated to: ...]
  Recommended starting point: [exact command]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VERDICT: [Clean continuation / Diverged codebase / Stale handoff / Regressions found]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Shall I proceed with the first validated next step, or would you like to
review any section above before we continue?
```

**Wait for explicit user confirmation before Step 4.**

### Step 4 — Build Action Plan

Convert §5 Next Steps (validated) into a prioritized task list using TodoWrite or equivalent. Present clearly.

Start with the state-verification command from §5 Step 1 — always run this first before touching any code.

### Step 5 — Execute

- Begin with the highest-priority validated task.
- Reference §3 Mental Model constantly — never repeat a dead end.
- Use `path/to/file:line` for every file mention.
- Reproduce errors from exact strings in §1, not from memory or paraphrase.
- After each major task: update your internal progress tracker and surface the updated §2 table to the user.
- When context fills again or work reaches a natural stopping point: **automatically prompt** `Run /create-handoff to preserve this state before continuing.`

---

## Fidelity Score Interpretation

| Score | Verdict | Action |
|-------|---------|--------|
| 90–100 | Clean continuation | Proceed immediately after confirmation |
| 70–89 | Minor drift | Review flagged items, then proceed |
| 50–69 | Diverged codebase | Discuss delta with user before starting |
| < 50 | Stale handoff | Reconstruct current state; treat handoff as reference only |

---

## Common Scenarios

| Scenario | Response |
|----------|----------|
| SHA matches, files exist, no errors | Full confidence — clean resume |
| SHA differs (new commits since handoff) | Show `git log` delta; re-validate §5 next steps |
| File in §1 no longer exists | Flag immediately; ask user before assuming it was deleted intentionally |
| Error in §1 no longer reproduces | Mark as resolved in tracker; skip its associated next steps |
| Dead end from §3 is being suggested as a fix | Block it — cite the exact entry from §3 and explain why |
| §2 shows ⏳ Pending but it's already committed | Update status to ✅; adjust next steps accordingly |

---

## Hard Rules

1. **Never skip the fidelity report** — even for a score of 100/100.
2. **Never paraphrase errors** — use exact strings from §1.
3. **Never retry a dead end** from §3, regardless of how promising it looks now.
4. **Never start implementation** without explicit user confirmation after Step 3.
5. **Never use bare filenames** — always `path/to/file:line`.
