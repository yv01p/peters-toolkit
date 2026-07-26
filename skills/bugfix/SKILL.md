---
name: bugfix
description: Use when fixing a reported bug end to end, when a fix looks like a quick one-liner, when under deadline pressure to ship a fix, when a bug spans multiple subsystems or has several defensible fixes, or when tempted to skip the failing test, the root-cause sign-off, or the review gate before opening a PR.
version: 1.0.0
---

# Bugfix

## Overview

The `bugfix` orchestrator is a **conductor**: it drives one bug, locally, from pickup to a merged fix, delegating every hard step to skills that already exist (superpowers + Peter's Toolkit) plus the tracker adapter. It re-implements none of their logic — it sequences the stages, enforces the human gates, routes by complexity tier, reads the per-project harness config, and writes the ticket work-log.

**Core principle: the orchestrator IS the always-present, staged, tier-routed, human-gated process, so the default path is the disciplined one.** Left to improvise, a capable agent under deadline pressure defaults to ad-hoc symptom-fixing: patch the symptom, test by hand, open the PR, "add the real test tomorrow." This skill exists so that never happens — every bug, trivial or full, walks the same pipeline through the same STOP gates. **Violating the letter of the process is violating the spirit of the process.**

## When to use

- Fixing any reported bug end to end, on any project with a harness config.
- The moment a fix "looks obvious" or "looks like a quick one-liner" — that is exactly when under-tiering and test-skipping happen.
- Under deadline/authority pressure to ship a fix fast.
- Whenever you catch yourself about to skip the failing test, the root-cause sign-off, or the pre-PR review gate.

Not for: greenfield feature work (use `thorough-brainstorming` → `thorough-writing-plans`); tracker mechanics themselves (the tracker adapter's job).

## Invocation

Invoked as `/bugfix [id]`, always from within the target repo (the orchestrator and the adapter both operate on that cwd).

- **`/bugfix <id>`** — start a new bug at that id, or resume it if work already exists. On resume, run `status.mjs` for the id, state the resume point, and **wait for the human to confirm** before continuing.
- **`/bugfix`** (no id) — run `status.mjs` across all in-flight (branch-cut) bugs and present a **picker**. The human picks one; narrow the exact spot from that bug's ticket work-log and confirm. Or supply a new id to start.

```
You have 3 bugs in progress:
  #123  Cache not invalidating    → plan done (in progress)
  #456  Off-by-one in pager       → branch cut (in progress)
  #789  Login redirect loop       → branch cut (in progress)

Pick one to resume — I'll narrow the exact spot from the ticket work-log and confirm with you.
Or give me a new ticket number to start.
```

The picker only sees bugs that have cut a branch (Stage 3+). Pre-branch bugs (Stages 0–2, e.g. paused in the needs-info loop) are resumed by explicit id; the orchestrator reads the ticket work-log (`getTicket`) to recover context. Full resumption mechanics live in **playbook.md**.

## The three tiers + gates (quick reference)

Selected at triage (G1): the orchestrator proposes a tier with its reasoning; the human confirms or overrides. Tiers differ **only** in whether Stages 4 and 5 run and how Stage 6 executes. All three share Stages 0–3 and 7–9.

| Tier | Stage 4 (design) | Stage 5 (plan) | Stage 6 (implement) | Gates | When |
|---|---|---|---|---|---|
| **Trivial** | — | — | direct TDD fix | G1, G2, G8 | Fix obvious from root cause |
| **Design-only** | `TB → CDR ⇄ UDD` | — | direct TDD fix | G1, G2, **G4**, G8 | Approach unclear, but the change is localized |
| **Full** | `TB → CDR ⇄ UDD` | `TWP → CIR ⇄ UIP` | `subagent-driven-development` | G1, G2, G4, **G5**, G8 (+ security review) | Approach unclear **and** multi-step / risky |

`CDR ⇄ UDD` / `CIR ⇄ UIP` = a mandatory review loop, run until the review is green. The fourth combination — plan without design — is deliberately not offered.

**The gates are mandatory human checkpoints — the orchestrator presents them in-chat and waits for approval before continuing:**

- **G1** — confirm the bug statement + tier classification.
- **G2** — **root-cause sign-off. A STOP before any fix, on all tiers.** Agree on *why* before *how*.
- **G4** *(design-only, full)* — approve the design / chosen option.
- **G5** *(full)* — approve the plan.
- **G8** — **human review before the PR is raised.** No self-approve.

## The four non-negotiables

These close the failures agents fall into the instant the process isn't enforced. They are Iron Laws, not preferences.

1. **G2 root-cause sign-off is a mandatory STOP before any fix — every tier, no exceptions.** Never verify your own hypothesis and proceed straight to the fix. Agree the *why* with the human first.
2. **Stage 3: the failing reproduction test comes first — Iron Law.** Not manual-only, not test-after, not "add it tomorrow." The test lands on the fix branch and fails *before* the fix exists. The only honest fallback (no automated path exists, e.g. some UI bugs, §11) is a **documented manual reproduction recorded in the work-log AND flagged as manual regression protection** — never a silent skip.
3. **Never under-tier.** Multiple defensible approaches, multiple subsystems touched, or an unclear approach ⇒ **design-only or full, NOT trivial** — even when the mechanical change sounds like a one-liner ("just bust all the caches, it's quick"). "Simple" chooses the tier; it never skips a gate.
4. **Stage 7 verify + G8 review are STOP gates before the PR.** Full verify (harness `format` + `test`, original reproduction gone) and human sign-off precede the PR. No self-approve, no "ship and monitor," no opening the PR with the test deferred.

## Red flags — STOP

If you catch yourself thinking or writing any of these, you are rationalizing a violation. Stop and run the stage:

- "Pragmatic, not dogmatic" / "pragmatic middle ground" / "pragmatic deadline-driven development"
- "Perfect is the enemy of done"
- "Manual testing is enough" / "provides reasonable confidence" / "basic smoke-test verification"
- "Add the test tomorrow" / "before merge" / "first thing tomorrow"
- "Ship with monitoring" / "merge directly but add extra monitoring"
- "The fix is simple / low-risk enough"
- "Opening the PR and adding the test are separable actions"
- "The hard stop / deadline is non-negotiable" (used to justify skipping the test)
- "I'm being transparent about the shortcut, so it's OK"
- "Just bust all the caches, it's quick" (an under-tiering tell)

**All of these mean: stop, return to the pipeline, and run the stage you were about to skip.**

## Rationalization table

| Excuse | Reality |
|---|---|
| "Pragmatic, not dogmatic" / "pragmatic middle ground" | The staged path IS the pragmatic one — it is what stops a 6pm one-liner from becoming tomorrow's incident. Process discipline erodes one exception at a time. Run the stage. |
| "Perfect is the enemy of done" | A fix with no failing test isn't "done," it's unverified. The failing-test-first law is the definition of done here, not gold-plating. |
| "Manual testing is enough" / "reasonable confidence" | Manual testing proves the bug is gone once, on your machine — zero regression protection. If no automated path exists, record the manual repro AND flag protection as manual (§11); never silently substitute it for the test. |
| "Add the test tomorrow / before merge" | The test goes on the branch BEFORE the fix — that is what proves the fix works and the bug was real. A test written after passes immediately and proves nothing. "Tomorrow" tests don't get written. |
| "Ship with monitoring" | Monitoring is not verification. Stage 7 (format+test, original repro gone) and G8 human review are STOP gates before the PR. You do not merge-then-watch. |
| "The fix is simple / low-risk enough" | "Simple" chooses the tier; it never skips a gate. Multiple defensible approaches / multi-subsystem / unclear approach ⇒ design-only or full, NOT trivial. Even a true trivial still stops at G2 and writes the failing test. |
| "Opening the PR and adding the test are separable actions" | They are not. The failing test is Stage 3; the PR is Stage 9. You cannot reach 9 without 3, and G8 review precedes the PR. |
| "The hard stop / deadline is non-negotiable" | The deadline is real; the shortcut is a choice. If a fix is urgent enough to bypass the workflow, that call belongs to a lead, made explicitly — not to you, made unilaterally under pressure. |
| "I'm being transparent about the shortcut, so it's OK" | Announcing a violation doesn't authorize it. Transparency is necessary, not sufficient. Stop and run the stage. |
| "Just bust all the caches, it's quick" | The mechanical change is quick; WHICH caches, in WHAT order, with WHAT invalidation strategy are design questions. Multi-subsystem ⇒ design-only or full. Route it, don't hack it. |

## Reference docs

Detail lives in the flat reference files beside this one — read them as you drive:

- **playbook.md** — the operational spine: Stages 0–9, per-stage delegation, the gates, the `review ⇄ update` loops, the needs-info loop, and the `systematic-debugging` fork. **This is what you follow to run a bug.**
- **harness-config.md** — the `.claude/bugfix.harness.md` format, the annotated Umbraco example, and how to author your own.
- **work-log.md** — the ticket work-log template, the hidden-marker convention, and the milestone → fields table.
- **customizing.md** — the extension points and the condensed decisions & rationale (why each seam is safe to change).
