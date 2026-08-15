# Bugfix playbook — the operational spine

The stage-by-stage conductor the orchestrator follows to drive one bug. At each stage it does **exactly one** of: **delegate to a skill** (Skill tool), **call the adapter** (node, §adapter below), or **apply its own judgment** (only for triage classification and work-log posting). It re-implements nothing.

Read **SKILL.md** first for the core principle, the tier table, the gates, the red-flags list, and the rationalization table. This file is the checklist you execute; the four non-negotiables in SKILL.md are enforced at their stages below.

## Cross-reference conventions

- **Superpowers skills** are cited as `**REQUIRED SUB-SKILL:** Use superpowers:<name>`.
- **Peter's Toolkit skills** are cited by bare backticked name (e.g. `thorough-brainstorming`).
- **The tracker adapter** is a node call, not a skill — see §adapter.
- Never `@`-link a skill file; that force-loads huge context.

## First: resolve state and config

On every invocation, before touching a stage:

1. **Read the harness config** `.claude/bugfix.harness.md` in the target repo (see harness-config.md). Echo the resolved values back at G1 so the human catches drift.
2. **Compute resume position.** Run the deterministic status script (offline git + filesystem — not inference):

   ```
   node <own-skill-base>/scripts/status.mjs "<branch-glob>" <specs-dir> <plans-dir> [id]
   ```

   Pass `branch` (as a glob) and the `artifacts.specs` / `artifacts.plans` dirs from the harness config. It emits JSON: one bug (`/bugfix <id>`) or all in-flight branch-cut bugs (`/bugfix`). The offline **phase** is coarse (`branch cut` / `design done` / `plan done`) — it cannot distinguish Stages 6–9, and a trivial bug stays `branch cut` its whole life.
3. **Narrow, then confirm.** Read the picked bug's ticket work-log (`getTicket`) to narrow the precise stage from the last recorded milestone, then **present the resume point and wait for the human to confirm** before driving. Precision comes from work-log-plus-confirm, never from the offline script alone.
4. **Pre-branch bugs** (Stages 0–2: no branch, no artifacts) are invisible to `status.mjs` — resume them by explicit id and recover context from the work-log (`getTicket`). This is why the G2 work-log entry matters (see work-log.md): it is the only durable record of a root-cause agreement made before the branch exists.

## The stage pipeline (0–9)

| # | Stage | Action | Gate |
|---|-------|--------|------|
| 0 | Pickup / ingest | adapter: `getTicket`, `assign … @me`, `setStatus … in-progress` | — (folded into G1) |
| 1 | Triage & route | **own judgment:** state expected-vs-actual; propose tier; post work-log | **G1** |
| 2 | Reproduce & root cause | `**REQUIRED SUB-SKILL:** Use superpowers:systematic-debugging` (the shared spine) → pause at G2 | **G2** |
| 3 | Isolate + failing test | `**REQUIRED SUB-SKILL:** Use superpowers:using-git-worktrees` (branch per harness convention) → `**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development` (failing reproduction test on the branch) | — |
| 4 | Solution options *(design-only, full)* | `thorough-brainstorming` → `critical-design-review` ⇄ `update-design-doc` (loop until CDR green) | **G4** |
| 5 | Plan *(full)* | `thorough-writing-plans` → `critical-implementation-review` ⇄ `update-implementation-plan` (loop until CIR green) | **G5** |
| 6 | Implement | full: `**REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development`; trivial/design-only: direct TDD fix (make the failing test pass) | — |
| 7 | Verify | `**REQUIRED SUB-SKILL:** Use superpowers:verification-before-completion` + run harness `format` / `test`; original reproduction gone | — |
| 8 | Review | `**REQUIRED SUB-SKILL:** Use superpowers:requesting-code-review` / `superpowers:receiving-code-review` (+ *optional* `critical-security-review` on full/security-relevant) (+ *optional* harness `review_skill`) | **G8** |
| 9 | Finish & writeback | `**REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch` (PR per harness convention, closing keyword); adapter: `linkPullRequest`, `setStatus … done` | — |

### Stage 0 — Pickup / ingest

Adapter calls (see §adapter): `getTicket <id>` (normalize the ticket), `assign <id> @me`, `setStatus <id> in-progress`. No separate gate — it folds into G1.

### Stage 1 — Triage & route (own judgment) — **G1**

State **expected vs. actual** in one or two lines. Then **propose a tier** with explicit reasoning, using this heuristic:

| Signal | Tier |
|---|---|
| Fix is obvious once the root cause is known; single localized change; one defensible approach | **trivial** |
| The *right* behavior needs real thought / there are **multiple defensible approaches**, but once decided the change is **localized** | **design-only** |
| Approach unclear **and** the change is **multi-step / multi-subsystem / risky** | **full** |

**Do not under-tier (non-negotiable #3).** The instant you notice *multiple defensible approaches*, *multiple subsystems touched* (e.g. three cache layers — CDN / Redis / in-process LRU — with several viable invalidation strategies), or *an unclear approach*, the tier is **design-only or full, NOT trivial** — no matter how quick the mechanical change ("just invalidate all three caches") sounds. "The mechanical act is simple, but WHICH calls, in WHAT order, with WHAT error handling are design questions" ⇒ that is a design-only (or full) bug, by definition.

Post the Triage work-log entry (see work-log.md). Then **G1: present the bug statement + proposed tier + the echoed harness config, and wait for the human to confirm or override.** Do not proceed unconfirmed.

### Stage 2 — Reproduce & root cause — **G2 (mandatory STOP)**

`**REQUIRED SUB-SKILL:** Use superpowers:systematic-debugging`. This is the shared investigation spine for **all tiers** — every bug is investigated the same way, to root cause. Reproduce first (for a UI bug, reproduction happens in a browser instead of a REPL/test — the discipline is identical). Do not guess.

**G2 — root-cause sign-off. This is the highest-value gate and a mandatory STOP before any fix, on every tier (non-negotiable #1).** Present the root cause — the *why* — and **wait for the human to sign off.** Never verify your own hypothesis and slide straight into the fix; agree the *why* before the *how*. Post the Root cause work-log entry (see work-log.md) at G2 — on a pre-branch bug this is the only durable record of the agreement.

**The `systematic-debugging` fork.** All tiers run Stage 2 identically and pause at G2. After sign-off:
- **Trivial** resumes straight into Stages 3 → 6 → 7 (systematic-debugging's own natural continuation, which already points to TDD then verification-before-completion).
- **Design-only / full** detour through Stage 4 (and, for full, Stage 5) before Stage 6.

**Needs-info loop.** If Stage 2 cannot reproduce for lack of information, post the "required to proceed" checklist (carried by the adapter skill), call `setStatus … needs-info --label <configured>`, post a work-log entry, and **pause**. The bug re-enters at Stage 2 by explicit id when the reporter responds (it is pre-branch, so not in the picker). Missing information never fails the run — and never licenses guessing at a root cause.

### Stage 3 — Isolate, then failing test first (Iron Law) — no gate, but non-negotiable #2

First `**REQUIRED SUB-SKILL:** Use superpowers:using-git-worktrees` to cut the branch per the harness `branch` convention (this is what makes the bug visible to `status.mjs`).

Then `**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development` to author a **failing reproduction test that lands on the fix branch and fails now, before the fix exists.**

**This is an Iron Law. No exceptions:**
- **Not manual-only** — a manual click-through is not the test.
- **Not test-after** — a test written after the fix passes immediately and proves nothing.
- **Not "add it tomorrow" / "before merge"** — the test comes first, on the branch, or the stage is not done.

**The only honest fallback** — when the project genuinely has no automated path for this class of bug (e.g. some UI defects with no E2E harness) — is a **documented manual reproduction** (steps + expected/actual) **recorded in the work-log, with regression protection explicitly flagged as manual, not automated.** Nothing is ever silently skipped. If an automated test is possible, it is mandatory.

### Stage 4 — Solution options *(design-only, full)* — **G4**

`thorough-brainstorming` (2–3 options → a design) → then the **mandatory review loop**: `critical-design-review` ⇄ `update-design-doc`, **run until the review is green.** Once `thorough-brainstorming` runs, its review runs; if the review is not green, `update-design-doc` applies the findings and `critical-design-review` re-runs — repeat until green. What is *optional* is `thorough-brainstorming` itself (the tier selects it); the review is not optional once the stage runs. `update-design-doc` is a no-op when the review found nothing to apply.

Each of these skills hard-gates against auto-chaining — it stops at a committed artifact and hands back. The orchestrator is the conductor that picks the next one up, runs the loop, and only advances **past G4 once the review is green and the human approves the chosen option / design.** Write the design to the harness `artifacts.specs` dir with the bug id in the filename. Post the Design work-log entry.

### Stage 5 — Plan *(full only)* — **G5**

`thorough-writing-plans` → the **mandatory review loop** `critical-implementation-review` ⇄ `update-implementation-plan`, **run until the review is green** (same loop semantics as Stage 4). Advance **past G5 only once CIR is green and the human approves the plan.** Write the plan to the harness `artifacts.plans` dir with the bug id in the filename. Post the Plan work-log entry.

### Stage 6 — Implement — no gate

- **Full:** `**REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development` to execute the approved plan.
- **Trivial / design-only:** a direct TDD fix — the minimal change that makes the Stage 3 failing test pass.

### Stage 7 — Verify (STOP gate before the PR) — non-negotiable #4

`**REQUIRED SUB-SKILL:** Use superpowers:verification-before-completion`, and run the harness `format` and `test` commands. **Evidence before claims:** confirm the suite is green AND the original reproduction is gone. For a visual UI defect, add a manual browser re-check on top of the suite.

**This is a hard gate. "Ship with monitoring," "merge and watch," or a manual smoke-test in place of the suite are all violations.** Post the Verify work-log entry (Test added / `format` ✅ / `test` ✅ / Original repro gone ✅).

### Stage 8 — Review — **G8 (STOP gate before the PR)** — non-negotiable #4

`**REQUIRED SUB-SKILL:** Use superpowers:requesting-code-review` then `superpowers:receiving-code-review`. On the **full** tier (or any security-relevant change) also run `critical-security-review`. If the harness sets `review_skill`, run it too.

**G8 — human review before the PR is raised. No self-approve; the PR is not opened until the human has reviewed.** "Opening the PR and adding the test / getting review are separable" is false — G8 precedes Stage 9.

### Stage 9 — Finish & writeback — no gate

`**REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch` to open the PR per the harness `pr` convention, including the closing keyword **on its own line in the body** (a title suffix alone won't auto-close). Then adapter: `linkPullRequest <id> <url>` and `setStatus <id> done`. `done` closes via the PR closing keyword, not a label. Post the Done work-log entry.

## §adapter — Tracker adapter invocation

The adapter is a sibling skill's script, invoked by **absolute path** resolved from this skill's own harness-provided base directory, and run **with cwd = the target repo** (so `gh` infers the repo from cwd):

```
node <own-skill-base>/../tracker-adapter/scripts/adapter.mjs github <verb> [args…]
```

Verbs by stage: `getTicket` (0, resume context), `assign` (0), `setStatus` (0, needs-info, 9), `comment` (work-log entries, needs-info checklist), `linkPullRequest` (9). Status-label names come from the harness `status_labels`; a status with no configured label degrades to the adapter's comment fallback. `listCandidates` is unused (deferred).

## Why delegation composes cleanly

Every chain-skill (`thorough-brainstorming`, `thorough-writing-plans`, `critical-design-review`, `critical-implementation-review`, `update-design-doc`, `update-implementation-plan`) hard-gates against auto-chaining: each stops at a committed artifact and hands back. Their natural stop points *are* the orchestrator's gates. The orchestrator picks each one up, runs the gate (looping `CDR ⇄ UDD` / `CIR ⇄ UIP` until green before advancing past G4/G5), and moves to the next. It conducts; it does not duplicate.
