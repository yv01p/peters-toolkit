---
name: create-handoff
description: Use when the context window is overwhelmed or nearing its limit, or when transitioning work to a fresh session or new agent - generates a structured technical handoff document that captures all session state, mental models, and decisions for seamless continuation
version: 2.0.0
---

# Create Handoff

## Overview

Generate a high-quality technical state-dump and structured handoff document so a fresh agent (zero context) can continue work seamlessly. The document must transfer **mental models and decisions**, not just status — what you know that git history cannot show.

## Process

### Step 1 — Gather State (Run All Commands First)

```bash
git rev-parse HEAD               # Full SHA
git branch --show-current        # Branch name
git status --short               # Staged/unstaged changes
git diff HEAD --stat             # Files touched this session
git log --oneline -8             # Recent commit context
git stash list                   # Any stashed work
```

### Step 2 — Determine Filename

```
handoffs/YYYY-MM-DD_HH-MM-SS_[2-4-word-slug].md
```

Example: `handoffs/2026-03-11_18-12-00_fix-auth-telemetry.md`

Use `date +%Y-%m-%d_%H-%M-%S` for the timestamp.

### Step 3 — Write the Document (Template Below)

Every file reference **must** use `path/to/file:line` syntax for Ctrl/Cmd+Click navigation. No bare filenames.

### Step 4 — Save and Acknowledge

```bash
mkdir -p handoffs
# write the file
git add handoffs/[FILENAME].md
```

Then output **exactly**:

```
Handoff successfully generated. Context preserved at: handoffs/[FILENAME].md

Clear your context window and run the resume command to continue.
Resume command:

resume handoff handoffs/[FILENAME].md
```

---

## Handoff Template

````markdown
---
date: [ISO 8601 Timestamp]
git_commit: [Full SHA — never abbreviate]
branch: [Branch name]
repository: [Repo root directory name]
topic: "[Ticket/Task] Transition Summary"
tags: [handoff, session-transition, relevant-tech-tags]
status: in_progress
last_updated: [YYYY-MM-DD]
type: implementation_handoff
---

# Handoff: [Concise Title]

## 0. Executive Summary (TL;DR)

[3 sentences MAX — rigid format:]
1. What was I doing and why?
2. Where did I stop exactly?
3. What is the single most important next action?

## 1. Technical State

**Active Working Set** (files in high rotation right now):
- `path/to/file.ts:42` — [why this file matters this moment]
- `path/to/other.ts:100` — [current concern]

**Current Errors / Blockers:**
```
[Paste EXACT error string — do not paraphrase. Fresh agent will grep/search for this.]
```
Or: `None`

**Environment:**
- Uncommitted changes: [yes/no — list specific files if yes]
- Staged changes: [list files, or none]
- ENV vars or config required: [any non-obvious ones]
- Any running processes / background jobs: [or none]

## 2. Progress Tracker

| Task | Status | Location | Notes |
|------|--------|----------|-------|
| [Task A] | ✅ Complete | `file:line` | |
| [Task B] | 🔄 In Progress | `file:line` | Blocked by X |
| [Task C] | ⏳ Pending | — | Depends on Task B |
| [Task D] | ❌ Abandoned | — | Tried, failed — see §3 |

## 3. Mental Model (Most Critical Section)

**Why the current approach was chosen:**
[Explain the reasoning. What alternatives were considered and rejected? What constraints forced this design? This is what git history cannot show.]

**Codebase Gotchas Discovered This Session:**
- `path/to/file:line` — [the surprise and what it means]
- [Pattern that seemed obvious but wasn't]

**Dead Ends — Do Not Repeat These:**
| Approach Tried | Why It Failed | Evidence |
|---------------|---------------|----------|
| [Did X] | [Failed because Y] | `file:line` |
| [Tried library Z] | [Incompatible with W] | — |

**Key Decisions Made:**
| Decision | Rationale | Alternative Rejected |
|----------|-----------|---------------------|
| [Chose approach A] | [Because of constraint X] | [B — caused Y] |

**Assumptions in Play:**
- [Assumption 1] — [what breaks if this is wrong]
- [Assumption 2]

## 4. Delta — Changes Made This Session

[Only changes NOT yet in git history, or changes since last commit:]
- `path/to/file.ts:42` — [WHAT changed and WHY — not just "updated the handler"]
- `path/to/other.ts:100` — [the intent behind the diff]

[If no uncommitted changes: "All changes committed — see git log above."]

## 5. Next Steps (Ordered — Do Not Skip Steps)

1. **Verify state** (run first to confirm environment):
   ```bash
   [exact command — e.g.: npm test src/auth 2>&1 | tail -20]
   ```
   Expected output: `[what success looks like]`

2. **Immediate action**: [single concrete next task — be specific]
   - Location: `path/to/file:line`

3. **Then**: [next sub-task after immediate]

4. **Verification**: `[exact test/check command]` — expect `[expected result]`

5. **Watch for**: [specific failure mode or edge case to anticipate]

## 6. Artifacts & References

- **Design doc / ADR**: `path/to/doc.md` (or N/A)
- **New files created this session**: `path/to/new-file.ts`
- **Key external references consulted**: [URLs or docs — be specific]
- **Related tickets / issues**: [links]
````

---

## Quality Checklist

Before saving, verify every item:

- [ ] Every file reference has a line number — `file.ts:42` not `file.ts`
- [ ] Executive summary is exactly 3 sentences in the rigid format
- [ ] Current error section has **exact** error text, not a paraphrase
- [ ] Mental model §3 explains **WHY**, not just WHAT
- [ ] Dead ends table is populated (prevents next agent repeating failures)
- [ ] Next Steps §5 starts with a state-verification command
- [ ] Progress tracker statuses are accurate
- [ ] All git state commands were run before writing (commit SHA is real)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Bare file refs: "see the auth module" | `src/auth/handler.ts:127` |
| Summary is just a status update | Include the one concrete next action |
| §3 restates the task description | Explain the *why* and *trade-offs* |
| Error paraphrased: "auth was failing" | Paste exact: `Error: JWT malformed at line 42` |
| Next steps: "continue the work" | "Run `npm test src/auth` — fix the 2 failing tests in `handler.test.ts:55`" |
| Missing dead ends | Always document failed approaches, even brief ones |
| Abbreviated git SHA | Always use full SHA from `git rev-parse HEAD` |
